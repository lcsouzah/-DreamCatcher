import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sleep_record.dart';
import 'storage_keys.dart';

/// 🧪 Enable mock mode to develop UI without Google Fit.
/// When true → DreamCatcher will auto-generate 7 days of realistic data.
const bool kMockMode = true;

class SleepReadWindow {
  SleepReadWindow({
    required this.from,
    required this.to,
    required this.records,
  });

  final DateTime from;
  final DateTime to;
  final List<SleepRecord> records;
}

class HealthService {
  HealthService({Health? health, SharedPreferences? preferences})
      : _health = health ?? Health(),
        _preferences = preferences;

  final Health _health;
  SharedPreferences? _preferences;
  SleepReadWindow? _memoryCache;

  static const List<HealthDataType> _googleFitTypes = <HealthDataType>[
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ];

  static const List<HealthDataType> _healthConnectTypes = <HealthDataType>[
    HealthDataType.SLEEP_SESSION,
  ];

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  // ---------------------------------------------------------------------------
  // 🔹 Permission flow (mock or real)
  // ---------------------------------------------------------------------------
  Future<bool> requestPermissions() async {
    if (kMockMode) {
      debugPrint("[DreamCatcher] ✅ MockMode → auto-grant permissions");
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }

    if (!await ensureActivityPermission()) return false;
    return requestSleepAuthorization();
  }

  Future<bool> requestSleepAuthorization() async {
    if (kMockMode) {
      debugPrint("[DreamCatcher] 💤 MockMode → skip Google Fit auth");
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }

    final List<HealthDataType> _fitTypes = <HealthDataType>[
      HealthDataType.SLEEP_SESSION,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
    ];

    final List<HealthDataType> primaryTypes = await _preferredTypes();
    debugPrint("[DreamCatcher] 🔄 Requesting authorization for: $primaryTypes");

    bool granted = await _health.requestAuthorization(primaryTypes);
    debugPrint("[DreamCatcher] Primary authorization result → $granted");

    if (!granted && !_sameTypes(primaryTypes, _fitTypes)) {
      debugPrint("[DreamCatcher] ⚠️ Retrying with Google Fit types: $_fitTypes");
      granted = await _health.requestAuthorization(_fitTypes);
      debugPrint("[DreamCatcher] Google Fit authorization result → $granted");
    }

    debugPrint("[DreamCatcher] ✅ Final authorization state: $granted");
    return granted;
  }

  // ---------------------------------------------------------------------------
  // 🔹 Sleep data reading (mock or real)
  // ---------------------------------------------------------------------------
  Future<List<SleepRecord>> readSleep({
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) async {
    if (kMockMode) {
      debugPrint("[DreamCatcher] 🧪 MockMode → generating fake sleep data");
      return _generateMockSleepData(from, to);
    }

    if (!forceRefresh) {
      final List<SleepRecord>? cached = _readFromMemoryCache(from, to);
      if (cached != null) return cached;
    }

    if (!forceRefresh) {
      final List<SleepRecord>? stored = await _readFromStorage(from, to);
      if (stored != null) {
        _memoryCache = SleepReadWindow(from: from, to: to, records: stored);
        return stored;
      }
    }

    final List<HealthDataType>? authorizedTypes =
    await _resolveAuthorizedTypes();
    if (authorizedTypes == null) return <SleepRecord>[];

    try {
      final List<SleepRecord> records =
      await _fetchSleep(from: from, to: to, types: authorizedTypes);
      await _cacheWindow(from, to, records);
      return records;
    } catch (e) {
      debugPrint("[DreamCatcher] ⚠️ Error reading sleep: $e");
      final List<SleepRecord>? cached = await _readFromStorage(from, to);
      return cached ?? <SleepRecord>[];
    }
  }

  // ---------------------------------------------------------------------------
  // 💤 Generate realistic mock sleep cycles (multi-stage)
  // ---------------------------------------------------------------------------
  List<SleepRecord> _generateMockSleepData(DateTime from, DateTime to) {
    final Random rng = Random();
    final List<SleepRecord> records = [];

    for (int i = 0; i < 7; i++) {
      final DateTime day = DateTime.now().subtract(Duration(days: i));

      final bool isWeekend = day.weekday == 6 || day.weekday == 7;
      final double baseSleepHours = isWeekend ? 8.0 : 6.5;
      final double variation = rng.nextDouble() * 1.5 - 0.75;
      final double totalSleep = (baseSleepHours + variation).clamp(5.0, 9.0);

      final int startHour = 22 + rng.nextInt(3);
      final int startMinute = rng.nextBool() ? 0 : 30;
      final DateTime start =
      DateTime(day.year, day.month, day.day, startHour, startMinute);
      final DateTime end =
      start.add(Duration(minutes: (totalSleep * 60).round()));

      // Divide into sleep stages (percent-based)
      final double remPct = 0.20 + rng.nextDouble() * 0.1;
      final double deepPct = 0.25 + rng.nextDouble() * 0.1;
      final double lightPct = 0.50 - (remPct + deepPct) + rng.nextDouble() * 0.05;
      final double awakePct = 1.0 - (remPct + deepPct + lightPct);

      // Convert to minutes
      final int remMins = (totalSleep * 60 * remPct).round();
      final int deepMins = (totalSleep * 60 * deepPct).round();
      final int lightMins = (totalSleep * 60 * lightPct).round();
      final int awakeMins = (totalSleep * 60 * awakePct).round();

      DateTime cursor = start;
      final segments = [
        {'type': 'light', 'duration': lightMins},
        {'type': 'deep', 'duration': deepMins},
        {'type': 'rem', 'duration': remMins},
        {'type': 'awake', 'duration': awakeMins},
      ]..shuffle(rng);

      for (final segment in segments) {
        final DateTime segmentEnd =
        cursor.add(Duration(minutes: segment['duration'] as int));
        if (segmentEnd.isAfter(end)) break;

        records.add(SleepRecord(
          start: cursor,
          end: segmentEnd,
          type: segment['type'] as String, source: '',
        ));
        cursor = segmentEnd;
      }
    }

    records.sort((a, b) => b.start.compareTo(a.start));
    debugPrint("[DreamCatcher] 💤 Generated ${records.length} staged mock segments");

    _memoryCache = SleepReadWindow(from: from, to: to, records: records);
    return records;
  }

  // ---------------------------------------------------------------------------
  // 🔹 Real data fetching (unused in mock mode)
  // ---------------------------------------------------------------------------
  Future<List<SleepRecord>> _fetchSleep({
    required DateTime from,
    required DateTime to,
    required List<HealthDataType> types,
  }) async {
    final List<HealthDataPoint> points = await _health.getHealthDataFromTypes(
      types: types,
      startTime: from,
      endTime: to,
    );

    final Set<String> seen = <String>{};
    final List<SleepRecord> records = <SleepRecord>[];

    for (final HealthDataPoint point in points) {
      final String key = jsonEncode({
        'from': point.dateFrom.millisecondsSinceEpoch,
        'to': point.dateTo.millisecondsSinceEpoch,
        'type': point.typeString,
        'source': point.sourceId,
      });
      if (seen.add(key)) {
        records.add(SleepRecord.fromHealthDataPoint(point));
      }
    }

    records.sort((a, b) => b.start.compareTo(a.start));
    return records;
  }

  // ---------------------------------------------------------------------------
  // 🔹 Permission helpers
  // ---------------------------------------------------------------------------
  Future<bool> hasSleepPermission() async => kMockMode ? true : false;
  Future<PermissionStatus> activityPermissionStatus() async =>
      PermissionStatus.granted;
  Future<bool> ensureActivityPermission() async => true;

  // ---------------------------------------------------------------------------
  // 🔹 Cache helpers
  // ---------------------------------------------------------------------------
  List<SleepRecord>? _readFromMemoryCache(DateTime from, DateTime to) {
    final SleepReadWindow? cache = _memoryCache;
    if (cache == null) return null;
    if (!_sameRange(cache.from, cache.to, from, to)) return null;
    return cache.records;
  }

  Future<List<SleepRecord>?> _readFromStorage(
      DateTime from, DateTime to) async {
    final SharedPreferences prefs = await _prefs;
    final String? raw = prefs.getString(StorageKeys.cachedSleepRecords);
    if (raw == null || raw.isEmpty) return null;

    try {
      final Map<String, dynamic> decoded =
      jsonDecode(raw) as Map<String, dynamic>;
      final DateTime storedFrom = DateTime.parse(decoded['from'] as String);
      final DateTime storedTo = DateTime.parse(decoded['to'] as String);
      if (!_sameRange(storedFrom, storedTo, from, to)) return null;
      final Iterable<dynamic> data =
          decoded['records'] as Iterable<dynamic>? ?? const <dynamic>[];
      return data
          .map((dynamic item) => SleepRecord.fromJson(
          Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheWindow(
      DateTime from,
      DateTime to,
      List<SleepRecord> records,
      ) async {
    _memoryCache = SleepReadWindow(from: from, to: to, records: records);
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(
      StorageKeys.cachedSleepRecords,
      jsonEncode({
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
        'records':
        records.map((SleepRecord record) => record.toJson()).toList(),
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // 🔹 Utilities
  // ---------------------------------------------------------------------------
  Future<List<HealthDataType>> _preferredTypes() async {
    final bool healthConnectAvailable = await _isHealthConnectAvailable();
    return healthConnectAvailable ? _healthConnectTypes : _googleFitTypes;
  }

  Future<List<HealthDataType>?> _resolveAuthorizedTypes() async {
    final List<HealthDataType> preferred = await _preferredTypes();
    if ((await _health.hasPermissions(preferred)) ?? false) return preferred;
    if (!_sameTypes(preferred, _googleFitTypes) &&
        ((await _health.hasPermissions(_googleFitTypes)) ?? false)) {
      return _googleFitTypes;
    }
    return null;
  }

  Future<bool> _isHealthConnectAvailable() async {
    try {
      return await _health.isDataTypeAvailable(HealthDataType.SLEEP_SESSION);
    } catch (_) {
      return false;
    }
  }

  bool _sameTypes(List<HealthDataType> a, List<HealthDataType> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _sameRange(DateTime aFrom, DateTime aTo, DateTime bFrom, DateTime bTo) {
    return aFrom.isAtSameMomentAs(bFrom) && aTo.isAtSameMomentAs(bTo);
  }
}
