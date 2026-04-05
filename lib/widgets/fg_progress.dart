import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';

class FGLinearProgress extends StatelessWidget {
  final double value; // 0..1
  final Color color;

  const FGLinearProgress({
    super.key,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 10,
        color: Colors.white.withOpacity(0.08),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, FitGenieTheme.primary.withOpacity(0.95)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}