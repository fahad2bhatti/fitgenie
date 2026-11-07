// lib/widgets/set_timer_widgets.dart
//
// Two reusable widgets for the "active workout" flow:
//   - CircularStopwatch  : counts UP while a set is in progress
//   - CircularRestTimer  : counts DOWN between sets, adjustable, auto-completes
//
// Also includes `suggestedRestSeconds()` — a helper that picks a sensible
// default rest duration based on exercise difficulty + whether the set
// was taken to failure.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../app/fitgenie_theme.dart';

// ============================================================
// 🕐 REST DURATION SUGGESTION LOGIC
// ============================================================

/// Suggests a rest duration (in seconds) based on how demanding the set was.
/// - Harder exercises (Advanced) get more base rest.
/// - Sets taken to failure get extra rest on top.
int suggestedRestSeconds({
  required String difficulty,
  bool toFailure = false,
}) {
  int base;
  switch (difficulty.toLowerCase()) {
    case 'advanced':
      base = 120;
      break;
    case 'intermediate':
      base = 90;
      break;
    default:
      base = 60; // Beginner
  }
  if (toFailure) base += 30;
  return base;
}

// ============================================================
// ⏱️ CIRCULAR STOPWATCH (counts up during an active set)
// ============================================================

class CircularStopwatch extends StatefulWidget {
  /// Called every second with the elapsed duration so far.
  final ValueChanged<Duration>? onTick;

  /// Diameter of the circle.
  final double size;

  const CircularStopwatch({
    super.key,
    this.onTick,
    this.size = 220,
  });

  @override
  State<CircularStopwatch> createState() => CircularStopwatchState();
}

class CircularStopwatchState extends State<CircularStopwatch> {
  // timer-v2
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
      widget.onTick?.call(_elapsed);
    });
  }

  /// Stops the stopwatch and returns the total elapsed duration.
  Duration stop() {
    _timer?.cancel();
    _running = false;
    return _elapsed;
  }

  void reset() {
    _timer?.cancel();
    _running = false;
    setState(() => _elapsed = Duration.zero);
  }

  String get _formatted {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final progress = (_elapsed.inSeconds % 60) / 60;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(widget.size),
            painter: _RingPainter(
              progress: progress,
              color: _running ? FitGenieTheme.primary : FitGenieTheme.muted,
              trackColor: FitGenieTheme.border,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatted,
                style: t.displayLarge?.copyWith(fontSize: widget.size * 0.3),
              ),
              const SizedBox(height: 4),
              Text(
                (_running
                        ? AppStrings.get('timer_in_progress')
                        : AppStrings.get('timer_ready'))
                    .toUpperCase(),
                style: t.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 😮‍💨 CIRCULAR REST TIMER (counts down between sets)
// ============================================================

class CircularRestTimer extends StatefulWidget {
  /// Starting duration for the rest period.
  final int initialSeconds;

  /// Called when the countdown reaches zero.
  final VoidCallback? onComplete;

  /// Called when the user taps "Skip Rest".
  final VoidCallback? onSkip;

  final double size;

  const CircularRestTimer({
    super.key,
    required this.initialSeconds,
    this.onComplete,
    this.onSkip,
    this.size = 220,
  });

  @override
  State<CircularRestTimer> createState() => _CircularRestTimerState();
}

class _CircularRestTimerState extends State<CircularRestTimer> {
  late int _totalSeconds;
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.initialSeconds;
    _remaining = widget.initialSeconds;
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _timer?.cancel();
        setState(() => _remaining = 0);
        widget.onComplete?.call();
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  void _addTime(int seconds) {
    setState(() {
      _remaining = (_remaining + seconds).clamp(0, 600);
      _totalSeconds = _remaining > _totalSeconds ? _remaining : _totalSeconds;
    });
  }

  String get _formatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final progress = _totalSeconds == 0 ? 0.0 : _remaining / _totalSeconds;
    final urgent = _remaining > 0 && _remaining <= 5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _RingPainter(
                  progress: progress,
                  color: urgent ? FitGenieTheme.hot : FitGenieTheme.primary,
                  trackColor: FitGenieTheme.border,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatted,
                    style: t.displayLarge?.copyWith(
                      fontSize: widget.size * 0.3,
                      color: urgent ? FitGenieTheme.hot : FitGenieTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (_remaining == 0
                            ? AppStrings.get('timer_go_next')
                            : AppStrings.get('timer_rest'))
                        .toUpperCase(),
                    style: t.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pill('-15s', () => _addTime(-15)),
            const SizedBox(width: 10),
            _pill('+15s', () => _addTime(15)),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              _timer?.cancel();
              widget.onSkip?.call();
            },
            child: Text(AppStrings.get('timer_skip_rest').toUpperCase()),
          ),
        ),
      ],
    );
  }

  Widget _pill(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: FitGenieTheme.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: FitGenieTheme.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ⭕ THIN PROGRESS RING (used by stopwatch + rest timer)
// ============================================================

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
