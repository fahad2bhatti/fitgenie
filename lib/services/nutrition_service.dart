import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'connectivity_service.dart';
import 'local_storage_service.dart';

// ==========================================
// 📦 MODELS
// ==========================================

class NutritionGoals {
  final int caloriesGoal;
  final int proteinGoal;
  final int carbsGoal;
  final int fatsGoal;
  final int waterGoal;

  const NutritionGoals({
    required this.caloriesGoal,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatsGoal,
    required this.waterGoal,
  });

  Map<String, dynamic> toMap() => {
    'caloriesGoal': caloriesGoal,
    'proteinGoal': proteinGoal,
    'carbsGoal': carbsGoal,
    'fatsGoal': fatsGoal,
    'waterGoal': waterGoal,
  };

  static NutritionGoals fromMap(Map<String, dynamic>? map) {
    return NutritionGoals(
      caloriesGoal: (map?['caloriesGoal'] is num)
          ? (map!['caloriesGoal'] as num).toInt()
          : 2400,
      proteinGoal: (map?['proteinGoal'] is num)
          ? (map!['proteinGoal'] as num).toInt()
          : 180,
      carbsGoal: (map?['carbsGoal'] is num)
          ? (map!['carbsGoal'] as num).toInt()
          : 250,
      fatsGoal: (map?['fatsGoal'] is num)
          ? (map!['fatsGoal'] as num).toInt()
          : 70,
      waterGoal: (map?['waterGoal'] is num)
          ? (map!['waterGoal'] as num).toInt()
          : 8,
    );
  }
}

class DailyNutritionLog {
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final int water;

  const DailyNutritionLog({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.water,
  });

  Map<String, dynamic> toMap() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fats': fats,
    'water': water,
  };

  static DailyNutritionLog fromMap(Map<String, dynamic>? map) {
    return DailyNutritionLog(
      calories: (map?['calories'] is num)
          ? (map!['calories'] as num).toInt()
          : 0,
      protein: (map?['protein'] is num)
          ? (map!['protein'] as num).toInt()
          : 0,
      carbs: (map?['carbs'] is num)
          ? (map!['carbs'] as num).toInt()
          : 0,
      fats: (map?['fats'] is num)
          ? (map!['fats'] as num).toInt()
          : 0,
      water: (map?['water'] is num)
          ? (map!['water'] as num).toInt()
          : 0,
    );
  }
}

class MealEntry {
  final String? id;
  final String name;
  final String quantity;
  final String mealType; // breakfast, lunch, dinner, snacks
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final String source; // manual | scanner | recent

  const MealEntry({
    this.id,
    required this.name,
    required this.quantity,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.source,
  });

  Map<String, dynamic> toMap({
    required String userId,
    required String dateKey,
    bool withCreatedAt = true,
  }) {
    return {
      'userId': userId,
      'dateKey': dateKey,
      'name': name,
      'quantity': quantity,
      'mealType': mealType,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'source': source,
      'updatedAt': FieldValue.serverTimestamp(),
      if (withCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static MealEntry fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MealEntry(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      quantity: (data['quantity'] ?? '').toString(),
      mealType: (data['mealType'] ?? 'snacks').toString(),
      calories: (data['calories'] is num)
          ? (data['calories'] as num).toInt()
          : 0,
      protein: (data['protein'] is num)
          ? (data['protein'] as num).toInt()
          : 0,
      carbs: (data['carbs'] is num)
          ? (data['carbs'] as num).toInt()
          : 0,
      fats: (data['fats'] is num)
          ? (data['fats'] as num).toInt()
          : 0,
      source: (data['source'] ?? 'manual').toString(),
    );
  }
}

class SavedMealItem {
  final String foodId;
  final String name;
  final String quantity;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final String source;

  const SavedMealItem({
    required this.foodId,
    required this.name,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.source,
  });

  factory SavedMealItem.fromMealEntry(MealEntry entry) {
    return SavedMealItem(
      foodId: entry.id ?? entry.name.toLowerCase().replaceAll(' ', '_'),
      name: entry.name,
      quantity: entry.quantity,
      calories: entry.calories,
      protein: entry.protein,
      carbs: entry.carbs,
      fats: entry.fats,
      source: entry.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'name': name,
      'quantity': quantity,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'source': source,
    };
  }

  factory SavedMealItem.fromMap(Map<String, dynamic> map) {
    return SavedMealItem(
      foodId: (map['foodId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      quantity: (map['quantity'] ?? '').toString(),
      calories: (map['calories'] is num) ? (map['calories'] as num).toInt() : 0,
      protein: (map['protein'] is num) ? (map['protein'] as num).toInt() : 0,
      carbs: (map['carbs'] is num) ? (map['carbs'] as num).toInt() : 0,
      fats: (map['fats'] is num) ? (map['fats'] as num).toInt() : 0,
      source: (map['source'] ?? 'saved').toString(),
    );
  }
}

class SavedMeal {
  final String? id;
  final String name;
  final String mealType;
  final List<SavedMealItem> items;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  const SavedMeal({
    this.id,
    required this.name,
    required this.mealType,
    required this.items,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mealType': mealType,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'items': items.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory SavedMeal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawItems = data['items'] as List<dynamic>? ?? [];

    return SavedMeal(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      mealType: (data['mealType'] ?? 'breakfast').toString(),
      calories: (data['calories'] is num) ? (data['calories'] as num).toInt() : 0,
      protein: (data['protein'] is num) ? (data['protein'] as num).toInt() : 0,
      carbs: (data['carbs'] is num) ? (data['carbs'] as num).toInt() : 0,
      fats: (data['fats'] is num) ? (data['fats'] as num).toInt() : 0,
      items: rawItems
          .map((e) => SavedMealItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

// ==========================================
// 🍎 NUTRITION SERVICE
// ==========================================

class NutritionService {
  final FirebaseFirestore _db;
  final ConnectivityService _connectivity;
  final LocalStorageService _localStorage;

  NutritionService({
    FirebaseFirestore? db,
    ConnectivityService? connectivity,
    LocalStorageService? localStorage,
  })  : _db = db ?? FirebaseFirestore.instance,
        _connectivity = connectivity ?? ConnectivityService(),
        _localStorage = localStorage ?? LocalStorageService();

  String _dateKey([DateTime? date]) =>
      DateFormat('yyyy-MM-dd').format(date ?? DateTime.now());

  DocumentReference<Map<String, dynamic>> _goalsRef(String uid) =>
      _db.collection('users').doc(uid).collection('goals').doc('main');

  DocumentReference<Map<String, dynamic>> _dayRef(String uid, [DateTime? date]) =>
      _db.collection('users').doc(uid).collection('dailyLogs').doc(_dateKey(date));

  CollectionReference<Map<String, dynamic>> _entriesRef(String uid, [DateTime? date]) =>
      _dayRef(uid, date).collection('entries');

  CollectionReference<Map<String, dynamic>> _recentFoodsRef(String uid) =>
      _db.collection('users').doc(uid).collection('recentFoods');

  CollectionReference<Map<String, dynamic>> _savedMealsRef(String uid) =>
      _db.collection('users').doc(uid).collection('savedMeals');

  // ==========================================
  // 🎯 GET GOALS
  // ==========================================

  Future<Map<String, int>> getGoals(String uid) async {
    if (_connectivity.isOnline) {
      try {
        final snap = await _goalsRef(uid).get();
        final goals = NutritionGoals.fromMap(snap.data()).toMap().map(
              (key, value) => MapEntry(key, value as int),
        );

        await _localStorage.saveNutritionGoals(uid, goals);
        debugPrint('✅ Nutrition goals fetched from Firebase');
        return goals;
      } catch (e) {
        debugPrint('⚠️ Goals online fetch failed: $e');
      }
    }

    final cached = _localStorage.getNutritionGoals(uid);
    if (cached != null) {
      return {
        'caloriesGoal': cached['caloriesGoal'] ?? 2400,
        'proteinGoal': cached['proteinGoal'] ?? 180,
        'carbsGoal': cached['carbsGoal'] ?? 250,
        'fatsGoal': cached['fatsGoal'] ?? 70,
        'waterGoal': cached['waterGoal'] ?? 8,
      };
    }

    return {
      'caloriesGoal': 2400,
      'proteinGoal': 180,
      'carbsGoal': 250,
      'fatsGoal': 70,
      'waterGoal': 8,
    };
  }

  // ==========================================
  // 🎯 SET GOALS
  // ==========================================

  // ==========================================
  // 💾 SAVED MEALS
  // ==========================================

  Future<List<SavedMeal>> getSavedMeals(String uid) async {
    try {
      final snap = await _savedMealsRef(uid)
          .orderBy('updatedAt', descending: true)
          .get();

      return snap.docs.map(SavedMeal.fromDoc).toList();
    } catch (e) {
      debugPrint('⚠️ getSavedMeals failed: $e');
      return [];
    }
  }

  Future<void> saveMealTemplate({
    required String uid,
    required String name,
    required String mealType,
    required List<MealEntry> items,
    String? savedMealId,
  }) async {
    if (items.isEmpty) return;

    final savedItems = items.map(SavedMealItem.fromMealEntry).toList();

    int calories = 0;
    int protein = 0;
    int carbs = 0;
    int fats = 0;

    for (final item in savedItems) {
      calories += item.calories;
      protein += item.protein;
      carbs += item.carbs;
      fats += item.fats;
    }

    final data = {
      'name': name,
      'mealType': mealType,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'items': savedItems.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (savedMealId == null) 'createdAt': FieldValue.serverTimestamp(),
    };

    if (savedMealId == null) {
      await _savedMealsRef(uid).add(data);
    } else {
      await _savedMealsRef(uid).doc(savedMealId).set(data, SetOptions(merge: true));
    }

    debugPrint('✅ Saved meal template stored');
  }

  Future<void> deleteSavedMeal({
    required String uid,
    required String savedMealId,
  }) async {
    await _savedMealsRef(uid).doc(savedMealId).delete();
    debugPrint('✅ Saved meal deleted');
  }

  Future<void> addSavedMealToDay({
    required String uid,
    required SavedMeal savedMeal,
    DateTime? date,
    String? overrideMealType,
  }) async {
    final mealType = overrideMealType ?? savedMeal.mealType;
    final key = _dateKey(date);

    final batch = _db.batch();

    for (final item in savedMeal.items) {
      final doc = _entriesRef(uid, date).doc();

      batch.set(doc, {
        'userId': uid,
        'dateKey': key,
        'name': item.name,
        'quantity': item.quantity,
        'mealType': mealType,
        'calories': item.calories,
        'protein': item.protein,
        'carbs': item.carbs,
        'fats': item.fats,
        'source': 'saved_meal',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    for (final item in savedMeal.items) {
      await _recentFoodsRef(uid)
          .doc(_normalizeFoodKey(item.name))
          .set({
        'name': item.name,
        'quantity': item.quantity,
        'calories': item.calories,
        'protein': item.protein,
        'carbs': item.carbs,
        'fats': item.fats,
        'lastUsedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await recalculateDailyTotals(uid, date: date);
    debugPrint('✅ Saved meal added to daily log');
  }

  Future<void> setGoals({
    required String uid,
    required int caloriesGoal,
    required int proteinGoal,
    required int carbsGoal,
    required int fatsGoal,
    required int waterGoal,
  }) async {
    final goals = {
      'caloriesGoal': caloriesGoal,
      'proteinGoal': proteinGoal,
      'carbsGoal': carbsGoal,
      'fatsGoal': fatsGoal,
      'waterGoal': waterGoal,
    };

    await _localStorage.saveNutritionGoals(uid, goals);

    await _goalsRef(uid).set({
      ...goals,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('✅ Nutrition goals updated');
  }

  // ==========================================
  // 📊 GET DAY LOG
  // ==========================================

  Future<Map<String, int>> getTodayLog(String uid, {DateTime? date}) async {
    final key = _dateKey(date);

    if (_connectivity.isOnline) {
      try {
        final snap = await _dayRef(uid, date).get();
        final log = DailyNutritionLog.fromMap(snap.data()).toMap().map(
              (key, value) => MapEntry(key, value as int),
        );

        await _localStorage.saveDailyLog(uid, key, log);
        debugPrint('✅ Daily nutrition log fetched from Firebase');
        return log;
      } catch (e) {
        debugPrint('⚠️ Daily log online fetch failed: $e');
      }
    }

    final cached = _localStorage.getDailyLog(uid, key);
    if (cached != null) {
      return {
        'calories': cached['calories'] ?? 0,
        'protein': cached['protein'] ?? 0,
        'carbs': cached['carbs'] ?? 0,
        'fats': cached['fats'] ?? 0,
        'water': cached['water'] ?? 0,
      };
    }

    return {
      'calories': 0,
      'protein': 0,
      'carbs': 0,
      'fats': 0,
      'water': 0,
    };
  }

  // ==========================================
  // 💾 SET DAY LOG
  // ==========================================

  Future<void> setTodayLog({
    required String uid,
    required int calories,
    required int protein,
    int carbs = 0,
    int fats = 0,
    int water = 0,
    DateTime? date,
  }) async {
    final key = _dateKey(date);

    final log = {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'water': water,
    };

    await _localStorage.saveDailyLog(uid, key, log);

    if (_connectivity.isOnline) {
      try {
        await _dayRef(uid, date).set({
          ...log,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('✅ Daily nutrition log synced');
      } catch (e) {
        debugPrint('⚠️ Day log sync failed: $e');
        await _localStorage.addPendingSync('nutrition_log', {
          'userId': uid,
          'date': key,
          ...log,
        });
      }
    } else {
      await _localStorage.addPendingSync('nutrition_log', {
        'userId': uid,
        'date': key,
        ...log,
      });
    }
  }

  // ==========================================
  // 🍽 GET MEAL ENTRIES
  // ==========================================

  Future<List<MealEntry>> getMealEntries(String uid, {DateTime? date}) async {
    try {
      final snap = await _entriesRef(uid, date)
          .orderBy('createdAt', descending: false)
          .get();

      return snap.docs.map(MealEntry.fromDoc).toList();
    } catch (e) {
      debugPrint('⚠️ getMealEntries failed: $e');
      return [];
    }
  }

  // ==========================================
  // ➕ ADD MEAL ENTRY
  // ==========================================

  Future<void> addMealEntry({
    required String uid,
    required MealEntry entry,
    DateTime? date,
  }) async {
    final key = _dateKey(date);

    await _entriesRef(uid, date).add(
      entry.toMap(
        userId: uid,
        dateKey: key,
        withCreatedAt: true,
      ),
    );

    await _upsertRecentFood(uid, entry);
    await recalculateDailyTotals(uid, date: date);

    debugPrint('✅ Meal entry added');
  }

  // ==========================================
  // ✏️ UPDATE MEAL ENTRY
  // ==========================================

  Future<void> updateMealEntry({
    required String uid,
    required String entryId,
    required MealEntry entry,
    DateTime? date,
  }) async {
    final key = _dateKey(date);

    await _entriesRef(uid, date).doc(entryId).update(
      entry.toMap(
        userId: uid,
        dateKey: key,
        withCreatedAt: false,
      ),
    );

    await _upsertRecentFood(uid, entry);
    await recalculateDailyTotals(uid, date: date);

    debugPrint('✅ Meal entry updated');
  }

  // ==========================================
  // ❌ DELETE MEAL ENTRY
  // ==========================================

  Future<void> deleteMealEntry({
    required String uid,
    required String entryId,
    DateTime? date,
  }) async {
    await _entriesRef(uid, date).doc(entryId).delete();
    await recalculateDailyTotals(uid, date: date);
    debugPrint('✅ Meal entry deleted');
  }

  // ==========================================
  // 🔄 RECALCULATE TOTALS FROM ENTRIES
  // ==========================================

  Future<void> recalculateDailyTotals(String uid, {DateTime? date}) async {
    final entries = await getMealEntries(uid, date: date);
    final current = await getTodayLog(uid, date: date);

    int calories = 0;
    int protein = 0;
    int carbs = 0;
    int fats = 0;

    for (final e in entries) {
      calories += e.calories;
      protein += e.protein;
      carbs += e.carbs;
      fats += e.fats;
    }

    await setTodayLog(
      uid: uid,
      date: date,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      water: current['water'] ?? 0,
    );
  }

  // ==========================================
  // 💧 WATER
  // ==========================================

  Future<void> incrementWater(
      String uid, {
        int amount = 1,
        DateTime? date,
      }) async {
    final current = await getTodayLog(uid, date: date);
    final newWater = (current['water'] ?? 0) + amount;

    await setTodayLog(
      uid: uid,
      date: date,
      calories: current['calories'] ?? 0,
      protein: current['protein'] ?? 0,
      carbs: current['carbs'] ?? 0,
      fats: current['fats'] ?? 0,
      water: newWater,
    );
  }

  Future<void> decrementWater(
      String uid, {
        int amount = 1,
        DateTime? date,
      }) async {
    final current = await getTodayLog(uid, date: date);
    int newWater = (current['water'] ?? 0) - amount;
    if (newWater < 0) newWater = 0;

    await setTodayLog(
      uid: uid,
      date: date,
      calories: current['calories'] ?? 0,
      protein: current['protein'] ?? 0,
      carbs: current['carbs'] ?? 0,
      fats: current['fats'] ?? 0,
      water: newWater,
    );
  }

  // ==========================================
  // 🕘 RECENT FOODS
  // ==========================================

  Future<List<Map<String, dynamic>>> getRecentFoods(
      String uid, {
        int limit = 10,
      }) async {
    try {
      final snap = await _recentFoodsRef(uid)
          .orderBy('lastUsedAt', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((e) => e.data()).toList();
    } catch (e) {
      debugPrint('⚠️ getRecentFoods failed: $e');
      return [];
    }
  }

  Future<void> _upsertRecentFood(String uid, MealEntry entry) async {
    final key = _normalizeFoodKey(entry.name);

    await _recentFoodsRef(uid).doc(key).set({
      'name': entry.name,
      'quantity': entry.quantity,
      'calories': entry.calories,
      'protein': entry.protein,
      'carbs': entry.carbs,
      'fats': entry.fats,
      'lastUsedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _normalizeFoodKey(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }
}