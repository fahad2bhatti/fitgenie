// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

// ═══════════════════════════════════════════
// 📦 AUTH RESULT CLASS
// ═══════════════════════════════════════════
class AuthResult {
  final bool success;
  final String message;
  final User? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

// ═══════════════════════════════════════════
// 🔐 AUTH SERVICE
// ═══════════════════════════════════════════
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '387230689296-h6ggsbl2jl9tmqcgsanmecc1l5d3rg47.apps.googleusercontent.com',
  );

  // ✅ Brute Force Protection
  int _loginAttempts = 0;
  DateTime? _lockoutUntil;
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 2);

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // ═══════════════════════════════════════════
  // 🛡️ INPUT SANITIZATION
  // ═══════════════════════════════════════════
  String _sanitizeInput(String input) {
    if (input.isEmpty) return '';
    String cleaned = input.trim();
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');
    cleaned = cleaned.replaceAll(
      RegExp(r'(javascript|script|onclick|onerror|onload)', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(SELECT|INSERT|UPDATE|DELETE|DROP|UNION|ALTER|CREATE)\b', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(';', '');
    cleaned = cleaned.replaceAll("'", '');
    cleaned = cleaned.replaceAll('"', '');
    return cleaned;
  }

  String _sanitizeName(String name) {
    String cleaned = _sanitizeInput(name);
    cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.length > 50) {
      cleaned = cleaned.substring(0, 50);
    }
    return cleaned.trim();
  }

  String _sanitizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  // ═══════════════════════════════════════════
  // 🛡️ INPUT VALIDATION
  // ═══════════════════════════════════════════
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email.trim());
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return 'Please enter your password.';
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Password must contain at least one uppercase letter (A-Z).';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Password must contain at least one lowercase letter (a-z).';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Password must contain at least one number (0-9).';
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?:{}|<>]'))) return 'Password must contain at least one special character (!@#\$%^&*).';
    return null;
  }

  String? _validateName(String name) {
    if (name.trim().isEmpty) return 'Please enter your name.';
    if (name.trim().length < 2) return 'Name must be at least 2 characters.';
    if (name.trim().length > 50) return 'Name is too long (max 50 characters).';
    return null;
  }

  // ═══════════════════════════════════════════
  // 🛡️ BRUTE FORCE CHECK
  // ═══════════════════════════════════════════
  String? _checkBruteForce() {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final remaining = _lockoutUntil!.difference(DateTime.now()).inSeconds;
      return 'Too many attempts. Please try again in $remaining seconds.';
    }
    return null;
  }

  void _recordFailedAttempt() {
    _loginAttempts++;
    debugPrint('⚠️ Failed attempt: $_loginAttempts/$_maxAttempts');
    if (_loginAttempts >= _maxAttempts) {
      _lockoutUntil = DateTime.now().add(_lockoutDuration);
      _loginAttempts = 0;
      debugPrint('🔒 Account locked until: $_lockoutUntil');
    }
  }

  void _resetAttempts() {
    _loginAttempts = 0;
    _lockoutUntil = null;
  }

  // ═══════════════════════════════════════════
  // 🔐 GOOGLE SIGN IN
  // ═══════════════════════════════════════════
  Future<AuthResult> signInWithGoogle() async {

      try {
        // Sirf agar already signed in ho tab signOut karo
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.disconnect(); // Firebase affect nahi hoga
        }

        debugPrint('🔄 Starting Google Sign-in...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ Google Sign-in cancelled by user');
        return AuthResult(
          success: false,
          message: 'Google Sign-in was cancelled.',
        );
      }

      debugPrint('✅ Google account selected: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        debugPrint('✅ Firebase sign-in successful: ${user.uid}');
        await _createGoogleUserDoc(user, googleUser);
        _resetAttempts();

        return AuthResult(
          success: true,
          message: 'Welcome ${user.displayName ?? 'User'}! 🎉',
          user: user,
        );
      }

      return AuthResult(
        success: false,
        message: 'Google Sign-in failed. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e.code),
      );
    } catch (e) {
      debugPrint('❌ Google Sign-in error: $e');
      return AuthResult(
        success: false,
        message: 'Google Sign-in failed. Please check your internet connection.',
      );
    }
  }

  // ═══════════════════════════════════════════
  // 👤 CREATE GOOGLE USER DOC
  // ═══════════════════════════════════════════
  Future<void> _createGoogleUserDoc(User user, GoogleSignInAccount googleUser) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    final sanitizedName = _sanitizeName(
      user.displayName ?? googleUser.displayName ?? 'User',
    );

    if (!doc.exists) {
      await docRef.set({
        'email': user.email ?? googleUser.email,
        'name': sanitizedName,
        'photoUrl': user.photoURL ?? googleUser.photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'profileComplete': false,
        'fitnessLevel': 'beginner',
        'goal': 'Stay Fit',
        'signInMethod': 'google',
      });

      await docRef.collection('goals').doc('main').set({
        'caloriesGoal': 2000,
        'proteinGoal': 100,
        'waterGoal': 8,
        'stepsGoal': 10000,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ New Google user document created');
    } else {
      await docRef.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'photoUrl': user.photoURL ?? googleUser.photoUrl,
      });

      debugPrint('✅ Existing user - updated last login');
    }
  }

  // ═══════════════════════════════════════════
  // 🔐 LOGIN (Email/Password)
  // ═══════════════════════════════════════════
  Future<AuthResult> login(String email, String password) async {
    try {
      final lockoutError = _checkBruteForce();
      if (lockoutError != null) {
        return AuthResult(success: false, message: lockoutError);
      }

      final cleanEmail = _sanitizeEmail(email);

      if (cleanEmail.isEmpty) return AuthResult(success: false, message: 'Please enter your email.');
      if (!_isValidEmail(cleanEmail)) return AuthResult(success: false, message: 'Please enter a valid email address.');
      if (password.isEmpty) return AuthResult(success: false, message: 'Please enter your password.');

      debugPrint('🔄 Attempting login for: $cleanEmail');

      final result = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = result.user;
      debugPrint('✅ Login successful: ${user?.uid}');

      if (user != null) {
        await _updateLastLogin(user);
        _resetAttempts();
      }

      return AuthResult(
        success: true,
        message: 'Welcome back! 🎉',
        user: user,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      _recordFailedAttempt();
      return AuthResult(success: false, message: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      debugPrint('❌ Unknown error: $e');
      _recordFailedAttempt();
      return AuthResult(success: false, message: 'Something went wrong. Please check your internet connection.');
    }
  }

  // ═══════════════════════════════════════════
  // 📝 SIGN UP WITH NAME
  // ═══════════════════════════════════════════
  Future<AuthResult> signUpWithName({
    required String email,
    required String password,
    required String name,
    String? confirmPassword,
  }) async {
    try {
      final cleanEmail = _sanitizeEmail(email);
      final cleanName = _sanitizeName(name);

      final nameError = _validateName(cleanName);
      if (nameError != null) return AuthResult(success: false, message: nameError);

      if (cleanEmail.isEmpty) return AuthResult(success: false, message: 'Please enter your email.');
      if (!_isValidEmail(cleanEmail)) return AuthResult(success: false, message: 'Please enter a valid email address.');

      final passwordError = _validatePassword(password);
      if (passwordError != null) return AuthResult(success: false, message: passwordError);

      if (confirmPassword != null && password != confirmPassword) {
        return AuthResult(success: false, message: 'Passwords do not match.');
      }

      debugPrint('🔄 Attempting signup for: $cleanEmail');

      final result = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = result.user;
      if (user != null) {
        await user.updateDisplayName(cleanName);
        await _createUserDoc(user, cleanName);
        await user.sendEmailVerification();

        debugPrint('✅ Signup successful: ${user.uid}');

        return AuthResult(
          success: true,
          message: 'Account created! Please verify your email. 🎉',
          user: user,
        );
      }

      return AuthResult(success: false, message: 'Signup failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code}');
      return AuthResult(success: false, message: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      debugPrint('❌ Unknown error: $e');
      return AuthResult(success: false, message: 'Something went wrong. Please check your internet connection.');
    }
  }

  // ═══════════════════════════════════════════
  // 📝 SIGN UP (Legacy)
  // ═══════════════════════════════════════════
  Future<AuthResult> signUp(String email, String password) async {
    return signUpWithName(
      email: email,
      password: password,
      name: email.split('@').first,
    );
  }

  // ═══════════════════════════════════════════
  // 🚪 LOGOUT
  // ═══════════════════════════════════════════
  Future<void> logout() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect().catchError((_) => null);
      }
      await _auth.signOut();
      _resetAttempts();
      debugPrint('✅ Logout successful');
    } catch (e) {
      debugPrint('❌ Logout error: $e');
    }
  }

  // ═══════════════════════════════════════════
  // 🔑 FORGOT PASSWORD
  // ═══════════════════════════════════════════
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      final cleanEmail = _sanitizeEmail(email);

      if (cleanEmail.isEmpty) return AuthResult(success: false, message: 'Please enter your email.');
      if (!_isValidEmail(cleanEmail)) return AuthResult(success: false, message: 'Please enter a valid email address.');

      await _auth.sendPasswordResetEmail(email: cleanEmail);

      return AuthResult(
        success: true,
        message: 'Password reset link has been sent to your email! 📧',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, message: 'Something went wrong. Please try again.');
    }
  }

  // ═══════════════════════════════════════════
  // 👤 CREATE USER DOC
  // ═══════════════════════════════════════════
  Future<void> _createUserDoc(User user, String name) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final cleanName = _sanitizeName(name);

    await docRef.set({
      'email': user.email ?? '',
      'name': cleanName,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'profileComplete': false,
      'fitnessLevel': 'beginner',
      'goal': 'Stay Fit',
      'signInMethod': 'email',
    });

    await docRef.collection('goals').doc('main').set({
      'caloriesGoal': 2000,
      'proteinGoal': 100,
      'waterGoal': 8,
      'stepsGoal': 10000,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════
  // 👤 ENSURE USER DOC
  // ═══════════════════════════════════════════
  Future<void> _ensureUserDoc(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final email = user.email ?? '';
    final derivedName = (email.contains('@') ? email.split('@').first : '').trim();
    final cleanName = _sanitizeName(derivedName);

    await docRef.set({
      'email': email,
      'name': cleanName.isNotEmpty ? cleanName : 'User',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ═══════════════════════════════════════════
  // 🕐 UPDATE LAST LOGIN
  // ═══════════════════════════════════════════
  Future<void> _updateLastLogin(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await _ensureUserDoc(user);
    }
  }

  // ═══════════════════════════════════════════
  // 👤 UPDATE USER NAME
  // ═══════════════════════════════════════════
  Future<AuthResult> updateUserName(String name) async {
    final user = currentUser;
    if (user == null) return AuthResult(success: false, message: 'User is not logged in.');

    final cleanName = _sanitizeName(name);
    final nameError = _validateName(cleanName);
    if (nameError != null) return AuthResult(success: false, message: nameError);

    try {
      await user.updateDisplayName(cleanName);
      await _firestore.collection('users').doc(user.uid).update({'name': cleanName});
      return AuthResult(success: true, message: 'Name updated successfully! ✅');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to update name. Please try again.');
    }
  }

  // ═══════════════════════════════════════════
  // 📧 UPDATE EMAIL
  // ═══════════════════════════════════════════
  Future<AuthResult> updateEmail(String newEmail) async {
    final user = currentUser;
    if (user == null) return AuthResult(success: false, message: 'User is not logged in.');

    final cleanEmail = _sanitizeEmail(newEmail);
    if (!_isValidEmail(cleanEmail)) return AuthResult(success: false, message: 'Please enter a valid email address.');

    try {
      await user.verifyBeforeUpdateEmail(cleanEmail);
      return AuthResult(success: true, message: 'Verification email sent. Please check your inbox! 📧');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to update email. Please try again.');
    }
  }

  // ═══════════════════════════════════════════
  // 🔒 UPDATE PASSWORD
  // ═══════════════════════════════════════════
  Future<AuthResult> updatePassword(String newPassword) async {
    final user = currentUser;
    if (user == null) return AuthResult(success: false, message: 'User is not logged in.');

    final passwordError = _validatePassword(newPassword);
    if (passwordError != null) return AuthResult(success: false, message: passwordError);

    try {
      await user.updatePassword(newPassword);
      return AuthResult(success: true, message: 'Password updated successfully! 🔐');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to update password. Please log in again and retry.');
    }
  }

  // ═══════════════════════════════════════════
  // 🗑️ DELETE ACCOUNT
  // ═══════════════════════════════════════════
  Future<AuthResult> deleteAccount() async {
    final user = currentUser;
    if (user == null) return AuthResult(success: false, message: 'User is not logged in.');

    try {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      return AuthResult(success: true, message: 'Account deleted successfully.');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to delete account. Please log in again and retry.');
    }
  }

  // ═══════════════════════════════════════════
  // 🔤 FIREBASE ERROR MESSAGES (English)
  // ═══════════════════════════════════════════
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'requires-recent-login':
        return 'Please log in again to complete this action.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

