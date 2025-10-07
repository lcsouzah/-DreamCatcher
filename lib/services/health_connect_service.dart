import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:health_connect/health_connect.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sleep_record.dart';
import 'storage_keys.dart';

/// 🧪 Enable mock mode to develop UI without Google Fit / Health Connect.
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

class HealthConnectUnavailableException implements Exception {
  const HealthConnectUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HealthConnectService {
  HealthConnectService({
    HealthConnectFactory? factory,
    HealthConnectManager? manager,
    SharedPreferences? preferences,
  })  : _factory = factory ?? HealthConnectFactory(),
        _manager = manager,
        _preferences = preferences;

  final dynamic _factory;
  HealthConnectManager? _manager;
  SharedPreferences? _preferences;
  SleepReadWindow? _memoryCache;

  static const List<HealthConnectDataType> _dataTypes =
  <HealthConnectDataType>[
    HealthConnectDataType.sleepSession,
    HealthConnectDataType.steps,
    HealthConnectDataType.heartRateSeries,
    HealthConnectDataType.mood,
  ];

  static List<HealthConnectPermission> get _readPermissions =>
      _dataTypes
          .map((HealthConnectDataType type) =>
          HealthConnectPermission.read(type))
          .toList();

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<HealthConnectManager> _ensureManager() async {
    final HealthConnectManager? cached = _manager;
    if (cached != null) return cached;

    final bool available = await _isHealthConnectAvailable();
    if (!available) {
      throw const HealthConnectUnavailableException(
        'Health Connect is not installed or not supported on this device.',
      );
    }

    try {
      final dynamic created = _factory.create();
      if (created is Future<HealthConnectManager>) {
        final HealthConnectManager manager = await created;
        _manager = manager;
        return manager;
      }
      if (created is HealthConnectManager) {
        _manager = created;
        return created;
      }
    } on NoSuchMethodError {
      // Fallback for factories that expose a differently named creator.
    }

    final dynamic fallback =
    _tryCall<dynamic>(() => _factory.createHealthConnectManager());
    if (fallback is Future<HealthConnectManager>) {
      final HealthConnectManager manager = await fallback;
      _manager = manager;
      return manager;
    }
    if (fallback is HealthConnectManager) {
      _manager = fallback;
      return fallback;
    }

    throw const HealthConnectUnavailableException(
      'Unable to create Health Connect manager instance.',
    );
  }

  // ---------------------------------------------------------------------------
  // 🔹 Permission flow (mock or real)
  // ---------------------------------------------------------------------------
  Future<bool> requestPermissions() async {
    if (kMockMode) {
      debugPrint('[DreamCatcher] ✅ MockMode → auto-grant permissions');
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }

    try {
      final HealthConnectManager manager = await _ensureManager();
      final bool granted = await manager.requestPermissions(_readPermissions);
      return granted;
    } on HealthConnectUnavailableException {
      rethrow;
    } on HealthConnectException catch (error) {
      debugPrint('[DreamCatcher] ⚠️ Health Connect error: $error');
      return false;
    } catch (error) {
      debugPrint('[DreamCatcher] ⚠️ Unexpected permission error: $error');
      return false;
    }
  }

  Future<bool> requestSleepAuthorization() => requestPermissions();

  // ---------------------------------------------------------------------------
  // 🔹 Sleep data reading (mock or real)
  // ---------------------------------------------------------------------------
  Future<List<SleepRecord>> readSleep({
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) async {
    if (kMockMode) {
      debugPrint('[DreamCatcher] 🧪 MockMode → generating fake sleep data');
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

    try {
      final HealthConnectManager manager = await _ensureManager();
      final List<SleepRecord> records =
      await _fetchSleep(manager: manager, from: from, to: to);
      await _cacheWindow(from, to, records);
      return records;
    } on HealthConnectUnavailableException catch (error) {
      debugPrint('[DreamCatcher] ❌ $error');
      rethrow;
    } catch (error) {
      debugPrint('[DreamCatcher] ⚠️ Error reading sleep: $error');
      final List<SleepRecord>? cached = await _readFromStorage(from, to);
      return cached ?? <SleepRecord>[];
    }
  }

  // ---------------------------------------------------------------------------
  // 💤 Generate realistic mock sleep cycles (multi-stage)
  // ---------------------------------------------------------------------------
  List<SleepRecord> _generateMockSleepData(DateTime from, DateTime to) {
    final Random rng = Random();
    final List<SleepRecord> records = <SleepRecord>[];

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

      final double remPct = 0.20 + rng.nextDouble() * 0.1;
      final double deepPct = 0.25 + rng.nextDouble() * 0.1;
      final double lightPct =
          0.50 - (remPct + deepPct) + rng.nextDouble() * 0.05;
      final double awakePct = 1.0 - (remPct + deepPct + lightPct);

      final int remMins = (totalSleep * 60 * remPct).round();
      final int deepMins = (totalSleep * 60 * deepPct).round();
      final int lightMins = (totalSleep * 60 * lightPct).round();
      final int awakeMins = (totalSleep * 60 * awakePct).round();

      DateTime cursor = start;
      final List<Map<String, dynamic>> segments = <Map<String, dynamic>>[
        <String, dynamic>{'type': 'light', 'duration': lightMins},
        <String, dynamic>{'type': 'deep', 'duration': deepMins},
        <String, dynamic>{'type': 'rem', 'duration': remMins},
        <String, dynamic>{'type': 'awake', 'duration': awakeMins},
      ]..shuffle(rng);

      for (final Map<String, dynamic> segment in segments) {
        final DateTime segmentEnd =
        cursor.add(Duration(minutes: segment['duration'] as int));
        if (segmentEnd.isAfter(end)) break;

        records.add(SleepRecord(
          start: cursor,
          end: segmentEnd,
          type: segment['type'] as String,
          source: 'DreamCatcher Mock',
        ));
        cursor = segmentEnd;
      }
    }

    records.sort((SleepRecord a, SleepRecord b) => b.start.compareTo(a.start));

    _memoryCache = SleepReadWindow(from: from, to: to, records: records);
    return records;
  }

  // ---------------------------------------------------------------------------
  // 🔹 Real data fetching (unused in mock mode)
  // ---------------------------------------------------------------------------
  Future<List<SleepRecord>> _fetchSleep({
    required HealthConnectManager manager,
    required DateTime from,
    required DateTime to,
  }) async {
    final List<dynamic> rawRecords = await _readSleepSessions(
      manager: manager,
      from: from,
      to: to,
    );

    final List<SleepRecord> records = rawRecords
        .map((dynamic record) => _sleepRecordFromHealthConnect(record))
        .where((SleepRecord? record) => record != null)
        .cast<SleepRecord>()
        .toList();

    records.sort((SleepRecord a, SleepRecord b) => b.start.compareTo(a.start));
    return records;
  }

  Future<List<dynamic>> _readSleepSessions({
    required HealthConnectManager manager,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final dynamic timeRange = _buildTimeRangeFilter(from, to);
      final dynamic response = await manager.getRecords(
        HealthConnectDataType.sleepSession,
        timeRange: timeRange,
      );

      if (response is List) {
        return response;
      }

      if (response is Map && response['records'] is List) {
        return List<dynamic>.from(response['records'] as List<dynamic>);
      }
    } on NoSuchMethodError {
      final dynamic timeRange = _buildTimeRangeFilter(from, to);
      final dynamic response = await manager.readRecords(
        dataType: HealthConnectDataType.sleepSession,
        timeRangeFilter: timeRange,
      );
      if (response is List) return response;
      if (response is Map && response['records'] is List) {
        return List<dynamic>.from(response['records'] as List<dynamic>);
      }
    }

    return <dynamic>[];
  }

  dynamic _buildTimeRangeFilter(DateTime from, DateTime to) {
    try {
      return HealthConnectTimeRangeFilter(
        startTime: from,
        endTime: to,
      );
    } on NoSuchMethodError {
      try {
        return HealthConnectTimeRangeFilter.between(
          startTime: from,
          endTime: to,
        );
      } catch (_) {
        return null;
      }
    }
  }

  SleepRecord? _sleepRecordFromHealthConnect(dynamic record) {
    final DateTime? start = _extractStart(record);
    final DateTime? end = _extractEnd(record);
    if (start == null || end == null) return null;

    final String source = _extractSource(record);
    final String stage = _extractStage(record);

    return SleepRecord(
      start: start,
      end: end,
      source: source,
      type: stage,
    );
  }

  DateTime? _extractStart(dynamic record) {
    final List<DateTime?> candidates = <DateTime?>[
      _toDateTime(_tryCall(() => record.startTime)),
      _toDateTime(_tryCall(() => record.startDateTime)),
      _toDateTime(_tryCall(() => record.start)),
      _toDateTime(_tryCall(() => record.startInstant)),
    ];
    return candidates.firstWhere((DateTime? value) => value != null,
        orElse: () => null);
  }

  DateTime? _extractEnd(dynamic record) {
    final List<DateTime?> candidates = <DateTime?>[
      _toDateTime(_tryCall(() => record.endTime)),
      _toDateTime(_tryCall(() => record.endDateTime)),
      _toDateTime(_tryCall(() => record.end)),
      _toDateTime(_tryCall(() => record.endInstant)),
    ];
    return candidates.firstWhere((DateTime? value) => value != null,
        orElse: () => null);
  }

  String _extractSource(dynamic record) {
    final List<String?> candidates = <String?>[
      _tryCall<String?>(() => record.metadata?.dataOrigin?.packageName),
      _tryCall<String?>(() => record.metadata?.dataOrigin?.appPackageName),
      _tryCall<String?>(() => record.metadata?.device?.manufacturer),
      _tryCall<String?>(() => record.metadata?.device?.model),
      _tryCall<String?>(() => record.packageName),
      _tryCall<String?>(() => record.sourcePackageName),
      _tryCall<String?>(() => record.title),
    ];

    return candidates.firstWhere(
          (String? value) => value != null && value.isNotEmpty,
      orElse: () => 'Health Connect',
    )!;
  }

  String _extractStage(dynamic record) {
    final String? stage = _tryCall<String?>(() => record.stage?.name);
    if (stage != null && stage.isNotEmpty) {
      return stage.toLowerCase();
    }

    return 'sleep';
  }

  T? _tryCall<T>(T Function() fn) {
    try {
      return fn();
    } catch (_) {
      return null;
    }
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    final DateTime? fromDateTime = _tryCall<DateTime?>(() => value.dateTime);
    if (fromDateTime != null) return fromDateTime;

    final DateTime? fromToDateTime = _tryCall<DateTime?>(() => value.toDateTime());
    if (fromToDateTime != null) return fromToDateTime;
    return null;
  }

  // ---------------------------------------------------------------------------
  // 🔹 Permission helpers
  // ---------------------------------------------------------------------------
  Future<bool> hasSleepPermission() async {
    if (kMockMode) return true;

    try {
      final HealthConnectManager manager = await _ensureManager();
      final dynamic status = await manager.checkPermissions(_readPermissions);
      if (status is Map<HealthConnectDataType, bool>) {
        return status[HealthConnectDataType.sleepSession] ?? false;
      }
      if (status is Map) {
        final dynamic value = status[HealthConnectDataType.sleepSession];
        if (value is bool) return value;
        if (value is HealthConnectPermissionStatus) {
          return value == HealthConnectPermissionStatus.granted;
        }
      }
    } catch (error) {
      debugPrint('[DreamCatcher] ⚠️ hasSleepPermission failed: $error');
    }

    return false;
  }

  Future<PermissionStatus> activityPermissionStatus() async {
    if (kMockMode) return PermissionStatus.granted;
    final PermissionStatus status = await Permission.activityRecognition.status;
    return status;
  }

  Future<bool> ensureActivityPermission() async {
    if (kMockMode) return true;
    final PermissionStatus status = await activityPermissionStatus();
    if (status.isGranted) return true;
    final PermissionStatus result =
    await Permission.activityRecognition.request();
    return result.isGranted;
  }

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
      jsonEncode(<String, dynamic>{
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
  /// Confirms the Health Connect provider is present before attempting to
  /// create a manager instance. This relies on the manifest `queries` entries
  /// for `com.google.android.apps.healthdata` and
  /// `com.google.android.healthconnect.controller`, ensuring package discovery
  /// succeeds on both standalone and system-integrated installs.
  Future<bool> _isHealthConnectAvailable() async {
    final List<dynamic> checks = <dynamic>[
      _tryCall<dynamic>(() => _factory.isApiSupported()),
      _tryCall<dynamic>(() => _factory.isAvailable()),
      _tryCall<dynamic>(() => _factory.isHealthConnectAvailable()),
    ];

    for (final dynamic result in checks) {
      if (result is Future<bool>) {
        if (await result) return true;
      } else if (result is bool && result) {
        return true;
      }
    }

    return false;
  }

  bool _sameRange(DateTime aFrom, DateTime aTo, DateTime bFrom, DateTime bTo) {
    return aFrom.isAtSameMomentAs(bFrom) && aTo.isAtSameMomentAs(bTo);
  }
}