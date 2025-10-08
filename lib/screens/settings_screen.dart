import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/health_connect_service.dart';
import '../services/storage_keys.dart';
import '../widgets/card.dart';
import '../widgets/permission_pill.dart';
import '../widgets/primary_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HealthConnectService _healthService = HealthConnectService();

  bool _activityGranted = false;
  bool _activityPermanentlyDenied = false;
  bool _sleepGranted = false;
  bool _loadingPermissions = true;

  bool _notificationsEnabled = false;
  bool _darkModeAccentIntensityEnabled = false;
  bool _healthConnectAutoSyncEnabled = false;

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
    final PermissionStatusData permissionStatus =
    await _getPermissionStatus();

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
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      _applyPermissionStatus(permissionStatus);
      _loadingPermissions = false;
    });
  }

  Future<PermissionStatusData> _getPermissionStatus() async {
    final bool sleepGranted = await _healthService.hasSleepPermission();
    final PermissionStatus activityStatus =
    await _healthService.activityPermissionStatus();

    return PermissionStatusData(
      activityGranted: activityStatus.isGranted,
      activityPermanentlyDenied: activityStatus.isPermanentlyDenied,
      sleepGranted: sleepGranted,
    );
  }

  void _applyPermissionStatus(PermissionStatusData status) {
    _activityGranted = status.activityGranted;
    _activityPermanentlyDenied = status.activityPermanentlyDenied;
    _sleepGranted = status.sleepGranted;
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

  Future<void> _requestActivityPermission() async {
    await _healthService.ensureActivityPermission();
    await _refreshPermissions();
  }

  Future<void> _requestSleepPermission() async {
    try {
      await _healthService.requestSleepAuthorization();
    } on HealthConnectUnavailableException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${error.message} Please install or enable Health Connect.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    await _refreshPermissions();
  }

  Future<void> _toggleNotifications(bool value) async {
    final SharedPreferences prefs =
        _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.enableNotifications, value);
    setState(() {
      _prefs = prefs;
      _notificationsEnabled = value;
    });
  }

  Future<void> _toggleDarkModeAccentIntensity(bool value) async {
    final SharedPreferences prefs =
        _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.darkModeAccentIntensity, value);
    setState(() {
      _prefs = prefs;
      _darkModeAccentIntensityEnabled = value;
    });
  }

  Future<void> _toggleHealthConnectAutoSync(bool value) async {
    final SharedPreferences prefs =
        _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.healthConnectAutoSync, value);
    setState(() {
      _prefs = prefs;
      _healthConnectAutoSyncEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Image.asset(
            'assets/screens/settings_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      DreamCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Permissions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_loadingPermissions)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else ...<Widget>[
                              PermissionPill(
                                label: 'Activity recognition',
                                status: _activityGranted
                                    ? 'Granted'
                                    : _activityPermanentlyDenied
                                    ? 'Denied (settings required)'
                                    : 'Not granted',
                                statusColor: _activityGranted
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                                onPressed: _activityGranted
                                    ? null
                                    : _requestActivityPermission,
                                actionLabel: _activityGranted ? null : 'Re-request',
                              ),
                              const SizedBox(height: 12),
                              PermissionPill(
                                label: 'Health Connect sleep data',
                                status:
                                _sleepGranted ? 'Granted' : 'Not granted',
                                statusColor: _sleepGranted
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                                onPressed:
                                _sleepGranted ? null : _requestSleepPermission,
                                actionLabel:
                                _sleepGranted ? null : 'Re-request',
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
                            const Text(
                              'Developer toggles',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ToggleSwitch(
                              label: 'Enable notifications',
                              value: _notificationsEnabled,
                              onChanged: _toggleNotifications,
                            ),
                            const SizedBox(height: 12),
                            _ToggleSwitch(
                              label: 'Stronger dark-mode accent colors',
                              value: _darkModeAccentIntensityEnabled,
                              onChanged: _toggleDarkModeAccentIntensity,
                            ),
                            const SizedBox(height: 12),
                            _ToggleSwitch(
                              label: 'Auto-sync sleep data with Health Connect',
                              value: _healthConnectAutoSyncEnabled,
                              onChanged: _toggleHealthConnectAutoSync,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      DreamCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Developer info',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'App version: $_appVersion',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Build number: ${_buildNumber.isEmpty ? '—' : _buildNumber}',
                              style: const TextStyle(color: Colors.white70),
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
      ],
    );
  }
}

class PermissionStatusData {
  PermissionStatusData({
    required this.activityGranted,
    required this.activityPermanentlyDenied,
    required this.sleepGranted,
  });

  final bool activityGranted;
  final bool activityPermanentlyDenied;
  final bool sleepGranted;
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF7B61FF),
        ),
      ],
    );
  }
}