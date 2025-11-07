import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if logged in
  bool get isLoggedIn => currentUser != null;

  // Get current user email
  String? get userEmail => currentUser?.email;

  // Register with email & password
  Future<UserCredential?> register({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle errors
      if (e.code == 'weak-password') {
        throw 'Password is too weak (minimum 6 characters)';
      } else if (e.code == 'email-already-in-use') {
        throw 'Email already exists';
      } else if (e.code == 'invalid-email') {
        throw 'Invalid email format';
      } else {
        throw e.message ?? 'Registration failed';
      }
    } catch (e) {
      throw 'Registration failed: $e';
    }
  }

  // Login with email & password
  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        throw 'Wrong password';
      } else if (e.code == 'invalid-email') {
        throw 'Invalid email format';
      } else {
        throw e.message ?? 'Login failed';
      }
    } catch (e) {
      throw 'Login failed: $e';
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw 'Invalid email format';
      } else if (e.code == 'user-not-found') {
        throw 'No user found with this email';
      } else {
        throw e.message ?? 'Failed to send reset email';
      }
    } catch (e) {
      throw 'Failed to send reset email: $e';
    }
  }
}