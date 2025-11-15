import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Keys for SharedPreferences
  static const String _isGuestKey = 'is_guest_mode';
  static const String _isFirstLaunchKey = 'is_first_launch';

  // Get current user
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      // Firebase not initialized yet
      return null;
    }
  }

  // Check if logged in (Firebase auth)
  bool get isLoggedIn => currentUser != null;
  
  // Check if in guest mode
  Future<bool> get isGuestMode async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isGuestKey) ?? false;
  }
  
  // Check if first launch
  Future<bool> get isFirstLaunch async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }
  
  // Get current user mode: 'first_launch', 'guest', 'logged_in'
  Future<String> get userMode async {
    // Priority 1: Firebase authenticated user (highest priority)
    if (isLoggedIn) return 'logged_in';
    // Priority 2: Guest mode
    if (await isGuestMode) return 'guest';
    // Priority 3: First launch
    if (await isFirstLaunch) return 'first_launch';
    return 'first_launch'; // fallback
  }

  // Get current user email
  String? get userEmail {
    try {
      return currentUser?.email;
    } catch (e) {
      return null;
    }
  }
  
  // Get current user ID (Firebase UID or guest identifier)
  Future<String> get userId async {
    if (isLoggedIn) {
      return currentUser!.uid;
    } else if (await isGuestMode) {
      return 'guest_user';
    }
    return 'initial_user';
  }

  // Set guest mode
  Future<void> setGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, true);
    await prefs.setBool(_isFirstLaunchKey, false);
  }
  
  // Mark first launch as completed
  Future<void> markFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
  }

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
      // Auto clear guest mode when registration succeeds
      await upgradeFromGuest();
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
      // Auto clear guest mode when login succeeds
      await upgradeFromGuest();
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
    // Clear guest mode when logging out
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, false);
  }
  
  // Switch from guest to registered user
  Future<void> upgradeFromGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, false);
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

  // Debug method to check auth state
  Future<Map<String, dynamic>> getAuthDebugInfo() async {
    return {
      'currentUser': currentUser?.uid ?? 'null',
      'userEmail': userEmail ?? 'null',
      'isLoggedIn': isLoggedIn,
      'isGuestMode': await isGuestMode,
      'isFirstLaunch': await isFirstLaunch,
      'userMode': await userMode,
      'userId': await userId,
    };
  }

  // Force clear all auth flags (for testing)
  Future<void> clearAuthFlags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, false);
    await prefs.setBool(_isFirstLaunchKey, false);
  }
}