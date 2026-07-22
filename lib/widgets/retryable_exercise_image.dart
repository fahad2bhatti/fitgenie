// lib/widgets/retryable_exercise_image.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app/fitgenie_theme.dart';

/// Exercise GIF with automatic + tap-to-retry on load failure.
/// Fixes intermittent GIF-not-loading issue caused by third-party
/// CDN flakiness (fitnessprogramer.com) under concurrent requests.
class RetryableExerciseImage extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const RetryableExerciseImage({
    super.key,
    required this.imageUrl,
    this.width = 72,
    this.height = 72,
    this.borderRadius,
  });

  @override
  State<RetryableExerciseImage> createState() =>
      _RetryableExerciseImageState();
}

class _RetryableExerciseImageState extends State<RetryableExerciseImage> {
  int _retryCount = 0;
  static const int _maxAutoRetries = 2;

  void _retry() {
    if (mounted) {
      setState(() => _retryCount++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        // Key changes on retry -> forces a fresh network attempt
        key: ValueKey('${widget.imageUrl}_$_retryCount'),
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (c, u) => Container(
          width: widget.width,
          height: widget.height,
          color: FitGenieTheme.background,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (c, u, e) {
          // Auto-retry silently a couple of times (handles transient drops)
          if (_retryCount < _maxAutoRetries) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(milliseconds: 800), _retry);
            });
          }

          return GestureDetector(
            onTap: _retry,
            child: Container(
              width: widget.width,
              height: widget.height,
              color: FitGenieTheme.background,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center, color: Colors.white24),
                  if (_retryCount >= _maxAutoRetries) ...[
                    const SizedBox(height: 4),
                    Icon(Icons.refresh,
                        size: 14, color: FitGenieTheme.muted),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}