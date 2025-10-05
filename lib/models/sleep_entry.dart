import 'dart:convert';
import 'sleep_record.dart';

class SleepEntry {
  SleepEntry({
    required this.date,
    required this.start,
    required this.end,
    required this.totalMinutes,
    required this.records, // 👈 added field
  });

  final DateTime date;
  final DateTime start;
  final DateTime end;
  final int totalMinutes;
  final List<SleepRecord> records; // 👈 keeps raw stage data for detail screen

  double get totalHours => totalMinutes / 60.0;
  Duration get duration => Duration(minutes: totalMinutes);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': date.toIso8601String(),
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'totalMinutes': totalMinutes,
      'records': records.map((r) => r.toJson()).toList(), // 👈 added
    };
  }

  factory SleepEntry.fromJson(Map<String, dynamic> json) {
    final List<SleepRecord> recs = (json['records'] as List?)
        ?.map((e) => SleepRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList() ??
        <SleepRecord>[];
    return SleepEntry(
      date: DateTime.parse(json['date'] as String),
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      totalMinutes: json['totalMinutes'] as int,
      records: recs,
    );
  }

  static List<SleepEntry> listFromJsonString(String jsonString) {
    final Iterable<dynamic> decoded = json.decode(jsonString) as Iterable<dynamic>;
    return decoded
        .map((dynamic item) =>
        SleepEntry.fromJson(Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
        .toList();
  }

  static String listToJsonString(List<SleepEntry> entries) {
    final List<Map<String, dynamic>> jsonList =
    entries.map((SleepEntry entry) => entry.toJson()).toList();
    return json.encode(jsonList);
  }

  static List<SleepEntry> aggregateFromRecords(List<SleepRecord> records, {int limit = 7}) {
    if (records.isEmpty) return <SleepEntry>[];

    final Map<DateTime, List<SleepRecord>> grouped = {};

    for (final SleepRecord record in records) {
      final DateTime bucket = DateTime(record.start.year, record.start.month, record.start.day);
      grouped.putIfAbsent(bucket, () => <SleepRecord>[]).add(record);
    }

    final List<SleepEntry> entries = grouped.entries.map((MapEntry<DateTime, List<SleepRecord>> entry) {
      final List<SleepRecord> dayRecords = List<SleepRecord>.from(entry.value)
        ..sort((a, b) => a.start.compareTo(b.start));

      DateTime start = dayRecords.first.start;
      DateTime end = dayRecords.last.end;
      int totalMinutes = 0;

      for (final SleepRecord record in dayRecords) {
        if (record.start.isBefore(start)) start = record.start;
        if (record.end.isAfter(end)) end = record.end;
        totalMinutes += record.duration.inMinutes;
      }

      return SleepEntry(
        date: entry.key,
        start: start,
        end: end,
        totalMinutes: totalMinutes,
        records: dayRecords, // 👈 include this day’s full data
      );
    }).toList();

    entries.sort((a, b) => b.date.compareTo(a.date));
    if (limit > 0 && entries.length > limit) {
      return entries.take(limit).toList();
    }
    return entries;
  }

  static String exportToCsv(List<SleepEntry> entries) {
    final StringBuffer buffer = StringBuffer('Date,Start,End,Duration (hours)\n');
    for (final SleepEntry entry in entries) {
      buffer.writeln(
        '${entry.date.toIso8601String()},'
            '${entry.start.toIso8601String()},'
            '${entry.end.toIso8601String()},'
            '${entry.totalHours.toStringAsFixed(2)}',
      );
    }
    return buffer.toString();
  }
}
