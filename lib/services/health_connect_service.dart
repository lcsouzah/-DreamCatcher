import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:health_connect/health_connect.dart';

class HealthConnectService {
  static final HealthConnectService _instance = HealthConnectService._internal();
  factory HealthConnectService() => _instance;
  HealthConnectService._internal();

  final HealthConnect _healthConnect = HealthConnect();

  /// Check if Health Connect is available on the device
  Future<bool> isAvailable() async {
    try {
      final available = await _healthConnect.isAvailable();
      if (kDebugMode) log('Health Connect available: $available');
      return available;
    } catch (e) {
      log('Error checking Health Connect availability: $e');
      return false;
    }
  }

  /// Request required permissions (e.g., for sleep data)
  Future<bool> requestPermissions() async {
    try {
      final granted = await _healthConnect.requestPermission(
        [HealthConnectDataType.sleepSession],
      );
      if (kDebugMode) log('Health Connect permission granted: $granted');
      return granted;
    } catch (e) {
      log('Error requesting Health Connect permission: $e');
      return false;
    }
  }

  /// Check if permissions are already granted
  Future<bool> hasPermissions() async {
    try {
      final granted = await _healthConnect.hasPermission(
        [HealthConnectDataType.sleepSession],
      );
      if (kDebugMode) log('Health Connect permission check: $granted');
      return granted;
    } catch (e) {
      log('Error checking Health Connect permissions: $e');
      return false;
    }
  }

  /// Read recent sleep sessions from Health Connect
  Future<List<SleepRecord>> readSleepSessions({
    Duration range = const Duration(days: 7),
  }) async {
    final now = DateTime.now();
    final start = now.subtract(range);

    try {
      final records = await _healthConnect.readRecords(
        HealthConnectDataType.sleepSession,
        startTime: start,
        endTime: now,
      );

      if (records.isEmpty) {
        if (kDebugMode) log('No sleep records found.');
        return [];
      }

      // Convert HealthConnectRecord to SleepRecord
      return records.map((r) {
        final session = r as HealthConnectSleepSession;
        final duration = session.endTime.difference(session.startTime);
        return SleepRecord(
          startTime: session.startTime,
          endTime: session.endTime,
          duration: duration,
          source: session.metadata.dataOrigin.packageName ?? 'Health Connect',
        );
      }).toList();
    } catch (e, st) {
      log('Error reading sleep sessions: $e', stackTrace: st);
      return [];
    }
  }

  /// Optional helper: revoke permissions if needed
  Future<void> revokePermissions() async {
    try {
      await _healthConnect.revokeAllPermissions();
      log('All Health Connect permissions revoked');
    } catch (e) {
      log('Error revoking permissions: $e');
    }
  }
}

/// A lightweight app model representing a single sleep record
class SleepRecord {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final String source;

  SleepRecord({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.source,
  });

  String get durationString {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
