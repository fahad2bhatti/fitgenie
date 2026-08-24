// lib/shared/widgets/medical_disclaimer.dart
//
// Fixes Google Play "Health Content and Services" policy rejection.
// Google requires apps giving fitness/nutrition guidance to remind users
// to consult a healthcare professional — this now covers BOTH health/fitness
// AND food/nutrition (AI meal scanner, calorie/macro estimates).
//
// Usage:
// 1) MedicalDisclaimerDialog ? show ONCE during onboarding (blocking, must accept).
// 2) MedicalDisclaimerBanner ? small persistent reminder on AI Coach chat screen
//    and/or Dashboard (non-blocking).

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../app/fitgenie_theme.dart';
import '../core/app_strings.dart';

const String _kSettingsBoxName = 'app_settings';
const String _kDisclaimerAcceptedKey = 'medical_disclaimer_accepted_v1';
const String _kWorkoutInjuryWarningKey = 'workout_injury_warning_shown_v1';

/// Call this once at app startup (e.g. in splash/auth redirect logic)
/// to check whether the user has already accepted the disclaimer.
Future<bool> hasAcceptedMedicalDisclaimer() async {
  final box = await Hive.openBox(_kSettingsBoxName);
  return box.get(_kDisclaimerAcceptedKey, defaultValue: false) as bool;
}

Future<void> _markDisclaimerAccepted() async {
  final box = await Hive.openBox(_kSettingsBoxName);
  await box.put(_kDisclaimerAcceptedKey, true);
}

Future<bool> _hasSeenWorkoutInjuryWarning() async {
  final box = await Hive.openBox(_kSettingsBoxName);
  return box.get(_kWorkoutInjuryWarningKey, defaultValue: false) as bool;
}

Future<void> _markWorkoutInjuryWarningSeen() async {
  final box = await Hive.openBox(_kSettingsBoxName);
  await box.put(_kWorkoutInjuryWarningKey, true);
}

/// Call this from a Workout screen's initState (NOT the medical disclaimer
/// dialog — this is a separate, lighter, non-blocking warning specific to
/// starting a workout). Shown as a SnackBar exactly ONCE ever per install
/// (persisted in Hive) — never shown again after the first time, even if
/// the user opens the Workout screen again.
void showWorkoutInjuryWarningIfNeeded(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final alreadySeen = await _hasSeenWorkoutInjuryWarning();
    if (alreadySeen || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: FitGenieTheme.warning, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.get('workout_injury_warning'),
                style: const TextStyle(
                    color: FitGenieTheme.text, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: FitGenieTheme.card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: FitGenieTheme.warning.withValues(alpha: 0.4)),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );

    await _markWorkoutInjuryWarningSeen();
  });
}

/// Blocking dialog shown once during onboarding.
/// User must tap "I Understand & Agree" to proceed ? cannot be dismissed
/// by tapping outside or back button.
class MedicalDisclaimerDialog extends StatelessWidget {
  const MedicalDisclaimerDialog({super.key});

  /// Shows the dialog and returns true once the user accepts.
  static Future<void> showIfNeeded(BuildContext context) async {
    final alreadyAccepted = await hasAcceptedMedicalDisclaimer();
    if (alreadyAccepted || !context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MedicalDisclaimerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              // 👇 FIX 1: cap the whole dialog's height to the screen
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: FitGenieTheme.card.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(FitGenieTheme.radiusXL),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.health_and_safety_outlined,
                          color: FitGenieTheme.primary, size: 28),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Health & Nutrition Disclaimer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: FitGenieTheme.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 👇 FIX 2: Flexible + Scrollbar so text scrolls
                  // instead of pushing the button off-screen
                  Flexible(
                    child: Scrollbar(
                      thumbVisibility: true,
                      radius: const Radius.circular(8),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'FitGenie provides general fitness and nutrition guidance '
                              'for informational purposes only. It is not medical or '
                              'dietary advice and is not a substitute for professional '
                              'diagnosis or treatment.\n\n'
                              'Calorie, macro, and nutrition data — including AI Meal '
                              'Scanner results and food search estimates — are '
                              'AI-generated or database-sourced estimates and may not '
                              'be fully accurate. FitGenie does not verify allergen '
                              'information; if you have food allergies or '
                              'intolerances, always check ingredients yourself before '
                              'eating.\n\n'
                              'Please consult a qualified healthcare professional or '
                              'registered dietitian before starting any new workout '
                              'or nutrition program, especially if you have any '
                              'existing medical condition, food allergy, or are '
                              'pregnant.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: FitGenieTheme.muted,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FitGenieTheme.primary,
                        foregroundColor: FitGenieTheme.text,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(FitGenieTheme.radiusMD),
                        ),
                      ),
                      onPressed: () async {
                        await _markDisclaimerAccepted();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text(
                        'I Understand & Agree',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small persistent, non-blocking reminder banner.
/// Drop this at the top of the AI Coach chat screen and/or Dashboard.
class MedicalDisclaimerBanner extends StatelessWidget {
  const MedicalDisclaimerBanner({super.key, this.compact = false});

  /// Use compact=true for a single-line version (e.g. inside chat AppBar area).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(FitGenieTheme.radiusMD),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.info_outline,
              size: compact ? 14 : 16, color: FitGenieTheme.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'For informational purposes only. Not a substitute for '
                  'professional medical or dietary advice.',
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                color: FitGenieTheme.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


