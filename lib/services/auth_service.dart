import 'dart:async';
import 'dart:developer' as developer;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
as gsi;

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

  final StreamController<GoogleUserProfile?> _controller =
  StreamController<GoogleUserProfile?>.broadcast();

  GoogleUserProfile? _current;
  bool _initialized = false;

  Stream<GoogleUserProfile?> get onUserChanged => _controller.stream;
  GoogleUserProfile? get currentUser => _current;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final String serverClientId = kGoogleServerClientId.trim();

    if (serverClientId.isNotEmpty) {
      developer.log(
        '[DreamCatcher][Auth] init with serverClientId',
        name: 'AuthService',
      );
      await gsi.GoogleSignInPlatform.instance.init(
        gsi.InitParameters(
          serverClientId: serverClientId,
        ),
      );
    } else {
      developer.log(
        '[DreamCatcher][Auth] init without serverClientId',
        name: 'AuthService',
      );
      await gsi.GoogleSignInPlatform.instance.init(
        const gsi.InitParameters(),
      );
    }

    _initialized = true;
  }

  Future<GoogleUserProfile?> signIn() async {
    await _ensureInitialized();

    try {
      developer.log('[DreamCatcher][Auth] signIn start', name: 'AuthService');

      final gsi.AuthenticationResults result =
      await gsi.GoogleSignInPlatform.instance.authenticate(
        const gsi.AuthenticateParameters(),
      );

      final GoogleUserProfile? user = _setUser(result.user);

      developer.log(
        '[DreamCatcher][Auth] signIn success: ${user?.email}',
        name: 'AuthService',
      );

      return user;
    } catch (e, st) {
      developer.log(
        '[DreamCatcher][Auth] signIn failed: $e',
        name: 'AuthService',
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<GoogleUserProfile?> signInSilently() async {
    await _ensureInitialized();

    try {
      developer.log(
        '[DreamCatcher][Auth] signInSilently start',
        name: 'AuthService',
      );

      final gsi.AuthenticationResults? result =
      await gsi.GoogleSignInPlatform.instance
          .attemptLightweightAuthentication(
        const gsi.AttemptLightweightAuthenticationParameters(),
      );

      final GoogleUserProfile? user = _setUser(result?.user);

      developer.log(
        '[DreamCatcher][Auth] signInSilently result: ${user?.email}',
        name: 'AuthService',
      );

      return user;
    } catch (e, st) {
      developer.log(
        '[DreamCatcher][Auth] signInSilently failed: $e',
        name: 'AuthService',
        stackTrace: st,
      );
      return null;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();

    try {
      developer.log('[DreamCatcher][Auth] signOut start', name: 'AuthService');
      await gsi.GoogleSignInPlatform.instance
          .disconnect(const gsi.DisconnectParams());
    } catch (e, st) {
      developer.log(
        '[DreamCatcher][Auth] signOut disconnect failed: $e',
        name: 'AuthService',
        stackTrace: st,
      );
    } finally {
      _setUser(null);
    }
  }

  GoogleUserProfile? _setUser(gsi.GoogleSignInUserData? user) {
    if (user == null) {
      _current = null;
      _controller.add(null);
      return null;
    }

    final GoogleUserProfile mapped = GoogleUserProfile(
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
