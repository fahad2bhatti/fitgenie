// lib/screens/calories_screen.dart

import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';
import '../services/ai_service.dart';
import '../services/nutrition_service.dart';
import '../widgets/fg_card.dart';
import '../widgets/fg_progress.dart';
import 'meal_scanner_screen.dart';
import 'food_search_screen.dart';
import 'saved_meals_screen.dart';

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
  // 📊 DATA LOADING
  // ============================================================

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final goals = await _service.getGoals(_uid);
      final log = await _service.getTodayLog(_uid, date: _selectedDate);
      final entries = await _service.getMealEntries(_uid, date: _selectedDate);
      final recent = await _service.getRecentFoods(_uid);

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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load failed: $e')),
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
      return 'Today';
    }

    if (_selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day) {
      return 'Yesterday';
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
  // 🍽 MEAL HELPERS
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
  // 🔎 FOOD SEARCH (General)
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.name} added to ${result.mealType} ✅')),
    );
  }

  // ============================================================
  // 🔎 FOOD SEARCH (Meal-Specific)
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${forcedEntry.name} added to $mealType ✅')),
    );
  }

  // ============================================================
  // 📸 MEAL SCANNER
  // ============================================================

  Future<void> _openMealScanner() async {
    final result = await Navigator.push<MealAnalysis>(
      context,
      MaterialPageRoute(builder: (_) => const MealScannerScreen()),
    );

    if (result == null || !mounted) return;

    final mealType = await _pickMealType(initial: 'lunch');
    if (mealType == null) return;

    final entry = MealEntry(
      name: result.foodName,
      quantity: result.quantity,
      mealType: mealType,
      calories: result.calories,
      protein: result.protein,
      carbs: 0,
      fats: 0,
      source: 'scanner',
    );

    await _service.addMealEntry(
      uid: _uid,
      entry: entry,
      date: _selectedDate,
    );

    await _load();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${result.foodName} added to ${mealType.toUpperCase()} ✅'),
      ),
    );
  }

  // ============================================================
  // 📚 SAVED MEALS PICKER
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${selectedMeal.name} added successfully ✅')),
    );
  }

  // ============================================================
  // 💾 SAVE MEAL AS TEMPLATE
  // ============================================================

  Future<void> _saveMealAsTemplate(String mealType) async {
    final items = _mealEntries(mealType);

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Is meal me abhi koi item nahi hai')),
      );
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
            const Text(
              'Save Meal Template 💾',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Current ${mealType.toUpperCase()} ko saved meal bana do.',
              style: const TextStyle(color: FitGenieTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. My Breakfast',
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
                child: const Text(
                  'Save Meal',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (mealName == null || mealName.trim().isEmpty) return;

    await _service.saveMealTemplate(
      uid: _uid,
      name: mealName.trim(),
      mealType: mealType,
      items: items,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$mealName saved to library ✅')),
    );
  }

  // ============================================================
  // 🍽 MEAL TYPE PICKER
  // ============================================================

  Future<String?> _pickMealType({String initial = 'breakfast'}) async {
    String selected = initial;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: FitGenieTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final mealTypes = {
            'breakfast': '🍳 Breakfast',
            'lunch': '🍛 Lunch',
            'dinner': '🍽 Dinner',
            'snacks': '🍿 Snacks',
          };

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Meal Type',
                  style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ...mealTypes.entries.map((entry) {
                  final isSelected = selected == entry.key;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () =>
                          setModalState(() => selected = entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? FitGenieTheme.primary.withOpacity(0.18)
                              : FitGenieTheme.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? FitGenieTheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(entry.value)),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: FitGenieTheme.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FitGenieTheme.primary,
                    ),
                    child: const Text('Continue',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // 💧 WATER
  // ============================================================

  Future<void> _quickAddWater() async {
    await _service.incrementWater(_uid, date: _selectedDate);
    await _load();
  }

  Future<void> _removeWater() async {
    await _service.decrementWater(_uid, date: _selectedDate);
    await _load();
  }

  // ============================================================
  // 🎯 GOALS SHEET
  // ============================================================

  Future<void> _openGoalsSheet() async {
    final caloriesCtrl =
    TextEditingController(text: caloriesGoal.toString());
    final proteinCtrl =
    TextEditingController(text: proteinGoal.toString());
    final carbsCtrl =
    TextEditingController(text: carbsGoal.toString());
    final fatsCtrl =
    TextEditingController(text: fatsGoal.toString());
    final waterCtrl =
    TextEditingController(text: waterGoal.toString());

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
              const Text(
                'Nutrition Goals 🎯',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 16),
              _goalField(caloriesCtrl, 'Calories Goal', 'kcal'),
              const SizedBox(height: 12),
              _goalField(proteinCtrl, 'Protein Goal', 'g'),
              const SizedBox(height: 12),
              _goalField(carbsCtrl, 'Carbs Goal', 'g'),
              const SizedBox(height: 12),
              _goalField(fatsCtrl, 'Fats Goal', 'g'),
              const SizedBox(height: 12),
              _goalField(waterCtrl, 'Water Goal', 'glasses'),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _service.setGoals(
                      uid: _uid,
                      caloriesGoal:
                      int.tryParse(caloriesCtrl.text.trim()) ??
                          2400,
                      proteinGoal:
                      int.tryParse(proteinCtrl.text.trim()) ??
                          180,
                      carbsGoal:
                      int.tryParse(carbsCtrl.text.trim()) ?? 250,
                      fatsGoal:
                      int.tryParse(fatsCtrl.text.trim()) ?? 70,
                      waterGoal:
                      int.tryParse(waterCtrl.text.trim()) ?? 8,
                    );
                    if (mounted) Navigator.pop(context);
                    await _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FitGenieTheme.primary,
                  ),
                  child: const Text('Save Goals',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ✍️ CUSTOM FOOD ENTRY SHEET
  // ============================================================

  Future<void> _openAddFoodSheet({
    MealEntry? initialEntry,
    String? entryId,
  }) async {
    final nameCtrl =
    TextEditingController(text: initialEntry?.name ?? '');
    final quantityCtrl =
    TextEditingController(text: initialEntry?.quantity ?? '');
    final caloriesCtrl = TextEditingController(
      text: initialEntry != null
          ? initialEntry.calories.toString()
          : '',
    );
    final proteinCtrl = TextEditingController(
      text: initialEntry != null
          ? initialEntry.protein.toString()
          : '',
    );
    final carbsCtrl = TextEditingController(
      text:
      initialEntry != null ? initialEntry.carbs.toString() : '',
    );
    final fatsCtrl = TextEditingController(
      text:
      initialEntry != null ? initialEntry.fats.toString() : '',
    );
    String selectedMeal = initialEntry?.mealType ?? 'breakfast';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FitGenieTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom:
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entryId == null
                        ? 'Custom Food Entry ✍️'
                        : 'Edit Food ✏️',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ye fallback option hai. Better experience ke liye Search Food use karo.',
                    style: TextStyle(
                      color: FitGenieTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Food Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                    _inputDecoration('Quantity / Serving'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Meal Type',
                      style:
                      TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: {
                      'breakfast': '🍳 Breakfast',
                      'lunch': '🍛 Lunch',
                      'dinner': '🍽 Dinner',
                      'snacks': '🍿 Snacks',
                    }.entries.map((entry) {
                      final selected =
                          selectedMeal == entry.key;
                      return GestureDetector(
                        onTap: () => setModalState(
                                () => selectedMeal = entry.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? FitGenieTheme.primary
                                .withOpacity(0.2)
                                : FitGenieTheme.background,
                            borderRadius:
                            BorderRadius.circular(20),
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
                          style: const TextStyle(
                              color: Colors.white),
                          decoration:
                          _inputDecoration('Calories'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: proteinCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: Colors.white),
                          decoration:
                          _inputDecoration('Protein'),
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
                          style: const TextStyle(
                              color: Colors.white),
                          decoration:
                          _inputDecoration('Carbs'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: fatsCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: Colors.white),
                          decoration:
                          _inputDecoration('Fats'),
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
                          quantity:
                          quantityCtrl.text.trim().isEmpty
                              ? '1 serving'
                              : quantityCtrl.text.trim(),
                          mealType: selectedMeal,
                          calories: int.tryParse(
                              caloriesCtrl.text.trim()) ??
                              0,
                          protein: int.tryParse(
                              proteinCtrl.text.trim()) ??
                              0,
                          carbs: int.tryParse(
                              carbsCtrl.text.trim()) ??
                              0,
                          fats: int.tryParse(
                              fatsCtrl.text.trim()) ??
                              0,
                          source: 'manual',
                        );

                        if (entry.name.isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                                content:
                                Text('Food name required')),
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

                        if (mounted) Navigator.pop(context);
                        await _load();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FitGenieTheme.primary,
                      ),
                      child: Text(
                        entryId == null
                            ? 'Add Food'
                            : 'Update Food',
                        style: const TextStyle(
                            color: Colors.white),
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
  }

  // ============================================================
  // ❌ DELETE ENTRY
  // ============================================================

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
  // 🛠 HELPER WIDGETS
  // ============================================================

  Widget _goalField(
      TextEditingController controller,
      String label,
      String suffix,
      ) {
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
    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Summary",
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 14),
          _macroProgress('Calories',
              '$calories / $caloriesGoal kcal',
              _progress(calories, caloriesGoal), FitGenieTheme.hot),
          const SizedBox(height: 14),
          _macroProgress('Protein',
              '$protein / $proteinGoal g',
              _progress(protein, proteinGoal), FitGenieTheme.teal),
          const SizedBox(height: 14),
          _macroProgress('Carbs', '$carbs / $carbsGoal g',
              _progress(carbs, carbsGoal), Colors.orange),
          const SizedBox(height: 14),
          _macroProgress('Fats', '$fats / $fatsGoal g',
              _progress(fats, fatsGoal), Colors.purple),
          const SizedBox(height: 14),
          _macroProgress('Water',
              '$water / $waterGoal glasses',
              _progress(water, waterGoal), Colors.blue),
        ],
      ),
    );
  }

  Widget _macroProgress(
      String title,
      String value,
      double progress,
      Color color,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    color: FitGenieTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        FGLinearProgress(value: progress, color: color),
      ],
    );
  }

  // ============================================================
  // ⚡ QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            icon: Icons.search,
            label: 'Search Food',
            color: FitGenieTheme.primary,
            onTap: _openFoodSearch,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionCard(
            icon: Icons.bookmark_border,
            label: 'Saved Meals',
            color: Colors.amber,
            onTap: () => _openSavedMealsPicker(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionCard(
            icon: Icons.camera_alt,
            label: 'Scan Meal',
            color: FitGenieTheme.teal,
            onTap: _openMealScanner,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionCard(
            icon: Icons.flag_outlined,
            label: 'Goals',
            color: Colors.orange,
            onTap: _openGoalsSheet,
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: FitGenieTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 💧 WATER CONTROLS
  // ============================================================

  Widget _buildWaterControls() {
    return FGCard(
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: Colors.blue),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Water Tracker',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          IconButton(
            onPressed: _removeWater,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.remove,
                  color: Colors.red, size: 18),
            ),
          ),
          Text('$water',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18)),
          IconButton(
            onPressed: _quickAddWater,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add,
                  color: Colors.green, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🍽 MEAL SECTION
  // ============================================================

  Widget _buildMealSection(
      String mealType, String title, String emoji) {
    final items = _mealEntries(mealType);

    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                '$emoji $title',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const Spacer(),
              if (items.isNotEmpty)
                GestureDetector(
                  onTap: () => _saveMealAsTemplate(mealType),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_add_outlined,
                            size: 14, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '${_mealCalories(mealType)} cal • ${_mealProtein(mealType)}g protein',
                style: const TextStyle(
                    color: FitGenieTheme.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FitGenieTheme.card2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('No items added yet',
                  style: TextStyle(
                      color: FitGenieTheme.muted, fontSize: 12)),
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

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _openFoodSearchForMeal(mealType),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: FitGenieTheme.primary
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: FitGenieTheme.primary
                              .withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search,
                            color: FitGenieTheme.primary,
                            size: 18),
                        SizedBox(width: 6),
                        Text('Search Food',
                            style: TextStyle(
                                color: FitGenieTheme.primary,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openSavedMealsPicker(
                      mealTypeOverride: mealType),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.amber.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border,
                            color: Colors.amber, size: 18),
                        SizedBox(width: 6),
                        Text('Saved Meal',
                            style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Custom Entry Link
          GestureDetector(
            onTap: () => _openAddFoodSheet(
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
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Custom manual entry',
                style: TextStyle(
                  color: FitGenieTheme.muted,
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🕐 RECENT FOODS
  // ============================================================

  Widget _buildRecentFoods() {
    if (_recentFoods.isEmpty) return const SizedBox.shrink();

    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Foods',
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 15)),
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
                      quantity:
                      (food['quantity'] ?? '1 serving')
                          .toString(),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: FitGenieTheme.card2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (food['name'] ?? 'Food').toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${food['calories'] ?? 0} cal • ${food['protein'] ?? 0}g P',
                        style: const TextStyle(
                            color: FitGenieTheme.muted,
                            fontSize: 10),
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
  // 🏗 MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding:
        const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          const Text('Nutrition 🍽️',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Track meals, macros & water',
              style: TextStyle(
                  color: FitGenieTheme.muted,
                  fontSize: 12)),
          const SizedBox(height: 14),

          // Date Switcher
          FGCard(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _changeDate(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _dateLabel(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isToday
                      ? null
                      : () => _changeDate(1),
                  icon: Icon(
                    Icons.chevron_right,
                    color: _isToday
                        ? Colors.white24
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _buildSummaryCard(),
          const SizedBox(height: 14),

          _buildQuickActions(),
          const SizedBox(height: 14),

          _buildWaterControls(),
          const SizedBox(height: 14),

          _buildMealSection(
              'breakfast', 'Breakfast', '🍳'),
          const SizedBox(height: 12),
          _buildMealSection('lunch', 'Lunch', '🍛'),
          const SizedBox(height: 12),
          _buildMealSection('dinner', 'Dinner', '🍽'),
          const SizedBox(height: 12),
          _buildMealSection('snacks', 'Snacks', '🍿'),
          const SizedBox(height: 12),

          _buildRecentFoods(),
        ],
      ),
    );
  }
}

// ============================================================
// 🍽 MEAL ENTRY TILE WIDGET
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
    final sourceIcon =
    entry.source == 'scanner'
        ? Icons.camera_alt
        : Icons.edit_note;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FitGenieTheme.card2,
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: entry.source == 'scanner'
                  ? FitGenieTheme.primary.withOpacity(0.18)
                  : FitGenieTheme.teal.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              sourceIcon,
              color: entry.source == 'scanner'
                  ? FitGenieTheme.primary
                  : FitGenieTheme.teal,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(entry.quantity,
                    style: const TextStyle(
                        color: FitGenieTheme.muted,
                        fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  '${entry.protein}g P • ${entry.carbs}g C • ${entry.fats}g F',
                  style: const TextStyle(
                      color: FitGenieTheme.muted,
                      fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.calories} cal',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: FitGenieTheme.hot)),
              const SizedBox(height: 4),
              PopupMenuButton<String>(
                color: FitGenieTheme.cardDark,
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                      value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete')),
                ],
                child: const Icon(Icons.more_vert,
                    size: 18, color: FitGenieTheme.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}