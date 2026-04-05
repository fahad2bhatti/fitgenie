// lib/services/google_fit_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleFitService {
  static final GoogleFitService _instance = GoogleFitService._internal();
  factory GoogleFitService() => _instance;
  GoogleFitService._internal();

  // ✅ FIX: Google Sign In with Fitness scopes
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/fitness.activity.read',
      'https://www.googleapis.com/auth/fitness.location.read',
    ],
  );

  GoogleSignInAccount? _currentUser;
  String? _accessToken;
  bool _isConnected = false;
  DateTime? _lastSuccessfulFetch;
  int _consecutiveErrors = 0;

  // Getters
  bool get isConnected => _isConnected;
  String? get userEmail => _currentUser?.email;
  DateTime? get lastSuccessfulFetch => _lastSuccessfulFetch;
  int get consecutiveErrors => _consecutiveErrors;

  // ═══════════════════════════════════════════
  // 🔍 STATUS CHECK METHODS
  // ═══════════════════════════════════════════

  Future<bool> isHealthConnectAvailable() async {
    try {
      await _googleSignIn.signInSilently();
      return true;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('api_not_connected') ||
          errorStr.contains('service_disabled') ||
          errorStr.contains('service_missing') ||
          errorStr.contains('service_invalid') ||
          errorStr.contains('unavailable')) {
        return false;
      }
      return true;
    }
  }

  // ✅ FIX: Better authorization check
  Future<bool> isAuthorized() async {
    try {
      // Check 1: Try silent sign in first
      if (_currentUser == null) {
        _currentUser = await _googleSignIn.signInSilently();
      }

      // ✅ FIX: If silent sign in fails, user needs to manually connect
      // Don't auto-popup sign in dialog here
      if (_currentUser == null) {
        debugPrint('🔐 Not authorized: No signed-in user (needs manual connect)');
        return false;
      }

      // Check 2: Get access token
      final auth = await _currentUser!.authentication;
      if (auth.accessToken == null) {
        debugPrint('🔐 Not authorized: No access token');
        return false;
      }

      _accessToken = auth.accessToken;
      return true;
    } catch (e) {
      debugPrint('🔐 Authorization check error: $e');
      return false;
    }
  }

  Future<bool> canFetchData() async {
    try {
      if (!_isConnected && _accessToken == null) {
        return false;
      }

      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 24));

      final startMillis = oneHourAgo.millisecondsSinceEpoch;
      final endMillis = now.millisecondsSinceEpoch;

      final response = await http.post(
        Uri.parse(
            'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'aggregateBy': [
            {
              'dataTypeName': 'com.google.step_count.delta',
              'dataSourceId':
              'derived:com.google.step_count.delta:com.google.android.gms:estimated_steps',
            }
          ],
          'bucketByTime': {'durationMillis': endMillis - startMillis},
          'startTimeMillis': startMillis,
          'endTimeMillis': endMillis,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _consecutiveErrors = 0;
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('📊 Can fetch data error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getDiagnostics() async {
    final diagnostics = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'isConnected': _isConnected,
      'hasUser': _currentUser != null,
      'userEmail': _currentUser?.email,
      'hasAccessToken': _accessToken != null,
      'lastSuccessfulFetch': _lastSuccessfulFetch?.toIso8601String(),
      'consecutiveErrors': _consecutiveErrors,
      'healthConnectAvailable': false,
      'isAuthorized': false,
      'canFetchData': false,
      'todaySteps': 0,
    };

    try {
      diagnostics['healthConnectAvailable'] = await isHealthConnectAvailable();
      if (diagnostics['healthConnectAvailable']) {
        diagnostics['isAuthorized'] = await isAuthorized();
      }
      if (diagnostics['isAuthorized']) {
        diagnostics['canFetchData'] = await canFetchData();
      }
      if (diagnostics['canFetchData']) {
        diagnostics['todaySteps'] = await getTodaySteps();
      }
    } catch (e) {
      diagnostics['error'] = e.toString();
    }

    return diagnostics;
  }

  // ═══════════════════════════════════════════
  // 🔐 CONNECT TO GOOGLE FIT — FIXED!
  // ═══════════════════════════════════════════
  Future<bool> connect() async {
    try {
      debugPrint('🔄 Connecting to Google Fit...');

      // ✅ FIX: Try silent sign in first (no popup)
      _currentUser = await _googleSignIn.signInSilently();

      // ✅ FIX: If silent fails, DON'T auto popup
      // User should manually tap "Connect Google Fit" button
      if (_currentUser == null) {
        debugPrint('⚠️ Google Fit: Silent sign-in failed, needs manual connect');
        _isConnected = false;
        return false;
      }

      // Get access token
      final auth = await _currentUser!.authentication;
      _accessToken = auth.accessToken;

      if (_accessToken == null) {
        debugPrint('❌ Failed to get access token');
        _isConnected = false;
        return false;
      }

      _isConnected = true;
      _consecutiveErrors = 0;
      debugPrint('✅ Google Fit connected: ${_currentUser!.email}');
      return true;
    } catch (e) {
      debugPrint('❌ Google Fit connect error: $e');
      _isConnected = false;
      _consecutiveErrors++;
      return false;
    }
  }

  // ═══════════════════════════════════════════
  // 🔐 MANUAL CONNECT — User taps button
  // ═══════════════════════════════════════════
  Future<bool> manualConnect() async {
    try {
      debugPrint('🔄 Manual Google Fit connection...');

      // ✅ This will show Google Sign-in popup
      _currentUser = await _googleSignIn.signIn();

      if (_currentUser == null) {
        debugPrint('❌ Google Sign-in cancelled by user');
        _isConnected = false;
        return false;
      }

      // Get access token
      final auth = await _currentUser!.authentication;
      _accessToken = auth.accessToken;

      if (_accessToken == null) {
        debugPrint('❌ Failed to get access token');
        _isConnected = false;
        return false;
      }

      _isConnected = true;
      _consecutiveErrors = 0;
      debugPrint('✅ Google Fit manually connected: ${_currentUser!.email}');
      return true;
    } catch (e) {
      debugPrint('❌ Manual connect error: $e');
      _isConnected = false;
      _consecutiveErrors++;
      return false;
    }
  }

  // ═══════════════════════════════════════════
  // 🔄 REFRESH TOKEN
  // ═══════════════════════════════════════════
  Future<bool> _refreshToken() async {
    try {
      if (_currentUser == null) {
        _currentUser = await _googleSignIn.signInSilently();
        if (_currentUser == null) {
          return false;
        }
      }

      final auth = await _currentUser!.authentication;
      _accessToken = auth.accessToken;

      if (_accessToken != null) {
        _consecutiveErrors = 0;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      _consecutiveErrors++;
      return false;
    }
  }

  // ═══════════════════════════════════════════
  // 👣 GET TODAY'S STEPS
  // ═══════════════════════════════════════════
  Future<int> getTodaySteps() async {
    if (!_isConnected) {
      final connected = await connect();
      if (!connected) return 0;
    }

    try {
      await _refreshToken();

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final startMillis = startOfDay.millisecondsSinceEpoch;
      final endMillis = now.millisecondsSinceEpoch;

      final response = await http.post(
        Uri.parse(
            'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'aggregateBy': [
            {
              'dataTypeName': 'com.google.step_count.delta',
              'dataSourceId':
              'derived:com.google.step_count.delta:com.google.android.gms:estimated_steps',
            }
          ],
          'bucketByTime': {'durationMillis': endMillis - startMillis},
          'startTimeMillis': startMillis,
          'endTimeMillis': endMillis,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int totalSteps = _parseStepsFromResponse(data);
        _lastSuccessfulFetch = DateTime.now();
        _consecutiveErrors = 0;
        debugPrint('📊 Google Fit today steps: $totalSteps');
        return totalSteps;
      } else if (response.statusCode == 401) {
        debugPrint('🔄 Token expired, refreshing...');
        final refreshed = await _refreshToken();
        if (refreshed) {
          return await _retryGetTodaySteps();
        }
        _consecutiveErrors++;
        return 0;
      } else {
        debugPrint('❌ Google Fit API error: ${response.statusCode}');
        _consecutiveErrors++;
        return 0;
      }
    } catch (e) {
      debugPrint('❌ Get today steps error: $e');
      _consecutiveErrors++;
      return 0;
    }
  }

  Future<int> _retryGetTodaySteps() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final startMillis = startOfDay.millisecondsSinceEpoch;
      final endMillis = now.millisecondsSinceEpoch;

      final response = await http.post(
        Uri.parse(
            'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'aggregateBy': [
            {
              'dataTypeName': 'com.google.step_count.delta',
              'dataSourceId':
              'derived:com.google.step_count.delta:com.google.android.gms:estimated_steps',
            }
          ],
          'bucketByTime': {'durationMillis': endMillis - startMillis},
          'startTimeMillis': startMillis,
          'endTimeMillis': endMillis,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _lastSuccessfulFetch = DateTime.now();
        _consecutiveErrors = 0;
        return _parseStepsFromResponse(data);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════
  // 📅 GET WEEKLY STEPS
  // ═══════════════════════════════════════════
  Future<List<int>> getWeeklySteps() async {
    if (!_isConnected) {
      final connected = await connect();
      if (!connected) return List.filled(7, 0);
    }

    try {
      await _refreshToken();

      final now = DateTime.now();
      final sevenDaysAgo = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));

      final startMillis = sevenDaysAgo.millisecondsSinceEpoch;
      final endMillis = now.millisecondsSinceEpoch;

      final response = await http.post(
        Uri.parse(
            'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'aggregateBy': [
            {
              'dataTypeName': 'com.google.step_count.delta',
              'dataSourceId':
              'derived:com.google.step_count.delta:com.google.android.gms:estimated_steps',
            }
          ],
          'bucketByTime': {'durationMillis': 86400000},
          'startTimeMillis': startMillis,
          'endTimeMillis': endMillis,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<int> weeklySteps = _parseWeeklyStepsFromResponse(data);
        _lastSuccessfulFetch = DateTime.now();
        _consecutiveErrors = 0;
        return weeklySteps;
      } else {
        _consecutiveErrors++;
        return List.filled(7, 0);
      }
    } catch (e) {
      _consecutiveErrors++;
      return List.filled(7, 0);
    }
  }

  // ═══════════════════════════════════════════
  // 🔥 GET TODAY'S CALORIES BURNED
  // ═══════════════════════════════════════════
  Future<double> getTodayCalories() async {
    if (!_isConnected) {
      final connected = await connect();
      if (!connected) return 0;
    }

    try {
      await _refreshToken();

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final startMillis = startOfDay.millisecondsSinceEpoch;
      final endMillis = now.millisecondsSinceEpoch;

      final response = await http.post(
        Uri.parse(
            'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'aggregateBy': [
            {'dataTypeName': 'com.google.calories.expended'}
          ],
          'bucketByTime': {'durationMillis': endMillis - startMillis},
          'startTimeMillis': startMillis,
          'endTimeMillis': endMillis,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double calories = _parseCaloriesFromResponse(data);
        _lastSuccessfulFetch = DateTime.now();
        return calories;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════
  // 📏 GET TODAY'S DISTANCE
  // ═══════════════════════════════════════════
  Future<double> getTodayDistance() async {
    if (!_isConnected) {
      final connected = await connect();
      if (!connected) return 0;
    }

    try {
      await _refreshToken();

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final startMillis = startOfDay.millisecondsSinceEpoch;
      final endMillis = now.millisecondsSinceEpoch;

      final response = await http.post(
        Uri.parse(
            'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'aggregateBy': [
            {'dataTypeName': 'com.google.distance.delta'}
          ],
          'bucketByTime': {'durationMillis': endMillis - startMillis},
          'startTimeMillis': startMillis,
          'endTimeMillis': endMillis,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double distance = _parseDistanceFromResponse(data);
        _lastSuccessfulFetch = DateTime.now();
        return distance / 1000;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════
  // 📊 GET ALL TODAY'S DATA
  // ═══════════════════════════════════════════
  Future<Map<String, dynamic>> getTodayData() async {
    final steps = await getTodaySteps();
    final calories = await getTodayCalories();
    final distance = await getTodayDistance();

    return {
      'steps': steps,
      'calories': calories,
      'distance': distance,
      'isConnected': _isConnected,
      'email': _currentUser?.email,
      'lastFetch': _lastSuccessfulFetch?.toIso8601String(),
    };
  }

  // ═══════════════════════════════════════════
  // 🔧 PARSE HELPERS
  // ═══════════════════════════════════════════
  int _parseStepsFromResponse(Map<String, dynamic> data) {
    int totalSteps = 0;
    try {
      final buckets = data['bucket'] as List?;
      if (buckets != null) {
        for (var bucket in buckets) {
          final datasets = bucket['dataset'] as List?;
          if (datasets != null) {
            for (var dataset in datasets) {
              final points = dataset['point'] as List?;
              if (points != null) {
                for (var point in points) {
                  final values = point['value'] as List?;
                  if (values != null && values.isNotEmpty) {
                    totalSteps += (values[0]['intVal'] as int?) ?? 0;
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Parse steps error: $e');
    }
    return totalSteps;
  }

  List<int> _parseWeeklyStepsFromResponse(Map<String, dynamic> data) {
    List<int> weeklySteps = [];
    try {
      final buckets = data['bucket'] as List?;
      if (buckets != null) {
        for (var bucket in buckets) {
          int daySteps = 0;
          final datasets = bucket['dataset'] as List?;
          if (datasets != null) {
            for (var dataset in datasets) {
              final points = dataset['point'] as List?;
              if (points != null) {
                for (var point in points) {
                  final values = point['value'] as List?;
                  if (values != null && values.isNotEmpty) {
                    daySteps += (values[0]['intVal'] as int?) ?? 0;
                  }
                }
              }
            }
          }
          weeklySteps.add(daySteps);
        }
      }
    } catch (e) {
      debugPrint('❌ Parse weekly steps error: $e');
    }
    while (weeklySteps.length < 7) {
      weeklySteps.insert(0, 0);
    }
    return weeklySteps.take(7).toList();
  }

  double _parseCaloriesFromResponse(Map<String, dynamic> data) {
    double totalCalories = 0;
    try {
      final buckets = data['bucket'] as List?;
      if (buckets != null) {
        for (var bucket in buckets) {
          final datasets = bucket['dataset'] as List?;
          if (datasets != null) {
            for (var dataset in datasets) {
              final points = dataset['point'] as List?;
              if (points != null) {
                for (var point in points) {
                  final values = point['value'] as List?;
                  if (values != null && values.isNotEmpty) {
                    totalCalories += (values[0]['fpVal'] as double?) ?? 0;
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Parse calories error: $e');
    }
    return totalCalories;
  }

  double _parseDistanceFromResponse(Map<String, dynamic> data) {
    double totalDistance = 0;
    try {
      final buckets = data['bucket'] as List?;
      if (buckets != null) {
        for (var bucket in buckets) {
          final datasets = bucket['dataset'] as List?;
          if (datasets != null) {
            for (var dataset in datasets) {
              final points = dataset['point'] as List?;
              if (points != null) {
                for (var point in points) {
                  final values = point['value'] as List?;
                  if (values != null && values.isNotEmpty) {
                    totalDistance += (values[0]['fpVal'] as double?) ?? 0;
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Parse distance error: $e');
    }
    return totalDistance;
  }

  // ═══════════════════════════════════════════
  // 🚪 DISCONNECT
  // ═══════════════════════════════════════════
  Future<void> disconnect() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _accessToken = null;
      _isConnected = false;
      _lastSuccessfulFetch = null;
      _consecutiveErrors = 0;
      debugPrint('🚪 Google Fit disconnected');
    } catch (e) {
      debugPrint('❌ Disconnect error: $e');
    }
  }
}