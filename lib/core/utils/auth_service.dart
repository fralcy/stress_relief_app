import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Keys for SharedPreferences
  static const String _isGuestKey = 'is_guest_mode';
  static const String _isDebugKey = 'is_debug_mode';
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

  // Check if in debug mode
  Future<bool> get isDebugMode async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isDebugKey) ?? false;
  }

  // Check if first launch
  Future<bool> get isFirstLaunch async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }
  
  // Get current user mode: 'first_launch', 'guest', 'logged_in', 'debug'
  Future<String> get userMode async {
    // Priority 1: Debug mode (highest priority - overrides all)
    if (await isDebugMode) return 'debug';
    // Priority 2: Firebase authenticated user
    if (isLoggedIn) return 'logged_in';
    // Priority 3: Guest mode
    if (await isGuestMode) return 'guest';
    // Priority 4: First launch
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
  
  // Get current user ID (Firebase UID, debug, guest, or initial identifier)
  Future<String> get userId async {
    if (isLoggedIn) {
      return currentUser!.uid;
    } else if (await isDebugMode) {
      return 'debug_user';
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

  // Set debug mode
  Future<void> setDebugMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDebugKey, true);
    await prefs.setBool(_isFirstLaunchKey, false);
    await prefs.setBool(_isGuestKey, false); // Clear conflicts
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
      'isDebugMode': await isDebugMode,
      'isFirstLaunch': await isFirstLaunch,
      'userMode': await userMode,
      'userId': await userId,
    };
  }

  // Force clear all auth flags (for testing)
  Future<void> clearAuthFlags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, false);
    await prefs.setBool(_isDebugKey, false);
    await prefs.setBool(_isFirstLaunchKey, false);
  }
}