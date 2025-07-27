import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/screens/settings_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: Column(
            children: const [
              SizedBox(height: 20),
              Text(
                'Settings',
                style: TextStyle(color: Colors.white, fontSize: 32),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
