import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/reward_service.dart';
import '../services/wallet_service.dart';
import '../themes/app_theme.dart';
import '../widgets/card.dart';
import '../widgets/primary_button.dart';

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
        gradientKey: _StreakGradientTone.legendary,
        label: 'Legendary focus',
      );
    }
    if (streak >= 7) {
      return const _StreakBadgeStyle(
        icon: Icons.local_fire_department,
        gradientKey: _StreakGradientTone.hotStreak,
        label: 'On a hot streak',
      );
    }
    if (streak >= 3) {
      return const _StreakBadgeStyle(
        icon: Icons.nightlight_round,
        gradientKey: _StreakGradientTone.findingRhythm,
        label: 'Finding rhythm',
      );
    }
    return const _StreakBadgeStyle(
      icon: Icons.bedtime,
      gradientKey: _StreakGradientTone.keepGoing,
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
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colors = theme.colorScheme;
    final DreamGradients gradients =
        theme.extension<DreamGradients>() ?? DreamGradients.fallback;
    final WalletSnapshot? snapshot = _snapshot;
    final bool hasMultiplier = _streakMultiplier != null && _streakBadgeStyle != null;
    final bool hasLoadedData =
        !_isLoading && snapshot != null && _rewardSnapshot != null && hasMultiplier;
    final bool isConnected = snapshot?.isWalletConnected ?? false;
    final double claimableAmount = snapshot?.claimableDream ?? 0;
    final bool canClaim = hasLoadedData && claimableAmount > 0;
    VoidCallback? primaryAction;

    if (!isConnected) {
      if (hasLoadedData && !_isProcessingAction) {
        primaryAction = _connectWallet;
      }
    } else if (canClaim && !_isProcessingAction) {
      primaryAction = _claimRewards;
    }

    final String primaryLabel = !isConnected
        ? 'Connect Wallet'
        : canClaim
        ? 'Claim Reward'
        : 'Wallet Connected';

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradients.wallet),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Wallet', style: textTheme.displaySmall),
              const SizedBox(height: 24),
              DreamCard(
                child: _isLoading
                    ? Center(
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(colors.onPrimary),
                    ),
                  ),
                )
                    : snapshot == null
                    ? Text(
                  'Unable to load wallet. Please try again shortly.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Balance', style: textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                '${snapshot.totalDream.toStringAsFixed(2)} DREAM',
                                style: textTheme.headlineSmall?.copyWith(
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '≈ \$${_walletService.convertDreamToUsd(snapshot.totalDream).toStringAsFixed(2)} USD',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
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
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (snapshot.lastClaimed != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        'Last claim: ${_formatLastClaimed(snapshot.lastClaimed!)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: primaryLabel,
                      onPressed: primaryAction,
                      isLoading: _isProcessingAction,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildStreakBadge(ThemeData theme) {
    final _StreakBadgeStyle? style = _streakBadgeStyle;
    final double? multiplier = _streakMultiplier;
    final int nights = _sleepStreak ?? 0;
    if (style == null || multiplier == null) {
      return const SizedBox.shrink();
    }

    final DreamGradients gradients =
        theme.extension<DreamGradients>() ?? DreamGradients.fallback;
    final DreamCardTheme cardTheme =
        theme.extension<DreamCardTheme>() ?? DreamCardTheme.fallback;
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colors = theme.colorScheme;

    LinearGradient badgeGradient;
    switch (style.gradientKey) {
      case _StreakGradientTone.legendary:
        badgeGradient = gradients.badgeLegendary;
        break;
      case _StreakGradientTone.hotStreak:
        badgeGradient = gradients.badgeHotStreak;
        break;
      case _StreakGradientTone.findingRhythm:
        badgeGradient = gradients.badgeFindingRhythm;
        break;
      case _StreakGradientTone.keepGoing:
      default:
        badgeGradient = gradients.badgeKeepGoing;
        break;
    }

    final String nightsLabel = nights == 1 ? '1 night streak' : '$nights night streak';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: cardTheme.blurSigma,
          sigmaY: cardTheme.blurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: badgeGradient,
            border: Border.all(color: cardTheme.borderColor.withOpacity(0.9)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: cardTheme.overlayColor,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(style.icon, color: colors.onPrimary, size: 24),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${multiplier.toStringAsFixed(1)}x',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      style.label,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nightsLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onPrimary.withOpacity(0.7),
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
    required this.gradientKey,
    required this.label,
  });

  final IconData icon;
  final _StreakGradientTone gradientKey;
  final String label;
}

enum _StreakGradientTone { keepGoing, findingRhythm, hotStreak, legendary }