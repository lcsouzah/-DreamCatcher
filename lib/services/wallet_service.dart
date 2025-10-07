import 'dart:async';

import 'reward_service.dart';

class WalletSnapshot {
  const WalletSnapshot({
    required this.totalDream,
    required this.claimableDream,
    required this.isWalletConnected,
    this.lastClaimed,
  });

  final double totalDream;
  final double claimableDream;
  final bool isWalletConnected;
  final DateTime? lastClaimed;

  WalletSnapshot copyWith({
    double? totalDream,
    double? claimableDream,
    bool? isWalletConnected,
    DateTime? lastClaimed,
  }) {
    return WalletSnapshot(
      totalDream: totalDream ?? this.totalDream,
      claimableDream: claimableDream ?? this.claimableDream,
      isWalletConnected: isWalletConnected ?? this.isWalletConnected,
      lastClaimed: lastClaimed ?? this.lastClaimed,
    );
  }
}

/// Provides a mock implementation of wallet interactions while the
/// blockchain integration is being built.
class WalletService {
  WalletService({RewardService? rewardService})
      : _rewardService = rewardService ?? RewardService();

  final RewardService _rewardService;

  static WalletSnapshot _mockSnapshot = WalletSnapshot(
    totalDream: 412.8,
    claimableDream: 46.2,
    isWalletConnected: false,
    lastClaimed: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
  );

  /// Returns the cached mock wallet state immediately.
  WalletSnapshot get currentSnapshot => _mockSnapshot;

  /// Fetches the wallet snapshot, simulating an RPC request.
  Future<WalletSnapshot> fetchWalletSnapshot() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _mockSnapshot;
  }

  /// Mimics connecting a wallet. Subsequent fetches will indicate the wallet
  /// is connected.
  Future<WalletSnapshot> connectWallet() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _mockSnapshot = _mockSnapshot.copyWith(isWalletConnected: true);
    return _mockSnapshot;
  }

  /// Claims the currently pending rewards. The mock simply moves the
  /// claimable amount to the balance and clears the pending bucket.
  Future<WalletSnapshot> claimRewards() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!_mockSnapshot.isWalletConnected || _mockSnapshot.claimableDream <= 0) {
      return _mockSnapshot;
    }

    _mockSnapshot = _mockSnapshot.copyWith(
      totalDream: _mockSnapshot.totalDream + _mockSnapshot.claimableDream,
      claimableDream: 0,
      lastClaimed: DateTime.now(),
    );
    return _mockSnapshot;
  }

  double convertDreamToUsd(double amount) {
    return _rewardService.convertDreamToUsd(amount);
  }
}