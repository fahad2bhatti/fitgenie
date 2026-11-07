// lib/screens/calories_screen.dart

import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';
import '../services/nutrition_service.dart';
import '../services/ai_service.dart' show MealAnalysis;
import '../widgets/fg_card.dart';
import '../widgets/app_snackbar.dart';
import '../core/app_strings.dart';
import 'food_search_screen.dart';
import 'saved_meals_screen.dart';
import 'meal_scanner_screen.dart';
import '../widgets/medical_disclaimer.dart';

class CaloriesScreen extends StatefulWidget {
  final String userId;

  const CaloriesScreen({
    super.key,
    required this.userId,
  });

  @override
  State<CaloriesScreen> createState() => _CaloriesScreenState();
}

class _CaloriesScreenState extends State<CaloriesScreen> {
  final _service = NutritionService();

  bool _loading = true;
  bool _hasLoaded = false;
  DateTime _selectedDate = DateTime.now();

  // Goals
  int caloriesGoal = 2400;
  int proteinGoal = 180;
  int carbsGoal = 250;
  int fatsGoal = 70;
  int waterGoal = 8;

  // Daily totals
  int calories = 0;
  int protein = 0;
  int carbs = 0;
  int fats = 0;
  int water = 0;

  // Data
  List<MealEntry> _entries = [];
  List<Map<String, dynamic>> _recentFoods = [];

  String get _uid => widget.userId;

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  // ============================================================
  // 🔄 LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ============================================================
  // 📥 DATA LOADING
  // ============================================================

  Future<void> _load() async {
    // speedfix
    // Poori screen par spinner sirf pehli baar. Baad mein purana content
    // dikhta rehta hai aur peeche se naya data aa jata hai.
    if (!_hasLoaded) {
      setState(() => _loading = true);
    }

    try {
      // Chaaron reads ek saath shuru, ek ke baad ek nahi
      final goalsF = _service.getGoals(_uid);
      final logF = _service.getTodayLog(_uid, date: _selectedDate);
      final entriesF = _service.getMealEntries(_uid, date: _selectedDate);
      final recentF = _service.getRecentFoods(_uid);

      await Future.wait([goalsF, logF, entriesF, recentF]);

      final goals = await goalsF;
      final log = await logF;
      final entries = await entriesF;
      final recent = await recentF;

      if (!mounted) return;

      setState(() {
        caloriesGoal = goals['caloriesGoal'] ?? 2400;
        proteinGoal = goals['proteinGoal'] ?? 180;
        carbsGoal = goals['carbsGoal'] ?? 250;
        fatsGoal = goals['fatsGoal'] ?? 70;
        waterGoal = goals['waterGoal'] ?? 8;

        calories = log['calories'] ?? 0;
        protein = log['protein'] ?? 0;
        carbs = log['carbs'] ?? 0;
        fats = log['fats'] ?? 0;
        water = log['water'] ?? 0;

        _entries = entries;
        _recentFoods = recent;
        _loading = false;
        _hasLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppSnackbar.showError(
        context,
        AppStrings.get('calories_load_failed', params: {'error': e.toString()}),
      );
    }
  }

  // ============================================================
  // 📅 DATE NAVIGATION
  // ============================================================

  String _dateLabel() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return AppStrings.get('calories_today');
    }

    if (_selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day) {
      return AppStrings.get('calories_yesterday');
    }

    return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
  }

  void _changeDate(int days) {
    final nextDate = _selectedDate.add(Duration(days: days));
    final now = DateTime.now();

    if (nextDate.isAfter(DateTime(now.year, now.month, now.day))) return;

    setState(() => _selectedDate = nextDate);
    _load();
  }

  // ============================================================
  // 🍽️ MEAL HELPERS
  // ============================================================

  List<MealEntry> _mealEntries(String mealType) {
    return _entries.where((e) => e.mealType == mealType).toList();
  }

  int _mealCalories(String mealType) {
    return _mealEntries(mealType).fold(0, (sum, e) => sum + e.calories);
  }

  int _mealProtein(String mealType) {
    return _mealEntries(mealType).fold(0, (sum, e) => sum + e.protein);
  }

  double _progress(int value, int goal) {
    if (goal <= 0) return 0;
    return (value / goal).clamp(0.0, 1.0);
  }

  // ============================================================
  // 🔍 FOOD SEARCH (General)
  // ============================================================

  Future<void> _openFoodSearch() async {
    final result = await Navigator.push<MealEntry>(
      context,
      MaterialPageRoute(builder: (_) => const FoodSearchScreen()),
    );

    if (result == null) return;

    await _service.addMealEntry(
      uid: _uid,
      entry: result,
      date: _selectedDate,
    );

    await _load();

    if (!mounted) return;
    AppSnackbar.showSuccess(
      context,
      AppStrings.get('calories_added_success', params: {'name': result.name}),
    );
  }

  // ============================================================
  // 🔍 FOOD SEARCH (Meal-Specific)
  // ============================================================

  Future<void> _openFoodSearchForMeal(String mealType) async {
    final result = await Navigator.push<MealEntry>(
      context,
      MaterialPageRoute(builder: (_) => const FoodSearchScreen()),
    );

    if (result == null) return;

    final forcedEntry = MealEntry(
      name: result.name,
      quantity: result.quantity,
      mealType: mealType,
      calories: result.calories,
      protein: result.protein,
      carbs: result.carbs,
      fats: result.fats,
      source: result.source,
    );

    await _service.addMealEntry(
      uid: _uid,
      entry: forcedEntry,
      date: _selectedDate,
    );

    await _load();

    if (!mounted) return;
    AppSnackbar.showSuccess(
      context,
      AppStrings.get('calories_added_success',
          params: {'name': forcedEntry.name}),
    );
  }

  // ============================================================
  // 📷 MEAL SCANNER (AI photo + barcode) — replaces old "Coming Soon"
  // ============================================================

  Future<void> _openMealScanner() async {
    final analysis = await Navigator.push<MealAnalysis>(
      context,
      MaterialPageRoute(builder: (_) => const MealScannerScreen()),
    );

    if (analysis == null || !mounted) return;

    final mealType = await _pickMealTypeForScan();
    if (mealType == null || !mounted) return;

    final entry = MealEntry(
      name: analysis.foodName,
      quantity: analysis.quantity,
      mealType: mealType,
      calories: analysis.calories,
      protein: analysis.protein,
      carbs: analysis.carbs,
      fats: analysis.fat,
      source: 'scanner',
    );

    await _service.addMealEntry(
      uid: _uid,
      entry: entry,
      date: _selectedDate,
    );

    await _load();

    if (!mounted) return;
    AppSnackbar.showSuccess(
      context,
      AppStrings.get('calories_added_success', params: {'name': entry.name}),
    );
  }

  /// Small bottom sheet asking which meal (breakfast/lunch/dinner/snacks)
  /// the scanned item belongs to. Returns null if the user dismisses it.
  Future<String?> _pickMealTypeForScan() async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: FitGenieTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('calories_which_meal'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: {
                'breakfast': AppStrings.get('meal_breakfast'),
                'lunch': AppStrings.get('meal_lunch'),
                'dinner': AppStrings.get('meal_dinner'),
                'snacks': AppStrings.get('meal_snacks'),
              }.entries.map((entry) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context, entry.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: FitGenieTheme.card2,
                      borderRadius:
                          BorderRadius.circular(FitGenieTheme.radiusMD),
                      border: Border.all(color: FitGenieTheme.border),
                    ),
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: FitGenieTheme.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📌 SAVED MEALS PICKER
  // ============================================================

  Future<void> _openSavedMealsPicker({String? mealTypeOverride}) async {
    final selectedMeal = await Navigator.push<SavedMeal>(
      context,
      MaterialPageRoute(
        builder: (_) => SavedMealsScreen(
          userId: _uid,
          pickerMode: true,
        ),
      ),
    );

    if (selectedMeal == null) return;

    await _service.addSavedMealToDay(
      uid: _uid,
      savedMeal: selectedMeal,
      date: _selectedDate,
      overrideMealType: mealTypeOverride,
    );

    await _load();

    if (!mounted) return;
    AppSnackbar.showSuccess(
      context,
      AppStrings.get('calories_added_success',
          params: {'name': selectedMeal.name}),
    );
  }

  // ============================================================
  // 💾 SAVE MEAL AS TEMPLATE
  // ============================================================

  Future<void> _saveMealAsTemplate(String mealType) async {
    final items = _mealEntries(mealType);

    if (items.isEmpty) {
      AppSnackbar.showWarning(
          context, AppStrings.get('calories_meal_empty_error'));
      return;
    }

    final controller = TextEditingController();

    final mealName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FitGenieTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('calories_save_template'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.get('calories_save_template_desc',
                  params: {'mealType': mealType.toUpperCase()}),
              style: const TextStyle(color: FitGenieTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppStrings.get('calories_template_name_hint'),
                hintStyle: const TextStyle(color: FitGenieTheme.muted),
                filled: true,
                fillColor: FitGenieTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  Navigator.pop(context, text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FitGenieTheme.primary,
                ),
                child: Text(
                  AppStrings.get('calories_save_meal'),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    _disposeLater([controller]);

    if (mealName == null || mealName.trim().isEmpty) return;

    await _service.saveMealTemplate(
      uid: _uid,
      name: mealName.trim(),
      mealType: mealType,
      items: items,
    );

    if (!mounted) return;
    AppSnackbar.showSuccess(
      context,
      AppStrings.get('calories_template_saved', params: {'name': mealName}),
    );
  }

  // ============================================================
  // 💧 WATER
  // ============================================================

  Future<void> _quickAddWater() async {
    // Number foran badlo, server ko baad mein batao
    setState(() => water++);
    await _service.incrementWater(_uid, date: _selectedDate);
    await _load();
  }

  Future<void> _removeWater() async {
    if (water <= 0) return;
    setState(() => water--);
    await _service.decrementWater(_uid, date: _selectedDate);
    await _load();
  }

  // ============================================================
  // 🎯 GOALS SHEET
  // ============================================================

  Future<void> _openGoalsSheet() async {
    final caloriesCtrl = TextEditingController(text: caloriesGoal.toString());
    final proteinCtrl = TextEditingController(text: proteinGoal.toString());
    final carbsCtrl = TextEditingController(text: carbsGoal.toString());
    final fatsCtrl = TextEditingController(text: fatsGoal.toString());
    final waterCtrl = TextEditingController(text: waterGoal.toString());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FitGenieTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.get('calories_goals_title'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 16),
              _goalField(caloriesCtrl, AppStrings.get('calories_goal_calories'),
                  'kcal'),
              const SizedBox(height: 12),
              _goalField(
                  proteinCtrl, AppStrings.get('calories_goal_protein'), 'g'),
              const SizedBox(height: 12),
              _goalField(carbsCtrl, AppStrings.get('calories_goal_carbs'), 'g'),
              const SizedBox(height: 12),
              _goalField(fatsCtrl, AppStrings.get('calories_goal_fats'), 'g'),
              const SizedBox(height: 12),
              _goalField(
                  waterCtrl, AppStrings.get('calories_goal_water'), 'glasses'),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _service.setGoals(
                      uid: _uid,
                      caloriesGoal:
                          int.tryParse(caloriesCtrl.text.trim()) ?? 2400,
                      proteinGoal: int.tryParse(proteinCtrl.text.trim()) ?? 180,
                      carbsGoal: int.tryParse(carbsCtrl.text.trim()) ?? 250,
                      fatsGoal: int.tryParse(fatsCtrl.text.trim()) ?? 70,
                      waterGoal: int.tryParse(waterCtrl.text.trim()) ?? 8,
                    );
                    if (context.mounted) Navigator.pop(context);
                    await _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FitGenieTheme.primary,
                  ),
                  child: Text(AppStrings.get('calories_save_goals'),
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    _disposeLater([
      caloriesCtrl,
      proteinCtrl,
      carbsCtrl,
      fatsCtrl,
      waterCtrl,
    ]);
  }

  // ============================================================
  // ✏️ CUSTOM FOOD ENTRY SHEET
  // ============================================================

  Future<void> _openAddFoodSheet({
    MealEntry? initialEntry,
    String? entryId,
  }) async {
    final nameCtrl = TextEditingController(text: initialEntry?.name ?? '');
    final quantityCtrl =
        TextEditingController(text: initialEntry?.quantity ?? '');
    final caloriesCtrl = TextEditingController(
      text: initialEntry != null ? initialEntry.calories.toString() : '',
    );
    final proteinCtrl = TextEditingController(
      text: initialEntry != null ? initialEntry.protein.toString() : '',
    );
    final carbsCtrl = TextEditingController(
      text: initialEntry != null ? initialEntry.carbs.toString() : '',
    );
    final fatsCtrl = TextEditingController(
      text: initialEntry != null ? initialEntry.fats.toString() : '',
    );
    String selectedMeal = initialEntry?.mealType ?? 'breakfast';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FitGenieTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entryId == null
                        ? AppStrings.get('calories_custom_entry')
                        : AppStrings.get('calories_edit_food'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.get('calories_custom_hint'),
                    style: TextStyle(
                      color: FitGenieTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        _inputDecoration(AppStrings.get('calories_food_name')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        _inputDecoration(AppStrings.get('calories_quantity')),
                  ),
                  const SizedBox(height: 12),
                  Text(AppStrings.get('food_search_meal_type'),
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: {
                      'breakfast': AppStrings.get('meal_breakfast'),
                      'lunch': AppStrings.get('meal_lunch'),
                      'dinner': AppStrings.get('meal_dinner'),
                      'snacks': AppStrings.get('meal_snacks'),
                    }.entries.map((entry) {
                      final selected = selectedMeal == entry.key;
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedMeal = entry.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? FitGenieTheme.primary.withValues(alpha: 0.2)
                                : FitGenieTheme.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? FitGenieTheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: selected
                                  ? FitGenieTheme.primary
                                  : FitGenieTheme.muted,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: caloriesCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(AppStrings.get('calories_field_calories')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: proteinCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(AppStrings.get('calories_field_protein')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: carbsCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(AppStrings.get('calories_field_carbs')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: fatsCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(AppStrings.get('calories_field_fats')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final entry = MealEntry(
                          name: nameCtrl.text.trim(),
                          quantity: quantityCtrl.text.trim().isEmpty
                              ? '1 serving'
                              : quantityCtrl.text.trim(),
                          mealType: selectedMeal,
                          calories: int.tryParse(caloriesCtrl.text.trim()) ?? 0,
                          protein: int.tryParse(proteinCtrl.text.trim()) ?? 0,
                          carbs: int.tryParse(carbsCtrl.text.trim()) ?? 0,
                          fats: int.tryParse(fatsCtrl.text.trim()) ?? 0,
                          source: 'manual',
                        );

                        if (entry.name.isEmpty) {
                          AppSnackbar.showWarning(
                            context,
                            AppStrings.get('calories_food_name_required'),
                          );
                          return;
                        }

                        if (entryId == null) {
                          await _service.addMealEntry(
                            uid: _uid,
                            entry: entry,
                            date: _selectedDate,
                          );
                        } else {
                          await _service.updateMealEntry(
                            uid: _uid,
                            entryId: entryId,
                            entry: entry,
                            date: _selectedDate,
                          );
                        }

                        if (context.mounted) Navigator.pop(context);
                        await _load();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FitGenieTheme.primary,
                      ),
                      child: Text(
                        entryId == null
                            ? AppStrings.get('calories_add_food')
                            : AppStrings.get('calories_update_food'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    _disposeLater([
      nameCtrl,
      quantityCtrl,
      caloriesCtrl,
      proteinCtrl,
      carbsCtrl,
      fatsCtrl,
    ]);
  }

  // ============================================================
  // 🗑️ DELETE ENTRY
  // ============================================================

  /// Bottom sheet ki close animation khatam hone ke baad controllers dispose karo.
  /// (showModalBottomSheet ka future animation shuru hote hi complete ho jata ha.)
  void _disposeLater(List<TextEditingController> controllers) {
    Future.delayed(const Duration(milliseconds: 500), () {
      for (final c in controllers) {
        c.dispose();
      }
    });
  }

  Future<void> _deleteEntry(MealEntry entry) async {
    if (entry.id == null) return;

    await _service.deleteMealEntry(
      uid: _uid,
      entryId: entry.id!,
      date: _selectedDate,
    );
    await _load();
  }

  // ============================================================
  // 🧩 HELPER WIDGETS
  // ============================================================

  Widget _goalField(
      TextEditingController controller, String label, String suffix) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: FitGenieTheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: FitGenieTheme.muted),
      filled: true,
      fillColor: FitGenieTheme.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ============================================================
  // 📊 SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard() {
    final t = Theme.of(context).textTheme;
    final remaining = caloriesGoal - calories;

    Widget macro(String label, int value, int goal) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: t.labelSmall),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$value', style: t.headlineSmall),
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '/ $goal g',
                      style: const TextStyle(
                          color: FitGenieTheme.muted, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: _progress(value, goal),
                  minHeight: 4,
                  backgroundColor: FitGenieTheme.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      FitGenieTheme.primary),
                ),
              ),
            ],
          ),
        );

    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppStrings.get('calories_summary').toUpperCase(),
                style: t.labelSmall,
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined,
                    size: 20, color: FitGenieTheme.muted),
                onPressed: _openGoalsSheet,
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$calories', style: t.displayLarge),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ $caloriesGoal kcal',
                  style: t.titleMedium?.copyWith(color: FitGenieTheme.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress(calories, caloriesGoal),
              minHeight: 8,
              backgroundColor: FitGenieTheme.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(FitGenieTheme.hot),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remaining >= 0 ? AppStrings.get('calories_kcal_left', params: {'n': '$remaining'}) : AppStrings.get('calories_kcal_over', params: {'n': '${-remaining}'}),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  remaining >= 0 ? FitGenieTheme.muted : FitGenieTheme.warning,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              macro(AppStrings.get('calories_field_protein'), protein, proteinGoal),
              const SizedBox(width: 16),
              macro(AppStrings.get('calories_field_carbs'), carbs, carbsGoal),
              const SizedBox(width: 16),
              macro(AppStrings.get('calories_field_fats'), fats, fatsGoal),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ⚡ QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Material(
            color: FitGenieTheme.primary,
            borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
            child: InkWell(
              borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
              onTap: _openFoodSearch,
              child: SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_rounded,
                        color: FitGenieTheme.onPrimary, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppStrings.get('calories_search'),
                        style: const TextStyle(
                          color: FitGenieTheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: FGCard(
            onTap: _openMealScanner,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.document_scanner_outlined,
                    size: 18, color: FitGenieTheme.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppStrings.get('calories_scan'),
                    style: const TextStyle(
                      color: FitGenieTheme.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 💧 WATER CONTROLS
  // ============================================================

  Widget _buildWaterControls() {
    final t = Theme.of(context).textTheme;
    final int segs = waterGoal.clamp(1, 16).toInt();
    final int filled = waterGoal > 0
        ? ((water / waterGoal) * segs).round().clamp(0, segs).toInt()
        : 0;

    Widget circleButton(IconData icon, VoidCallback onTap,
        {bool filledStyle = false}) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filledStyle ? FitGenieTheme.teal : Colors.transparent,
            border: Border.all(
              color: filledStyle ? FitGenieTheme.teal : FitGenieTheme.border,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: filledStyle ? Colors.black : FitGenieTheme.text,
          ),
        ),
      );
    }

    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('calories_water').toUpperCase(),
                      style: t.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$water', style: t.headlineMedium),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '/ $waterGoal',
                            style: const TextStyle(
                                color: FitGenieTheme.muted, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              circleButton(Icons.remove_rounded, _removeWater),
              const SizedBox(width: 10),
              circleButton(Icons.add_rounded, _quickAddWater,
                  filledStyle: true),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(segs, (i) {
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: i == segs - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color:
                        i < filled ? FitGenieTheme.teal : FitGenieTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🍽️ MEAL SECTION
  // ============================================================

  Widget _buildMealSection(String mealType, String title, String emoji) {
    final t = Theme.of(context).textTheme;
    final items = _mealEntries(mealType);

    Widget pill(String label, VoidCallback onTap) => Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(FitGenieTheme.radiusMD),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FitGenieTheme.radiusMD),
                border: Border.all(color: FitGenieTheme.border),
              ),
              child: Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '+ ',
                        style: TextStyle(
                          color: FitGenieTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: label,
                        style: const TextStyle(
                          color: FitGenieTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );

    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title.toUpperCase(), style: t.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${_mealCalories(mealType)} kcal · ${_mealProtein(mealType)}g protein',
                      style: const TextStyle(
                          color: FitGenieTheme.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (items.isNotEmpty)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: AppStrings.get('calories_save_template'),
                  icon: const Icon(Icons.bookmark_add_outlined,
                      size: 20, color: FitGenieTheme.muted),
                  onPressed: () => _saveMealAsTemplate(mealType),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                AppStrings.get('calories_empty'),
                style:
                    const TextStyle(color: FitGenieTheme.muted, fontSize: 12),
              ),
            )
          else
            ...items.map(
              (entry) => _MealEntryTile(
                entry: entry,
                onEdit: () => _openAddFoodSheet(
                  initialEntry: entry,
                  entryId: entry.id,
                ),
                onDelete: () => _deleteEntry(entry),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              pill(AppStrings.get('calories_search'),
                  () => _openFoodSearchForMeal(mealType)),
              const SizedBox(width: 8),
              pill(AppStrings.get('calories_saved'),
                  () => _openSavedMealsPicker(mealTypeOverride: mealType)),
              const SizedBox(width: 8),
              pill(
                AppStrings.get('calories_custom'),
                () => _openAddFoodSheet(
                  initialEntry: MealEntry(
                    name: '',
                    quantity: '',
                    mealType: mealType,
                    calories: 0,
                    protein: 0,
                    carbs: 0,
                    fats: 0,
                    source: 'manual',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🕓 RECENT FOODS
  // ============================================================

  Widget _buildRecentFoods() {
    if (_recentFoods.isEmpty) return const SizedBox.shrink();

    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.get('calories_recent').toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentFoods.map((food) {
              return GestureDetector(
                onTap: () {
                  _openAddFoodSheet(
                    initialEntry: MealEntry(
                      name: (food['name'] ?? '').toString(),
                      quantity: (food['quantity'] ?? '1 serving').toString(),
                      mealType: 'breakfast',
                      calories: (food['calories'] is num)
                          ? (food['calories'] as num).toInt()
                          : 0,
                      protein: (food['protein'] is num)
                          ? (food['protein'] as num).toInt()
                          : 0,
                      carbs: (food['carbs'] is num)
                          ? (food['carbs'] as num).toInt()
                          : 0,
                      fats: (food['fats'] is num)
                          ? (food['fats'] as num).toInt()
                          : 0,
                      source: 'recent',
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(FitGenieTheme.radiusMD),
                    border: Border.all(color: FitGenieTheme.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (food['name'] ?? AppStrings.get('calories_food_fallback')).toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${food['calories'] ?? 0} kcal · ${food['protein'] ?? 0}g P',
                        style: const TextStyle(
                            color: FitGenieTheme.muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🏗️ MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // nutrition-v2
    final t = Theme.of(context).textTheme;

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            color: FitGenieTheme.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                FitGenieTheme.screenPadding,
                12,
                FitGenieTheme.screenPadding,
                24,
              ),
              children: [
                Text(AppStrings.get('calories_title'), style: t.displaySmall),
                const SizedBox(height: 4),
                Text(
                  AppStrings.get('calories_sub'),
                  style:
                      const TextStyle(color: FitGenieTheme.muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                const MedicalDisclaimerBanner(compact: true),
                const SizedBox(height: 8),

                // Date switcher: seedhi row, card nahi
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _changeDate(-1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(_dateLabel(), style: t.titleMedium),
                      ),
                    ),
                    IconButton(
                      onPressed: _isToday ? null : () => _changeDate(1),
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: _isToday
                            ? FitGenieTheme.border
                            : FitGenieTheme.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _buildSummaryCard(),
                const SizedBox(height: 12),
                _buildQuickActions(),
                const SizedBox(height: 12),
                _buildWaterControls(),
                const SizedBox(height: 12),

                _buildMealSection(
                    'breakfast', AppStrings.get('meal_breakfast'), ''),
                const SizedBox(height: 12),
                _buildMealSection('lunch', AppStrings.get('meal_lunch'), ''),
                const SizedBox(height: 12),
                _buildMealSection('dinner', AppStrings.get('meal_dinner'), ''),
                const SizedBox(height: 12),
                _buildMealSection('snacks', AppStrings.get('meal_snacks'), ''),
                const SizedBox(height: 12),

                _buildRecentFoods(),
              ],
            ),
          );
  }
}

// ============================================================
// 🍱 MEAL ENTRY TILE WIDGET
// ============================================================

class _MealEntryTile extends StatelessWidget {
  final MealEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MealEntryTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: FitGenieTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.quantity} · ${entry.protein}g P · ${entry.carbs}g C · ${entry.fats}g F',
                  style:
                      const TextStyle(color: FitGenieTheme.muted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${entry.calories}',
            style: t.headlineSmall?.copyWith(
              fontSize: 20,
              color: FitGenieTheme.hot,
            ),
          ),
          const SizedBox(width: 3),
          const Text(
            'kcal',
            style: TextStyle(color: FitGenieTheme.muted, fontSize: 11),
          ),
          PopupMenuButton<String>(
            color: FitGenieTheme.cardDark,
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(AppStrings.get('edit'))),
              PopupMenuItem(
                  value: 'delete', child: Text(AppStrings.get('delete'))),
            ],
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child:
                  Icon(Icons.more_vert, size: 18, color: FitGenieTheme.muted),
            ),
          ),
        ],
      ),
    );
  }
}
