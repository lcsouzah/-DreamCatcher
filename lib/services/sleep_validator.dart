import 'package:dreamcatcher/models/sleep_entry.dart';

class ValidationResult {
  ValidationResult({required this.isEligible, this.reasons = const []});
  final bool isEligible;
  final List<String> reasons;
}

class SleepValidator {
  static const int minDurationMinutes = 120;
  static const int maxDurationMinutes = 900;
  static const int maxSessionsPerDay = 3;
  static const int overlapThresholdMinutes = 30;

  static ValidationResult validateSleepEntryForClaim(
      SleepEntry entry, List<SleepEntry> history) {
    final reasons = <String>[];

    // Check duration
    if (entry.totalMinutes < minDurationMinutes ||
        entry.totalMinutes > maxDurationMinutes) {
      reasons.add(
          'Duration out of range (${entry.totalMinutes} mins). Must be between $minDurationMinutes and $maxDurationMinutes mins.');
    }

    // Check for future dates
    final now = DateTime.now();
    if (entry.start.isAfter(now) || entry.end.isAfter(now)) {
      reasons.add('Session is in the future.');
    }

    // Check for duplicates
    final isDuplicate = history.any((historicalEntry) =>
        historicalEntry.start == entry.start && historicalEntry.end == entry.end);
    if (isDuplicate) {
      reasons.add('Duplicate session found.');
    }

    // Check for significant overlaps
    final hasOverlap = history.any((historicalEntry) {
      final overlap = entry.start.isBefore(historicalEntry.end) &&
          entry.end.isAfter(historicalEntry.start);
      if (overlap) {
        final overlapDuration = (entry.start.isBefore(historicalEntry.end)
                ? historicalEntry.end
                : entry.end)
            .difference(entry.start.isAfter(historicalEntry.start)
                ? entry.start
                : historicalEntry.start)
            .inMinutes;
        return overlapDuration > overlapThresholdMinutes;
      }
      return false;
    });

    if (hasOverlap) {
      reasons.add('Session overlaps with another by more than $overlapThresholdMinutes minutes.');
    }

    // Check for too many sessions in one day
    final sessionsOnDate =
        history.where((e) => e.date == entry.date).length;
    if (sessionsOnDate > maxSessionsPerDay) {
      reasons.add('Exceeds max of $maxSessionsPerDay sessions for this day.');
    }

    // No manual entry check. Assuming Health Connect is the only source.

    return ValidationResult(isEligible: reasons.isEmpty, reasons: reasons);
  }
}
