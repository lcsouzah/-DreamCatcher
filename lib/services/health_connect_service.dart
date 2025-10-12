import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../models/sleep_record.dart';

class HealthConnectService {
  HealthConnectService._();

  static final HealthConnectService _instance = HealthConnectService._();
  factory HealthConnectService() => _instance;

  final HealthFactory _healthFactory = HealthFactory();

  static const List<HealthDataType> _sleepDataTypes = <HealthDataType>[
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_IN_BED,
  ];

  static const List<HealthDataAccess> _sleepReadPermissions =
  <HealthDataAccess>[
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<bool> isAvailable() async {
    try {
      final bool available = await _healthFactory.isHealthConnectSupported();
      if (kDebugMode) log('Health Connect available: $available');
      return available;
    } catch (error, stackTrace) {
      log('Error determining Health Connect availability: $error',
          stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> hasPermissions() async {
    try {
      final bool? granted = await _healthFactory.hasPermissions(
        _sleepDataTypes,
        permissions: _sleepReadPermissions,
      );
      if (kDebugMode) log('Health Connect permission status: $granted');
      return granted ?? false;
    } catch (error, stackTrace) {
      log('Error checking Health Connect permissions: $error',
          stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final bool granted = await _healthFactory.requestAuthorization(
        _sleepDataTypes,
        permissions: _sleepReadPermissions,
      );
      if (kDebugMode) {
        log('Health Connect permission request result: $granted');
      }
      return granted;
    } catch (error, stackTrace) {
      log('Error requesting Health Connect permissions: $error',
          stackTrace: stackTrace);
      return false;
    }
  }

  Future<List<SleepRecord>> readSleepSessions({
    Duration range = const Duration(days: 7),
  }) async {
    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(range);

    try {
      final List<HealthDataPoint> dataPoints =
      await _healthFactory.getHealthDataFromTypes(
        start,
        now,
        _sleepDataTypes,
      );

      if (dataPoints.isEmpty) {
        if (kDebugMode) log('No Health Connect sleep sessions returned.');
        return <SleepRecord>[];
      }

      final Iterable<HealthDataPoint> cleaned =
      HealthFactory.removeDuplicates(dataPoints);

      final List<SleepRecord> mapped = cleaned.map((HealthDataPoint point) {
        final DateTime sessionStart = point.dateFrom;
        final DateTime sessionEnd = point.dateTo;
        final String source = (point.sourceName?.isNotEmpty ?? false)
            ? point.sourceName!
            : (point.sourceId?.isNotEmpty ?? false)
            ? point.sourceId!
            : 'Health Connect';

        return SleepRecord(
          start: sessionStart,
          end: sessionEnd,
          source: source,
          type: _mapSleepType(point.type),
        );
      }).toList()
        ..sort((SleepRecord a, SleepRecord b) => b.start.compareTo(a.start));

      return mapped;
    } catch (error, stackTrace) {
      log('Error reading Health Connect sleep sessions: $error',
          stackTrace: stackTrace);
      return <SleepRecord>[];
    }
  }

  Future<void> revokePermissions() async {
    try {
      await _healthFactory.revokePermissions();
      if (kDebugMode) log('Health Connect permissions revoked.');
    } catch (error, stackTrace) {
      log('Error revoking Health Connect permissions: $error',
          stackTrace: stackTrace);
    }
  }

  String _mapSleepType(HealthDataType type) {
    switch (type) {
      case HealthDataType.SLEEP_AWAKE:
        return 'awake';
      case HealthDataType.SLEEP_ASLEEP:
        return 'asleep';
      case HealthDataType.SLEEP_IN_BED:
        return 'in_bed';
      default:
        return type.name.toLowerCase();
    }
  }
}