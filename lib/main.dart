import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const DreamCatcherApp());
}

class DreamCatcherApp extends StatelessWidget {
  const DreamCatcherApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DreamCatcher',
      theme: ThemeData.dark(), // replace with your custom theme later
      home: const PageControllerView(),
      );
  }
}


class PageControllerView extends StatelessWidget {
  const PageControllerView({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView(
      children: [
        HomeScreen(),
        HistoryScreen(),
        WalletScreen(),
        SettingsScreen(),
      ],
    );
  }
}
