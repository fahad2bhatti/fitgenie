// lib/core/language_provider.dart
// Language Provider — Persists user language preference

import 'package:flutter/material.dart';
import 'hive_boxes.dart';

class LanguageProvider extends ChangeNotifier {
  static final LanguageProvider _instance = LanguageProvider._internal();
  factory LanguageProvider() => _instance;
  LanguageProvider._internal();

  bool _isEnglish = true;
  bool get isEnglish => _isEnglish;

  // ──────────────────────────────────────────
  // 🔄 Initialize
  // ──────────────────────────────────────────
  void init() {
    final saved = HiveBoxes.settingsBox.get('language', defaultValue: 'en');
    _isEnglish = saved == 'en';
    notifyListeners();
  }

  // ──────────────────────────────────────────
  // 🌐 Toggle Language
  // ──────────────────────────────────────────
  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    HiveBoxes.settingsBox.put('language', _isEnglish ? 'en' : 'ur');
    notifyListeners();
  }

  // ──────────────────────────────────────────
  // 🌐 Set Language
  // ──────────────────────────────────────────
  void setLanguage(bool isEnglish) {
    _isEnglish = isEnglish;
    HiveBoxes.settingsBox.put('language', _isEnglish ? 'en' : 'ur');
    notifyListeners();
  }

  // ──────────────────────────────────────────
  // 🔍 Check if language is selected
  // ──────────────────────────────────────────
  bool get isLanguageSelected {
    return HiveBoxes.settingsBox.containsKey('language');
  }

  // ──────────────────────────────────────────
  // 🗑️ Reset (for testing)
  // ──────────────────────────────────────────
  void reset() {
    HiveBoxes.settingsBox.delete('language');
    _isEnglish = true;
    notifyListeners();
  }
}