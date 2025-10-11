import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sleep_entry.dart';
import '../models/sleep_record.dart';
import '../services/health_connect_service.dart';
import '../services/mock_sleep_service.dart';
import '../services/storage_keys.dart';
import '../widgets/card.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';
import '../screens/sleep_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HealthConnectService _healthService = HealthConnectService();

  List<SleepEntry> _entries = <SleepEntry>[];
  bool _isLoading = true;
  bool _permissionDenied = false;
  bool _useMockData = false;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool useMock = prefs.getBool(StorageKeys.useMockData) ?? false;

    if (!mounted) return;

    setState(() {
      _prefs = prefs;
      _useMockData = useMock;
    });

    await _load();
  }

  Future<void> _load() async {
    if (_useMockData) {
      final List<SleepRecord> records =
      MockSleepService.generateMockData(days: 14);
      if (!mounted) return;
      setState(() {
        _entries = SleepEntry.aggregateFromRecords(records, limit: 0);
        _isLoading = false;
        _permissionDenied = false;
      });
      return;
    }

    final bool hasPermissions = await _healthService.hasPermissions();

    if (!mounted) return;

    if (!hasPermissions) {
      setState(() {
        _entries = <SleepEntry>[];
        _isLoading = false;
        _permissionDenied = false;
      });
      return;
    }

    try {
      final List<SleepRecord> records =
      await _healthService.readSleepSessions();
      setState(() {
        _entries = SleepEntry.aggregateFromRecords(records, limit: 0);
        _isLoading = false;
        _permissionDenied = false;
      });
    } catch (error) {
      debugPrint('[DreamCatcher] ⚠️ Failed to load history: $error');
      setState(() {
        _entries = <SleepEntry>[];
        _isLoading = false;
        _permissionDenied = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
    });

    final SharedPreferences prefs =
        _prefs ?? await SharedPreferences.getInstance();
    final bool useMock = prefs.getBool(StorageKeys.useMockData) ?? false;
    if (useMock != _useMockData) {
      setState(() {
        _prefs = prefs;
        _useMockData = useMock;
      });
    }

    if (_useMockData) {
      final List<SleepRecord> records =
      MockSleepService.generateMockData(days: 14);
      if (!mounted) return;
      setState(() {
        _entries = SleepEntry.aggregateFromRecords(records, limit: 0);
        _isLoading = false;
      });
      return;
    }

    final bool permissionGranted = await _healthService.requestPermissions();

    if (!permissionGranted) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
      });
      return;
    }

    try {
      final List<SleepRecord> records =
      await _healthService.readSleepSessions();
      if (!mounted) return;
      setState(() {
        _entries = SleepEntry.aggregateFromRecords(records, limit: 0);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('[DreamCatcher] ⚠️ Error refreshing history: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareCsv() async {
    if (_entries.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sleep sessions to export yet.')),
      );
      return;
    }

    final String csv = SleepEntry.exportToCsv(_entries);
    await Share.share(csv, subject: 'DreamCatcher sleep history');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Image.asset(
            'assets/screens/history_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PrimaryButton(
                      label: 'Export CSV',
                      expanded: false,
                      onPressed: _shareCsv,
                      isLoading: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_permissionDenied)
                  const ErrorBanner(
                    message:
                    'Permission not granted. Refresh to try syncing again.',
                  ),
                if (_permissionDenied) const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(
                    child: CircularProgressIndicator(),
                  )
                      : RefreshIndicator(
                    onRefresh: _refresh,
                    child: _entries.isEmpty
                        ? ListView(
                      physics:
                      const AlwaysScrollableScrollPhysics(),
                      children: const <Widget>[
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No sleep history yet. Start tracking tonight!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    )
                        : ListView.separated(
                      physics:
                      const AlwaysScrollableScrollPhysics(),
                      itemCount: _entries.length,
                      separatorBuilder:
                          (BuildContext context, int index) =>
                      const SizedBox(height: 12),
                      itemBuilder:
                          (BuildContext context, int index) {
                        final SleepEntry entry = _entries[index];
                        return GestureDetector(
                          onTap: () => _openDetail(entry),
                          child: DreamCard(
                            child: _HistoryRow(entry: entry),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Refresh history',
                  onPressed: _refresh,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openDetail(SleepEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SleepDetailScreen(entry: entry),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final SleepEntry entry;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations =
    MaterialLocalizations.of(context);
    final String dateLabel = localizations.formatMediumDate(entry.date);
    final String range =
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(entry.start))} – '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(entry.end))}';

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                dateLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                range,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${entry.totalHours.toStringAsFixed(1)} h',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
