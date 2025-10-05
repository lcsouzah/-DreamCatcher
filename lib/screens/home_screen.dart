import 'package:flutter/material.dart';

import '../models/sleep_entry.dart';
import '../models/sleep_record.dart';
import '../services/health_service.dart';
import '../widgets/card.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HealthService _healthService = HealthService();

  List<SleepEntry> _entries = <SleepEntry>[];
  bool _isLoading = false;
  bool _permissionDenied = false;
  bool _noData = false;

  @override
  void initState() {
    super.initState();
    _loadCached();
    // user must tap Refresh button to request Google Fit permission
  }


  Future<void> _loadCached() async {
    final DateTime now = DateTime.now();
    final DateTime start =
    DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    try {
      final List<SleepRecord> records = await _healthService.readSleep(
        from: start,
        to: now,
      );
      if (!mounted) return;
      final List<SleepEntry> entries = SleepEntry.aggregateFromRecords(records);
      setState(() {
        _entries = entries;
        _noData = entries.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = <SleepEntry>[];
        _noData = true;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
      _noData = false;
    });

    debugPrint("[DreamCatcher] 🔄 Starting refresh... requesting permissions");

    final bool permissionGranted = await _healthService.requestPermissions();

    debugPrint("[DreamCatcher] Permission result: $permissionGranted");

    if (!permissionGranted) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
        _noData = _entries.isEmpty;
      });
      debugPrint("[DreamCatcher] ❌ Permission denied");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Google Fit permission not granted"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime start =
    DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

    try {
      debugPrint("[DreamCatcher] 📡 Fetching sleep records from $start to $now");

      final List<SleepRecord> records = await _healthService.readSleep(
        from: start,
        to: now,
        forceRefresh: true,
      );

      final List<SleepEntry> entries = SleepEntry.aggregateFromRecords(records);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _entries = entries;
        _noData = entries.isEmpty;
      });

      debugPrint(
          "[DreamCatcher] ✅ Fetch complete: ${records.length} records, ${entries.length} aggregated entries");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            records.isEmpty
                ? "⚠️ No new sleep data found"
                : "✅ Synced ${records.length} sleep records",
          ),
          backgroundColor: records.isEmpty ? Colors.orange : Colors.green,
        ),
      );
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _noData = _entries.isEmpty;
      });

      debugPrint("[DreamCatcher] ⚠️ Sleep fetch error: $e");
      debugPrint(st.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Error fetching sleep data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  double get _weeklyTotalHours {
    return _entries.fold<double>(
      0,
          (double previousValue, SleepEntry entry) =>
      previousValue + entry.totalHours,
    );
  }

  @override
  Widget build(BuildContext context) {
    final SleepEntry? today = _todayEntry;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Positioned.fill(
            child: Image.asset(
              'assets/screens/home_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                  const SizedBox(height: 24),

                  if (_permissionDenied)
                    const ErrorBanner(
                      message:
                      'Permission not granted. Tap Refresh to try requesting access again.',
                    ),
                  if (_permissionDenied) const SizedBox(height: 16),

                  if (_noData && !_permissionDenied)
                    const ErrorBanner(
                      message:
                      'No data found. Sync with Google Fit to start earning for your sleep.',
                      icon: Icons.bedtime,
                      backgroundColor: Color(0xFF1E2F3B),
                    ),
                  if (_noData && !_permissionDenied) const SizedBox(height: 16),

                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        DreamCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  const Text(
                                    "Today's sleep",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    today != null
                                        ? '${today.totalHours.toStringAsFixed(1)} hrs'
                                        : '--',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                today != null
                                    ? _formatRange(context, today)
                                    : 'Start a sleep session to see your stats.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        DreamCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  const Text(
                                    'Last 7 nights',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_weeklyTotalHours.toStringAsFixed(1)} hrs',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              for (final SleepEntry entry in _entries)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        _formatDay(context, entry.date),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '${entry.totalHours.toStringAsFixed(1)} hrs',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        PrimaryButton(
                          label: 'Refresh',
                          onPressed: _refresh,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

// 🔹 Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Syncing with Google Fit...",
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

  String _formatRange(BuildContext context, SleepEntry entry) {
    final MaterialLocalizations localizations =
    MaterialLocalizations.of(context);
    final String start =
    localizations.formatTimeOfDay(TimeOfDay.fromDateTime(entry.start));
    final String end =
    localizations.formatTimeOfDay(TimeOfDay.fromDateTime(entry.end));
    return '$start – $end';
  }

  String _formatDay(BuildContext context, DateTime date) {
    final MaterialLocalizations localizations =
    MaterialLocalizations.of(context);
    return localizations.formatMediumDate(date);
  }
}
