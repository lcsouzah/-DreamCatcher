import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/screens/wallet_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: Column(
            children: const [
              SizedBox(height: 20),
              Text(
                'Wallet',
                style: TextStyle(color: Colors.white, fontSize: 32),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
