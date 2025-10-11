import 'dart:math';

import '../models/sleep_record.dart';

class MockSleepService {
  const MockSleepService._();

  static List<SleepRecord> generateMockData({int days = 7}) {
    final Random random = Random();
    final List<SleepRecord> records = <SleepRecord>[];
    final DateTime today = DateTime.now();

    for (int i = 0; i < days; i++) {
      final DateTime day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      final double startOffsetHours = 3 + random.nextDouble() * 2; // 21:00-23:00
      DateTime cursor =
      day.subtract(Duration(minutes: (startOffsetHours * 60).round()));

      final Duration lightDuration =
      Duration(minutes: 90 + random.nextInt(30)); // 90-119 minutes
      final Duration deepDuration =
      Duration(minutes: 70 + random.nextInt(40));
      final Duration remDuration =
      Duration(minutes: 80 + random.nextInt(30));
      final Duration awakeDuration =
      Duration(minutes: 5 + random.nextInt(15));

      records.add(
        SleepRecord(
          start: cursor,
          end: cursor.add(lightDuration),
          source: 'Mock Data',
          type: 'light',
        ),
      );
      cursor = cursor.add(lightDuration);

      records.add(
        SleepRecord(
          start: cursor,
          end: cursor.add(deepDuration),
          source: 'Mock Data',
          type: 'deep',
        ),
      );
      cursor = cursor.add(deepDuration);

      records.add(
        SleepRecord(
          start: cursor,
          end: cursor.add(remDuration),
          source: 'Mock Data',
          type: 'rem',
        ),
      );
      cursor = cursor.add(remDuration);

      records.add(
        SleepRecord(
          start: cursor,
          end: cursor.add(awakeDuration),
          source: 'Mock Data',
          type: 'awake',
        ),
      );
    }

    records.sort((SleepRecord a, SleepRecord b) => b.start.compareTo(a.start));
    return records;
  }
}