import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream of auth state changes from Supabase.
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  /// Returns the current user if a session exists.
  User? get currentUser => _supabase.auth.currentUser;

  /// Returns the current session.
  Session? get currentSession => _supabase.auth.currentSession;

  /// Starts the Google OAuth flow using Supabase.
  /// 
  /// This will open the system browser for the user to select their account.
  /// After completion, the user will be redirected back to the app via deep link.
  Future<void> signInWithGoogle() async {
    developer.log('[DreamCatcher][Auth] signInWithGoogle button pressed', name: 'AuthService');
    
    try {
      developer.log('[DreamCatcher][Auth] Starting OAuth redirect flow...', name: 'AuthService');
      
      // redirectTo must match the scheme configured in AndroidManifest.xml
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'dreamcatcher://login-callback',
      );
      
      developer.log('[DreamCatcher][Auth] OAuth flow initiated in browser', name: 'AuthService');
    } catch (e, st) {
      developer.log(
        '[DreamCatcher][Auth] OAuth redirect failed: $e',
        name: 'AuthService',
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Signs the user out of the current Supabase session.
  Future<void> signOut() async {
    developer.log('[DreamCatcher][Auth] Signing out...', name: 'AuthService');
    await _supabase.auth.signOut();
  }
}
