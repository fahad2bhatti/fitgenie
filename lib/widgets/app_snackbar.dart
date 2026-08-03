// lib/widgets/app_snackbar.dart
// Premium Glassmorphism Snackbar System — FitGenie Theme

import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';


class AppSnackbar {
  // ──────────────────────────────────────────
  // 🎯 Show Error Snackbar
  // ──────────────────────────────────────────
  static void showError(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
      }) {
    _show(
      context,
      message: message,
      type: SnackbarType.error,
      duration: duration,
    );
  }

  // ──────────────────────────────────────────
  // ✅ Show Success Snackbar
  // ──────────────────────────────────────────
  static void showSuccess(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
      }) {
    _show(
      context,
      message: message,
      type: SnackbarType.success,
      duration: duration,
    );
  }

  // ──────────────────────────────────────────
  // ℹ️ Show Info Snackbar
  // ──────────────────────────────────────────
  static void showInfo(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
      }) {
    _show(
      context,
      message: message,
      type: SnackbarType.info,
      duration: duration,
    );
  }

  // ──────────────────────────────────────────
  // ⚠️ Show Warning Snackbar
  // ──────────────────────────────────────────
  static void showWarning(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
      }) {
    _show(
      context,
      message: message,
      type: SnackbarType.warning,
      duration: duration,
    );
  }

  // ──────────────────────────────────────────
  // 🧠 Core Show Method
  // ──────────────────────────────────────────
  static void _show(
      BuildContext context, {
        required String message,
        required SnackbarType type,
        required Duration duration,
      }) {
    // Remove any existing snackbar
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    // Get colors based on type
    final colors = _getColors(type);

    // Show premium snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _buildContent(context, message, colors),  // ✅ FIX: Pass context
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // 🎨 Build Snackbar Content
  // ──────────────────────────────────────────
  static Widget _buildContent(
      BuildContext context,  // ✅ FIX: Added context parameter
      String message,
      _SnackbarColors colors,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.backgroundColor.withValues(alpha: 0.92),  // ✅ FIX: withValues
            colors.backgroundColor.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.backgroundColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: colors.backgroundColor.withValues(alpha: 0.1),
            blurRadius: 40,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.iconBackgroundColor,
              borderRadius: BorderRadius.circular(FitGenieTheme.radiusMD),
              border: Border.all(
                color: colors.iconColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              colors.icon,
              color: colors.iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: FitGenieTheme.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: FitGenieTheme.text.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(FitGenieTheme.radiusSM),
              ),
              child: Icon(
                Icons.close,
                color: FitGenieTheme.muted,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // 🎨 Get Colors by Type — Using FitGenieTheme
  // ──────────────────────────────────────────
  static _SnackbarColors _getColors(SnackbarType type) {
    switch (type) {
      case SnackbarType.error:
        return _SnackbarColors(
          backgroundColor: FitGenieTheme.error,
          borderColor: FitGenieTheme.error,
          icon: Icons.error_outline,
          iconColor: FitGenieTheme.error,
          iconBackgroundColor: FitGenieTheme.error.withValues(alpha: 0.2),
        );

      case SnackbarType.success:
        return _SnackbarColors(
          backgroundColor: FitGenieTheme.success,
          borderColor: FitGenieTheme.success,
          icon: Icons.check_circle_outline,
          iconColor: FitGenieTheme.success,
          iconBackgroundColor: FitGenieTheme.success.withValues(alpha: 0.2),
        );

      case SnackbarType.info:
        return _SnackbarColors(
          backgroundColor: FitGenieTheme.info,
          borderColor: FitGenieTheme.info,
          icon: Icons.info_outline,
          iconColor: FitGenieTheme.info,
          iconBackgroundColor: FitGenieTheme.info.withValues(alpha: 0.2),
        );

      case SnackbarType.warning:
        return _SnackbarColors(
          backgroundColor: FitGenieTheme.warning,
          borderColor: FitGenieTheme.warning,
          icon: Icons.warning_amber_outlined,
          iconColor: FitGenieTheme.warning,
          iconBackgroundColor: FitGenieTheme.warning.withValues(alpha: 0.2),
        );
    }
  }
}

// ──────────────────────────────────────────
// 📦 Helper Classes
// ──────────────────────────────────────────

enum SnackbarType { error, success, info, warning }

class _SnackbarColors {
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;

  _SnackbarColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
  });
}