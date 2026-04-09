import 'dart:async';
import 'dart:developer' as developer;
import 'package:google_sign_in/google_sign_in.dart';
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

    const String serverClientId = '84818727473-dp55em8h0mfsjlsp63m4cqnrbuguuipc.apps.googleusercontent.com';

    developer.log('[DreamCatcher][Auth] Initializing GoogleSignIn (Bypass Firebase).', name: 'AuthService');

    await GoogleSignIn.instance.initialize(
      serverClientId: serverClientId,
    );

    GoogleSignIn.instance.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        _updateUser(event.user);
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
        _updateUser(null);
      }
    }, onError: (error) {
      developer.log('[DreamCatcher][Auth] Status stream error: $error', name: 'AuthService');
    });

    _initialized = true;
  }

  Future<GoogleUserProfile?> signIn() async {
    await _ensureInitialized();

    try {
      developer.log('[DreamCatcher][Auth] signIn start', name: 'AuthService');
      
      // Explicitly sign out first to ensure the account picker always appears for the demo
      await GoogleSignIn.instance.signOut().catchError((_) => null);
      
      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      final GoogleUserProfile? user = _updateUser(account);

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

      final Future<GoogleSignInAccount?>? attempt = GoogleSignIn.instance.attemptLightweightAuthentication();
      if (attempt == null) return null;

      final GoogleSignInAccount? account = await attempt;
      
      if (account != null) {
        return _updateUser(account);
      }

      return null;
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
      await GoogleSignIn.instance.disconnect().catchError((_) => null);
      await GoogleSignIn.instance.signOut();
    } catch (e, st) {
      developer.log(
        '[DreamCatcher][Auth] signOut failed: $e',
        name: 'AuthService',
        stackTrace: st,
      );
    } finally {
      _updateUser(null);
    }
  }

  GoogleUserProfile? _updateUser(GoogleSignInAccount? account) {
    if (account == null) {
      _current = null;
      _controller.add(null);
      return null;
    }

    final GoogleUserProfile mapped = GoogleUserProfile(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );

    _current = mapped;
    _controller.add(mapped);
    return mapped;
  }

  void dispose() {
    _controller.close();
  }
}
