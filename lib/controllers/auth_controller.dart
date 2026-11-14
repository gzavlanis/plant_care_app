// lib/controllers/auth_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// \u03a0\u03b1\u03c1\u03b1\u03ba\u03bf\u03bb\u03bf\u03c5\u03b8\u03b5\u03af \u03b6\u03c9\u03bd\u03c4\u03b1\u03bd\u03ac \u03c4\u03b7\u03bd \u03ba\u03b1\u03c4\u03ac\u03c3\u03c4\u03b1\u03c3\u03b7 \u03c3\u03cd\u03bd\u03b4\u03b5\u03c3\u03b7\u03c2 \u03c4\u03bf\u03c5 \u03c7\u03c1\u03ae\u03c3\u03c4\u03b7
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  /// \u0395\u03be\u03b1\u03c3\u03c6\u03b1\u03bb\u03af\u03b6\u03b5\u03b9 \u03cc\u03c4\u03b9 \u03c5\u03c0\u03ac\u03c1\u03c7\u03b5\u03b9 \u03c0\u03ac\u03bd\u03c4\u03b1 \u03b5\u03bd\u03b5\u03c1\u03b3\u03cc\u03c2 \u03c7\u03c1\u03ae\u03c3\u03c4\u03b7\u03c2 (Guest-first)
  Future<User> ensureSignedIn() async {
    if (_auth.currentUser != null) {
      return _auth.currentUser!;
    }
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  /// \u0394\u03b7\u03bc\u03b9\u03bf\u03c5\u03c1\u03b3\u03af\u03b1 \u03bb\u03bf\u03b3\u03b1\u03c1\u03b9\u03b1\u03c3\u03bc\u03bf\u03cd: \u03a3\u03c5\u03bd\u03b4\u03ad\u03b5\u03b9 \u03c4\u03bf\u03bd \u03c5\u03c0\u03ac\u03c1\u03c7\u03bf\u03bd\u03c4\u03b1 Guest \u03bb\u03bf\u03b3\u03b1\u03c1\u03b9\u03b1\u03c3\u03bc\u03cc \u03bc\u03b5 Email/Password
  /// \u03ce\u03c3\u03c4\u03b5 \u03bd\u03b1 \u03b4\u03b9\u03b1\u03c4\u03b7\u03c1\u03b7\u03b8\u03bf\u03cd\u03bd \u03cc\u03bb\u03b1 \u03c4\u03b1 \u03c6\u03c5\u03c4\u03ac \u03c0\u03bf\u03c5 \u03ae\u03b4\u03b7 \u03ad\u03c7\u03b5\u03b9 \u03c0\u03c1\u03bf\u03c3\u03b8\u03ad\u03c3\u03b5\u03b9!
  Future<void> upgradeGuestToEmail({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );

    if (user != null && user.isAnonymous) {
      await user.linkWithCredential(credential);
    } else {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    }
  }

  /// \u03a3\u03cd\u03bd\u03b4\u03b5\u03c3\u03b7 \u03c3\u03b5 \u03c5\u03c0\u03ac\u03c1\u03c7\u03bf\u03bd\u03c4\u03b1 \u03bb\u03bf\u03b3\u03b1\u03c1\u03b9\u03b1\u03c3\u03bc\u03cc
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// \u0395\u03c0\u03b1\u03bd\u03b1\u03c6\u03bf\u03c1\u03ac \u03ba\u03c9\u03b4\u03b9\u03ba\u03bf\u03cd \u03c0\u03c1\u03cc\u03c3\u03b2\u03b1\u03c3\u03b7\u03c2
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// \u0391\u03c0\u03bf\u03c3\u03cd\u03bd\u03b4\u03b5\u03c3\u03b7 \u03ba\u03b1\u03b9 \u03ac\u03bc\u03b5\u03c3\u03b7 \u03bc\u03b5\u03c4\u03ac\u03b2\u03b1\u03c3\u03b7 \u03c3\u03b5 \u03bd\u03ad\u03bf Guest session
  Future<void> signOut() async {
    await _auth.signOut();
    await _auth.signInAnonymously();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());