// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'app/fitgenie_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart' as login_screen;
import 'screens/shell_screen.dart';
import 'services/notification_service.dart';
import 'services/connectivity_service.dart';
import 'services/local_storage_service.dart';
import 'services/sync_service.dart';
import 'services/step_counter_service.dart';
import 'widgets/offline_indicator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════
  // 🔒 STEP 1: Load Environment Variables FIRST
  // ═══════════════════════════════════════════
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Environment loaded');

    final hasKey = dotenv.env['GEMINI_API_KEY']?.isNotEmpty ?? false;
    debugPrint('✅ GEMINI_API_KEY found: $hasKey');
  } catch (e) {
    debugPrint('⚠️ .env load error: $e');
  }

  // ═══════════════════════════════════════════
  // 🔥 STEP 2: Firebase Init
  // ═══════════════════════════════════════════
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase error: $e');
  }

  // ═══════════════════════════════════════════
  // 🗃️ STEP 3: Local Storage Init
  // ═══════════════════════════════════════════
  try {
    final localStorage = LocalStorageService();
    await localStorage.initialize();
    debugPrint('✅ LocalStorage initialized');
  } catch (e) {
    debugPrint('⚠️ LocalStorage error: $e');
  }

  // ═══════════════════════════════════════════
  // 🌐 STEP 4: Connectivity Init
  // ═══════════════════════════════════════════
  try {
    await ConnectivityService().initialize();
    debugPrint('✅ Connectivity initialized');
  } catch (e) {
    debugPrint('⚠️ Connectivity error: $e');
  }

  // ═══════════════════════════════════════════
  // 🔄 STEP 5: Sync Service Start
  // ═══════════════════════════════════════════
  try {
    SyncService().startAutoSync();
    debugPrint('✅ SyncService started');
  } catch (e) {
    debugPrint('⚠️ SyncService error: $e');
  }

  // ═══════════════════════════════════════════
  // 🔔 STEP 6: Notifications Init
  // ═══════════════════════════════════════════
  try {
    await NotificationService().initialize();
    await NotificationService().scheduleAllDailyNotifications();
    debugPrint('✅ Notifications initialized');
  } catch (e) {
    debugPrint('⚠️ Notification error: $e');
  }

  // ═══════════════════════════════════════════
  // 🚀 STEP 7: Run App
  // ═══════════════════════════════════════════
  runApp(const FitGenieApp());
}

class FitGenieApp extends StatelessWidget {
  const FitGenieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitGenie',
      debugShowCheckedModeBanner: false,
      theme: FitGenieTheme.dark(),
      home: const AppEntry(),
    );
  }
}

// ═══════════════════════════════════════════
// 🎬 App Entry with Splash Screen
// ═══════════════════════════════════════════
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _showSplash = true;

  void _onSplashComplete() {
    if (mounted) {
      setState(() => _showSplash = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashComplete);
    }
    return const AuthGate();
  }
}

// ═══════════════════════════════════════════
// 🔐 AuthGate with Offline Banner + Step Counter Init
// ═══════════════════════════════════════════
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _cachedUid;
  Future<String>? _cachedNameFuture;

  Future<String> _resolveUserName(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      final name = data?['name'];

      if (doc.exists && name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
    } catch (_) {}

    final email = user.email;
    if (email != null && email.contains('@')) {
      final derived = email.split('@').first.trim();
      if (derived.isNotEmpty) return derived;
    }
    return 'User';
  }

  Future<String> _getNameFutureFor(User user) {
    if (_cachedUid != user.uid || _cachedNameFuture == null) {
      _cachedUid = user.uid;
      _cachedNameFuture = _resolveUserName(user);
    }
    return _cachedNameFuture!;
  }

  // ✅ NEW: Initialize step counter as soon as user is authenticated
  void _initializeStepCounter(String userId) {
    final stepService = StepCounterService();
    stepService.initialize(userId).then((success) {
      if (success) {
        debugPrint('✅ Step counter pre-initialized for user: $userId');
      }
    }).catchError((e) {
      debugPrint('⚠️ Step counter pre-init error: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return OfflineBanner(
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const login_screen.LoginScreen();
          }

          // ✅ NEW: Pre-initialize step counter when user logs in
          _initializeStepCounter(user.uid);

          return FutureBuilder<String>(
            future: _getNameFutureFor(user),
            builder: (context, nameSnapshot) {
              if (nameSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final userName = nameSnapshot.data ?? 'User';
              return ShellScreen(
                userId: user.uid,
                userName: userName,
              );
            },
          );
        },
      ),
    );
  }
}