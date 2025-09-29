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
      : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final GoogleSignIn _googleSignIn;

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Stream<GoogleSignInAccount?> get onAuthStateChanged =>
      _googleSignIn.onCurrentUserChanged;

  Future<GoogleUserProfile?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      return null;
    }

    return GoogleUserProfile(
      id: account.id,
      displayName: account.displayName,
      email: account.email,
      photoUrl: account.photoUrl,
    );
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
