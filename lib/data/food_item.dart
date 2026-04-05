// lib/data/food_item.dart

class FoodItem {
  final String id;
  final String name;
  final List<String> aliases;
  final String category;
  final String servingLabel; // e.g. 1 roti, 1 katori, 1 plate
  final int servingGrams;

  // Per serving values
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final int fiber;

  final bool isEstimated;

  const FoodItem({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.category,
    required this.servingLabel,
    required this.servingGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.fiber = 0,
    this.isEstimated = false,
  });

  bool matchesQuery(String query) {
    final q = _normalize(query);
    if (q.isEmpty) return true;

    if (_normalize(name).contains(q)) return true;
    if (_normalize(category).contains(q)) return true;

    for (final alias in aliases) {
      if (_normalize(alias).contains(q)) return true;
    }

    return false;
  }

  FoodPortion calculatePortion(double multiplier) {
    return FoodPortion(
      foodId: id,
      name: name,
      category: category,
      quantityLabel: multiplier == 1
          ? servingLabel
          : '${_formatMultiplier(multiplier)} × $servingLabel',
      calories: (calories * multiplier).round(),
      protein: (protein * multiplier).round(),
      carbs: (carbs * multiplier).round(),
      fats: (fats * multiplier).round(),
      fiber: (fiber * multiplier).round(),
      isEstimated: isEstimated,
    );
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _formatMultiplier(double value) {
    if (value == value.toInt()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class FoodPortion {
  final String foodId;
  final String name;
  final String category;
  final String quantityLabel;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final int fiber;
  final bool isEstimated;

  const FoodPortion({
    required this.foodId,
    required this.name,
    required this.category,
    required this.quantityLabel,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.fiber,
    required this.isEstimated,
  });

  Map<String, dynamic> toMealEntryMap({
    required String mealType,
    String source = 'database',
  }) {
    return {
      'foodId': foodId,
      'name': name,
      'quantity': quantityLabel,
      'mealType': mealType,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'fiber': fiber,
      'source': source,
      'isEstimated': isEstimated,
    };
  }
}