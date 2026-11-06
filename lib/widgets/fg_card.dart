// lib/widgets/fg_card.dart

import 'package:flutter/material.dart';

import '../app/fitgenie_theme.dart';

/// FitGenie surface. Flat, solid, thin border. No glass, no glow.
/// Same constructor as before, so every existing screen keeps working.
/// Tap now gets a proper ripple (the old GestureDetector had none).
class FGCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  const FGCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.border,
    this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final radius =
        BorderRadius.circular(borderRadius ?? FitGenieTheme.radiusLG);

    return Container(
      decoration: BoxDecoration(
        color: color ?? FitGenieTheme.card,
        borderRadius: radius,
        border: border ?? Border.all(color: FitGenieTheme.border),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: FitGenieTheme.primary.withValues(alpha: 0.08),
            highlightColor: FitGenieTheme.primary.withValues(alpha: 0.04),
            child: Padding(
              padding:
                  padding ?? const EdgeInsets.all(FitGenieTheme.cardPadding),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
