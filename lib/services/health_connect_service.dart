import 'dart:developer';

import 'package:health/health.dart';

import '../models/sleep_record.dart';

class HealthConnectServiceException implements Exception {
  const HealthConnectServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HealthConnectService {
  HealthConnectService._();
  static final HealthConnectService _instance = HealthConnectService._();
  factory HealthConnectService() => _instance;

  final Health _health = Health();

  static const List<HealthDataType> _types = <HealthDataType>[
    HealthDataType.SLEEP_SESSION,
  ];

  Future<bool> isAvailable() async {
    try {
      final bool available = await _health.isHealthConnectAvailable();
      log('[Health] Health Connect availability: $available');
      return available;
    } catch (e, st) {
      log('[Health] Error checking availability: $e', stackTrace: st);
      return false;
    }
  }

  Future<bool> hasPermissions() async {
    final bool available = await isAvailable();
    if (!available) {
      return false;
    }

    try {
      final bool? has = await _health.hasPermissions(_types);
      log('[Health] hasPermissions: $has');
      return has ?? false;
    } catch (e, st) {
      log('[Health] hasPermissions error: $e', stackTrace: st);
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    final bool available = await isAvailable();
    if (!available) {
      log('[Health] requestPermissions skipped: Health Connect unavailable');
      return false;
    }

    try {
      log('[Health] Requesting permissions for types: $_types');
      final bool requested = await _health.requestAuthorization(
        _types,
        permissions: _types.map((_) => HealthDataAccess.READ).toList(),
      );
      log('[Health] Permission request result: $requested');
      return requested;
    } catch (e, st) {
      log('[Health] requestPermissions error: $e', stackTrace: st);
      return false;
    }
  }

  Future<List<SleepRecord>> readSleepSessions({DateTime? from, DateTime? to}) async {
    final DateTime end = to ?? DateTime.now();
    final DateTime start = from ?? end.subtract(const Duration(days: 7));

    final bool available = await isAvailable();
    if (!available) {
      throw const HealthConnectServiceException(
        'Health Connect is not available on this device. Install or update Health Connect and try again.',
      );
    }

    final bool hasPermission = await hasPermissions();
    if (!hasPermission) {
      throw const HealthConnectServiceException(
        'Health Connect permission is not granted for sleep data.',
      );
    }

    try {
      log('[Health] Reading sleep records from $start to $end');
      final List<HealthDataPoint> dataPoints = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: _types,
      );

      final List<SleepRecord> out = <SleepRecord>[];
      for (final HealthDataPoint point in dataPoints) {
        if (point.type == HealthDataType.SLEEP_SESSION) {
          out.add(
            SleepRecord(
              start: point.dateFrom,
              end: point.dateTo,
              source: point.sourceName,
              type: 'light',
            ),
          );
        }
      }

      out.sort((SleepRecord a, SleepRecord b) => b.start.compareTo(a.start));
      log('[Health] Successfully read ${out.length} records');
      return out;
    } catch (e, st) {
      log('[Health] readSleepSessions error: $e', stackTrace: st);
      throw const HealthConnectServiceException(
        'Unable to read sleep data right now. Please try again.',
      );
    }
  }

  String _mapHealthTypeToSleepType(HealthDataType type) {
    switch (type) {
      case HealthDataType.SLEEP_DEEP:
        return 'deep';
      case HealthDataType.SLEEP_REM:
        return 'rem';
      case HealthDataType.SLEEP_AWAKE:
        return 'awake';
      case HealthDataType.SLEEP_ASLEEP:
      case HealthDataType.SLEEP_SESSION:
      default:
        return 'light';
    }
  }

  Future<void> openHealthConnectSettings() async {
    try {
      await _health.installHealthConnect();
    } catch (e, st) {
      log('[Health] Could not open Health Connect settings: $e', stackTrace: st);
    }
  }
}