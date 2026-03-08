// lib/services/auth_service.dart (platform-interface, v7+ compatible)
import 'dart:async';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart' as gsi;

import 'storage_keys.dart';

class GoogleUserProfile {
  const GoogleUserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
}

class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final _controller = StreamController<GoogleUserProfile?>.broadcast();
  GoogleUserProfile? _current;

  /// Emits the mapped profile or null when signed out.
  Stream<GoogleUserProfile?> get onUserChanged => _controller.stream;

  /// Current signed-in user (if any).
  GoogleUserProfile? get currentUser => _current;



  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await gsi.GoogleSignInPlatform.instance.init(
      const gsi.InitParameters(
        serverClientId: kGoogleFitClientId,
      ),
    );
    _initialized = true;
  }

  Future<GoogleUserProfile?> signIn() async {
    await _ensureInitialized();
    final gsi.AuthenticationResults result =
        await gsi.GoogleSignInPlatform.instance.authenticate(
      const gsi.AuthenticateParameters(),
    );
    return _setUser(result.user);
  }

  /// Attempts a lightweight sign-in first; falls back to full auth if needed.
  Future<GoogleUserProfile?> signInSilently() async {
    await _ensureInitialized();
    final gsi.AuthenticationResults? result =
        await gsi.GoogleSignInPlatform.instance.attemptLightweightAuthentication(
      const gsi.AttemptLightweightAuthenticationParameters(),
    );
    return _setUser(result?.user);
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await gsi.GoogleSignInPlatform.instance.disconnect(const gsi.DisconnectParams());
    _setUser(null);
  }

  GoogleUserProfile? _setUser(gsi.GoogleSignInUserData? user) {
    if (user == null) {
      _current = null;
      _controller.add(null);
      return null;
    }
    final mapped = GoogleUserProfile(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
    );
    _current = mapped;
    _controller.add(mapped);
    return mapped;
  }

  void dispose() {
    _controller.close();
  }
}
