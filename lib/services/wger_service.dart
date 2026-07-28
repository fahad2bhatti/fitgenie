// lib/services/wger_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ==========================================
// 📦 MODELS
// ==========================================

class WgerCategory {
  final int id;
  final String name;

  WgerCategory({required this.id, required this.name});

  factory WgerCategory.fromJson(Map<String, dynamic> json) {
    return WgerCategory(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? 'Unknown',
    );
  }
}

class WgerExercise {
  final int id;
  final String name;
  final String description;
  final String categoryName;
  final List<String> muscles;
  final List<String> secondaryMuscles;
  final List<String> equipment;
  final String? imageUrl;

  WgerExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryName,
    required this.muscles,
    required this.secondaryMuscles,
    required this.equipment,
    this.imageUrl,
  });

  factory WgerExercise.fromJson(Map<String, dynamic> json) {
    // Name & description live inside "translations" (per-language).
    // language == 2 is English. Fall back to the first available translation.
    final translations = (json['translations'] as List?) ?? [];
    Map<String, dynamic>? englishTranslation;
    for (final t in translations) {
      if (t is Map<String, dynamic> && t['language'] == 2) {
        englishTranslation = t;
        break;
      }
    }
    englishTranslation ??= translations.isNotEmpty
        ? translations.first as Map<String, dynamic>
        : null;

    final name = englishTranslation?['name']?.toString().trim() ?? '';
    final rawDescription = englishTranslation?['description']?.toString() ?? '';

    final categoryJson = json['category'] as Map<String, dynamic>?;
    final categoryName = categoryJson?['name']?.toString() ?? 'General';

    final muscles = ((json['muscles'] as List?) ?? [])
        .map((m) => (m is Map ? (m['name_en'] ?? m['name'] ?? '') : '').toString())
        .where((s) => s.isNotEmpty)
        .toList();

    final secondaryMuscles = ((json['muscles_secondary'] as List?) ?? [])
        .map((m) => (m is Map ? (m['name_en'] ?? m['name'] ?? '') : '').toString())
        .where((s) => s.isNotEmpty)
        .toList();

    final equipment = ((json['equipment'] as List?) ?? [])
        .map((e) => (e is Map ? (e['name'] ?? '') : '').toString())
        .where((s) => s.isNotEmpty)
        .toList();

    final images = (json['images'] as List?) ?? [];
    String? imageUrl;
    if (images.isNotEmpty && images.first is Map) {
      imageUrl = (images.first as Map)['image']?.toString();
    }

    return WgerExercise(
      id: json['id'] as int? ?? 0,
      name: name.isEmpty ? 'Unnamed Exercise' : name,
      description: _stripHtml(rawDescription),
      categoryName: categoryName,
      muscles: muscles,
      secondaryMuscles: secondaryMuscles,
      equipment: equipment,
      imageUrl: imageUrl,
    );
  }

  static String _stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .trim();
  }
}

// ==========================================
// 🏋️ WGER SERVICE
// Free exercise database. No API key needed for read-only endpoints.
// ==========================================
class WgerService {
  static const String _baseUrl = 'https://wger.de/api/v2';
  static const Duration _timeout = Duration(seconds: 15);
  static const int _englishLanguageId = 2;

  /// Fetches all exercise categories (Chest, Back, Legs, Arms, Abs, Cardio...).
  Future<List<WgerCategory>> getCategories() async {
    try {
      final url = Uri.parse('$_baseUrl/exercisecategory/?limit=50');
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint('❌ Wger categories error: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? [];
      return results
          .map((c) => WgerCategory.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Wger categories exception: $e');
      return [];
    }
  }

  /// Fetches exercises, optionally filtered by category ID.
  /// Uses /exerciseinfo/ which returns the full combined data
  /// (name, description, muscles, equipment, images) in one call.
  Future<List<WgerExercise>> getExercises({int? categoryId, int limit = 50}) async {
    try {
      final params = {
        'language': '$_englishLanguageId',
        'limit': '$limit',
        if (categoryId != null) 'category': '$categoryId',
      };

      final url = Uri.parse('$_baseUrl/exerciseinfo/').replace(queryParameters: params);
      debugPrint('🔍 Wger fetch: $url');

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint('❌ Wger exercises error: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? [];

      final exercises = results
          .map((e) => WgerExercise.fromJson(e as Map<String, dynamic>))
          .where((e) => e.name != 'Unnamed Exercise') // skip untranslated junk entries
          .toList();

      debugPrint('✅ Wger fetched ${exercises.length} exercises');
      return exercises;
    } catch (e) {
      debugPrint('❌ Wger exercises exception: $e');
      return [];
    }
  }
}