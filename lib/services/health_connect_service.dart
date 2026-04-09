import 'dart:developer';
import 'package:flutter_health_connect/flutter_health_connect.dart';

import '../models/sleep_record.dart';

class HealthConnectService {
  HealthConnectService._();
  static final HealthConnectService _instance = HealthConnectService._();
  factory HealthConnectService() => _instance;

  static const List<HealthConnectDataType> _sleepTypes = <HealthConnectDataType>[
    HealthConnectDataType.SleepSession,
  ];

  /// Safety lock to prevent "Reply already submitted" crash in the plugin.
  bool _isRequesting = false;

  Future<bool> hasPermissions() async {
    try {
      final has = await HealthConnectFactory.hasPermissions(_sleepTypes, readOnly: true);
      log('[Health] hasPermissions: $has');
      return has ?? false;
    } catch (e) {
      log('[Health] hasPermissions error: $e');
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    if (_isRequesting) {
      log('[Health] Request already in progress, ignoring duplicate call.');
      return false;
    }

    _isRequesting = true;
    try {
      log('[Health] Requesting permissions...');
      final ok = await HealthConnectFactory.requestPermissions(_sleepTypes, readOnly: true);
      log('[Health] requestPermissions result: $ok');
      return ok;
    } catch (e, st) {
      log('[Health] requestPermissions error: $e', stackTrace: st);
      return false;
    } finally {
      _isRequesting = false;
    }
  }

  Future<List<SleepRecord>> readSleepSessions({DateTime? from, DateTime? to}) async {
    final DateTime end = to ?? DateTime.now();
    final DateTime start = from ?? end.subtract(const Duration(days: 14));
    
    try {
      log('[Health] Reading sleep records from $start to $end');
      final map = await HealthConnectFactory.getRecord(
        startTime: start,
        endTime: end,
        type: HealthConnectDataType.SleepSession,
        ascendingOrder: true,
      );

      final dynamic sessions = map[HealthConnectDataType.SleepSession.name];
      final out = <SleepRecord>[];

      if (sessions is List) {
        for (final item in sessions) {
          final String? startIso = item['startTime'] as String?;
          final String? endIso = item['endTime'] as String?;
          if (startIso == null || endIso == null) continue;

          out.add(SleepRecord(
            start: DateTime.parse(startIso),
            end: DateTime.parse(endIso),
            source: (item['dataOrigin']?['packageName'] ?? 'Health Connect').toString(),
            type: 'session',
          ));
        }
      }

      log('[Health] Successfully read ${out.length} records');
      out.sort((a, b) => b.start.compareTo(a.start));
      return out;
    } catch (e, st) {
      log('[Health] readSleepSessions error: $e', stackTrace: st);
      return <SleepRecord>[];
    }
  }
}
