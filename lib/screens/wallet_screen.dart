import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/reward_service.dart';
import '../services/wallet_service.dart';
import '../widgets/card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  final RewardService _rewardService = RewardService();

  WalletSnapshot? _snapshot;
  RewardSnapshot? _rewardSnapshot;
  bool _isLoading = false;
  bool _isProcessingAction = false;
  double? _streakMultiplier;
  int? _sleepStreak;
  _StreakBadgeStyle? _streakBadgeStyle;
  StreamSubscription<int>? _streakSubscription;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  @override
  void dispose() {
    _streakSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<dynamic> results = await Future.wait(<Future<dynamic>>[
        _walletService.fetchWalletSnapshot(),
        _rewardService.fetchRewardSnapshot(),
      ]);
      final WalletSnapshot walletSnapshot = results[0] as WalletSnapshot;
      final RewardSnapshot rewardSnapshot = results[1] as RewardSnapshot;
      if (!mounted) return;

      _applyStreak(rewardSnapshot.sleepStreak);
      _subscribeToStreak();

      setState(() {
        _snapshot = walletSnapshot;
        _rewardSnapshot = rewardSnapshot;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('[DreamCatcher] ⚠️ Failed to load wallet: $error');
      if (!mounted) return;
      setState(() {
        _snapshot = null;
        _rewardSnapshot = null;
        _streakMultiplier = null;
        _sleepStreak = null;
        _streakBadgeStyle = null;
        _isLoading = false;
      });
    }
  }

  void _subscribeToStreak() {
    _streakSubscription?.cancel();
    _streakSubscription = _rewardService.watchSleepStreak().listen((int streak) {
      if (!mounted) return;
      _applyStreak(streak);
    });
  }

  void _applyStreak(int streak) {
    final double multiplier = _calculateMultiplier(streak);
    final _StreakBadgeStyle badgeStyle = _resolveBadgeStyle(streak);
    setState(() {
      _streakMultiplier = multiplier;
      _sleepStreak = streak;
      _streakBadgeStyle = badgeStyle;
    });
  }

  double _calculateMultiplier(int streak) {
    if (streak <= 0) {
      return 1.0;
    }
    double clamped = 1 + (streak / 5);
    if (clamped < 1.0) {
      clamped = 1.0;
    } else if (clamped > 3.0) {
      clamped = 3.0;
    }
    return double.parse(clamped.toStringAsFixed(2));
  }

  _StreakBadgeStyle _resolveBadgeStyle(int streak) {
    if (streak >= 12) {
      return const _StreakBadgeStyle(
        icon: Icons.auto_awesome,
        gradient: <Color>[Color(0xFFFF8A80), Color(0xFFFF5F6D)],
        label: 'Legendary focus',
      );
    }
    if (streak >= 7) {
      return const _StreakBadgeStyle(
        icon: Icons.local_fire_department,
        gradient: <Color>[Color(0xFFFFD180), Color(0xFFFF8F00)],
        label: 'On a hot streak',
      );
    }
    if (streak >= 3) {
      return const _StreakBadgeStyle(
        icon: Icons.nightlight_round,
        gradient: <Color>[Color(0xFF80DEEA), Color(0xFF5E72EB)],
        label: 'Finding rhythm',
      );
    }
    return const _StreakBadgeStyle(
      icon: Icons.bedtime,
      gradient: <Color>[Color(0xFF7B61FF), Color(0xFF4E54C8)],
      label: 'Keep it going',
    );
  }

  Future<void> _connectWallet() async {
    setState(() {
      _isProcessingAction = true;
    });
    final WalletSnapshot snapshot = await _walletService.connectWallet();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _isProcessingAction = false;
    });
  }

  Future<void> _claimRewards() async {
    setState(() {
      _isProcessingAction = true;
    });
    final WalletSnapshot snapshot = await _walletService.claimRewards();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _isProcessingAction = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WalletSnapshot? snapshot = _snapshot;
    final bool hasMultiplier = _streakMultiplier != null && _streakBadgeStyle != null;
    final bool hasLoadedData =
        !_isLoading && snapshot != null && _rewardSnapshot != null && hasMultiplier;
    final bool isConnected = snapshot?.isWalletConnected ?? false;
    final double claimableAmount = snapshot?.claimableDream ?? 0;
    final bool canClaim = hasLoadedData && claimableAmount > 0;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Image.asset(
            'assets/screens/wallet_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Wallet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                DreamCard(
                  child: _isLoading
                      ? const Center(
                    child: SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                      : snapshot == null
                      ? const Text(
                    'Unable to load wallet. Please try again shortly.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Balance',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${snapshot.totalDream.toStringAsFixed(2)} DREAM',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '≈ \$${_walletService.convertDreamToUsd(snapshot.totalDream).toStringAsFixed(2)} USD',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasMultiplier)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: _buildStreakBadge(theme),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Claimable: ${claimableAmount.toStringAsFixed(2)} DREAM',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      if (snapshot.lastClaimed != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          'Last claim: ${_formatLastClaimed(snapshot.lastClaimed!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (!isConnected)
                        _buildWalletActionButton(
                          label: 'Connect Wallet',
                          onPressed: hasLoadedData && !_isProcessingAction
                              ? _connectWallet
                              : null,
                          isLoading: _isProcessingAction,
                        )
                      else
                        _buildWalletActionButton(
                          label: canClaim ? 'Claim Reward' : 'Wallet Connected',
                          onPressed: canClaim && !_isProcessingAction
                              ? _claimRewards
                              : null,
                          isLoading: _isProcessingAction,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakBadge(ThemeData theme) {
    final _StreakBadgeStyle? style = _streakBadgeStyle;
    final double? multiplier = _streakMultiplier;
    final int nights = _sleepStreak ?? 0;
    if (style == null || multiplier == null) {
      return const SizedBox.shrink();
    }

    final String nightsLabel = nights == 1 ? '1 night streak' : '$nights night streak';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: style.gradient,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.black.withOpacity(0.18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(style.icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${multiplier.toStringAsFixed(1)}x',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ) ??
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      style.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ) ??
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nightsLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ) ??
                          const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletActionButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    final bool isEnabled = onPressed != null && !isLoading;
    final Widget child = isLoading
        ? const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    )
        : Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.6,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
                gradient: isEnabled
                    ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF8C7BFF),
                    Color(0xFF6E8EF5),
                  ],
                )
                    : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Colors.white.withOpacity(0.18),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
              child: TextButton(
                onPressed: isEnabled ? onPressed : null,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatLastClaimed(DateTime dateTime) {
    final Duration difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 1) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
    if (difference.inHours >= 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
    return 'Just now';
  }
}

class _StreakBadgeStyle {
  const _StreakBadgeStyle({
    required this.icon,
    required this.gradient,
    required this.label,
  });

  final IconData icon;
  final List<Color> gradient;
  final String label;
}