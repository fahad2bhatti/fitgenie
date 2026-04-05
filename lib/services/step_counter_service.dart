// lib/services/step_counter_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'google_fit_service.dart';

class StepCounterService {
  static final StepCounterService _instance = StepCounterService._internal();
  factory StepCounterService() => _instance;
  StepCounterService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleFitService _googleFit = GoogleFitService();

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  int _todaySteps = 0;
  int _initialSteps = 0;
  bool _isInitialized = false;
  bool _initialStepsSet = false;
  bool _sensorAvailable = true;
  bool _useGoogleFit = false;
  String _pedestrianStatus = 'unknown';
  String? _userId;

  Function(int steps)? onStepsChanged;
  Function(String status)? onStatusChanged;
  Function(double calories)? onCaloriesChanged;
  Function(GoogleFitConnectionStatus status)? onGoogleFitStatusChanged;

  // Getters
  int get todaySteps => _todaySteps;
  String get pedestrianStatus => _pedestrianStatus;
  bool get isInitialized => _isInitialized;
  bool get isUsingHealthConnect => _useGoogleFit;
  bool get isSensorAvailable => _sensorAvailable;

  // ═══════════════════════════════════════════
  // 🚀 INITIALIZE
  // ═══════════════════════════════════════════
  Future<bool> initialize(String userId) async {
    if (_isInitialized && _userId == userId) {
      debugPrint('✅ Step counter already initialized');
      return true;
    }

    _userId = userId;

    // ✅ FIX: Load saved steps from Firestore FIRST
    await _loadTodaySteps();

    // Try Google Fit silent connect (no popup)
    final googleFitConnected = await _googleFit.connect();

    if (googleFitConnected) {
      _useGoogleFit = true;
      debugPrint('✅ Using Google Fit for background steps');

      // Get steps from Google Fit
      final googleSteps = await _googleFit.getTodaySteps();
      // ✅ FIX: Use max of saved and Google Fit steps
      if (googleSteps > _todaySteps) {
        _todaySteps = googleSteps;
      }
      onStepsChanged?.call(_todaySteps);
      onGoogleFitStatusChanged?.call(GoogleFitConnectionStatus.connected);

      // Start periodic sync
      _startGoogleFitSync();
    } else {
      debugPrint('⚠️ Google Fit not connected, using Pedometer');
      _useGoogleFit = false;
      onGoogleFitStatusChanged?.call(GoogleFitConnectionStatus.disconnected);
    }

    // Request pedometer permission
    final hasPermission = await _requestPermission();
    if (hasPermission) {
      _initPedometer();
    }

    _isInitialized = true;
    debugPrint('✅ Step counter initialized — Steps: $_todaySteps (Google Fit: $_useGoogleFit)');
    return true;
  }

  // ═══════════════════════════════════════════
  // 🔍 GOOGLE FIT STATUS CHECK
  // ═══════════════════════════════════════════

  /// Full detailed status check
  Future<GoogleFitStatus> checkGoogleFitStatus() async {
    final status = GoogleFitStatus();

    try {
      // Check 1: Health Connect app installed hai?
      status.healthConnectAvailable = await _googleFit.isHealthConnectAvailable();

      if (!status.healthConnectAvailable) {
        status.errorMessage = 'Health Connect app not installed on this device';
        status.overallStatus = GoogleFitConnectionStatus.unavailable;
        onGoogleFitStatusChanged?.call(status.overallStatus);
        return status;
      }

      // Check 2: Activity Recognition permission
      final activityPerm = await Permission.activityRecognition.status;
      status.activityPermissionGranted = activityPerm.isGranted;

      if (!status.activityPermissionGranted) {
        status.errorMessage = 'Activity Recognition permission not granted';
        status.overallStatus = GoogleFitConnectionStatus.permissionDenied;
        onGoogleFitStatusChanged?.call(status.overallStatus);
        return status;
      }

      // Check 3: Health Connect authorization
      status.healthAuthorized = await _googleFit.isAuthorized();

      if (!status.healthAuthorized) {
        status.errorMessage = 'Google Fit not authorized. Tap Connect to sign in.';
        status.overallStatus = GoogleFitConnectionStatus.notAuthorized;
        onGoogleFitStatusChanged?.call(status.overallStatus);
        return status;
      }

      // Check 4: Can we actually fetch data?
      status.dataAccessible = await _googleFit.canFetchData();
      status.todaySteps = await _googleFit.getTodaySteps();

      if (status.dataAccessible) {
        status.overallStatus = GoogleFitConnectionStatus.connected;
        status.errorMessage = '';
      } else {
        status.overallStatus = GoogleFitConnectionStatus.connectedNoData;
        status.errorMessage = 'Connected but no step data yet. Walk a few steps!';
      }

      // Check 5: Last sync time
      status.lastSyncTime = DateTime.now();
      status.isActivelysyncing = _useGoogleFit;

    } catch (e) {
      status.errorMessage = 'Error checking status: $e';
      status.overallStatus = GoogleFitConnectionStatus.error;
      debugPrint('❌ Google Fit status check error: $e');
    }

    onGoogleFitStatusChanged?.call(status.overallStatus);
    return status;
  }

  /// Quick check — returns simple bool
  Future<bool> isGoogleFitEnabled() async {
    try {
      if (!_useGoogleFit) return false;

      final isAvailable = await _googleFit.isHealthConnectAvailable();
      if (!isAvailable) return false;

      final isAuthorized = await _googleFit.isAuthorized();
      if (!isAuthorized) return false;

      final canFetch = await _googleFit.canFetchData();
      return canFetch;
    } catch (e) {
      debugPrint('❌ Quick check error: $e');
      return false;
    }
  }

  // ✅ FIX: Removed throw UnimplementedError()
  /// Get readable status string
  Future<String> getGoogleFitStatusText() async {
    final status = await checkGoogleFitStatus();
    switch (status.overallStatus) {
      case GoogleFitConnectionStatus.connected:
        return '✅ Connected — ${status.todaySteps} steps today';
      case GoogleFitConnectionStatus.connectedNoData:
        return '🟡 Connected — No data yet, walk a few steps';
      case GoogleFitConnectionStatus.connecting:
        return '🔄 Connecting...';
      case GoogleFitConnectionStatus.notAuthorized:
        return '🔐 Not authorized — Tap to grant permission';
      case GoogleFitConnectionStatus.permissionDenied:
        return '❌ Activity permission denied';
      case GoogleFitConnectionStatus.unavailable:
        return '📱 Health Connect not installed';
      case GoogleFitConnectionStatus.disconnected:
        return '🔌 Disconnected — Tap to connect';
      case GoogleFitConnectionStatus.error:
        return '⚠️ Error: ${status.errorMessage}';
    }
  }

  // ═══════════════════════════════════════════
  // 🔄 GOOGLE FIT SYNC (Every 5 min)
  // ═══════════════════════════════════════════
  Timer? _syncTimer;

  void _startGoogleFitSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
          (_) => _syncFromGoogleFit(),
    );
    debugPrint('🔄 Google Fit sync started (every 5 min)');
  }

  Future<void> _syncFromGoogleFit() async {
    if (!_useGoogleFit) return;

    try {
      // Pehle check karo ki abhi bhi connected hai
      final stillConnected = await _googleFit.isAuthorized();
      if (!stillConnected) {
        debugPrint('⚠️ Google Fit disconnected during sync');
        _useGoogleFit = false;
        _syncTimer?.cancel();
        onGoogleFitStatusChanged?.call(GoogleFitConnectionStatus.disconnected);
        return;
      }

      final googleFitSteps = await _googleFit.getTodaySteps();

      // Use higher value
      if (googleFitSteps > _todaySteps) {
        _todaySteps = googleFitSteps;
        onStepsChanged?.call(_todaySteps);
        onCaloriesChanged?.call(calculateCaloriesBurned(_todaySteps));
        _saveStepsThrottled();
        debugPrint('📊 Synced from Google Fit: $_todaySteps');
      }
    } catch (e) {
      debugPrint('❌ Google Fit sync error: $e');
    }
  }

  // ═══════════════════════════════════════════
  // 👟 PEDOMETER
  // ═══════════════════════════════════════════
  void _initPedometer() {
    try {
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: _onPedestrianStatusError,
        cancelOnError: false,
      );

      debugPrint('👂 Pedometer streams started');
    } catch (e) {
      debugPrint('❌ Pedometer init error: $e');
      _sensorAvailable = false;
    }
  }

  Future<bool> _requestPermission() async {
    try {
      PermissionStatus status = await Permission.activityRecognition.status;
      if (status.isGranted) return true;

      if (status.isDenied) {
        status = await Permission.activityRecognition.request();
        return status.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Permission error: $e');
      return false;
    }
  }

  void _onStepCount(StepCount event) {
    _sensorAvailable = true;

    if (!_initialStepsSet) {
      _initialSteps = event.steps - _todaySteps;
      _initialStepsSet = true;
    }

    final newSteps = event.steps - _initialSteps;

    // Only update if pedometer has more than current (Google Fit may have more)
    if (newSteps > _todaySteps) {
      _todaySteps = newSteps;
      onStepsChanged?.call(_todaySteps);
      onCaloriesChanged?.call(calculateCaloriesBurned(_todaySteps));
      _saveStepsThrottled();
    }
  }

  void _onStepCountError(dynamic error) {
    debugPrint('⚠️ Pedometer error: $error');
    if (error.toString().contains('not available')) {
      _sensorAvailable = false;
      _pedestrianStatus = 'unavailable';
    }
    onStatusChanged?.call(_pedestrianStatus);
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    _sensorAvailable = true;
    _pedestrianStatus = event.status;
    onStatusChanged?.call(_pedestrianStatus);
  }

  void _onPedestrianStatusError(dynamic error) {
    if (_pedestrianStatus != 'unavailable') {
      _pedestrianStatus = 'unknown';
    }
    onStatusChanged?.call(_pedestrianStatus);
  }

  // ═══════════════════════════════════════════
  // 📐 CALCULATIONS
  // ═══════════════════════════════════════════
  double calculateCaloriesBurned(int steps, {double weightKg = 70}) {
    return steps * 0.0005 * weightKg;
  }

  double calculateDistance(int steps, {double strideLength = 0.762}) {
    return (steps * strideLength) / 1000;
  }

  int calculateActiveMinutes(int steps) {
    return (steps / 100).round();
  }

  // ═══════════════════════════════════════════
  // 💾 FIRESTORE
  // ═══════════════════════════════════════════
  Future<void> _loadTodaySteps() async {
    if (_userId == null) return;

    try {
      final dateStr = _getDateString(DateTime.now());
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(dateStr)
          .get();

      if (doc.exists && doc.data() != null) {
        final savedSteps = (doc.data()!['steps'] as num?)?.toInt() ?? 0;
        if (savedSteps > _todaySteps) {
          _todaySteps = savedSteps;
          debugPrint('📊 Loaded saved steps from Firestore: $_todaySteps');
        }
      }
    } catch (e) {
      debugPrint('❌ Load steps error: $e');
    }
  }

  Timer? _saveTimer;

  void _saveStepsThrottled() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 15), _saveStepsToFirestore);
  }

  Future<void> _saveStepsToFirestore() async {
    if (_userId == null) return;

    try {
      final dateStr = _getDateString(DateTime.now());

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(dateStr)
          .set({
        'steps': _todaySteps,
        'stepsCalories': calculateCaloriesBurned(_todaySteps).round(),
        'stepsDistance': double.parse(calculateDistance(_todaySteps).toStringAsFixed(2)),
        'stepsActiveMinutes': calculateActiveMinutes(_todaySteps),
        'stepsUpdatedAt': FieldValue.serverTimestamp(),
        'stepsSource': _useGoogleFit ? 'google_fit' : 'pedometer',
        'googleFitEnabled': _useGoogleFit,
      }, SetOptions(merge: true));

      debugPrint('💾 Steps saved: $_todaySteps (source: ${_useGoogleFit ? "Google Fit" : "Pedometer"})');
    } catch (e) {
      debugPrint('❌ Save steps error: $e');
    }
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ═══════════════════════════════════════════
  // 🔄 PUBLIC METHODS
  // ═══════════════════════════════════════════
  Future<void> refreshSteps() async {
    if (_useGoogleFit) {
      await _syncFromGoogleFit();
    }
    await _loadTodaySteps();
    onStepsChanged?.call(_todaySteps);
  }

  Future<void> forceSave() async {
    _saveTimer?.cancel();
    await _saveStepsToFirestore();
  }

  Future<void> addSteps(int steps) async {
    if (steps <= 0) return;
    _todaySteps += steps;
    onStepsChanged?.call(_todaySteps);
    onCaloriesChanged?.call(calculateCaloriesBurned(_todaySteps));
    await _saveStepsToFirestore();
  }

  Map<String, dynamic> getStats({double weightKg = 70}) {
    return {
      'steps': _todaySteps,
      'calories': calculateCaloriesBurned(_todaySteps, weightKg: weightKg),
      'distance': calculateDistance(_todaySteps),
      'activeMinutes': calculateActiveMinutes(_todaySteps),
      'status': _pedestrianStatus,
      'source': _useGoogleFit ? 'Google Fit' : 'Pedometer',
      'sensorAvailable': _sensorAvailable,
      'googleFitConnected': _useGoogleFit,
    };
  }

  Future<void> resetDailySteps() async {
    _todaySteps = 0;
    _initialStepsSet = false;
    onStepsChanged?.call(0);
    onCaloriesChanged?.call(0);
  }

  Future<List<int>> getWeeklySteps() async {
    // Prefer Google Fit data
    if (_useGoogleFit) {
      return await _googleFit.getWeeklySteps();
    }

    // Fallback to Firestore
    List<int> weeklySteps = [0, 0, 0, 0, 0, 0, 0];
    if (_userId == null) return weeklySteps;

    try {
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final dateStr = _getDateString(date);
        final doc = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('dailyLogs')
            .doc(dateStr)
            .get();

        if (doc.exists) {
          weeklySteps[i] = (doc.data()?['steps'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (e) {
      debugPrint('❌ Weekly steps error: $e');
    }

    return weeklySteps;
  }

  // ═══════════════════════════════════════════
  // 🔌 CONNECT/DISCONNECT GOOGLE FIT — FIXED!
  // ═══════════════════════════════════════════

  /// ✅ FIX: Uses manualConnect() — shows Google Sign-in popup
  Future<bool> connectGoogleFit() async {
    onGoogleFitStatusChanged?.call(GoogleFitConnectionStatus.connecting);

    // ✅ FIX: manualConnect() shows Google Sign-in popup
    // connect() only does silent sign-in (no popup)
    final connected = await _googleFit.manualConnect();

    if (connected) {
      _useGoogleFit = true;
      debugPrint('✅ Google Fit manually connected!');

      // Sync steps immediately
      await _syncFromGoogleFit();

      // Start periodic sync
      _startGoogleFitSync();

      // Save to Firestore
      await _saveStepsToFirestore();

      onGoogleFitStatusChanged?.call(GoogleFitConnectionStatus.connected);
    } else {
      debugPrint('❌ Google Fit manual connect failed');
      onGoogleFitStatusChanged?.call(GoogleFitConnectionStatus.disconnected);
    }
    return connected;
  }

  Future<void> disconnectGoogleFit() async {
    await _googleFit.disconnect();
    _useGoogleFit = false;
    _syncTimer?.cancel();
    onGoogleFitStatusChanged?.call(GoogleFitConnectionStatus.disconnected);
    debugPrint('🔌 Google Fit disconnected');
  }

  // ═══════════════════════════════════════════
  // 🛑 DISPOSE
  // ═══════════════════════════════════════════
  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _saveTimer?.cancel();
    _syncTimer?.cancel();
    _isInitialized = false;
    _initialStepsSet = false;
    debugPrint('🛑 Step counter disposed');
  }
}

// ═══════════════════════════════════════════
// 📋 STATUS MODELS
// ═══════════════════════════════════════════

/// Connection status enum
enum GoogleFitConnectionStatus {
  connected,
  connectedNoData,
  connecting,
  notAuthorized,
  permissionDenied,
  unavailable,
  disconnected,
  error,
}

/// Detailed status model
class GoogleFitStatus {
  bool healthConnectAvailable = false;
  bool activityPermissionGranted = false;
  bool healthAuthorized = false;
  bool dataAccessible = false;
  bool isActivelysyncing = false;
  int todaySteps = 0;
  DateTime? lastSyncTime;
  String errorMessage = '';
  GoogleFitConnectionStatus overallStatus = GoogleFitConnectionStatus.disconnected;

  bool get isFullyWorking =>
      healthConnectAvailable &&
          activityPermissionGranted &&
          healthAuthorized &&
          dataAccessible;

  String get statusIcon {
    switch (overallStatus) {
      case GoogleFitConnectionStatus.connected:
        return '✅';
      case GoogleFitConnectionStatus.connectedNoData:
        return '🟡';
      case GoogleFitConnectionStatus.connecting:
        return '🔄';
      case GoogleFitConnectionStatus.notAuthorized:
        return '🔐';
      case GoogleFitConnectionStatus.permissionDenied:
        return '❌';
      case GoogleFitConnectionStatus.unavailable:
        return '📱';
      case GoogleFitConnectionStatus.disconnected:
        return '🔌';
      case GoogleFitConnectionStatus.error:
        return '⚠️';
    }
  }

  String get statusText {
    switch (overallStatus) {
      case GoogleFitConnectionStatus.connected:
        return 'Connected & Syncing';
      case GoogleFitConnectionStatus.connectedNoData:
        return 'Connected — Walk to see data';
      case GoogleFitConnectionStatus.connecting:
        return 'Connecting...';
      case GoogleFitConnectionStatus.notAuthorized:
        return 'Authorization Required';
      case GoogleFitConnectionStatus.permissionDenied:
        return 'Permission Denied';
      case GoogleFitConnectionStatus.unavailable:
        return 'Health Connect Not Installed';
      case GoogleFitConnectionStatus.disconnected:
        return 'Disconnected';
      case GoogleFitConnectionStatus.error:
        return 'Error Occurred';
    }
  }

  @override
  String toString() {
    return '''
╔══════════════════════════════════════╗
║     GOOGLE FIT STATUS REPORT        ║
╠══════════════════════════════════════╣
║ Overall: $statusIcon $statusText
║ Health Connect Installed: ${healthConnectAvailable ? "✅" : "❌"}
║ Activity Permission: ${activityPermissionGranted ? "✅" : "❌"}
║ Health Authorized: ${healthAuthorized ? "✅" : "❌"}
║ Data Accessible: ${dataAccessible ? "✅" : "❌"}
║ Today Steps: $todaySteps
║ Actively Syncing: ${isActivelysyncing ? "✅" : "❌"}
║ Last Sync: ${lastSyncTime ?? "Never"}
║ Error: ${errorMessage.isEmpty ? "None" : errorMessage}
╚══════════════════════════════════════╝
    ''';
  }
}