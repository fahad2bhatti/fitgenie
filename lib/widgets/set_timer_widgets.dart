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
import 'package:flutter/material.dart';
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
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: null, // indeterminate spinner style while active
              strokeWidth: 8,
              backgroundColor: FitGenieTheme.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                _running ? FitGenieTheme.primary : FitGenieTheme.muted,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatted,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _running ? 'SET IN PROGRESS' : 'READY',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: FitGenieTheme.muted,
                ),
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
    final progress = _totalSeconds == 0 ? 0.0 : _remaining / _totalSeconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: FitGenieTheme.background,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    FitGenieTheme.success,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatted,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _remaining == 0 ? 'GO! NEXT SET' : 'REST',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: FitGenieTheme.muted,
                    ),
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
            _pillButton('-15s', () => _addTime(-15)),
            const SizedBox(width: 10),
            _pillButton('+15s', () => _addTime(15)),
            const SizedBox(width: 10),
            _pillButton('Skip Rest', () {
              _timer?.cancel();
              widget.onSkip?.call();
            }, filled: true),
          ],
        ),
      ],
    );
  }

  Widget _pillButton(String label, VoidCallback onTap, {bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? FitGenieTheme.primary : FitGenieTheme.card,
          borderRadius: BorderRadius.circular(24),
          border: filled
              ? null
              : Border.all(color: FitGenieTheme.muted.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : FitGenieTheme.muted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}