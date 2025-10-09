import 'themes/app_theme.dart';


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/wallet_screen.dart';
import 'services/storage_keys.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool hasCompletedOnboarding =
      prefs.getBool(StorageKeys.onboardingComplete) ?? false;

  runApp(DreamCatcherApp(showOnboarding: !hasCompletedOnboarding));
}

class DreamCatcherApp extends StatefulWidget {
  const DreamCatcherApp({super.key, required this.showOnboarding});

  final bool showOnboarding;

  @override
  State<DreamCatcherApp> createState() => _DreamCatcherAppState();
}

class _DreamCatcherAppState extends State<DreamCatcherApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  void _handleOnboardingFinished() {
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DreamCatcher',
      theme: AppTheme.dreamTheme, // replace with your custom theme later
      home: _showOnboarding
          ? OnboardingScreen(onFinished: _handleOnboardingFinished)
          : const PageControllerView(),
    );
  }
}

class PageControllerView extends StatelessWidget {
  const PageControllerView({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView(
      children: const <Widget> [
        HomeScreen(),
        HistoryScreen(),
        WalletScreen(),
        SettingsScreen(),
      ],
    );
  }
}
