import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/health_service.dart';
import '../services/storage_keys.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final AuthService _authService = AuthService();
  final HealthService _healthService = HealthService();

  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _handleContinue() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final profile = await _authService.signInWithGoogle();
      if (profile == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _errorMessage = 'Sign-in was cancelled. Please try again to continue.';
        });
        return;
      }

      if (!mounted) {
        return;
      }
      final permissionsGranted = await _healthService.requestPermissions();
      if (!permissionsGranted) {
        if (!mounted) {
          return;
        }
        setState(() {
          _errorMessage =
          'Health permissions are required so DreamCatcher can sync your sleep.';
        });
        return;
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.onboardingComplete, true);

      if (!mounted) {
        return;
      }
      widget.onFinished();
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.\n$error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
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
                  color: Colors.white10,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const <Widget>[
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
                          'Read last night\'s sleep from Google Fit to calculate rewards.',
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isProcessing ? null : _handleContinue,
                    icon: _isProcessing
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.login),
                    label: Text(
                      _isProcessing ? 'Connecting…' : 'Continue with Google',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
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