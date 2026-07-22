// lib/widgets/active_set_sheet.dart
//
// Full replacement for the old "Log Set" modal.
// Flow: tap "Start Set" -> stopwatch runs -> tap "Finish Set" -> set is
// logged automatically -> rest timer auto-starts -> rest ends -> sheet closes,
// ready for the next set.

import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';
import '../data/exercise_data.dart';
import 'set_timer_widgets.dart';

enum _SetPhase { performing, resting }

class ActiveSetSheet extends StatefulWidget {
  /// The exercise being performed (for name, difficulty, GIF).
  final Exercise? exercise;
  final String exerciseNameFallback;

  /// Starting weight/reps, pulled from the workout's saved config.
  final double initialWeight;
  final String initialReps;

  /// e.g. "Set 2 of 3"
  final String setLabel;

  /// Called once the set is finished (before rest starts) so the parent
  /// can persist it to Firestore / local state.
  final void Function(double weight, String reps, int durationSeconds, bool toFailure)
  onSetLogged;

  const ActiveSetSheet({
    super.key,
    required this.exercise,
    required this.exerciseNameFallback,
    required this.initialWeight,
    required this.initialReps,
    required this.setLabel,
    required this.onSetLogged,
  });

  @override
  State<ActiveSetSheet> createState() => _ActiveSetSheetState();
}

class _ActiveSetSheetState extends State<ActiveSetSheet> {
  final _stopwatchKey = GlobalKey<CircularStopwatchState>();

  _SetPhase _phase = _SetPhase.performing;
  late double _weight;
  late String _reps;
  bool _toFailure = false;
  int _restSeconds = 60;

  @override
  void initState() {
    super.initState();
    _weight = widget.initialWeight;
    _reps = widget.initialReps;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stopwatchKey.currentState?.start();
    });
  }

  void _adjustWeight(double delta) {
    setState(() => _weight = (_weight + delta).clamp(0, 500));
  }

  void _adjustReps(int delta) {
    final current = int.tryParse(_reps.replaceAll(RegExp(r'[^0-9]'), '')) ?? 12;
    final next = (current + delta).clamp(1, 100);
    setState(() => _reps = '$next');
  }

  void _finishSet() {
    final elapsed = _stopwatchKey.currentState?.stop() ?? Duration.zero;

    widget.onSetLogged(_weight, _reps, elapsed.inSeconds, _toFailure);

    final difficulty = widget.exercise?.difficulty ?? 'Beginner';
    _restSeconds = suggestedRestSeconds(
      difficulty: difficulty,
      toFailure: _toFailure,
    );

    setState(() => _phase = _SetPhase.resting);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.exercise?.name ?? widget.exerciseNameFallback;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: FitGenieTheme.cardDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.setLabel,
                      style: TextStyle(color: FitGenieTheme.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (_phase == _SetPhase.performing)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _stopwatchKey.currentState?.stop();
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (_phase == _SetPhase.performing) ...[
            CircularStopwatch(key: _stopwatchKey, size: 200),
            const SizedBox(height: 24),

            // Weight stepper
            _stepperRow(
              label: 'Weight',
              value: '${_weight.toStringAsFixed(_weight % 1 == 0 ? 0 : 1)} kg',
              onMinus: () => _adjustWeight(-2.5),
              onPlus: () => _adjustWeight(2.5),
            ),
            const SizedBox(height: 12),

            // Reps stepper
            _stepperRow(
              label: 'Reps',
              value: _reps,
              onMinus: () => _adjustReps(-1),
              onPlus: () => _adjustReps(1),
            ),
            const SizedBox(height: 16),

            // To failure toggle
            Row(
              children: [
                Switch(
                  value: _toFailure,
                  activeThumbColor: FitGenieTheme.primary,
                  onChanged: (v) => setState(() => _toFailure = v),
                ),
                const SizedBox(width: 8),
                Text(
                  'Went to failure?',
                  style: TextStyle(color: FitGenieTheme.muted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _finishSet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FitGenieTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Finish Set ✅',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ] else ...[
            CircularRestTimer(
              initialSeconds: _restSeconds,
              onComplete: () {
                if (mounted) Navigator.pop(context);
              },
              onSkip: () {
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepperRow({
    required String label,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        Row(
          children: [
            _circleIconButton(Icons.remove, onMinus),
            SizedBox(
              width: 70,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _circleIconButton(Icons.add, onPlus),
          ],
        ),
      ],
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: FitGenieTheme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}