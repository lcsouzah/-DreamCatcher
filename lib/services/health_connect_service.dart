import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:health_connect/health_connect.dart';

import '../models/sleep_record.dart';

class HealthConnectService {
  HealthConnectService._();

  static final HealthConnectService _instance = HealthConnectService._();
  factory HealthConnectService() => _instance;

  final HealthConnect _healthConnect = HealthConnect();

  Future<bool> isAvailable() async {
    try {
      final bool available = await _healthConnect.isAvailable();
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
      final bool granted = await _healthConnect.hasPermission(
        <HealthConnectDataType>[HealthConnectDataType.sleepSession],
      );
      if (kDebugMode) log('Health Connect permission status: $granted');
      return granted;
    } catch (error, stackTrace) {
      log('Error checking Health Connect permissions: $error',
          stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final bool granted = await _healthConnect.requestPermission(
        <HealthConnectDataType>[HealthConnectDataType.sleepSession],
      );
      if (kDebugMode) log('Health Connect permission request result: $granted');
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
      final List<HealthConnectRecord> records = await _healthConnect.readRecords(
        HealthConnectDataType.sleepSession,
        startTime: start,
        endTime: now,
      );

      if (records.isEmpty) {
        if (kDebugMode) log('No Health Connect sleep sessions returned.');
        return <SleepRecord>[];
      }

      final List<SleepRecord> mapped = records
          .whereType<HealthConnectSleepSession>()
          .map((HealthConnectSleepSession session) {
        final DateTime sessionStart = session.startTime;
        final DateTime sessionEnd = session.endTime;
        final String? originPackage =
            session.metadata.dataOrigin.packageName;
        final String source =
        (originPackage != null && originPackage.isNotEmpty)
            ? originPackage
            : 'Health Connect';

        return SleepRecord(
          start: sessionStart,
          end: sessionEnd,
          source: source,
          type: 'session',
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
      await _healthConnect.revokeAllPermissions();
      if (kDebugMode) log('Health Connect permissions revoked.');
    } catch (error, stackTrace) {
      log('Error revoking Health Connect permissions: $error',
          stackTrace: stackTrace);
    }
  }
}
