import 'dart:convert';

class SleepEntry {
  SleepEntry({
    required this.date,
    required this.start,
    required this.end,
    required this.totalMinutes,
  });

  final DateTime date;
  final DateTime start;
  final DateTime end;
  final int totalMinutes;

  double get totalHours => totalMinutes / 60.0;

  Duration get duration => Duration(minutes: totalMinutes);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': date.toIso8601String(),
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'totalMinutes': totalMinutes,
    };
  }

  factory SleepEntry.fromJson(Map<String, dynamic> json) {
    return SleepEntry(
      date: DateTime.parse(json['date'] as String),
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      totalMinutes: json['totalMinutes'] as int,
    );
  }

  static List<SleepEntry> listFromJsonString(String jsonString) {
    final Iterable<dynamic> decoded =
    json.decode(jsonString) as Iterable<dynamic>;
    return decoded
        .map((dynamic item) => SleepEntry.fromJson(
        Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
        .toList();
  }

  static String listToJsonString(List<SleepEntry> entries) {
    final List<Map<String, dynamic>> jsonList =
    entries.map((SleepEntry entry) => entry.toJson()).toList();
    return json.encode(jsonList);
  }
}