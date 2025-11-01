// lib/services/health_connect_service.dart (final fix)
// - from/to made optional with sensible defaults
// - fixed session merge logic
// - explicit aliasing of 'health' package to avoid local name conflicts
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart' as health;

import '../models/sleep_record.dart';

class HealthConnectService {
  HealthConnectService._();
  static final HealthConnectService _instance = HealthConnectService._();
  factory HealthConnectService() => _instance;

  final health.HealthFactory _health = health.HealthFactory(useHealthConnectIfAvailable: true);

  static const _sleepTypes = <health.HealthDataType>[
    health.HealthDataType.SLEEP_ASLEEP,
    health.HealthDataType.SLEEP_AWAKE,
    health.HealthDataType.SLEEP_IN_BED,
  ];

  /// Returns true if the app already holds READ permissions for sleep.
  Future<bool> hasPermissions() async {
    try {
      final has = await _health.hasPermissions(
        _sleepTypes,
        permissions: _sleepTypes.map((_) => health.HealthDataAccess.READ).toList(),
      );
      if (kDebugMode) log('hasPermissions: $has');
      return has ?? false;
    } catch (e, st) {
      log('hasPermissions error: $e', stackTrace: st);
      return false;
    }
  }

  /// Shows the Health permissions sheet and returns true if granted.
  Future<bool> requestPermissions() async {
    try {
      final ok = await _health.requestAuthorization(
        _sleepTypes,
        permissions: _sleepTypes.map((_) => health.HealthDataAccess.READ).toList(),
      );
      if (kDebugMode) log('requestPermissions -> $ok');
      return ok;
    } catch (e, st) {
      log('requestPermissions error: $e', stackTrace: st);
      return false;
    }
  }

  /// For compatibility with other code paths.
  Future<bool> ensurePermissions() => requestPermissions();

  /// Raw sleep segments. If [from]/[to] are null, defaults to last 14 days.
  Future<List<SleepRecord>> readSleep({DateTime? from, DateTime? to}) async {
    final DateTime end = to ?? DateTime.now();
    final DateTime start = from ?? end.subtract(const Duration(days: 14));

    try {
      final data = await _health.getHealthDataFromTypes(start, end, _sleepTypes);
      final out = <SleepRecord>[];
      for (final d in data) {
        final s = d.dateFrom;
        final e = d.dateTo;
        if (s == null || e == null) continue;
        out.add(SleepRecord(
          start: s,
          end: e,
          source: d.sourceName ?? 'Health Connect',
          type: _sleepTypeName(d.type),
        ));
      }
      out.sort((a, b) => b.start.compareTo(a.start));
      return out;
    } catch (e, st) {
      log('readSleep error: $e', stackTrace: st);
      return <SleepRecord>[];
    }
  }

  /// Groups contiguous segments into nightly "sessions".
  /// If [from]/[to] are null, defaults to last 14 days.
  Future<List<SleepRecord>> readSleepSessions({
    DateTime? from,
    DateTime? to,
    Duration gap = const Duration(minutes: 30),
  }) async {
    final segments = await readSleep(from: from, to: to);
    if (segments.isEmpty) return segments;

    // sort ascending for grouping
    segments.sort((a, b) => a.start.compareTo(b.start));

    final sessions = <SleepRecord>[];
    var curStart = segments.first.start;
    var curEnd = segments.first.end;
    var curSource = segments.first.source;

    for (var i = 1; i < segments.length; i++) {
      final s = segments[i];
      // merge if gap between previous end and next start is small
      if (s.start.difference(curEnd) <= gap) {
        // extend window
        if (s.end.isAfter(curEnd)) curEnd = s.end;
      } else {
        sessions.add(SleepRecord(
          start: curStart,
          end: curEnd,
          source: curSource,
          type: 'session',
        ));
        curStart = s.start;
        curEnd = s.end;
        curSource = s.source;
      }
    }

    // push last session
    sessions.add(SleepRecord(
      start: curStart,
      end: curEnd,
      source: curSource,
      type: 'session',
    ));

    // newest-first
    sessions.sort((a, b) => b.start.compareTo(a.start));
    return sessions;
  }

  String _sleepTypeName(health.HealthDataType t) {
    switch (t) {
      case health.HealthDataType.SLEEP_ASLEEP:
        return 'asleep';
      case health.HealthDataType.SLEEP_AWAKE:
        return 'awake';
      case health.HealthDataType.SLEEP_IN_BED:
        return 'in_bed';
      default:
        return t.name.toLowerCase();
    }
  }
}
