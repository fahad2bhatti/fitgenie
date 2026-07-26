// lib/services/open_food_facts_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'ai_service.dart'; // reuses the existing MealAnalysis model

// ==========================================
// 🍏 OPEN FOOD FACTS SERVICE
// Free, no API key needed. Barcode -> real packaged-food nutrition data.
// ==========================================
class OpenFoodFactsService {
  static const Duration _timeout = Duration(seconds: 15);
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  /// Looks up a product by barcode and maps it into the app's MealAnalysis
  /// model, so the existing UI (card / nutrition grid / health tip) works
  /// with zero changes. Returns null if the product isn't found or the
  /// request fails — caller should fall back gracefully (e.g. offer AI scan
  /// or manual entry).
  Future<MealAnalysis?> getProductByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    try {
      final url = Uri.parse(
        '$_baseUrl/$cleanBarcode.json'
            '?fields=product_name,nutriments,quantity,serving_size,nutriscore_grade,brands',
      );

      debugPrint('🔍 OpenFoodFacts lookup: $cleanBarcode');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint('❌ OpenFoodFacts HTTP error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // status == 1 means product found; status == 0 means not in database
      if (data['status'] != 1 || data['product'] == null) {
        debugPrint('⚠️ Product not found for barcode: $cleanBarcode');
        return null;
      }

      final product = data['product'] as Map<String, dynamic>;
      final nutriments = (product['nutriments'] as Map<String, dynamic>?) ?? {};

      final rawName = product['product_name']?.toString().trim() ?? '';
      final brand = product['brands']?.toString().trim() ?? '';
      final displayName = rawName.isNotEmpty
          ? rawName
          : (brand.isNotEmpty ? brand : 'Unknown Product');

      final grade = product['nutriscore_grade']?.toString().toLowerCase();
      final isHealthy = grade == null || grade == 'a' || grade == 'b';

      final quantityLabel = (product['serving_size']?.toString().isNotEmpty ?? false)
          ? '${product['serving_size']} (per 100g values)'
          : 'per 100g';

      return MealAnalysis(
        foodName: _truncate(displayName, 100),
        foodNameHindi: _truncate(displayName, 100),
        calories: _num(nutriments['energy-kcal_100g']),
        protein: _num(nutriments['proteins_100g']),
        carbs: _num(nutriments['carbohydrates_100g']),
        fat: _num(nutriments['fat_100g']),
        fiber: _num(nutriments['fiber_100g']),
        quantity: quantityLabel,
        isHealthy: isHealthy,
        healthTip: grade != null
            ? 'Nutri-Score: ${grade.toUpperCase()} — ${isHealthy ? "acha choice hai!" : "kam khao, ya alternative dhoondo."}'
            : 'Nutri-Score is product ke lia available nahi hai.',
      );
    } catch (e) {
      debugPrint('❌ OpenFoodFacts exception: $e');
      return null;
    }
  }

  int _num(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return double.tryParse(value)?.round() ?? 0;
    return 0;
  }

  String _truncate(String s, int max) => s.length > max ? s.substring(0, max) : s;
}