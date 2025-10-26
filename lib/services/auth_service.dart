import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

class GoogleUserProfile {
  GoogleUserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  final String id;
  final String? displayName;
  final String email;
  final String? photoUrl;
}

class AuthService {
  AuthService({
    GoogleSignInPlatform? googleSignInPlatform,
    GoogleSignInController? controller,
  })  : _controllerFuture = controller != null
      ? Future<GoogleSignInController>.value(controller)
      : (googleSignInPlatform ?? GoogleSignInPlatform.instance)
      .initWithParams(const GoogleSignInInitParams(
    scopes: <String>[
      'email',
      // optional: add Google Fit scope for sleep syncing
      'https://www.googleapis.com/auth/fitness.sleep.read',
    ],
  ));

  final Future<GoogleSignInController> _controllerFuture;
  StreamController<GoogleUserProfile?>? _userChangeController;
  StreamSubscription<GoogleSignInUserData?>? _userChangeSubscription;

  /// Provides the underlying controller once initialised.
  Future<GoogleSignInController> get _controller async => _controllerFuture;

  /// The currently signed-in user, or null if not signed in.
  Future<GoogleUserProfile?> get currentUser async {
    final GoogleSignInController controller = await _controller;
    return _mapUser(controller.currentUser);
  }

  /// Stream that notifies when the signed-in user changes.
  Stream<GoogleUserProfile?> get onAuthStateChanged {
    if (_userChangeController != null) {
      return _userChangeController!.stream;
    }

    final StreamController<GoogleUserProfile?> controller =
    StreamController<GoogleUserProfile?>.broadcast(
      onListen: () {
        unawaited(_controller.then((GoogleSignInController signInController) {
          controller.add(_mapUser(signInController.currentUser));
          _userChangeSubscription =
              signInController.onCurrentUserChanged.listen(
                    (GoogleSignInUserData? user) {
                  controller.add(_mapUser(user));
                },
                onError: controller.addError,
              );
        }));
      },
      onCancel: () {
        final Future<void>? cancellation = _userChangeSubscription?.cancel();
        _userChangeSubscription = null;
        if (cancellation != null) {
          unawaited(cancellation);
        }
      },
    );

    _userChangeController = controller;
    return controller.stream;
  }

  /// Signs the user in with Google.
  Future<GoogleUserProfile?> signInWithGoogle() async {
    try {
      final GoogleSignInController controller = await _controller;
      final GoogleSignInUserData? account = await controller.signIn();
      return _mapUser(account);
    } catch (e) {
      print('[AuthService] Google sign-in failed: $e');
      return null;
    }
  }

  /// Attempts silent sign-in without showing UI.
  Future<GoogleUserProfile?> signInSilently() async {
    try {
      final GoogleSignInController controller = await _controller;
      final GoogleSignInUserData? account = await controller.signInSilently();
      return _mapUser(account);
    } catch (e) {
      print('[AuthService] Silent sign-in failed: $e');
      return null;
    }
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    try {
      final GoogleSignInController controller = await _controller;
      await controller.signOut();
      print('[AuthService] User signed out.');
    } catch (e) {
      print('[AuthService] Sign-out failed: $e');
    }
  }

  GoogleUserProfile? _mapUser(GoogleSignInUserData? account) {
    if (account == null) return null;

    return GoogleUserProfile(
      id: account.id,
      displayName: account.displayName,
      email: account.email,
      photoUrl: account.photoUrl,
    );
  }
}