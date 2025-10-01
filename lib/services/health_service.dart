import 'dart:async';
import 'dart:convert';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sleep_record.dart';
import 'storage_keys.dart';

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

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<bool> requestPermissions() async {
    if (!await ensureActivityPermission()) {
      return false;
    }

    return requestSleepAuthorization();
  }

  Future<List<SleepRecord>> readSleep({
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final List<SleepRecord>? cached = _readFromMemoryCache(from, to);
      if (cached != null) {
        return cached;
      }
    }

    if (!forceRefresh) {
      final List<SleepRecord>? stored = await _readFromStorage(from, to);
      if (stored != null) {
        _memoryCache = SleepReadWindow(
          from: from,
          to: to,
          records: stored,
        );
        return stored;
      }
    }

    final List<HealthDataType>? authorizedTypes =
    await _resolveAuthorizedTypes();
    if (authorizedTypes == null) {
      final List<SleepRecord>? cached = await _readFromStorage(from, to);
      if (cached != null) {
        _memoryCache = SleepReadWindow(
          from: from,
          to: to,
          records: cached,
        );
        return cached;
      }
      return <SleepRecord>[];
    }

    try {
      final List<SleepRecord> records = await _fetchSleep(
        from: from,
        to: to,
        types: authorizedTypes,
      );
      await _cacheWindow(from, to, records);
      return records;
    } on Exception {
      if (!_sameTypes(authorizedTypes, _googleFitTypes)) {
        final List<SleepRecord>? fallbackRecords =
        await _tryFallback(from: from, to: to);
        if (fallbackRecords != null) {
          await _cacheWindow(from, to, fallbackRecords);
          return fallbackRecords;
        }
      }
      final List<SleepRecord>? cached = await _readFromStorage(from, to);
      if (cached != null) {
        _memoryCache = SleepReadWindow(
          from: from,
          to: to,
          records: cached,
        );
        return cached;
      }
      rethrow;
    }
  }

  Future<bool> hasSleepPermission() async {
    final List<HealthDataType> preferred = await _preferredTypes();
    if ((await _health.hasPermissions(preferred)) ?? false) {
      return true;
    }
    if (!_sameTypes(preferred, _googleFitTypes)) {
      return (await _health.hasPermissions(_googleFitTypes)) ?? false;
    }
    return false;
  }

  Future<PermissionStatus> activityPermissionStatus() async {
    return Permission.activityRecognition.status;
  }

  Future<bool> ensureActivityPermission() async {
    PermissionStatus status = await Permission.activityRecognition.status;
    if (status.isGranted) {
      return true;
    }

    status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      status = await Permission.activityRecognition.request();
    }

    return status.isGranted;
  }

  Future<bool> requestSleepAuthorization() async {
    final List<HealthDataType> primaryTypes = await _preferredTypes();
    bool granted = await _health.requestAuthorization(primaryTypes);
    if (!granted && !_sameTypes(primaryTypes, _googleFitTypes)) {
      granted = await _health.requestAuthorization(_googleFitTypes);
    }
    return granted;
  }

  Future<List<SleepRecord>?> _tryFallback({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!((await _health.hasPermissions(_googleFitTypes)) ?? false)) {
      return null;
    }
    try {
      return await _fetchSleep(from: from, to: to, types: _googleFitTypes);
    } on Exception {
      return null;
    }
  }

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
      final String key = jsonEncode(<String, dynamic>{
        'from': point.dateFrom.millisecondsSinceEpoch,
        'to': point.dateTo.millisecondsSinceEpoch,
        'type': point.typeString,
        'source': point.sourceId,
      });
      if (seen.add(key)) {
        records.add(SleepRecord.fromHealthDataPoint(point));
      }
    }

    records.sort((SleepRecord a, SleepRecord b) => b.start.compareTo(a.start));
    return records;
  }

  Future<List<HealthDataType>> _preferredTypes() async {
    final bool healthConnectAvailable = await _isHealthConnectAvailable();
    return healthConnectAvailable ? _healthConnectTypes : _googleFitTypes;
  }

  Future<List<HealthDataType>?> _resolveAuthorizedTypes() async {
    final List<HealthDataType> preferred = await _preferredTypes();
    if ((await _health.hasPermissions(preferred)) ?? false) {
      return preferred;
    }
    if (!_sameTypes(preferred, _googleFitTypes) &&
        (await _health.hasPermissions(_googleFitTypes)) ?? false) {
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

  List<SleepRecord>? _readFromMemoryCache(DateTime from, DateTime to) {
    final SleepReadWindow? cache = _memoryCache;
    if (cache == null) {
      return null;
    }
    if (!_sameRange(cache.from, cache.to, from, to)) {
      return null;
    }
    return cache.records;
  }

  Future<List<SleepRecord>?> _readFromStorage(
      DateTime from, DateTime to) async {
    final SharedPreferences prefs = await _prefs;
    final String? raw = prefs.getString(StorageKeys.cachedSleepRecords);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> decoded =
      jsonDecode(raw) as Map<String, dynamic>;
      final DateTime storedFrom = DateTime.parse(decoded['from'] as String);
      final DateTime storedTo = DateTime.parse(decoded['to'] as String);
      if (!_sameRange(storedFrom, storedTo, from, to)) {
        return null;
      }
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
    _memoryCache = SleepReadWindow(
      from: from,
      to: to,
      records: records,
    );

    final SharedPreferences prefs = await _prefs;
    await prefs.setString(
      StorageKeys.cachedSleepRecords,
      jsonEncode(<String, dynamic>{
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
        'records': records
            .map((SleepRecord record) => record.toJson())
            .toList(growable: false),
      }),
    );
  }

  bool _sameTypes(List<HealthDataType> a, List<HealthDataType> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  bool _sameRange(DateTime aFrom, DateTime aTo, DateTime bFrom, DateTime bTo) {
    return aFrom.isAtSameMomentAs(bFrom) && aTo.isAtSameMomentAs(bTo);
  }
}