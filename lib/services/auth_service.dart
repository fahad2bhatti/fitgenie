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
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

    // Remove HTML tags
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');

    // Remove script injections
    cleaned = cleaned.replaceAll(
      RegExp(r'(javascript|script|onclick|onerror|onload)', caseSensitive: false),
      '',
    );

    // Remove SQL keywords
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(SELECT|INSERT|UPDATE|DELETE|DROP|UNION|ALTER|CREATE)\b', caseSensitive: false),
      '',
    );

    // Remove dangerous characters - semicolon
    cleaned = cleaned.replaceAll(';', '');

    // Remove quotes
    cleaned = cleaned.replaceAll("'", '');
    cleaned = cleaned.replaceAll('"', '');

    return cleaned;
  }

  String _sanitizeName(String name) {
    String cleaned = _sanitizeInput(name);

    // Only allow letters, spaces, dot and hyphen
    cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');

    // Remove extra spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Limit length
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
    if (password.isEmpty) {
      return 'Password daal bhai';
    }
    if (password.length < 8) {
      return 'Password 8+ characters ka hona chahiye';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password mein ek capital letter daal (A-Z)';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password mein ek small letter daal (a-z)';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password mein ek number daal (0-9)';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?:{}|<>]'))) {
      return 'Password mein ek special character daal (!@#\$%^&*)';
    }
    return null;
  }

  String? _validateName(String name) {
    if (name.trim().isEmpty) {
      return 'Naam daal bhai';
    }
    if (name.trim().length < 2) {
      return 'Naam kam se kam 2 letters ka ho';
    }
    if (name.trim().length > 50) {
      return 'Naam bahut lamba hai (max 50 characters)';
    }
    return null;
  }

  // ═══════════════════════════════════════════
  // 🛡️ BRUTE FORCE CHECK
  // ═══════════════════════════════════════════
  String? _checkBruteForce() {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final remaining = _lockoutUntil!.difference(DateTime.now()).inSeconds;
      return 'Bahut zyada attempts! $remaining seconds baad try kar.';
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
      debugPrint('🔄 Starting Google Sign-in...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ Google Sign-in cancelled by user');
        return AuthResult(
          success: false,
          message: 'Google Sign-in cancel kar diya.',
        );
      }

      debugPrint('✅ Google account selected: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

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
        message: 'Google Sign-in failed.',
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
        message: 'Google Sign-in mein error. Internet check kar.',
      );
    }
  }

  // ═══════════════════════════════════════════
  // 👤 CREATE GOOGLE USER DOC
  // ═══════════════════════════════════════════
  Future<void> _createGoogleUserDoc(
      User user, GoogleSignInAccount googleUser) async {
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

      if (cleanEmail.isEmpty) {
        return AuthResult(success: false, message: 'Email daal bhai');
      }
      if (!_isValidEmail(cleanEmail)) {
        return AuthResult(success: false, message: 'Email format sahi nahi hai');
      }
      if (password.isEmpty) {
        return AuthResult(success: false, message: 'Password daal bhai');
      }

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

      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e.code),
      );
    } catch (e) {
      debugPrint('❌ Unknown error: $e');
      _recordFailedAttempt();

      return AuthResult(
        success: false,
        message: 'Kuch gadbad ho gayi. Internet check kar.',
      );
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
      if (nameError != null) {
        return AuthResult(success: false, message: nameError);
      }

      if (cleanEmail.isEmpty) {
        return AuthResult(success: false, message: 'Email daal bhai');
      }
      if (!_isValidEmail(cleanEmail)) {
        return AuthResult(success: false, message: 'Email format sahi nahi hai');
      }

      final passwordError = _validatePassword(password);
      if (passwordError != null) {
        return AuthResult(success: false, message: passwordError);
      }

      if (confirmPassword != null && password != confirmPassword) {
        return AuthResult(
          success: false,
          message: 'Dono passwords match nahi kar rahe',
        );
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
          message: 'Account ban gaya! Email verify kar le. 🎉',
          user: user,
        );
      }

      return AuthResult(
        success: false,
        message: 'Signup failed. Dobara try kar.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code}');
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e.code),
      );
    } catch (e) {
      debugPrint('❌ Unknown error: $e');
      return AuthResult(
        success: false,
        message: 'Kuch gadbad ho gayi. Internet check kar.',
      );
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
        await _googleSignIn.signOut();
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

      if (cleanEmail.isEmpty) {
        return AuthResult(success: false, message: 'Email daal bhai');
      }
      if (!_isValidEmail(cleanEmail)) {
        return AuthResult(success: false, message: 'Email format sahi nahi hai');
      }

      await _auth.sendPasswordResetEmail(email: cleanEmail);

      return AuthResult(
        success: true,
        message: 'Password reset link email pe bhej diya! 📧',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Error ho gaya. Dobara try kar.',
      );
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
    final derivedName =
    (email.contains('@') ? email.split('@').first : '').trim();
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
    if (user == null) {
      return AuthResult(success: false, message: 'User logged in nahi hai');
    }

    final cleanName = _sanitizeName(name);
    final nameError = _validateName(cleanName);
    if (nameError != null) {
      return AuthResult(success: false, message: nameError);
    }

    try {
      await user.updateDisplayName(cleanName);
      await _firestore.collection('users').doc(user.uid).update({
        'name': cleanName,
      });

      return AuthResult(success: true, message: 'Name update ho gaya! ✅');
    } catch (e) {
      return AuthResult(success: false, message: 'Name update nahi ho paya');
    }
  }

  // ═══════════════════════════════════════════
  // 📧 UPDATE EMAIL
  // ═══════════════════════════════════════════
  Future<AuthResult> updateEmail(String newEmail) async {
    final user = currentUser;
    if (user == null) {
      return AuthResult(success: false, message: 'User logged in nahi hai');
    }

    final cleanEmail = _sanitizeEmail(newEmail);
    if (!_isValidEmail(cleanEmail)) {
      return AuthResult(success: false, message: 'Email format sahi nahi hai');
    }

    try {
      await user.verifyBeforeUpdateEmail(cleanEmail);
      return AuthResult(
        success: true,
        message: 'Verification email bhej diya. Check karo! 📧',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Email update nahi ho paya');
    }
  }

  // ═══════════════════════════════════════════
  // 🔒 UPDATE PASSWORD
  // ═══════════════════════════════════════════
  Future<AuthResult> updatePassword(String newPassword) async {
    final user = currentUser;
    if (user == null) {
      return AuthResult(success: false, message: 'User logged in nahi hai');
    }

    final passwordError = _validatePassword(newPassword);
    if (passwordError != null) {
      return AuthResult(success: false, message: passwordError);
    }

    try {
      await user.updatePassword(newPassword);
      return AuthResult(success: true, message: 'Password update ho gaya! 🔐');
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Password update nahi ho paya. Re-login karke try kar.',
      );
    }
  }

  // ═══════════════════════════════════════════
  // 🗑️ DELETE ACCOUNT
  // ═══════════════════════════════════════════
  Future<AuthResult> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      return AuthResult(success: false, message: 'User logged in nahi hai');
    }

    try {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();

      return AuthResult(success: true, message: 'Account delete ho gaya');
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Account delete nahi ho paya. Re-login karke try kar.',
      );
    }
  }

  // ═══════════════════════════════════════════
  // 🔤 FIREBASE ERROR MESSAGES (Hinglish)
  // ═══════════════════════════════════════════
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ye email already registered hai. Login kar.';
      case 'invalid-email':
        return 'Email format galat hai.';
      case 'weak-password':
        return 'Password zyada strong rakh.';
      case 'user-not-found':
        return 'Is email se koi account nahi hai.';
      case 'wrong-password':
        return 'Password galat hai.';
      case 'invalid-credential':
        return 'Email ya password galat hai.';
      case 'user-disabled':
        return 'Ye account disable hai. Support se baat kar.';
      case 'too-many-requests':
        return 'Bahut zyada attempts! Thodi der baad try kar.';
      case 'network-request-failed':
        return 'Internet check kar bhai.';
      case 'requires-recent-login':
        return 'Dobara login karke try kar.';
      case 'operation-not-allowed':
        return 'Ye feature abhi available nahi hai.';
      default:
        return  'Kuch gadbad ho gayi. Dobara try kar.';
    }
  }
}

