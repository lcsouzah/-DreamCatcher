import 'package:flutter/material.dart';

import '../services/wallet_service.dart';
import '../widgets/card.dart';
import '../widgets/primary_button.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();

  WalletSnapshot? _snapshot;
  bool _isLoading = false;
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final WalletSnapshot snapshot = await _walletService.fetchWalletSnapshot();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('[DreamCatcher] ⚠️ Failed to load wallet: $error');
      if (!mounted) return;
      setState(() {
        _snapshot = null;
        _isLoading = false;
      });
    }
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
    final bool isConnected = snapshot?.isWalletConnected ?? false;

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
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Balance',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${snapshot.totalDream.toStringAsFixed(2)} DREAM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '≈ \$${_walletService.convertDreamToUsd(snapshot.totalDream).toStringAsFixed(2)} USD',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Claimable: ${snapshot.claimableDream.toStringAsFixed(2)} DREAM',
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
                      const SizedBox(height: 20),
                      if (!isConnected)
                        PrimaryButton(
                          label: 'Connect wallet',
                          onPressed: _isProcessingAction
                              ? null
                              : _connectWallet,
                          isLoading: _isProcessingAction,
                        )
                      else
                        PrimaryButton(
                          label: snapshot.claimableDream > 0
                              ? 'Claim rewards'
                              : 'Wallet connected',
                          onPressed: snapshot.claimableDream > 0 &&
                              !_isProcessingAction
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