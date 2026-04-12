import 'dart:math' as math;
import 'dart:ui';

import 'package:dreamcatcher/services/sleep_validator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sleep_entry.dart';
import '../models/sleep_record.dart';
import '../services/health_connect_service.dart';
import '../services/mock_sleep_service.dart';
import '../services/reward_service.dart';
import '../services/storage_keys.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HealthConnectService _healthService = HealthConnectService();
  final RewardService _rewardService = RewardService();

  List<SleepEntry> _entries = <SleepEntry>[];
  bool _isLoading = false;
  bool _isClaiming = false;
  bool _permissionDenied = false;
  bool _noData = false;
  bool _useMockData = false;
  bool _enableDebugLogging = false;
  RewardSnapshot? _rewardSnapshot;
  bool _isLoadingRewards = false;
  SharedPreferences? _prefs;

  final List<double> _mockTrendHours = const <double>[7.5, 6.8, 8.1, 7.6, 6.9, 7.3, 8.0];
  final List<_DreamFeedItem> _mockDreamFeed = const <_DreamFeedItem>[
    _DreamFeedItem(
      title: 'Lucid Flight',
      subtitle: 'You were soaring above neon-lit cities collecting stardust.',
      timestamp: '2h ago',
    ),
    _DreamFeedItem(
      title: 'Forest Whispers',
      subtitle: 'Talking owls guided you through a misty grove to hidden treasure.',
      timestamp: 'Yesterday',
    ),
    _DreamFeedItem(
      title: 'Ocean Echoes',
      subtitle: 'A calm tide translated whale songs into soothing melodies.',
      timestamp: '2 days ago',
    ),
  ];
  final List<String> _moodEmojis = const <String>['😴', '🙂', '😊', '🤩', '🌟'];
  final List<String> _moodLabels = const <String>[
    'Sleepy',
    'Calm',
    'Refreshed',
    'Energized',
    'Inspired',
  ];
  int _selectedMoodIndex = 2;

  @override
  void initState() {
    super.initState();
    _initialize();
    _loadMockRewards();
  }

  Future<void> _initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool useMock = prefs.getBool(StorageKeys.useMockData) ?? false;
    final bool enableDebug = prefs.getBool(StorageKeys.enableDebugLogging) ?? false;

    if (!mounted) return;

    setState(() {
      _prefs = prefs;
      _useMockData = useMock;
      _enableDebugLogging = enableDebug;
    });

    await _loadInitialRecords();
  }

  Future<void> _loadInitialRecords() async {
    // Load from cache first
    final String? cachedRecordsJson = _prefs?.getString(StorageKeys.cachedSleepRecords);
    if (cachedRecordsJson != null) {
      final records = SleepRecord.listFromJsonString(cachedRecordsJson);
      _processAndValidateEntries(records);
    }

    if (_useMockData) {
      final List<SleepRecord> records = MockSleepService.generateMockData(days: 7);
      _processAndValidateEntries(records);
      return;
    }

    final bool hasPermissions = await _healthService.hasPermissions();

    if (!mounted) return;

    if (!hasPermissions) {
      if(cachedRecordsJson == null) {
        setState(() {
          _entries = <SleepEntry>[];
          _noData = true;
          _permissionDenied = false;
        });
      }
      return;
    }

    await _refresh();
  }

  void _processAndValidateEntries(List<SleepRecord> records) {
    final allEntries = SleepEntry.aggregateFromRecords(records, limit: 0);
    final validatedEntries = allEntries.map((entry) {
      final history = allEntries.where((e) => e.date.isBefore(entry.date)).toList();
      return SleepEntry(
          date: entry.date,
          start: entry.start,
          end: entry.end,
          totalMinutes: entry.totalMinutes,
          records: entry.records,
          validationResult: SleepValidator.validateSleepEntryForClaim(entry, history));
    }).toList();
    validatedEntries.sort((a, b) => b.date.compareTo(a.date));
    final limitedEntries = validatedEntries.take(7).toList();

    if (!mounted) return;
    setState(() {
      _entries = limitedEntries;
      _noData = limitedEntries.isEmpty;
      _permissionDenied = false;
    });
  }

  Future<List<SleepRecord>> _fetchSleepRecords() async {
    if (_useMockData) {
      return MockSleepService.generateMockData(days: 7);
    }
    return _healthService.readSleepSessions();
  }

  Future<void> _setUseMockData(bool value) async {
    final SharedPreferences prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.useMockData, value);

    if (!mounted) return;

    setState(() {
      _prefs = prefs;
      _useMockData = value;
    });

    await _loadInitialRecords();
  }

  Future<void> _loadMockRewards() async {
    setState(() {
      _isLoadingRewards = true;
    });

    try {
      final RewardSnapshot snapshot = await _rewardService.fetchRewardSnapshot();
      if (!mounted) return;
      setState(() {
        _rewardSnapshot = snapshot;
        _isLoadingRewards = false;
      });
    } catch (error) {
      debugPrint('[DreamCatcher] ⚠️ Failed to load mock rewards: $error');
      if (!mounted) return;
      setState(() {
        _rewardSnapshot = null;
        _isLoadingRewards = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
      _noData = false;
    });

    debugPrint("[DreamCatcher] 🔄 Refreshing data...");

    final SharedPreferences prefs = _prefs ?? await SharedPreferences.getInstance();
    final bool useMock = prefs.getBool(StorageKeys.useMockData) ?? false;
    if (useMock != _useMockData) {
      setState(() {
        _prefs = prefs;
        _useMockData = useMock;
      });
    }

    if (_useMockData) {
      final List<SleepRecord> records = MockSleepService.generateMockData(days: 7);
      _processAndValidateEntries(records);
      await _prefs?.setString(StorageKeys.cachedSleepRecords, SleepRecord.listToJsonString(records));

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _entries.isEmpty
                ? '⚠️ Mock mode: no generated sleep data'
                : '✅ Loaded ${_entries.length} nights of mock sleep',
          ),
          backgroundColor: _entries.isEmpty ? Colors.orange : Colors.green,
        ),
      );
      return;
    }

    // Step 2 Fix: Use hasPermissions instead of requestPermissions to prevent crashes on transition
    final bool hasPermission = await _healthService.hasPermissions();

    debugPrint("[DreamCatcher] Permission status: $hasPermission");

    if (!hasPermission) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
        _noData = _entries.isEmpty;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Health Connect permission not granted. Please enable it in Settings.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      debugPrint('[DreamCatcher] 📡 Fetching sleep records');

      final List<SleepRecord> records = await _fetchSleepRecords();
      _processAndValidateEntries(records);
      await _prefs?.setString(StorageKeys.cachedSleepRecords, SleepRecord.listToJsonString(records));

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      debugPrint(
          "[DreamCatcher] ✅ Fetch complete: ${records.length} records, ${_entries.length} aggregated entries");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            records.isEmpty
                ? '⚠️ No new sleep data found'
                : '✅ Synced ${records.length} sleep records',
          ),
          backgroundColor: records.isEmpty ? Colors.orange : Colors.green,
        ),
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _noData = _entries.isEmpty;
      });

      debugPrint('[DreamCatcher] ⚠️ Sleep fetch error: $error');
      debugPrint(stackTrace.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Error fetching sleep data: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _claimRewards(SleepEntry entry) async {
    setState(() {
      _isClaiming = true;
    });

    final result = await _rewardService.requestClaim(entry: entry, walletAddress: '0x123...abc');
    await _loadMockRewards();

    if (!mounted) return;
    setState(() {
      _isClaiming = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.status == RewardClaimStatus.paid
          ? '🎉 Claim successful! ${result.amount?.toStringAsFixed(2)} DREAM earned.'
          : '😢 Claim failed: ${result.reason}'),
      backgroundColor: result.status == RewardClaimStatus.paid ? Colors.green : Colors.red,
    ));
  }

  SleepEntry? get _todayEntry {
    final DateTime now = DateTime.now();
    final DateTime key = DateTime(now.year, now.month, now.day);
    for (final SleepEntry entry in _entries) {
      if (entry.date.year == key.year &&
          entry.date.month == key.month &&
          entry.date.day == key.day) {
        return entry;
      }
    }
    return null;
  }

  SleepEntry? get _latestSleepEntry {
    if (_entries.isEmpty) {
      return null;
    }
    return _entries.first;
  }

  String _formatHours(double hours) {
    final int h = hours.floor();
    final int minutes = ((hours - h) * 60).round();
    if (minutes == 0) {
      return '${h}h';
    }
    return '${h}h ${minutes.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SleepEntry? today = _todayEntry;
    final SleepEntry? lastNightEntry = today ?? _latestSleepEntry;
    final double lastNightHours = lastNightEntry?.totalHours ?? 7.8;
    final String lastNightRange = lastNightEntry != null
        ? _formatRange(context, lastNightEntry)
        : '10:45 PM – 6:30 AM';
    final int goalPercent = ((lastNightHours / 8.0) * 100).clamp(0, 150).round();
    final double averageTrend = _mockTrendHours.isEmpty
        ? 0
        : _mockTrendHours.reduce((double a, double b) => a + b) /
            _mockTrendHours.length;

    final bool isEligible = lastNightEntry?.validationResult?.isEligible ?? false;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              'assets/screens/home_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xAA0D1B2D),
                    Color(0x660D1B2D),
                    Color(0x220D1B2D),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool isTablet = constraints.maxWidth >= 900;
                final double horizontalPadding = isTablet ? 48 : 24;
                final double contentWidth =
                    constraints.maxWidth - (horizontalPadding * 2);
                final double cardWidth =
                    isTablet ? (contentWidth - 24) / 2 : contentWidth;
                final double fullWidth = contentWidth;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'DreamCatcher',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sleep to earn better rest rewards.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _useMockData
                                  ? 'Mock sleep data enabled'
                                  : 'Health Connect sleep data',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: _useMockData,
                            onChanged: (bool value) => _setUseMockData(value),
                            activeColor: Colors.white,
                            activeTrackColor: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_permissionDenied)
                        const ErrorBanner(
                          message:
                              'Permission not granted. Please go to Settings to enable Health Connect access.',
                        ),
                      if (_permissionDenied) const SizedBox(height: 16),
                      if (_noData && !_permissionDenied)
                        const ErrorBanner(
                          message:
                              'No data found. Sync with Health Connect to start earning for your sleep.',
                          icon: Icons.bedtime,
                          backgroundColor: Color(0xFF1E2F3B),
                        ),
                      if (_noData && !_permissionDenied)
                        const SizedBox(height: 16),
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: <Widget>[
                          SizedBox(
                            width: cardWidth,
                            child: GlassCard(
                              child: _buildLastNightCard(
                                context: context,
                                theme: theme,
                                hours: lastNightHours,
                                range: lastNightRange,
                                goalPercent: goalPercent,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: GlassCard(
                              child: _buildTrendCard(
                                context,
                                theme,
                                averageTrend,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: GlassCard(
                              child: _buildRewardsCard(theme),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: GlassCard(
                              child: _buildMoodCard(theme),
                            ),
                          ),
                          SizedBox(
                            width: isTablet ? fullWidth : cardWidth,
                            child: GlassCard(
                              child: _buildDreamFeedCard(theme),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: isTablet ? fullWidth : cardWidth,
                        child: PrimaryButton(
                          label: isEligible ? 'Claim Rewards' : 'Not eligible for rewards',
                          onPressed: isEligible && !_isClaiming
                              ? () => _claimRewards(lastNightEntry!)
                              : null,
                          isLoading: _isClaiming,
                        ),
                      ),
                       if (_enableDebugLogging && lastNightEntry?.validationResult?.reasons.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Validation Failures:', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                              ...?lastNightEntry?.validationResult?.reasons.map((r) => Text(' - $r', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)))
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: isTablet ? fullWidth : cardWidth,
                        child: PrimaryButton(
                          label: 'Refresh',
                          onPressed: _refresh,
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Syncing with Health Connect...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLastNightCard({
    required BuildContext context,
    required ThemeData theme,
    required double hours,
    required String range,
    required int goalPercent,
  }) {
    final List<Map<String, String>> highlights = <Map<String, String>>[
      <String, String>{
        'label': 'Time asleep',
        'value': _formatHours(hours),
      },
      <String, String>{
        'label': 'Sleep window',
        'value': range,
      },
      <String, String>{
        'label': 'Goal progress',
        'value': '$goalPercent% of 8h goal',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _GlassCardHeader(title: 'Last night\'s sleep'),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    hours.toStringAsFixed(1),
                    style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ) ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'hours asleep',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.08),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Text(
                      range,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 110,
              width: 110,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  CircularProgressIndicator(
                    value: goalPercent / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF7F5FFF),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '$goalPercent%',
                        style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ) ??
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'of goal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: highlights
              .map(
                (Map<String, String> highlight) => SizedBox(
                  width: 160,
                  child: _GlassStatChip(
                    label: highlight['label']!,
                    value: highlight['value']!,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTrendCard(
    BuildContext context,
    ThemeData theme,
    double averageTrend,
  ) {
    final double bestNight =
        _mockTrendHours.isEmpty ? 0 : _mockTrendHours.reduce(math.max);
    final double totalHours = _mockTrendHours.fold<double>(
      0,
      (double previousValue, double element) => previousValue + element,
    );
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('E');
    final List<String> labels = List<String>.generate(
      _mockTrendHours.length,
      (int index) {
        final DateTime day = now.subtract(
          Duration(days: _mockTrendHours.length - 1 - index),
        );
        return formatter.format(day);
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _GlassCardHeader(
          title: '7-day trend',
          trailing: Text(
            '${averageTrend.toStringAsFixed(1)}h avg',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Consistent sleep builds your DREAM streak.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: _SleepTrendChart(
            data: _mockTrendHours,
            labels: labels,
            average: averageTrend,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _GlassSummaryTile(
                label: 'Best night',
                value: '${bestNight.toStringAsFixed(1)}h',
                icon: Icons.nightlight_round,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassSummaryTile(
                label: 'Total week',
                value: '${totalHours.toStringAsFixed(1)}h',
                icon: Icons.timeline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRewardsCard(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _GlassCardHeader(title: 'DREAM rewards'),
        const SizedBox(height: 12),
        if (_isLoadingRewards)
          const Center(
            child: SizedBox(
              height: 32,
              width: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          )
        else if (_rewardSnapshot != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${_rewardSnapshot!.totalDreamEarned.toStringAsFixed(2)} DREAM',
                style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ) ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '≈ \$${_rewardService.convertDreamToUsd(_rewardSnapshot!.totalDreamEarned).toStringAsFixed(2)} USD total',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              _GlassSummaryTile(
                label: 'Pending',
                value: '${_rewardSnapshot!.pendingDream.toStringAsFixed(2)} DREAM',
                icon: Icons.lock_clock,
              ),
              const SizedBox(height: 12),
              _GlassSummaryTile(
                label: 'Sleep streak',
                value: '${_rewardSnapshot!.sleepStreak} nights',
                icon: Icons.local_fire_department,
              ),
              const SizedBox(height: 12),
              _GlassSummaryTile(
                label: 'Earned this week',
                value:
                    '${_rewardSnapshot!.weeklyDreamEarned.toStringAsFixed(2)} DREAM',
                icon: Icons.auto_graph,
              ),
            ],
          )
        else
          Text(
            'Unable to load rewards. Try refreshing soon.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.red[200],
            ),
          ),
      ],
    );
  }

  Widget _buildMoodCard(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _GlassCardHeader(title: 'Mood tracker'),
        const SizedBox(height: 12),
        Text(
          'How did you feel after waking up?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List<Widget>.generate(_moodEmojis.length, (int index) {
            final bool isSelected = _selectedMoodIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMoodIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected
                      ? Colors.white.withOpacity(0.18)
                      : Colors.white.withOpacity(0.08),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.15),
                  ),
                  boxShadow: isSelected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _moodEmojis[index],
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _moodLabels[index],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(
          'Tip: Logging moods daily keeps your insights personal.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildDreamFeedCard(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _GlassCardHeader(
          title: 'Dream feed',
          trailing: Text(
            'See all',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _mockDreamFeed.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) {
            final _DreamFeedItem item = _mockDreamFeed[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: <Color>[
                          Color(0xFF7F5FFF),
                          Color(0xFF5BD6FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                item.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              item.timestamp,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatRange(BuildContext context, SleepEntry entry) {
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final String start =
        localizations.formatTimeOfDay(TimeOfDay.fromDateTime(entry.start));
    final String end =
        localizations.formatTimeOfDay(TimeOfDay.fromDateTime(entry.end));
    return '$start – $end';
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withOpacity(0.24),
                Colors.white.withOpacity(0.06),
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.black.withOpacity(0.12),
            ),
            padding: padding ?? const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GlassCardHeader extends StatelessWidget {
  const _GlassCardHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ) ??
                const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _GlassSummaryTile extends StatelessWidget {
  const _GlassSummaryTile({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassStatChip extends StatelessWidget {
  const _GlassStatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _SleepTrendChart extends StatelessWidget {
  const _SleepTrendChart({
    required this.data,
    required this.labels,
    required this.average,
  });

  final List<double> data;
  final List<String> labels;
  final double average;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxValue =
            data.isEmpty ? 0 : data.reduce((double a, double b) => math.max(a, b));
        final double labelHeight = 24;
        final double chartHeight = (constraints.maxHeight - labelHeight)
            .clamp(60, constraints.maxHeight);
        final double averagePosition = maxValue == 0
            ? chartHeight
            : chartHeight * (1 - (average / maxValue).clamp(0, 1));

        return Column(
          children: <Widget>[
            SizedBox(
              height: chartHeight,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: averagePosition,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.4),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: (averagePosition - 18).clamp(0, chartHeight - 18),
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.12),
                        border: Border.all(color: Colors.white.withOpacity(0.16)),
                      ),
                      child: Text(
                        'Average',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List<Widget>.generate(data.length, (int index) {
                      final double value = data[index];
                      final double heightFactor =
                          maxValue == 0 ? 0 : (value / maxValue).clamp(0, 1);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: chartHeight * heightFactor,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Color(0xFF5BD6FF),
                                    Color(0xFF7F5FFF),
                                  ],
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List<Widget>.generate(labels.length, (int index) {
                return Expanded(
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _DreamFeedItem {
  const _DreamFeedItem({
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  final String title;
  final String subtitle;
  final String timestamp;
}
