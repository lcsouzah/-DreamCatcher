import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/storage_keys.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for session changes to detect when the user returns from the browser
    _authStateSubscription = _authService.onAuthStateChange.listen((data) async {
      final Session? session = data.session;
      if (session != null && mounted) {
        developer.log('[DreamCatcher][UI] Supabase Session Acquired: ${session.user.email}', name: 'Onboarding');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(StorageKeys.onboardingComplete, true);

        if (!mounted) return;
        setState(() => _isLoading = false);
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1447), Color(0xFF2C1E5D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 24),
                const Text(
                  'Welcome to DreamCatcher',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontFamily: 'DreamFont',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Turn every night of quality sleep into DREAM rewards.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  color: Colors.white.withOpacity(0.08),
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'To get started we need to:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 16),
                        _OnboardingBullet(
                          icon: Icons.lock_outline,
                          text:
                          'Connect your Google account so we can create your DreamCatcher wallet.',
                        ),
                        SizedBox(height: 12),
                        _OnboardingBullet(
                          icon: Icons.health_and_safety_outlined,
                          text:
                          'Read last night\'s sleep from Health Connect to calculate rewards.',
                        ),
                        SizedBox(height: 12),
                        _OnboardingBullet(
                          icon: Icons.notifications_active_outlined,
                          text:
                          'Send friendly nudges if permissions are turned off later.',
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (_errorMessage != null) ...<Widget>[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.favorite, color: Colors.white),
                    label: const Text("Continue with Google"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                      setState(() => _isLoading = true);
                      _errorMessage = null;

                      developer.log('[DreamCatcher][UI] Initiating Google Sign-In via Supabase', name: 'Onboarding');

                      try {
                        await _authService.signInWithGoogle();
                      } catch (error) {
                        developer.log('[DreamCatcher][UI] Login Initiation Error: $error', name: 'Onboarding');
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                            _errorMessage = error.toString();
                          });
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'We only track your sleep duration to issue rewards. You can revoke access any time in system settings.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingBullet extends StatelessWidget {
  const _OnboardingBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: Colors.lightBlueAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
