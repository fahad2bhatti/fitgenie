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

  // Sync all pending changes
  Future<void> syncPendingChanges() async {
    if (_isSyncing) return;
    if (!_connectivity.isOnline) return;

    _isSyncing = true;
    debugPrint('🔄 Starting sync...');

    try {
      final pendingList = _localStorage.getPendingSyncs();

      for (int i = 0; i < pendingList.length; i++) {
        final pending = pendingList[i];
        final type = pending['type'] as String;
        final data = Map<String, dynamic>.from(pending['data']);

        try {
          await _syncItem(type, data);
          await _localStorage.removePendingSync(0); // Always remove first
          debugPrint('✅ Synced: $type');
        } catch (e) {
          debugPrint('❌ Sync failed for $type: $e');
          // Don't remove, will retry next time
          break;
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