// lib/widgets/active_set_sheet.dart
//
// Full replacement for the old "Log Set" modal.
// Flow: tap "Start Set" -> stopwatch runs -> tap "Finish Set" -> set is
// logged automatically -> rest timer auto-starts -> rest ends -> sheet closes,
// ready for the next set.

import 'package:flutter/material.dart';
import '../core/app_strings.dart';
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

  /// Rest between sets (from the workout plan). When null, a
  /// difficulty-based suggestion is used.
  final int? restSeconds;

  /// Called once the set is finished (before rest starts) so the parent
  /// can persist it to Firestore / local state.
  final Future<void> Function(
          double weight, String reps, int durationSeconds, bool toFailure)
      onSetLogged;

  const ActiveSetSheet({
    super.key,
    required this.exercise,
    required this.exerciseNameFallback,
    required this.initialWeight,
    required this.initialReps,
    required this.setLabel,
    required this.onSetLogged,
    this.restSeconds,
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

  void _finishSet() async {
    final elapsed = _stopwatchKey.currentState?.stop() ?? Duration.zero;

    try {
      await widget.onSetLogged(_weight, _reps, elapsed.inSeconds, _toFailure);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get('set_save_error'))),
        );
      }
    }

    if (!mounted) return;

    final difficulty = widget.exercise?.difficulty ?? 'Beginner';
    _restSeconds = widget.restSeconds ??
        suggestedRestSeconds(
          difficulty: difficulty,
          toFailure: _toFailure,
        );

    setState(() => _phase = _SetPhase.resting);
  }

  @override
  Widget build(BuildContext context) {
    // set-sheet-v2
    final t = Theme.of(context).textTheme;
    final name = widget.exercise?.name ?? widget.exerciseNameFallback;
    final performing = _phase == _SetPhase.performing;
    final hasGif = widget.exercise != null && widget.exercise!.hasGif;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: FitGenieTheme.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(FitGenieTheme.radiusXL),
          ),
          border: Border(top: BorderSide(color: FitGenieTheme.border)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: FitGenieTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.setLabel.toUpperCase(),
                          style: t.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name.toUpperCase(),
                          style: t.headlineSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (performing)
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: FitGenieTheme.muted),
                      onPressed: () {
                        _stopwatchKey.currentState?.stop();
                        Navigator.pop(context, false);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (performing) ...[
                if (hasGif) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
                    child: Image.asset(
                      widget.exercise!.gifAsset,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Center(child: CircularStopwatch(key: _stopwatchKey, size: 170)),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _stepperRow(
                        label: AppStrings.get('set_weight'),
                        value:
                            _weight.toStringAsFixed(_weight % 1 == 0 ? 0 : 1),
                        unit: 'kg',
                        onMinus: () => _adjustWeight(-2.5),
                        onPlus: () => _adjustWeight(2.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _stepperRow(
                        label: AppStrings.get('set_reps'),
                        value: _reps,
                        onMinus: () => _adjustReps(-1),
                        onPlus: () => _adjustReps(1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(FitGenieTheme.radiusMD),
                    border: Border.all(color: FitGenieTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.get('set_failure'),
                          style: const TextStyle(
                            color: FitGenieTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch(
                        value: _toFailure,
                        onChanged: (v) => setState(() => _toFailure = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _finishSet,
                  child: Text(AppStrings.get('set_finish').toUpperCase()),
                ),
              ] else
                CircularRestTimer(
                  initialSeconds: _restSeconds,
                  onComplete: () {
                    if (mounted) Navigator.pop(context, true);
                  },
                  onSkip: () {
                    if (mounted) Navigator.pop(context, true);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepperRow({
    required String label,
    required String value,
    String? unit,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FitGenieTheme.card2,
        borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
        border: Border.all(color: FitGenieTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: t.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: t.displaySmall),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: FitGenieTheme.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleIconButton(Icons.remove_rounded, onMinus),
              _circleIconButton(Icons.add_rounded, onPlus, filled: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton(
    IconData icon,
    VoidCallback onTap, {
    bool filled = false,
  }) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? FitGenieTheme.primary : Colors.transparent,
          border: Border.all(
            color: filled ? FitGenieTheme.primary : FitGenieTheme.border,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: filled ? FitGenieTheme.onPrimary : FitGenieTheme.text,
        ),
      ),
    );
  }
}
