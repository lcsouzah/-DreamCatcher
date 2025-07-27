import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/screens/history_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: Column(
            children: const [
              SizedBox(height: 20),
              Text(
                'History',
                style: TextStyle(color: Colors.white, fontSize: 32),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
