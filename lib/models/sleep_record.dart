import 'dart:convert';

import 'package:health/health.dart';

class SleepRecord {
  SleepRecord({
    required this.start,
    required this.end,
    required this.source,
  }) : duration = end.difference(start);

  factory SleepRecord.fromHealthDataPoint(HealthDataPoint point) {
    return SleepRecord(
      start: point.dateFrom,
      end: point.dateTo,
      source: point.sourceName ?? point.sourceId ?? 'Unknown',
    );
  }

  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    return SleepRecord(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      source: json['source'] as String? ?? 'Unknown',
    );
  }

  final DateTime start;
  final DateTime end;
  final Duration duration;
  final String source;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'duration': duration.inSeconds,
      'source': source,
    };
  }

  static String listToJsonString(List<SleepRecord> records) {
    final List<Map<String, dynamic>> encoded =
    records.map((SleepRecord record) => record.toJson()).toList();
    return jsonEncode(<String, dynamic>{'records': encoded});
  }

  static List<SleepRecord> listFromJsonString(String raw) {
    final Map<String, dynamic> decoded =
    jsonDecode(raw) as Map<String, dynamic>;
    final Iterable<dynamic> list = decoded['records'] as Iterable<dynamic>? ??
        const <dynamic>[];
    return list
        .map((dynamic item) => SleepRecord.fromJson(
        Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
        .toList();
  }
}