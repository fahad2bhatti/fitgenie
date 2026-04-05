// lib/services/local_storage_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageService {
  // Singleton
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  // ═══════════════════════════════════════════
  // 🔐 SECURE STORAGE FOR ENCRYPTION KEY
  // ═══════════════════════════════════════════
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _encryptionKeyName = 'fitgenie_hive_encryption_key';

  // Box names
  static const String _userBox = 'user_data';
  static const String _nutritionBox = 'nutrition_data';
  static const String _workoutBox = 'workout_data';
  static const String _pendingSyncBox = 'pending_sync';
  static const String _chatBox = 'chat_history';

  bool _isInitialized = false;
  Uint8List? _encryptionKey;

  // ═══════════════════════════════════════════
  // 🔑 GET OR CREATE ENCRYPTION KEY
  // ═══════════════════════════════════════════
  Future<Uint8List> _getEncryptionKey() async {
    try {
      // Try to get existing key
      final existingKey = await _secureStorage.read(key: _encryptionKeyName);

      if (existingKey != null) {
        debugPrint('🔑 Using existing encryption key');
        return base64Url.decode(existingKey);
      }

      // Generate new 32-byte key for AES-256
      final newKey = Hive.generateSecureKey();

      // Store in secure storage
      await _secureStorage.write(
        key: _encryptionKeyName,
        value: base64Url.encode(newKey),
      );

      debugPrint('🔑 New encryption key generated and stored');
      return Uint8List.fromList(newKey);
    } catch (e) {
      debugPrint('⚠️ Encryption key error: $e');
      // Fallback - generate temporary key (not ideal but prevents crash)
      return Uint8List.fromList(Hive.generateSecureKey());
    }
  }

  // ═══════════════════════════════════════════
  // 🚀 INITIALIZE WITH ENCRYPTION
  // ═══════════════════════════════════════════
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ LocalStorage already initialized');
      return;
    }

    try {
      // Initialize Hive
      await Hive.initFlutter();
      debugPrint('✅ Hive.initFlutter() done');
    } catch (e) {
      debugPrint('⚠️ Hive.initFlutter() error (may be already init): $e');
    }

    // Get encryption key
    _encryptionKey = await _getEncryptionKey();
    final cipher = HiveAesCipher(_encryptionKey!);

    // Open encrypted boxes
    try {
      if (!Hive.isBoxOpen(_userBox)) {
        await Hive.openBox(_userBox, encryptionCipher: cipher);
      }
      if (!Hive.isBoxOpen(_nutritionBox)) {
        await Hive.openBox(_nutritionBox, encryptionCipher: cipher);
      }
      if (!Hive.isBoxOpen(_workoutBox)) {
        await Hive.openBox(_workoutBox, encryptionCipher: cipher);
      }
      if (!Hive.isBoxOpen(_pendingSyncBox)) {
        await Hive.openBox(_pendingSyncBox, encryptionCipher: cipher);
      }
      if (!Hive.isBoxOpen(_chatBox)) {
        await Hive.openBox(_chatBox, encryptionCipher: cipher);
      }
      debugPrint('✅ All encrypted Hive boxes opened');
    } catch (e) {
      debugPrint('❌ Hive box open error: $e');
      // If encryption fails, try to recover by deleting old boxes
      await _recoverFromEncryptionError();
    }

    _isInitialized = true;
    debugPrint('💾 LocalStorage initialized with encryption 🔐');
  }

  // ═══════════════════════════════════════════
  // 🔧 RECOVER FROM ENCRYPTION ERROR
  // ═══════════════════════════════════════════
  Future<void> _recoverFromEncryptionError() async {
    debugPrint('🔧 Attempting recovery from encryption error...');

    try {
      // Delete corrupted boxes
      await Hive.deleteBoxFromDisk(_userBox);
      await Hive.deleteBoxFromDisk(_nutritionBox);
      await Hive.deleteBoxFromDisk(_workoutBox);
      await Hive.deleteBoxFromDisk(_pendingSyncBox);
      await Hive.deleteBoxFromDisk(_chatBox);

      // Generate new encryption key
      final newKey = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _encryptionKeyName,
        value: base64Url.encode(newKey),
      );
      _encryptionKey = Uint8List.fromList(newKey);

      final cipher = HiveAesCipher(_encryptionKey!);

      // Reopen boxes
      await Hive.openBox(_userBox, encryptionCipher: cipher);
      await Hive.openBox(_nutritionBox, encryptionCipher: cipher);
      await Hive.openBox(_workoutBox, encryptionCipher: cipher);
      await Hive.openBox(_pendingSyncBox, encryptionCipher: cipher);
      await Hive.openBox(_chatBox, encryptionCipher: cipher);

      debugPrint('✅ Recovery successful - boxes recreated with new key');
    } catch (e) {
      debugPrint('❌ Recovery failed: $e');
    }
  }

  // ═══════════════════════════════════════════
  // 🛡️ DATA SANITIZATION
  // ═══════════════════════════════════════════
  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      // Clean key
      final cleanKey = key.replaceAll(RegExp(r'[^\w]'), '');

      if (value is String) {
        // Remove HTML and limit length
        String cleanValue = value
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .trim();
        if (cleanValue.length > 10000) {
          cleanValue = cleanValue.substring(0, 10000);
        }
        sanitized[cleanKey] = cleanValue;
      } else if (value is num) {
        // Clamp numbers to reasonable range
        sanitized[cleanKey] = value.clamp(-999999, 999999);
      } else if (value is List) {
        // Limit list size
        sanitized[cleanKey] = value.take(1000).toList();
      } else if (value is Map) {
        sanitized[cleanKey] = _sanitizeData(Map<String, dynamic>.from(value));
      } else {
        sanitized[cleanKey] = value;
      }
    });

    return sanitized;
  }

  // ═══════════════════════════════════════════
  // 📦 SAFE BOX GETTER
  // ═══════════════════════════════════════════
  Box _getBox(String name) {
    if (Hive.isBoxOpen(name)) {
      return Hive.box(name);
    }
    throw Exception('Box $name not opened. Call initialize() first.');
  }

  // ═══════════════════════════════════════════
  // 👤 USER DATA
  // ═══════════════════════════════════════════
  Future<void> saveUserData(String userId, Map<String, dynamic> data) async {
    try {
      // Validate userId
      if (userId.isEmpty || userId.length > 128) {
        debugPrint('❌ Invalid userId');
        return;
      }

      final box = _getBox(_userBox);
      final sanitizedData = _sanitizeData(data);
      sanitizedData['lastUpdated'] = DateTime.now().toIso8601String();

      await box.put(userId, sanitizedData);
      debugPrint('✅ User data saved (encrypted)');
    } catch (e) {
      debugPrint('❌ saveUserData error: $e');
    }
  }

  Map<String, dynamic>? getUserData(String userId) {
    try {
      if (userId.isEmpty) return null;

      final box = _getBox(_userBox);
      final data = box.get(userId);
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      debugPrint('❌ getUserData error: $e');
    }
    return null;
  }

  // ═══════════════════════════════════════════
  // 🍎 NUTRITION DATA
  // ═══════════════════════════════════════════
  Future<void> saveNutritionGoals(String userId, Map<String, int> goals) async {
    try {
      if (userId.isEmpty) return;

      final box = _getBox(_nutritionBox);

      // Validate goals
      final validatedGoals = <String, int>{
        'caloriesGoal': (goals['caloriesGoal'] ?? 2000).clamp(500, 10000),
        'proteinGoal': (goals['proteinGoal'] ?? 100).clamp(10, 500),
        'waterGoal': (goals['waterGoal'] ?? 8).clamp(1, 20),
        'stepsGoal': (goals['stepsGoal'] ?? 10000).clamp(1000, 100000),
      };

      await box.put('${userId}_goals', validatedGoals);
      debugPrint('✅ Nutrition goals saved (encrypted)');
    } catch (e) {
      debugPrint('❌ saveNutritionGoals error: $e');
    }
  }

  Map<String, int>? getNutritionGoals(String userId) {
    try {
      if (userId.isEmpty) return null;

      final box = _getBox(_nutritionBox);
      final data = box.get('${userId}_goals');
      if (data != null) {
        return Map<String, int>.from(data);
      }
    } catch (e) {
      debugPrint('❌ getNutritionGoals error: $e');
    }
    return null;
  }

  Future<void> saveDailyLog(String userId, String date, Map<String, int> log) async {
    try {
      if (userId.isEmpty || date.isEmpty) return;

      // Validate date format (YYYY-MM-DD)
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
        debugPrint('❌ Invalid date format');
        return;
      }

      final box = _getBox(_nutritionBox);

      // Validate log values
      final validatedLog = <String, int>{
        'calories': (log['calories'] ?? 0).clamp(0, 10000),
        'protein': (log['protein'] ?? 0).clamp(0, 1000),
        'water': (log['water'] ?? 0).clamp(0, 50),
        'steps': (log['steps'] ?? 0).clamp(0, 200000),
      };

      await box.put('${userId}_log_$date', validatedLog);
    } catch (e) {
      debugPrint('❌ saveDailyLog error: $e');
    }
  }

  Map<String, int>? getDailyLog(String userId, String date) {
    try {
      if (userId.isEmpty || date.isEmpty) return null;

      final box = _getBox(_nutritionBox);
      final data = box.get('${userId}_log_$date');
      if (data != null) {
        return Map<String, int>.from(data);
      }
    } catch (e) {
      debugPrint('❌ getDailyLog error: $e');
    }
    return null;
  }

  // ═══════════════════════════════════════════
  // 💪 WORKOUT DATA
  // ═══════════════════════════════════════════
  Future<void> saveWorkout(String userId, String workoutId, Map<String, dynamic> workout) async {
    try {
      if (userId.isEmpty || workoutId.isEmpty) return;

      final box = _getBox(_workoutBox);
      final sanitizedWorkout = _sanitizeData(workout);
      sanitizedWorkout['savedAt'] = DateTime.now().toIso8601String();
      sanitizedWorkout['synced'] = false;

      await box.put('${userId}_$workoutId', sanitizedWorkout);

      // Save to workout list
      List<String> workoutIds = getWorkoutIds(userId);
      if (!workoutIds.contains(workoutId)) {
        workoutIds.insert(0, workoutId);
        // Limit to 100 workouts locally
        if (workoutIds.length > 100) {
          workoutIds = workoutIds.sublist(0, 100);
        }
        await box.put('${userId}_workout_ids', workoutIds);
      }

      debugPrint('✅ Workout saved (encrypted)');
    } catch (e) {
      debugPrint('❌ saveWorkout error: $e');
    }
  }

  List<String> getWorkoutIds(String userId) {
    try {
      if (userId.isEmpty) return [];

      final box = _getBox(_workoutBox);
      final data = box.get('${userId}_workout_ids');
      if (data != null) {
        return List<String>.from(data);
      }
    } catch (e) {
      debugPrint('❌ getWorkoutIds error: $e');
    }
    return [];
  }

  Map<String, dynamic>? getWorkout(String userId, String workoutId) {
    try {
      if (userId.isEmpty || workoutId.isEmpty) return null;

      final box = _getBox(_workoutBox);
      final data = box.get('${userId}_$workoutId');
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      debugPrint('❌ getWorkout error: $e');
    }
    return null;
  }

  List<Map<String, dynamic>> getRecentWorkouts(String userId, {int limit = 5}) {
    if (userId.isEmpty) return [];

    final workoutIds = getWorkoutIds(userId);
    final workouts = <Map<String, dynamic>>[];

    // Clamp limit
    final safeLimit = limit.clamp(1, 50);

    for (int i = 0; i < workoutIds.length && workouts.length < safeLimit; i++) {
      final workout = getWorkout(userId, workoutIds[i]);
      if (workout != null) {
        workouts.add(workout);
      }
    }

    return workouts;
  }

  // ═══════════════════════════════════════════
  // 💬 CHAT HISTORY
  // ═══════════════════════════════════════════
  Future<void> saveChatMessage(String userId, String userMessage, String aiResponse) async {
    try {
      if (userId.isEmpty) return;

      final box = _getBox(_chatBox);

      // Get existing chats
      List<Map<String, dynamic>> chats = getChatHistory(userId);

      // Add new message
      chats.add({
        'userMessage': userMessage.substring(0, userMessage.length.clamp(0, 500)),
        'aiResponse': aiResponse.substring(0, aiResponse.length.clamp(0, 2000)),
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Keep only last 50 messages
      if (chats.length > 50) {
        chats = chats.sublist(chats.length - 50);
      }

      await box.put('${userId}_chats', chats);
    } catch (e) {
      debugPrint('❌ saveChatMessage error: $e');
    }
  }

  List<Map<String, dynamic>> getChatHistory(String userId) {
    try {
      if (userId.isEmpty) return [];

      final box = _getBox(_chatBox);
      final data = box.get('${userId}_chats');
      if (data != null) {
        return List<Map<String, dynamic>>.from(
          (data as List).map((e) => Map<String, dynamic>.from(e)),
        );
      }
    } catch (e) {
      debugPrint('❌ getChatHistory error: $e');
    }
    return [];
  }

  // ═══════════════════════════════════════════
  // 🔄 PENDING SYNC (For offline changes)
  // ═══════════════════════════════════════════
  Future<void> addPendingSync(String type, Map<String, dynamic> data) async {
    try {
      if (type.isEmpty) return;

      final box = _getBox(_pendingSyncBox);

      List<Map<String, dynamic>> pending = getPendingSyncs();

      // Limit pending syncs
      if (pending.length >= 100) {
        debugPrint('⚠️ Too many pending syncs, removing oldest');
        pending.removeAt(0);
      }

      pending.add({
        'type': type,
        'data': _sanitizeData(data),
        'timestamp': DateTime.now().toIso8601String(),
        'retryCount': 0,
      });

      await box.put('pending_list', pending);
      debugPrint('📝 Added pending sync: $type');
    } catch (e) {
      debugPrint('❌ addPendingSync error: $e');
    }
  }

  List<Map<String, dynamic>> getPendingSyncs() {
    try {
      final box = _getBox(_pendingSyncBox);
      final data = box.get('pending_list');
      if (data != null) {
        return List<Map<String, dynamic>>.from(
          (data as List).map((e) => Map<String, dynamic>.from(e)),
        );
      }
    } catch (e) {
      debugPrint('❌ getPendingSyncs error: $e');
    }
    return [];
  }

  Future<void> clearPendingSyncs() async {
    try {
      final box = _getBox(_pendingSyncBox);
      await box.delete('pending_list');
      debugPrint('✅ Cleared pending syncs');
    } catch (e) {
      debugPrint('❌ clearPendingSyncs error: $e');
    }
  }

  Future<void> removePendingSync(int index) async {
    try {
      final box = _getBox(_pendingSyncBox);
      List<Map<String, dynamic>> pending = getPendingSyncs();
      if (index >= 0 && index < pending.length) {
        pending.removeAt(index);
        await box.put('pending_list', pending);
      }
    } catch (e) {
      debugPrint('❌ removePendingSync error: $e');
    }
  }

  Future<void> incrementRetryCount(int index) async {
    try {
      final box = _getBox(_pendingSyncBox);
      List<Map<String, dynamic>> pending = getPendingSyncs();
      if (index >= 0 && index < pending.length) {
        pending[index]['retryCount'] = (pending[index]['retryCount'] ?? 0) + 1;
        await box.put('pending_list', pending);
      }
    } catch (e) {
      debugPrint('❌ incrementRetryCount error: $e');
    }
  }

  // ═══════════════════════════════════════════
  // 🧹 CLEAR ALL DATA
  // ═══════════════════════════════════════════
  Future<void> clearAll() async {
    try {
      if (Hive.isBoxOpen(_userBox)) await Hive.box(_userBox).clear();
      if (Hive.isBoxOpen(_nutritionBox)) await Hive.box(_nutritionBox).clear();
      if (Hive.isBoxOpen(_workoutBox)) await Hive.box(_workoutBox).clear();
      if (Hive.isBoxOpen(_pendingSyncBox)) await Hive.box(_pendingSyncBox).clear();
      if (Hive.isBoxOpen(_chatBox)) await Hive.box(_chatBox).clear();
      debugPrint('🧹 All local data cleared');
    } catch (e) {
      debugPrint('❌ clearAll error: $e');
    }
  }

  Future<void> clearUserData(String userId) async {
    try {
      if (userId.isEmpty) return;

      // Clear user box
      if (Hive.isBoxOpen(_userBox)) {
        final userBox = Hive.box(_userBox);
        await userBox.delete(userId);
      }

      // Clear nutrition data
      if (Hive.isBoxOpen(_nutritionBox)) {
        final nutritionBox = Hive.box(_nutritionBox);
        final nutritionKeys = nutritionBox.keys
            .where((k) => k.toString().startsWith(userId))
            .toList();
        for (var key in nutritionKeys) {
          await nutritionBox.delete(key);
        }
      }

      // Clear workout data
      if (Hive.isBoxOpen(_workoutBox)) {
        final workoutBox = Hive.box(_workoutBox);
        final workoutKeys = workoutBox.keys
            .where((k) => k.toString().startsWith(userId))
            .toList();
        for (var key in workoutKeys) {
          await workoutBox.delete(key);
        }
      }

      // Clear chat history
      if (Hive.isBoxOpen(_chatBox)) {
        final chatBox = Hive.box(_chatBox);
        await chatBox.delete('${userId}_chats');
      }

      debugPrint('🧹 User data cleared for: $userId');
    } catch (e) {
      debugPrint('❌ clearUserData error: $e');
    }
  }

  // ═══════════════════════════════════════════
  // 🔐 DELETE ENCRYPTION KEY (Full reset)
  // ═══════════════════════════════════════════
  Future<void> fullReset() async {
    try {
      // Clear all boxes
      await clearAll();

      // Delete encryption key
      await _secureStorage.delete(key: _encryptionKeyName);

      // Close all boxes
      await Hive.close();

      _isInitialized = false;
      _encryptionKey = null;

      debugPrint('🔐 Full reset complete - encryption key deleted');
    } catch (e) {
      debugPrint('❌ fullReset error: $e');
    }
  }
}
