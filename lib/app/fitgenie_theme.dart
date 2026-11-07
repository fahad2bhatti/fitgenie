import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FitGenie theme v2 — "Volt on Ink"
/// Drop-in replacement: all old member names are kept so existing screens compile.
///
/// Colour roles (use them by meaning, not by mood):
///   primary -> volt lime : main actions, active states, key numbers
///   hot     -> flame     : calories, streaks, intensity
///   teal    -> mint      : water, steps, recovery
///   ai      -> violet    : AI Coach only (so AI always feels distinct)
class FitGenieTheme {
  FitGenieTheme._();

  // ==========================================
  // 🎨 COLORS
  // ==========================================
  static const bg = Color(0xFF0C0C0E); // near-black, warm (no blue tint)
  static const card = Color(0xFF151518);
  static const card2 = Color(0xFF111114);

  static const primary = Color(0xFF6B6BFF); // volt lime
  static const teal = Color(0xFF6EE7D8); // mint (water / steps)
  static const hot = Color(0xFFFF5B3A); // flame (calories / streak)
  static const ai = Color(0xFF9D8CFF); // violet, AI Coach only

  static const text = Color(0xFFF4F4F0); // warm white
  static const muted = Color(0xFF8E8E96);

  /// Text/icon colour to place ON top of [primary] (lime needs dark text).
  static const onPrimary = Color(0xFFFFFFFF);
  static const Color buttonBlue = Color(0xFF6B6BFF);

  static Color get background => bg;
  static Color get cardDark => card2;

  // Additional Colors
  static const Color primaryLight = Color(0xFF8B8BFF);
  static const Color primaryDark = Color(0xFF4B4BDB);
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF4D4D);
  static const Color info = Color(0xFF5CC8FF);
  static const Color textSecondary = Color(0xFFB4B4BA);
  static const Color border = Color(0xFF26262B);
  static const Color divider = Color(0xFF1E1E22);

  // ==========================================
  // 📐 SPACING (8-pt scale)
  // ==========================================
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double screenPadding = 20.0;
  static const double cardPadding = 18.0;

  // ==========================================
  // 🔲 BORDER RADIUS (tighter = more athletic)
  // ==========================================
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 14.0;
  static const double radiusXL = 20.0;

  // ==========================================
  // ⏱️ ANIMATIONS
  // ==========================================
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);

  // ==========================================
  // 🔤 TEXT THEME
  // Barlow Condensed for big numbers/headlines, DM Sans for everything else.
  // ==========================================
  static TextTheme _textTheme(TextTheme base) {
    final body = GoogleFonts.dmSansTextTheme(base).apply(
      bodyColor: text,
      displayColor: text,
    );

    TextStyle display(double size) => GoogleFonts.barlowCondensed(
          fontSize: size,
          fontWeight: FontWeight.w700,
          height: 1.0,
          letterSpacing: -0.5,
          color: text,
        );

    return body.copyWith(
      displayLarge: display(60),
      displayMedium: display(46),
      displaySmall: display(36),
      headlineLarge: display(32),
      headlineMedium: display(28),
      headlineSmall: display(24),
      titleLarge: body.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyMedium: body.bodyMedium?.copyWith(height: 1.45),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
      labelSmall: body.labelSmall?.copyWith(
        color: muted,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ==========================================
  // 🎨 THEME DATA
  // ==========================================
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final radius = BorderRadius.circular(radiusLG);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: teal,
        tertiary: hot,
        surface: card,
        error: error,
        onPrimary: onPrimary,
        onSecondary: Colors.black,
        onSurface: text,
        outline: border,
      ),
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: text,
        centerTitle: false,
        titleTextStyle: GoogleFonts.barlowCondensed(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLG)),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: buttonBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: buttonBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: buttonBlue,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: const TextStyle(color: muted),
        labelStyle: const TextStyle(color: muted),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: card2,
        selectedItemColor: primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card2,
        indicatorColor: primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : muted,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: const TextStyle(color: text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          side: const BorderSide(color: border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusXL)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border,
        circularTrackColor: border,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: primary,
        side: const BorderSide(color: border),
        labelStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w600,
          color: text,
        ),
        secondaryLabelStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700,
          color: onPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? onPrimary : muted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? primary : border),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(onPrimary),
        side: const BorderSide(color: muted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

// ==========================================
// 🛠️ EXTENSIONS (unchanged)
// ==========================================

extension SpacingExtension on num {
  SizedBox get h => SizedBox(height: toDouble());
  SizedBox get w => SizedBox(width: toDouble());
}

extension PaddingExtension on Widget {
  Widget padAll(double value) => Padding(
        padding: EdgeInsets.all(value),
        child: this,
      );

  Widget padH(double value) => Padding(
        padding: EdgeInsets.symmetric(horizontal: value),
        child: this,
      );

  Widget padV(double value) => Padding(
        padding: EdgeInsets.symmetric(vertical: value),
        child: this,
      );
}
