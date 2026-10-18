// lib/services/update_service.dart
//
// Google Play in-app update (immediate / forced).
// Naya version Play Store pe aate hi user ko dialog dikhta hai;
// update karne ke baad app khud restart hoti hai.
// NOTE: sirf Play Store se install ki hui build pe kaam karta hai
// (debug / sideload APK pe nahi).

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';

import '../core/language_provider.dart';

class UpdateService {
  UpdateService._();

  static bool _checked = false;

  static Future<void> checkAndPrompt(BuildContext context) async {
    if (_checked || kDebugMode || !Platform.isAndroid) return;
    _checked = true;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;
      if (!info.immediateUpdateAllowed) return;
      if (!context.mounted) return;
      await _showForceUpdateDialog(context);
    } catch (e) {
      // Play Store na ho / network issue / sideload: chup-chap app chalne do
      debugPrint('⚠️ Update check failed: $e');
    }
  }

  static Future<void> _showForceUpdateDialog(BuildContext context) async {
    final en = LanguageProvider().isEnglish;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(en ? 'Update available' : 'Naya update aa gaya hai'),
          content: Text(
            en
                ? 'A new version of FitGenie is available. Please update to keep using the app.'
                : 'FitGenie ka naya version available hai. App use karne ke liye pehle update karo.',
          ),
          actions: [
            TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: Text(en ? 'Exit' : 'Band karo'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final result = await InAppUpdate.performImmediateUpdate();
                  // success: Play app ko khud restart kar deta hai
                  // userDeniedUpdate / failed: dialog khula rehta hai, dobara try kar sakte hain
                  debugPrint('Update result: $result');
                } catch (e) {
                  debugPrint('⚠️ performImmediateUpdate error: $e');
                }
              },
              child: Text(en ? 'Update now' : 'Update karo'),
            ),
          ],
        ),
      ),
    );
  }
}
