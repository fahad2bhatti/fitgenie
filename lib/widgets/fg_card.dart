// lib/widgets/fg_card.dart

import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(FitGenieTheme.cardPadding),
        decoration: BoxDecoration(
          color: color ?? FitGenieTheme.card,
          borderRadius: BorderRadius.circular(borderRadius ?? FitGenieTheme.radiusLG),
          border: border ?? Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: boxShadow,
        ),
        child: child,
      ),
    );
  }
}