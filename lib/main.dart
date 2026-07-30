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

import 'screens/onboarding_screen.dart';

// NEW IMPORTS - Phase 1 language system
import 'core/hive_boxes.dart';
import 'core/language_provider.dart';
import 'screens/language_selection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    debugPrint('Environment loaded');

    final hasKey = dotenv.env['GEMINI_API_KEY']?.isNotEmpty ?? false;
    debugPrint('GEMINI_API_KEY found: $hasKey');
  } catch (e) {
    debugPrint('.env load error: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized');
  } catch (e) {
    debugPrint('Firebase error: $e');
  }

  try {
    await HiveBoxes.init();
    LanguageProvider().init();
    debugPrint('Hive + LanguageProvider initialized');
  } catch (e) {
    debugPrint('Hive/LanguageProvider error: $e');
  }

  try {
    final localStorage = LocalStorageService();
    await localStorage.initialize();
    debugPrint('LocalStorage initialized');
  } catch (e) {
    debugPrint('LocalStorage error: $e');
  }

  try {
    await ConnectivityService().initialize();
    debugPrint('Connectivity initialized');
  } catch (e) {
    debugPrint('Connectivity error: $e');
  }

  try {
    SyncService().startAutoSync();
    debugPrint('SyncService started');
  } catch (e) {
    debugPrint('SyncService error: $e');
  }

  try {
    await NotificationService().initialize();
    await NotificationService().scheduleAllDailyNotifications();
    debugPrint('Notifications initialized');
  } catch (e) {
    debugPrint('Notification error: $e');
  }

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

// -----------------------------------------------
// App Entry with Splash Screen
// -----------------------------------------------
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
    return const LanguageGate();
  }
}

// -----------------------------------------------
// LanguageGate
// Shows LanguageSelectionScreen once (first launch only),
// then listens to LanguageProvider and moves into AuthGate.
// -----------------------------------------------
class LanguageGate extends StatefulWidget {
  const LanguageGate({super.key});

  @override
  State<LanguageGate> createState() => _LanguageGateState();
}

class _LanguageGateState extends State<LanguageGate> {
  final LanguageProvider _provider = LanguageProvider();

  @override
  void initState() {
    super.initState();
    _provider.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _provider.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_provider.isLanguageSelected) {
      return const LanguageSelectionScreen();
    }
    return AuthGate();
  }
}

// -----------------------------------------------
// Helper class - carries name + onboarding status together
// -----------------------------------------------
class _UserGateInfo {
  final String name;
  final bool profileComplete;
  const _UserGateInfo({required this.name, required this.profileComplete});
}

// -----------------------------------------------
// AuthGate with Offline Banner + Step Counter Init
// -----------------------------------------------
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _cachedUid;
  Future<_UserGateInfo>? _cachedInfoFuture;
  String? _lastInitializedUid;

  Future<_UserGateInfo> _resolveUserInfo(User user) async {
    String name = 'User';
    bool profileComplete = false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      final rawName = data?['name'];

      if (doc.exists && rawName is String && rawName.trim().isNotEmpty) {
        name = rawName.trim();
      }
      profileComplete = data?['profileComplete'] == true;
    } catch (_) {}

    if (name == 'User') {
      final email = user.email;
      if (email != null && email.contains('@')) {
        final derived = email.split('@').first.trim();
        if (derived.isNotEmpty) name = derived;
      }
    }

    return _UserGateInfo(name: name, profileComplete: profileComplete);
  }

  Future<_UserGateInfo> _getInfoFutureFor(User user) {
    if (_cachedUid != user.uid || _cachedInfoFuture == null) {
      _cachedUid = user.uid;
      _cachedInfoFuture = _resolveUserInfo(user);
    }
    return _cachedInfoFuture!;
  }

  void _initializeStepCounter(String userId) {
    if (_lastInitializedUid == userId) return;
    _lastInitializedUid = userId;
    final stepService = StepCounterService();
    stepService.initialize(userId).then((success) {
      if (success) {
        debugPrint('Step counter pre-initialized for user: $userId');
      }
    }).catchError((e) {
      debugPrint('Step counter pre-init error: $e');
    });
  }

  // ================================================================
  // 🔤 LANGUAGE FIX: whole build() wrapped in AnimatedBuilder so that
  // ANY screen below (Login, Onboarding, ShellScreen, etc.) rebuilds
  // the instant LanguageProvider.setLanguage() is called anywhere
  // in the app — no more app-restart needed to see new language.
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageProvider(),
      builder: (context, _) {
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

              // Not logged in
              if (user == null) {
                return const login_screen.LoginScreen();
              }

              // Email verification check (only for email/password users)
              final isEmailUser = user.providerData
                  .any((p) => p.providerId == 'password') &&
                  !user.providerData.any((p) => p.providerId == 'google.com');

              if (!user.emailVerified && isEmailUser) {
                return Scaffold(
                  backgroundColor: FitGenieTheme.bg,
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.email, color: Colors.blue, size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'Email Verify Karo!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Email pe verification link bheja hai. Verify karo phir login karo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () async {
                              await user.reload();
                            },
                            child: const Text('Check karo'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                            },
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // User logged in - initialize step counter
              _initializeStepCounter(user.uid);

              return FutureBuilder<_UserGateInfo>(
                future: _getInfoFutureFor(user),
                builder: (context, infoSnapshot) {
                  if (infoSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final info = infoSnapshot.data ??
                      const _UserGateInfo(name: 'User', profileComplete: false);

                  if (!info.profileComplete) {
                    return OnboardingScreen(
                      userId: user.uid,
                      userName: info.name,
                    );
                  }

                  return ShellScreen(
                    userId: user.uid,
                    userName: info.name,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}