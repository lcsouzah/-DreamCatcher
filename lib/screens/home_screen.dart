import 'package:flutter/material.dart';

import '../models/sleep_entry.dart';
import '../services/sleep_service.dart';
import '../widgets/card.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SleepService _sleepService = SleepService();

  List<SleepEntry> _entries = <SleepEntry>[];
  bool _isLoading = false;
  bool _permissionDenied = false;
  bool _noData = false;

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  Future<void> _loadCached() async {
    final List<SleepEntry> cached = await _sleepService.loadCachedEntries();
    if (!mounted) {
      return;
    }
    setState(() {
      _entries = cached;
      _noData = cached.isEmpty;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
      _noData = false;
    });

    final SleepFetchResult result =
    await _sleepService.refreshSleepEntries(context);
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _permissionDenied = !result.permissionGranted;
      _entries = result.entries;
      _noData = result.permissionGranted && result.entries.isEmpty;
    });
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

    return Stack(
      children: <Widget>[
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
                            if (_entries.isEmpty)
                              Text(
                                'No tracked sleep yet. Tap refresh after a night of sleep.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              )
                            else
                              Column(
                                children: _entries
                                    .map(
                                      (SleepEntry entry) => Padding(
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                    child: _SleepSummaryRow(entry: entry),
                                  ),
                                )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Refresh',
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

  String _formatRange(BuildContext context, SleepEntry entry) {
    final MaterialLocalizations localizations =
    MaterialLocalizations.of(context);
    final TimeOfDay start = TimeOfDay.fromDateTime(entry.start);
    final TimeOfDay end = TimeOfDay.fromDateTime(entry.end);
    return '${localizations.formatTimeOfDay(start)} – ${localizations.formatTimeOfDay(end)}';
  }
}

class _SleepSummaryRow extends StatelessWidget {
  const _SleepSummaryRow({required this.entry});

  final SleepEntry entry;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations =
    MaterialLocalizations.of(context);
    final DateTime date = entry.date;
    final String dateLabel =
    localizations.formatMediumDate(DateTime(date.year, date.month, date.day));
    final TimeOfDay start = TimeOfDay.fromDateTime(entry.start);
    final TimeOfDay end = TimeOfDay.fromDateTime(entry.end);

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
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${localizations.formatTimeOfDay(start)} – ${localizations.formatTimeOfDay(end)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          '${entry.totalHours.toStringAsFixed(1)} h',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}