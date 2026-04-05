import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'connectivity_service.dart';
import 'local_storage_service.dart';

class WorkoutService {
  final FirebaseFirestore _db;
  final ConnectivityService _connectivity;
  final LocalStorageService _localStorage;
  final Uuid _uuid;

  WorkoutService({
    FirebaseFirestore? db,
    ConnectivityService? connectivity,
    LocalStorageService? localStorage,
  })  : _db = db ?? FirebaseFirestore.instance,
        _connectivity = connectivity ?? ConnectivityService(),
        _localStorage = localStorage ?? LocalStorageService(),
        _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _sessionsRef(String uid) {
    return _db.collection('users').doc(uid).collection('workouts');
  }

  // ==========================================
  // 🏋️ START SESSION (Online + Offline)
  // ==========================================

  Future<String> startSession(String uid, {String? type}) async {
    debugPrint('WorkoutService.startSession called for uid=$uid');

    final sessionId = _uuid.v4();
    final now = DateTime.now();

    final workoutData = {
      'id': sessionId,
      'type': type ?? 'Workout',
      'startedAt': now.toIso8601String(),
      'endedAt': null,
      'totalSets': 0,
      'sets': <Map<String, dynamic>>[],
      'status': 'active',
      'isLocalOnly': true, // Flag for sync
    };

    // Save locally first
    await _localStorage.saveWorkout(uid, sessionId, workoutData);
    debugPrint('💾 Workout saved locally: $sessionId');

    // Try to sync to Firebase
    if (_connectivity.isOnline) {
      try {
        final firebaseData = Map<String, dynamic>.from(workoutData);
        firebaseData['startedAt'] = FieldValue.serverTimestamp();
        firebaseData.remove('isLocalOnly');
        firebaseData.remove('id');

        await _sessionsRef(uid).doc(sessionId).set(firebaseData);

        // Update local to remove isLocalOnly flag
        workoutData['isLocalOnly'] = false;
        await _localStorage.saveWorkout(uid, sessionId, workoutData);

        debugPrint('✅ Workout synced to Firebase: $sessionId');
      } catch (e) {
        debugPrint('⚠️ Firebase sync failed, will sync later: $e');
        await _addWorkoutToPendingSync(uid, sessionId, workoutData);
      }
    } else {
      await _addWorkoutToPendingSync(uid, sessionId, workoutData);
      debugPrint('📝 Workout added to pending sync (offline)');
    }

    return sessionId;
  }

  // ==========================================
  // ✅ END SESSION (Online + Offline)
  // ==========================================

  Future<void> endSession({
    required String uid,
    required String sessionId,
  }) async {
    final now = DateTime.now();

    // Update locally first
    final localWorkout = _localStorage.getWorkout(uid, sessionId);
    if (localWorkout != null) {
      localWorkout['endedAt'] = now.toIso8601String();
      localWorkout['status'] = 'completed';

      // Calculate duration
      final startedAt = DateTime.tryParse(localWorkout['startedAt'] ?? '');
      if (startedAt != null) {
        localWorkout['duration'] = now.difference(startedAt).inMinutes;
      }

      await _localStorage.saveWorkout(uid, sessionId, localWorkout);
      debugPrint('💾 Workout ended locally: $sessionId');
    }

    // Try to sync
    if (_connectivity.isOnline) {
      try {
        await _sessionsRef(uid).doc(sessionId).update({
          'endedAt': FieldValue.serverTimestamp(),
          'status': 'completed',
          'duration': localWorkout?['duration'] ?? 0,
        });
        debugPrint('✅ Workout end synced to Firebase');
      } catch (e) {
        debugPrint('⚠️ End session sync failed: $e');
      }
    }
  }

  // ==========================================
  // ➕ ADD SET (Online + Offline)
  // ==========================================

  Future<void> addSet({
    required String uid,
    required String sessionId,
    required String exercise,
    required double weight,
    required int reps,
  }) async {
    final now = DateTime.now();

    final newSet = {
      'exercise': exercise,
      'weight': weight,
      'reps': reps,
      'timestamp': now.toIso8601String(),
    };

    // Update locally first
    final localWorkout = _localStorage.getWorkout(uid, sessionId);
    if (localWorkout != null) {
      final sets = List<Map<String, dynamic>>.from(
          (localWorkout['sets'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []
      );
      sets.add(newSet);

      localWorkout['sets'] = sets;
      localWorkout['totalSets'] = sets.length;

      await _localStorage.saveWorkout(uid, sessionId, localWorkout);
      debugPrint('💾 Set added locally: $exercise');
    }

    // Try to sync
    if (_connectivity.isOnline) {
      try {
        final docRef = _sessionsRef(uid).doc(sessionId);

        await _db.runTransaction((tx) async {
          final snap = await tx.get(docRef);
          final data = snap.data() ?? <String, dynamic>{};
          final List<dynamic> sets = List.from(data['sets'] ?? []);

          final firebaseSet = Map<String, dynamic>.from(newSet);
          firebaseSet['timestamp'] = FieldValue.serverTimestamp();
          sets.add(firebaseSet);

          final int totalSets = sets.length;

          tx.set(
            docRef,
            {
              'sets': sets,
              'totalSets': totalSets,
            },
            SetOptions(merge: true),
          );
        });
        debugPrint('✅ Set synced to Firebase');
      } catch (e) {
        debugPrint('⚠️ Set sync failed: $e');
      }
    }
  }

  // ==========================================
  // 📋 GET RECENT WORKOUTS (Online + Offline)
  // ==========================================

  Future<List<Map<String, dynamic>>> getRecentWorkouts(
      String uid, {
        int limit = 5,
      }) async {
    // Try online first
    if (_connectivity.isOnline) {
      try {
        final query = await _sessionsRef(uid)
            .orderBy('startedAt', descending: true)
            .limit(limit)
            .get();

        final workouts = query.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Cache locally
        for (var workout in workouts) {
          await _localStorage.saveWorkout(uid, workout['id'], workout);
        }

        debugPrint('✅ Recent workouts fetched from Firebase');
        return workouts;
      } catch (e) {
        debugPrint('⚠️ Firebase error, falling back to cache: $e');
      }
    }

    // Offline: Get from local storage
    final cached = _localStorage.getRecentWorkouts(uid, limit: limit);
    debugPrint('📦 Recent workouts loaded from cache: ${cached.length}');
    return cached;
  }

  // ==========================================
  // 📊 GET SESSION SETS
  // ==========================================

  Future<List<Map<String, dynamic>>> getSessionSets({
    required String uid,
    required String sessionId,
  }) async {
    // Try local first (faster)
    final localWorkout = _localStorage.getWorkout(uid, sessionId);
    if (localWorkout != null) {
      final sets = (localWorkout['sets'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (sets != null && sets.isNotEmpty) {
        return sets;
      }
    }

    // Try Firebase
    if (_connectivity.isOnline) {
      try {
        final snap = await _sessionsRef(uid).doc(sessionId).get();
        final data = snap.data();
        if (data != null) {
          final List<dynamic> raw = data['sets'] ?? [];
          return raw.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching sets: $e');
      }
    }

    return [];
  }

  // ==========================================
  // 🔍 GET ACTIVE SESSION
  // ==========================================

  Future<String?> getActiveSessionId(String uid) async {
    // Check local first
    final workoutIds = _localStorage.getWorkoutIds(uid);
    for (var id in workoutIds) {
      final workout = _localStorage.getWorkout(uid, id);
      if (workout != null && workout['status'] == 'active') {
        return id;
      }
    }

    // Check Firebase
    if (_connectivity.isOnline) {
      try {
        final q = await _sessionsRef(uid)
            .where('status', isEqualTo: 'active')
            .orderBy('startedAt', descending: true)
            .limit(1)
            .get();

        if (q.docs.isNotEmpty) {
          return q.docs.first.id;
        }
      } catch (e) {
        debugPrint('⚠️ Error checking active session: $e');
      }
    }

    return null;
  }

  // ==========================================
  // 🔄 PENDING SYNC
  // ==========================================

  Future<void> _addWorkoutToPendingSync(
      String uid,
      String workoutId,
      Map<String, dynamic> workout,
      ) async {
    await _localStorage.addPendingSync('workout', {
      'userId': uid,
      'workoutId': workoutId,
      'workout': workout,
    });
  }
}