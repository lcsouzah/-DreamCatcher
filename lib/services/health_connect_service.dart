import 'dart:developer';
import 'package:health/health.dart';
import '../models/sleep_record.dart';

class HealthConnectService {
  HealthConnectService._();
  static final HealthConnectService _instance = HealthConnectService._();
  factory HealthConnectService() => _instance;

  final Health _health = Health();

  static const List<HealthDataType> _types = [
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ];

  /// Checks if Health Connect is available on the device.
  Future<bool> isAvailable() async {
    try {
      final available = await _health.isHealthConnectAvailable();
      log('[Health] Health Connect availability: $available');
      return available;
    } catch (e) {
      log('[Health] Error checking availability: $e');
      return false;
    }
  }

  /// Checks if the necessary permissions are already granted.
  Future<bool> hasPermissions() async {
    try {
      final has = await _health.hasPermissions(_types);
      log('[Health] hasPermissions: $has');
      return has ?? false;
    } catch (e) {
      log('[Health] hasPermissions error: $e');
      return false;
    }
  }

  /// Requests permissions from the user.
  /// Decoupled from Google Sign-In on Android when using Health Connect.
  Future<bool> requestPermissions() async {
    try {
      log('[Health] Requesting permissions for types: $_types');
      final requested = await _health.requestAuthorization(
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

  /// Reads sleep records from Health Connect.
  Future<List<SleepRecord>> readSleepSessions({DateTime? from, DateTime? to}) async {
    final DateTime end = to ?? DateTime.now();
    final DateTime start = from ?? end.subtract(const Duration(days: 7));

    try {
      log('[Health] Reading sleep records from $start to $end');
      
      // Fetching health data
      final List<HealthDataPoint> dataPoints = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: _types,
      );

      final out = <SleepRecord>[];

      // Grouping data by session if possible, or mapping individual points
      // Note: SLEEP_SESSION usually represents the whole night
      for (final point in dataPoints) {
        if (point.type == HealthDataType.SLEEP_SESSION || 
            point.type == HealthDataType.SLEEP_ASLEEP ||
            point.type == HealthDataType.SLEEP_DEEP ||
            point.type == HealthDataType.SLEEP_REM ||
            point.type == HealthDataType.SLEEP_AWAKE) {
          
          out.add(SleepRecord(
            start: point.dateFrom,
            end: point.dateTo,
            source: point.sourceName,
            type: _mapHealthTypeToSleepType(point.type),
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
        return 'light'; // Defaulting to light/general sleep
    }
  }

  /// Opens Health Connect settings for the user to manage permissions manually.
  Future<void> openHealthConnectSettings() async {
    try {
      await _health.installHealthConnect();
    } catch (e) {
      log('[Health] Could not open Health Connect settings: $e');
    }
  }
}
