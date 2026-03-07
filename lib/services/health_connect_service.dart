import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_health_connect/flutter_health_connect.dart';

import '../models/sleep_record.dart';

class HealthConnectService {
  HealthConnectService._();
  static final HealthConnectService _instance = HealthConnectService._();
  factory HealthConnectService() => _instance;

  static const List<HealthConnectDataType> _sleepTypes = <HealthConnectDataType>[
    HealthConnectDataType.SleepSession,
    HealthConnectDataType.SleepStage,
  ];

  Future<bool> hasPermissions() async {
    try {
      final has = await HealthConnectFactory.hasPermissions(_sleepTypes, readOnly: true);
      if (kDebugMode) log('hasPermissions: $has');
      return has ?? false;
    } catch (e, st) {
      log('hasPermissions error: $e', stackTrace: st);
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final ok = await HealthConnectFactory.requestPermissions(_sleepTypes, readOnly: true);
      if (kDebugMode) log('requestPermissions -> $ok');
      return ok;
    } catch (e, st) {
      log('requestPermissions error: $e', stackTrace: st);
      return false;
    }
  }

  Future<bool> ensurePermissions() => requestPermissions();

  /// Sleep *sessions* (nightly merged). Defaults to last 14 days.
  Future<List<SleepRecord>> readSleepSessions({DateTime? from, DateTime? to}) async {
    final DateTime end = to ?? DateTime.now();
    final DateTime start = from ?? end.subtract(const Duration(days: 14));
    try {
      final map = await HealthConnectFactory.getRecord(
        startTime: start,
        endTime: end,
        type: HealthConnectDataType.SleepSession, // ✅ single required 'type'
        ascendingOrder: true,
      );

      final dynamic sessions = map[HealthConnectDataType.SleepSession.name];
      final out = <SleepRecord>[];

      if (sessions is List) {
        for (final item in sessions) {
          final String? startIso = item['startTime'] as String?;
          final String? endIso = item['endTime'] as String?;
          if (startIso == null || endIso == null) continue;

          final s = DateTime.parse(startIso);
          final e = DateTime.parse(endIso);
          final source = (item['dataOrigin']?['packageName'] ?? 'Health Connect').toString();

          out.add(SleepRecord(
            start: s,
            end: e,
            source: source,
            type: 'session',
          ));
        }
      }

      out.sort((a, b) => b.start.compareTo(a.start));
      return out;
    } catch (e, st) {
      log('readSleepSessions error: $e', stackTrace: st);
      return <SleepRecord>[];
    }
  }
}
