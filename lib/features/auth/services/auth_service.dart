import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // We create a private instance of FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. A Stream that listens to user login/logout changes in real-time
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 2. Get the currently logged-in user
  User? get currentUser => _auth.currentUser;

  // 3. Sign In with Email & Password
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // In production, we throw clean error messages back to the UI
      throw Exception(_handleAuthError(e.code));
    }
  }

  // 4. Register a new user
  Future<UserCredential> register(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code));
    }
  }

  // 5. Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 6. Delete Account
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // NOTE: In production, ensure the "Delete User Data" Firebase Extension
        // is installed in your Firebase Console to wipe their Firestore data!
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      // Handle the specific security error for old login tokens
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'For security reasons, please log out and log back in before deleting your account.',
        );
      }
      throw Exception(_handleAuthError(e.code));
    }
  }

  // Helper method to translate ugly Firebase error codes into human-readable text
  String _handleAuthError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'An unknown error occurred. Please try again.';
    }
  }
}
