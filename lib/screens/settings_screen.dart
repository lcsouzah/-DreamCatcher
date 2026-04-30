import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/health_connect_service.dart';
import '../services/storage_keys.dart';
import '../widgets/card.dart';
import '../widgets/permission_pill.dart';
import '../widgets/primary_button.dart';
import '../themes/app_theme.dart';
import 'health_test_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HealthConnectService _healthService = HealthConnectService();

  bool _sleepGranted = false;
  bool _healthAvailable = true;
  bool _loadingPermissions = true;

  bool _notificationsEnabled = false;
  bool _darkModeAccentIntensityEnabled = false;
  bool _healthConnectAutoSyncEnabled = false;
  bool _supabaseEnabled = false;
  bool _debugEnabled = false;
  bool _useMockData = false;


  String _appVersion = 'Loading…';
  String _buildNumber = '';

  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final bool useMock = prefs.getBool(StorageKeys.useMockData) ?? false;
    final PermissionStatusData permissionStatus =
    await _getPermissionStatus(useMockData: useMock);

    if (!mounted) {
      return;
    }

    setState(() {
      _prefs = prefs;
      _notificationsEnabled =
          prefs.getBool(StorageKeys.enableNotifications) ?? false;
      _darkModeAccentIntensityEnabled =
          prefs.getBool(StorageKeys.darkModeAccentIntensity) ?? false;
      _healthConnectAutoSyncEnabled =
          prefs.getBool(StorageKeys.healthConnectAutoSync) ?? false;
      _supabaseEnabled = prefs.getBool(StorageKeys.enableSupabase) ?? false;
      _debugEnabled =
          prefs.getBool(StorageKeys.enableDebugLogging) ?? false;
      _useMockData = useMock;
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      _applyPermissionStatus(permissionStatus);
      _loadingPermissions = false;
    });
  }

  Future<PermissionStatusData> _getPermissionStatus({bool? useMockData}) async {
    final bool usingMock = useMockData ?? _useMockData;
    if (usingMock) {
      return const PermissionStatusData(sleepGranted: true, healthAvailable: true);
    }

    final bool healthAvailable = await _healthService.isAvailable();
    final bool sleepGranted = healthAvailable && await _healthService.hasPermissions();

    return PermissionStatusData(sleepGranted: sleepGranted, healthAvailable: healthAvailable);
  }

  void _applyPermissionStatus(PermissionStatusData status) {
    _sleepGranted = status.sleepGranted;
    _healthAvailable = status.healthAvailable;
  }

  Future<void> _refreshPermissions() async {
    setState(() {
      _loadingPermissions = true;
    });
    final PermissionStatusData status = await _getPermissionStatus();
    if (!mounted) {
      return;
    }

    setState(() {
      _applyPermissionStatus(status);
      _loadingPermissions = false;
    });
  }

  Future<void> _requestSleepPermission() async {
    if (_useMockData) {
      return;
    }

    final bool granted = await _healthService.requestPermissions();
    if (!mounted) return;

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sleep permission not granted.')),
      );
    }

    await _refreshPermissions();
  }

  Future<void> _toggleMockData(bool value) async {
    final SharedPreferences prefs =
        _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.useMockData, value);

    if (!mounted) {
      return;
    }

    setState(() {
      _prefs = prefs;
      _useMockData = value;
      if (value) {
        _sleepGranted = true;
      }
    });

    if (!value) {
      await _refreshPermissions();
    }
  }

  Future<void> _toggleSupabase(bool value) async {
    final SharedPreferences prefs =
        _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.enableSupabase, value);
    setState(() {
      _prefs = prefs;
      _supabaseEnabled = value;
    });
  }

  Future<void> _toggleDebug(bool value) async {
    final SharedPreferences prefs =
        _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.enableDebugLogging, value);
    setState(() {
      _prefs = prefs;
      _debugEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colors = theme.colorScheme;
    final DreamGradients gradients =
        theme.extension<DreamGradients>() ?? DreamGradients.fallback;

    final Color grantedColor = colors.tertiary;
    final Color cautionColor = colors.secondary;
    final Color errorColor = colors.error;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradients.settings),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Settings', style: textTheme.displaySmall),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    DreamCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Permissions', style: textTheme.titleMedium),
                          const SizedBox(height: 16),
                          if (_loadingPermissions)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(colors.primary),
                                ),
                              ),
                            )
                          else ...<Widget>[
                            PermissionPill(
                              label: 'Health Connect availability',
                              status: _healthAvailable ? 'Available' : 'Unavailable',
                              statusColor: _healthAvailable ? grantedColor : errorColor,
                              onPressed: _healthAvailable ? null : _healthService.openHealthConnectSettings,
                              actionLabel: _healthAvailable ? null : 'Install/Open',
                            ),
                            const SizedBox(height: 12),
                            PermissionPill(
                              label: 'Health Connect sleep data',
                              status: _sleepGranted ? 'Granted' : 'Not granted',
                              statusColor:
                              _sleepGranted ? grantedColor : cautionColor,
                              onPressed:
                              (_sleepGranted || !_healthAvailable) ? null : _requestSleepPermission,
                              actionLabel: (_sleepGranted || !_healthAvailable) ? null : 'Re-request',
                            ),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: 'Health Connect Test Screen',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HealthTestScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: 'Refresh permission status',
                              onPressed: _refreshPermissions,
                              isLoading: _loadingPermissions,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    DreamCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Developer toggles', style: textTheme.titleMedium),
                          const SizedBox(height: 12),
                          _ToggleSwitch(
                            label: 'Use mock sleep data (no Health Connect)',
                            value: _useMockData,
                            onChanged: (bool value) {
                              _toggleMockData(value);
                            },
                          ),
                          const SizedBox(height: 12),
                          _ToggleSwitch(
                            label: 'Enable Supabase integration',
                            value: _supabaseEnabled,
                            onChanged: _toggleSupabase,
                          ),
                          const SizedBox(height: 12),
                          _ToggleSwitch(
                            label: 'Enable debug logging',
                            value: _debugEnabled,
                            onChanged: _toggleDebug,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    DreamCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Developer info', style: textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Text(
                            'App version: $_appVersion',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Build number: ${_buildNumber.isEmpty ? '—' : _buildNumber}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}


class PermissionStatusData {
  const PermissionStatusData({
    required this.sleepGranted,
    required this.healthAvailable,
  });

  final bool sleepGranted;
  final bool healthAvailable;
}

class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colors = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: colors.onPrimary,
          activeTrackColor: colors.primary,
          inactiveThumbColor: colors.onSurfaceVariant,
          inactiveTrackColor: colors.surfaceVariant,
        ),
      ],
    );
  }
}