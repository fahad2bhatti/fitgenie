// lib/shared/widgets/medical_disclaimer.dart
//
// Fixes Google Play "Health Content and Services" policy rejection.
// Google requires apps giving fitness/nutrition guidance to remind users
// to consult a healthcare professional.
//
// Usage:
// 1) MedicalDisclaimerDialog — show ONCE during onboarding (blocking, must accept).
// 2) MedicalDisclaimerBanner — small persistent reminder on AI Coach chat screen
//    and/or Dashboard (non-blocking).

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../app/fitgenie_theme.dart';

const String _kSettingsBoxName = 'app_settings';
const String _kDisclaimerAcceptedKey = 'medical_disclaimer_accepted_v1';

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

/// Blocking dialog shown once during onboarding.
/// User must tap "I Understand & Agree" to proceed — cannot be dismissed
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
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
                      const Text(
                        'Health Disclaimer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: FitGenieTheme.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'FitGenie provides general fitness and nutrition guidance '
                        'for informational purposes only. It is not medical advice '
                        'and is not a substitute for professional diagnosis or '
                        'treatment.\n\n'
                        'Please consult a qualified healthcare professional before '
                        'starting any new workout or nutrition program, especially '
                        'if you have any existing medical condition.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: FitGenieTheme.muted,
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
                  'professional medical advice.',
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