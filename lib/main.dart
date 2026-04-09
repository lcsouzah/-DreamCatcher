import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/wallet_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_keys.dart';
import 'services/supabase_initializer.dart';
import 'themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  developer.log('[DreamCatcher][Main] App starting...', name: 'Main');

  try {
    // 1. Load environment variables
    await dotenv.load(fileName: ".env").catchError((e) {
      developer.log('[DreamCatcher][Main] .env file not found: $e', name: 'Main');
    });

    // 2. Initialize Supabase
    await SupabaseInitializer.initialize();

    // 3. Initialize Auth (Silent sign-in)
    // We bypassed Firebase to focus on a stable demo with pure Google Sign-In.
    final authService = AuthService();
    await authService.signInSilently();
    developer.log('[DreamCatcher][Main] Auth initialized', name: 'Main');

  } catch (e, st) {
    developer.log('[DreamCatcher][Main] Critical initialization error: $e', name: 'Main', stackTrace: st);
  }

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
      theme: AppTheme.dreamTheme,
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
