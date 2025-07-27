import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/screens/home_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: Column(
            children: const [
              SizedBox(height: 20),
              Text(
                'Home',
                style: TextStyle(color: Colors.white, fontSize: 32),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
