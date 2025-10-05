import 'dart:convert';
import 'package:health/health.dart';

class SleepRecord {
  SleepRecord({
    required this.start,
    required this.end,
    required this.source,
    required this.type,
  }) : duration = end.difference(start);

  /// Create from HealthDataPoint (used when reading from Google Fit)
  factory SleepRecord.fromHealthDataPoint(HealthDataPoint point) {
    final String parsedType =
    point.typeString.split('.').last.toLowerCase(); // e.g. sleep_rem → rem

    return SleepRecord(
      start: point.dateFrom,
      end: point.dateTo,
      source: point.sourceName ?? point.sourceId ?? 'Unknown',
      type: parsedType,
    );
  }

  /// Deserialize from JSON (used when loading cached data)
  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    return SleepRecord(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      source: json['source'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? 'light',
    );
  }

  final DateTime start;
  final DateTime end;
  final Duration duration;
  final String source;
  final String type;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'duration': duration.inSeconds,
      'source': source,
      'type': type,
    };
  }

  // ---------------------------------------------------------------------------
  // 💤 Static helpers
  // ---------------------------------------------------------------------------

  static String listToJsonString(List<SleepRecord> records) {
    final List<Map<String, dynamic>> encoded =
    records.map((SleepRecord record) => record.toJson()).toList();
    return jsonEncode(<String, dynamic>{'records': encoded});
  }

  static List<SleepRecord> listFromJsonString(String raw) {
    final Map<String, dynamic> decoded =
    jsonDecode(raw) as Map<String, dynamic>;
    final Iterable<dynamic> list =
        decoded['records'] as Iterable<dynamic>? ?? const <dynamic>[];
    return list
        .map((dynamic item) => SleepRecord.fromJson(
      Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
    ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // 🌙 Sleep quality system
  // ---------------------------------------------------------------------------

  /// Calculate overall quality for a group of records (0–100)
  static double calculateQuality(List<SleepRecord> records) {
    if (records.isEmpty) return 0;

    double totalMinutes = 0;
    double deepMinutes = 0;
    double remMinutes = 0;
    double awakeMinutes = 0;

    for (final record in records) {
      final double mins = record.duration.inMinutes.toDouble();
      totalMinutes += mins;

      switch (record.type.toLowerCase()) {
        case 'deep':
          deepMinutes += mins;
          break;
        case 'rem':
          remMinutes += mins;
          break;
        case 'awake':
          awakeMinutes += mins;
          break;
      }
    }

    if (totalMinutes == 0) return 0;

    final double deepRatio = deepMinutes / totalMinutes;
    final double remRatio = remMinutes / totalMinutes;
    final double awakeRatio = awakeMinutes / totalMinutes;

    // Ideal ranges (based on average healthy sleep composition)
    const double idealDeep = 0.20; // 20%
    const double idealRem = 0.25;  // 25%
    const double idealAwake = 0.05; // 5% or less

    // Deviation penalties
    final double deepScore = (1 - (idealDeep - deepRatio).abs()) * 40;
    final double remScore = (1 - (idealRem - remRatio).abs()) * 40;
    final double awakePenalty = (1 - awakeRatio / idealAwake).clamp(0, 1) * 20;

    double baseScore = deepScore + remScore + awakePenalty;

    // Duration adjustment
    final double hours = totalMinutes / 60.0;
    if (hours < 6) baseScore *= 0.7;
    if (hours >= 7 && hours <= 8.5) baseScore *= 1.05; // optimal bonus
    if (hours > 9) baseScore *= 0.9; // too long penalty

    return baseScore.clamp(0, 100);
  }

  /// Calculate quality for a single night (0–100)
  double get quality => calculateQuality([this]);
}
