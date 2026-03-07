import 'dart:async';

import 'package:dreamcatcher/models/sleep_entry.dart';

enum RewardClaimStatus { pending, approved, rejected, paid }

class RewardClaimResult {
  RewardClaimResult(
      {required this.status, this.amount, this.reason, this.referenceId});
  final RewardClaimStatus status;
  final double? amount;
  final String? reason;
  final String? referenceId;
}

/// Simple data model representing the mock reward snapshot that the
/// application can render while the real backend is under development.
class RewardSnapshot {
  const RewardSnapshot({
    required this.totalDreamEarned,
    required this.weeklyDreamEarned,
    required this.pendingDream,
    required this.sleepStreak,
    required this.lastUpdated,
  });

  /// Lifetime earnings in the mock wallet.
  final double totalDreamEarned;

  /// Total rewards accumulated over the last seven days.
  final double weeklyDreamEarned;

  /// Rewards that are ready to be claimed.
  final double pendingDream;

  /// Current consecutive-day streak.
  final int sleepStreak;

  /// Timestamp the mock data was last refreshed.
  final DateTime lastUpdated;

  RewardSnapshot copyWith({
    double? totalDreamEarned,
    double? weeklyDreamEarned,
    double? pendingDream,
    int? sleepStreak,
    DateTime? lastUpdated,
  }) {
    return RewardSnapshot(
      totalDreamEarned: totalDreamEarned ?? this.totalDreamEarned,
      weeklyDreamEarned: weeklyDreamEarned ?? this.weeklyDreamEarned,
      pendingDream: pendingDream ?? this.pendingDream,
      sleepStreak: sleepStreak ?? this.sleepStreak,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Provides mocked reward computations for UI development.
class RewardService {
  RewardService();

  /// Temporary conversion rate used for displaying a fiat approximation.
  static const double dreamToUsdRate = 0.18;

  static RewardSnapshot _mockSnapshot = RewardSnapshot(
    totalDreamEarned: 245.30,
    weeklyDreamEarned: 32.40,
    pendingDream: 18.75,
    sleepStreak: 5,
    lastUpdated: DateTime.now(),
  );

  /// Returns the latest cached snapshot of mock data.
  RewardSnapshot get currentSnapshot => _mockSnapshot;

  /// Fetches the mock snapshot. In lieu of a backend we simply return a
  /// cached value after a slight delay to emulate network latency.
  Future<RewardSnapshot> fetchRewardSnapshot() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _mockSnapshot;
  }

  Future<RewardClaimResult> requestClaim(
      {required SleepEntry entry, required String walletAddress}) async {
    // Stubbed backend logic
    await Future.delayed(const Duration(seconds: 2));

    if (entry.validationResult?.isEligible == false) {
      return RewardClaimResult(
          status: RewardClaimStatus.rejected,
          reason: entry.validationResult?.reasons.first ?? 'Not eligible');
    }

    final double estimatedReward = await estimateDreamForSleep(entry.totalHours);

    _mockSnapshot = _mockSnapshot.copyWith(
      pendingDream: _mockSnapshot.pendingDream - estimatedReward,
      totalDreamEarned: _mockSnapshot.totalDreamEarned + estimatedReward,
      lastUpdated: DateTime.now(),
    );

    return RewardClaimResult(
        status: RewardClaimStatus.paid,
        amount: estimatedReward,
        referenceId: 'txn_${DateTime.now().millisecondsSinceEpoch}');
  }

  /// Estimates how many $DREAM a user could earn for the provided number of
  /// hours slept. The numbers are deliberately generous to keep morale high
  /// during development.
  Future<double> estimateDreamForSleep(double hoursSlept) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final double base = hoursSlept.clamp(0, 12) * 2.1;
    final double bonus = hoursSlept >= 7.5 ? 3.5 : 0;
    return double.parse((base + bonus).toStringAsFixed(2));
  }

  /// Provides a stream that can be listened to for streak updates. The stream
  /// currently emits the cached streak value and completes.
  Stream<int> watchSleepStreak() async* {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    yield _mockSnapshot.sleepStreak;
  }

  /// Converts $DREAM to a USD approximation using the static conversion rate.
  double convertDreamToUsd(double amount) {
    return double.parse((amount * dreamToUsdRate).toStringAsFixed(2));
  }

  /// Helper used by other mock services to simulate nightly earnings.
  Future<RewardSnapshot> simulateNightlyEarning(double hoursSlept) async {
    final double earned = await estimateDreamForSleep(hoursSlept);
    final RewardSnapshot updated = _mockSnapshot.copyWith(
      totalDreamEarned: _mockSnapshot.totalDreamEarned + earned,
      weeklyDreamEarned: (_mockSnapshot.weeklyDreamEarned + earned)
          .clamp(0, double.infinity),
      pendingDream: _mockSnapshot.pendingDream + earned,
      sleepStreak: hoursSlept >= 6 ? _mockSnapshot.sleepStreak + 1 : 0,
      lastUpdated: DateTime.now(),
    );
    _mockSnapshot = updated;
    return updated;
  }
}
