import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/health_connect_service.dart';
import '../services/storage_keys.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final AuthService _authService = AuthService();
  final HealthConnectService _healthService = HealthConnectService();

  bool _isLoading = false;
  bool _isConnectingHealth = false;
  bool _healthConnected = false;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialHealthStatus();
    // Listen for session changes to detect when the user returns from the browser
    _authStateSubscription = _authService.onAuthStateChange.listen((data) async {
      final Session? session = data.session;
      if (session != null && mounted) {
        developer.log('[DreamCatcher][UI] Supabase Session Acquired: ${session.user.email}', name: 'Onboarding');
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _checkInitialHealthStatus() async {
    final has = await _healthService.hasPermissions();
    if (mounted) {
      setState(() => _healthConnected = has);
    }
  }

  Future<void> _connectHealth() async {
    setState(() {
      _isConnectingHealth = true;
      _errorMessage = null;
    });

    try {
      if (!await _healthService.isAvailable()) {
        await _healthService.openHealthConnectSettings();
        if (mounted) setState(() => _isConnectingHealth = false);
        return;
      }

      final granted = await _healthService.requestPermissions();
      if (mounted) {
        setState(() {
          _isConnectingHealth = false;
          _healthConnected = granted;
          if (!granted) {
            _errorMessage = "Health permission is required to track sleep rewards.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnectingHealth = false;
          _errorMessage = "Error connecting to Health Connect: $e";
        });
      }
    }
  }

  Future<void> _finishOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.onboardingComplete, true);
    if (!mounted) return;
    widget.onFinished();
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
                          'To get started:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 16),
                        _OnboardingBullet(
                          icon: Icons.lock_outline,
                          text: 'Optionally connect Google for account sync and rewards profile.',
                        ),
                        SizedBox(height: 12),
                        _OnboardingBullet(
                          icon: Icons.health_and_safety_outlined,
                          text: 'Read last night\'s sleep from Health Connect to calculate rewards.',
                        ),
                        SizedBox(height: 12),
                        _OnboardingBullet(
                          icon: Icons.notifications_active_outlined,
                          text: 'Send friendly nudges if permissions are turned off later.',
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
                    icon: Icon(
                      _healthConnected ? Icons.check_circle : Icons.favorite,
                      color: Colors.white,
                    ),
                    label: Text(_healthConnected ? "Health Connected" : "Connect Health Data"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _healthConnected ? Colors.green : const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isConnectingHealth || _healthConnected ? null : _connectHealth,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.account_circle, color: Colors.white),
                    label: const Text("Sign in with Google (Optional)"),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            _errorMessage = null;
                            try {
                              await _authService.signInWithGoogle();
                            } catch (error) {
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || _isConnectingHealth ? null : _finishOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Health Connect sleep permission is requested separately. Google login is optional.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
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
        Icon(icon, color: Colors.lightBlueAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
