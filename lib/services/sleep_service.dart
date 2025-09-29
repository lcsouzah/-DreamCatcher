import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sleep_entry.dart';
import 'health_service.dart';
import 'storage_keys.dart';

class SleepFetchResult {
  SleepFetchResult({
    required this.permissionGranted,
    required this.entries,
  });

  final bool permissionGranted;
  final List<SleepEntry> entries;

  bool get hasData => entries.isNotEmpty;
}

class SleepService {
  SleepService({HealthService? healthService, SharedPreferences? preferences})
      : _healthService = healthService ?? HealthService(),
        _preferences = preferences;

  final HealthService _healthService;
  SharedPreferences? _preferences;

  Future<SharedPreferences> _getPrefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<List<SleepEntry>> loadCachedEntries() async {
    final SharedPreferences prefs = await _getPrefs();
    final String? raw = prefs.getString(StorageKeys.cachedSleepEntries);
    if (raw == null || raw.isEmpty) {
      return <SleepEntry>[];
    }
    try {
      return SleepEntry.listFromJsonString(raw);
    } catch (_) {
      return <SleepEntry>[];
    }
  }

  Future<void> clearCache() async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.remove(StorageKeys.cachedSleepEntries);
  }

  Future<SleepFetchResult> refreshSleepEntries(BuildContext context) async {
    final bool permissionsGranted =
    await _healthService.requestPermissions(context);
    if (!permissionsGranted) {
      return SleepFetchResult(permissionGranted: false, entries: <SleepEntry>[]);
    }

    final DateTime now = DateTime.now();
    final DateTime start =
    DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

    try {
      final List<HealthDataPoint> rawPoints = await _healthService.getSleepData(
        start: start,
        end: now,
      );

      final List<SleepEntry> entries = _convertToEntries(rawPoints);
      await _cacheEntries(entries);

      return SleepFetchResult(permissionGranted: true, entries: entries);
    } catch (_) {
      return SleepFetchResult(permissionGranted: true, entries: <SleepEntry>[]);
    }
  }

  Future<void> _cacheEntries(List<SleepEntry> entries) async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.setString(
      StorageKeys.cachedSleepEntries,
      SleepEntry.listToJsonString(entries),
    );
  }

  List<SleepEntry> _convertToEntries(List<HealthDataPoint> dataPoints) {
    if (dataPoints.isEmpty) {
      return <SleepEntry>[];
    }

    dataPoints.sort((HealthDataPoint a, HealthDataPoint b) =>
        a.dateFrom.compareTo(b.dateFrom));

    final Map<DateTime, List<HealthDataPoint>> grouped =
    <DateTime, List<HealthDataPoint>>{};

    for (final HealthDataPoint point in dataPoints) {
      final DateTime bucket = DateTime(
        point.dateFrom.year,
        point.dateFrom.month,
        point.dateFrom.day,
      );
      grouped.putIfAbsent(bucket, () => <HealthDataPoint>[]).add(point);
    }

    final List<SleepEntry> entries = grouped.entries.map((entry) {
      final List<HealthDataPoint> points = entry.value
        ..sort((HealthDataPoint a, HealthDataPoint b) =>
            a.dateFrom.compareTo(b.dateFrom));

      DateTime start = points.first.dateFrom;
      DateTime end = points.first.dateTo;
      int totalMinutes = 0;

      for (final HealthDataPoint point in points) {
        if (point.dateFrom.isBefore(start)) {
          start = point.dateFrom;
        }
        if (point.dateTo.isAfter(end)) {
          end = point.dateTo;
        }
        totalMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
      }

      return SleepEntry(
        date: entry.key,
        start: start,
        end: end,
        totalMinutes: totalMinutes,
      );
    }).toList();

    entries.sort((SleepEntry a, SleepEntry b) => b.date.compareTo(a.date));

    return entries.take(7).toList();
  }

  String exportToCsv(List<SleepEntry> entries) {
    final StringBuffer buffer = StringBuffer('Date,Start,End,Duration (hours)\n');
    for (final SleepEntry entry in entries) {
      buffer.writeln(
        '${entry.date.toIso8601String()},'
            '${entry.start.toIso8601String()},'
            '${entry.end.toIso8601String()},'
            '${entry.totalHours.toStringAsFixed(2)}',
      );
    }
    return buffer.toString();
  }
}