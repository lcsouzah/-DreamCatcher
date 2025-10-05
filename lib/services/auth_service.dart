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
  AuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
      GoogleSignIn(
        scopes: const [
          'email',
          // optional: add Google Fit scope for sleep syncing
          'https://www.googleapis.com/auth/fitness.sleep.read',
        ],
      );

  final GoogleSignIn _googleSignIn;

  /// The currently signed-in user, or null if not signed in.
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Stream that notifies when the signed-in user changes.
  Stream<GoogleSignInAccount?> get onAuthStateChanged =>
      _googleSignIn.onCurrentUserChanged;

  /// Signs the user in with Google.
  Future<GoogleUserProfile?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      return GoogleUserProfile(
        id: account.id,
        displayName: account.displayName,
        email: account.email,
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      print('[AuthService] Google sign-in failed: $e');
      return null;
    }
  }

  /// Attempts silent sign-in without showing UI.
  Future<GoogleUserProfile?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return null;

      return GoogleUserProfile(
        id: account.id,
        displayName: account.displayName,
        email: account.email,
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      print('[AuthService] Silent sign-in failed: $e');
      return null;
    }
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('[AuthService] User signed out.');
    } catch (e) {
      print('[AuthService] Sign-out failed: $e');
    }
  }
}
