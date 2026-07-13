// lib/core/hive_boxes.dart

import 'package:flutter/foundation.dart';  // ✅ ADD THIS IMPORT
import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  static const String _settingsBoxName = 'settings_box';

  static late Box _settingsBox;

  // ──────────────────────────────────────────
  // 🚀 Initialize
  // ──────────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();

    _settingsBox = await Hive.openBox(_settingsBoxName);

    debugPrint('✅ Hive boxes initialized: $_settingsBoxName');  // ✅ FIX: Added import
  }

  // ──────────────────────────────────────────
  // 📦 Get Boxes
  // ──────────────────────────────────────────
  static Box get settingsBox => _settingsBox;
}