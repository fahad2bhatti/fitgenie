// lib/screens/food_search_screen.dart

import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';
import '../widgets/fg_card.dart';
import '../data/food_item.dart';
import '../data/food_database.dart';
import '../services/nutrition_service.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String _selectedCategory = 'All';

  List<FoodItem> get _results {
    return FoodDatabase.search(
      _query,
      category: _selectedCategory,
      limit: 100,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFoodConfigSheet(FoodItem food) async {
    double selectedQty = 1;
    String selectedMealType = 'breakfast';

    final result = await showModalBottomSheet<MealEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FitGenieTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final portion = food.calculatePortion(selectedQty);

          final mealTypes = {
            'breakfast': '🍳 Breakfast',
            'lunch': '🍛 Lunch',
            'dinner': '🍽 Dinner',
            'snacks': '🍿 Snacks',
          };

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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (food.isEstimated)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Estimated',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${food.category} • ${food.servingLabel}',
                    style: const TextStyle(
                      color: FitGenieTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Quantity',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: FoodDatabase.quantityOptionsFor(food).map((qty) {
                      final selected = selectedQty == qty;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedQty = qty),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? FitGenieTheme.primary.withOpacity(0.18)
                                : FitGenieTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? FitGenieTheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            qty == qty.toInt()
                                ? qty.toInt().toString()
                                : qty.toStringAsFixed(1),
                            style: TextStyle(
                              color: selected
                                  ? FitGenieTheme.primary
                                  : FitGenieTheme.muted,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Meal Type',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: mealTypes.entries.map((entry) {
                      final selected = selectedMealType == entry.key;
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedMealType = entry.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? FitGenieTheme.teal.withOpacity(0.18)
                                : FitGenieTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? FitGenieTheme.teal
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: selected
                                  ? FitGenieTheme.teal
                                  : FitGenieTheme.muted,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  FGCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Calculated Nutrition',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _macroRow('Calories', '${portion.calories} kcal',
                            FitGenieTheme.hot),
                        const SizedBox(height: 10),
                        _macroRow('Protein', '${portion.protein} g',
                            FitGenieTheme.teal),
                        const SizedBox(height: 10),
                        _macroRow(
                            'Carbs', '${portion.carbs} g', Colors.orange),
                        const SizedBox(height: 10),
                        _macroRow('Fats', '${portion.fats} g', Colors.purple),
                        if (portion.fiber > 0) ...[
                          const SizedBox(height: 10),
                          _macroRow('Fiber', '${portion.fiber} g',
                              Colors.green),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          'Serving: ${portion.quantityLabel}',
                          style: const TextStyle(
                            color: FitGenieTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final entry = MealEntry(
                          name: portion.name,
                          quantity: portion.quantityLabel,
                          mealType: selectedMealType,
                          calories: portion.calories,
                          protein: portion.protein,
                          carbs: portion.carbs,
                          fats: portion.fats,
                          source: 'database',
                        );

                        Navigator.pop(context, entry);
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add to Meal',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FitGenieTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  Widget _macroRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: FitGenieTheme.muted,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _foodTile(FoodItem food) {
    return GestureDetector(
      onTap: () => _openFoodConfigSheet(food),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: FGCard(
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: FitGenieTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: FitGenieTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${food.category} • ${food.servingLabel}',
                      style: const TextStyle(
                        color: FitGenieTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${food.calories} cal • ${food.protein}g P • ${food.carbs}g C • ${food.fats}g F',
                      style: const TextStyle(
                        fontSize: 11,
                        color: FitGenieTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (food.isEstimated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Est.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: FitGenieTheme.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = FoodDatabase.categories;

    return Scaffold(
      backgroundColor: FitGenieTheme.background,
      appBar: AppBar(
        backgroundColor: FitGenieTheme.cardDark,
        title: const Text('Search Food 🔎'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search e.g. anda, roti, daal, biryani...',
                hintStyle: const TextStyle(color: FitGenieTheme.muted),
                prefixIcon:
                const Icon(Icons.search, color: FitGenieTheme.muted),
                filled: true,
                fillColor: FitGenieTheme.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.clear,
                      color: FitGenieTheme.muted),
                )
                    : null,
              ),
            ),
          ),

          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: categories.map((category) {
                final selected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? FitGenieTheme.primary.withOpacity(0.18)
                            : FitGenieTheme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? FitGenieTheme.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected
                              ? FitGenieTheme.primary
                              : FitGenieTheme.muted,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Text(
                  '${_results.length} foods found',
                  style: const TextStyle(
                    color: FitGenieTheme.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _results.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 46,
                    color: FitGenieTheme.muted,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No food found',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try another keyword like anda, roti, daal',
                    style: TextStyle(
                      color: FitGenieTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                return _foodTile(_results[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}