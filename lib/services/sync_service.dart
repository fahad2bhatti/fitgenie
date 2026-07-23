import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'connectivity_service.dart';
import 'local_storage_service.dart';

class SyncService {
  // Singleton
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorage = LocalStorageService();
  final ConnectivityService _connectivity = ConnectivityService();

  bool _isSyncing = false;

  // An unknown/unrecognized item is dropped (with a loud log) only after
  // this many failed attempts, so a genuinely bad item can't grow the
  // queue forever, but a transient failure still gets retried.
  static const int _maxRetries = 5;

  // Sync all pending changes
  Future<void> syncPendingChanges() async {
    if (_isSyncing) return;
    if (!_connectivity.isOnline) return;

    _isSyncing = true;
    debugPrint('🔄 Starting sync...');

    try {
      // Snapshot of the queue at the start of this run. Each item carries
      // its own stable 'id', so removal/retry never depends on list
      // position — earlier items failing no longer blocks later ones.
      final pendingList = _localStorage.getPendingSyncs();

      for (final pending in pendingList) {
        final id = pending['id'] as String?;
        final type = pending['type'] as String? ?? 'unknown';
        final retryCount = (pending['retryCount'] as int?) ?? 0;
        final data = Map<String, dynamic>.from(pending['data'] ?? {});

        try {
          await _syncItem(type, data);
          if (id != null) {
            await _localStorage.removePendingSyncById(id);
          } else {
            // Legacy item queued before ids existed — best effort cleanup.
            await _localStorage.removePendingSync(0);
          }
          debugPrint('✅ Synced: $type');
        } catch (e) {
          debugPrint('❌ Sync failed for $type: $e');

          if (id == null) {
            // No stable id to retry against — drop it rather than risk
            // looping on it forever or deleting the wrong item.
            debugPrint('⚠️ Dropping legacy pending item with no id ($type)');
            continue;
          }

          if (retryCount + 1 >= _maxRetries) {
            debugPrint(
              '🛑 Giving up on pending sync "$type" after $_maxRetries attempts — dropping to avoid infinite retry: $e',
            );
            await _localStorage.removePendingSyncById(id);
          } else {
            await _localStorage.incrementRetryCountById(id);
          }
          // Continue with the rest of the queue instead of aborting the
          // whole sync run on one bad/unreachable item.
        }
      }

      debugPrint('🔄 Sync complete!');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncItem(String type, Map<String, dynamic> data) async {
    switch (type) {
      case 'nutrition_log':
        await _syncNutritionLog(data);
        break;
      case 'workout':
        await _syncWorkout(data);
        break;
      case 'weight_log':
        await _syncWeightLog(data);
        break;
      default:
      // Previously fell through silently and was then marked "synced"
      // by the caller, permanently losing the data. Throwing here means
      // it's retried and, if genuinely unrecognized, eventually dropped
      // with a loud log instead of vanishing quietly.
        throw Exception('Unknown pending sync type: "$type"');
    }
  }

  Future<void> _syncNutritionLog(Map<String, dynamic> data) async {
    final userId = data['userId'] as String;
    final date = data['date'] as String;
    final calories = data['calories'] as int;
    final protein = data['protein'] as int;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyLogs')
        .doc(date)
        .set({
      'calories': calories,
      'protein': protein,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _syncWorkout(Map<String, dynamic> data) async {
    final userId = data['userId'] as String;
    final workoutId = data['workoutId'] as String;
    final workoutData = Map<String, dynamic>.from(data['workout']);

    // Remove local-only fields
    workoutData.remove('isLocalOnly');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .set(workoutData, SetOptions(merge: true));
  }

  Future<void> _syncWeightLog(Map<String, dynamic> data) async {
    final userId = data['userId'] as String;
    final date = data['date'] as String;
    final weight = data['weight'] as double;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('weightLogs')
        .doc(date)
        .set({
      'weight': weight,
      'date': FieldValue.serverTimestamp(),
    });
  }

  // Listen to connectivity and auto-sync
  void startAutoSync() {
    _connectivity.addListener(() {
      if (_connectivity.isOnline) {
        debugPrint('📶 Back online! Starting sync...');
        syncPendingChanges();
      }
    });
  }
}