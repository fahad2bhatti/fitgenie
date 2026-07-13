// lib/screens/saved_meals_screen.dart

import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';
import '../widgets/fg_card.dart';
import '../widgets/app_snackbar.dart';
import '../core/app_strings.dart';
import '../services/nutrition_service.dart';

class SavedMealsScreen extends StatefulWidget {
  final String userId;
  final bool pickerMode;

  const SavedMealsScreen({
    super.key,
    required this.userId,
    this.pickerMode = false,
  });

  @override
  State<SavedMealsScreen> createState() => _SavedMealsScreenState();
}

class _SavedMealsScreenState extends State<SavedMealsScreen> {
  final NutritionService _service = NutritionService();
  late Future<List<SavedMeal>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getSavedMeals(widget.userId);
  }

  void _reload() {
    setState(() {
      _future = _service.getSavedMeals(widget.userId);
    });
  }

  Future<void> _deleteMeal(String id) async {
    await _service.deleteSavedMeal(uid: widget.userId, savedMealId: id);
    _reload();

    if (mounted) {
      AppSnackbar.showSuccess(
        context,
        AppStrings.get('saved_delete_success'),
      );
    }
  }

  Future<void> _confirmDelete(SavedMeal meal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitGenieTheme.cardDark,
        title: Text(AppStrings.get('saved_delete_confirm')),
        content: Text(
          AppStrings.get('saved_delete_sub', params: {'name': meal.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: FitGenieTheme.error),
            child: Text(
              AppStrings.get('delete'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (ok == true && meal.id != null) {
      await _deleteMeal(meal.id!);
    }
  }

  String _mealEmoji(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return '🍳';
      case 'lunch':
        return '🍛';
      case 'dinner':
        return '🍽️';
      case 'snacks':
        return '🍿';
      default:
        return '🍴';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitGenieTheme.background,
      appBar: AppBar(
        backgroundColor: FitGenieTheme.cardDark,
        title: Text(
          widget.pickerMode
              ? AppStrings.get('saved_picker')
              : AppStrings.get('saved_title'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<SavedMeal>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final meals = snapshot.data ?? [];

          if (meals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border,
                        size: 52, color: FitGenieTheme.muted),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.get('saved_empty'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.get('saved_empty_sub'),
                      style: TextStyle(
                        color: FitGenieTheme.muted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                child: GestureDetector(
                  onTap: widget.pickerMode
                      ? () => Navigator.pop(context, meal)
                      : null,
                  child: FGCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: FitGenieTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  _mealEmoji(meal.mealType),
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meal.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${meal.items.length} items • ${meal.calories} cal',
                                    style: TextStyle(
                                      color: FitGenieTheme.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              color: FitGenieTheme.cardDark,
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _confirmDelete(meal);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                              child: const Icon(Icons.more_vert,
                                  color: FitGenieTheme.muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _infoTag('${meal.protein}g P', FitGenieTheme.teal),
                            _infoTag('${meal.carbs}g C', FitGenieTheme.warning),
                            _infoTag('${meal.fats}g F', Colors.purple),
                            _infoTag(meal.mealType.toUpperCase(), FitGenieTheme.primary),
                          ],
                        ),

                        const SizedBox(height: 12),

                        ...meal.items.take(4).map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.circle,
                                    size: 6, color: FitGenieTheme.muted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${item.name} (${item.quantity})',
                                    style: TextStyle(
                                      color: FitGenieTheme.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        if (meal.items.length > 4)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+${meal.items.length - 4} more items',
                              style: TextStyle(
                                color: FitGenieTheme.muted,
                                fontSize: 11,
                              ),
                            ),
                          ),

                        if (widget.pickerMode) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: FitGenieTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                AppStrings.get('saved_choose'),
                                style: TextStyle(
                                  color: FitGenieTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}