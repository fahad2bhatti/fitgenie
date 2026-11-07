// apply_set_sheet_redesign.dart
//
// 1) Set sheet (active_set_sheet.dart + set_timer_widgets.dart) naye design mein:
//    * Header: "SET 2 / 3" chhota label + exercise ka naam bade Barlow mein
//    * Stopwatch / rest timer: patli gol ring (har minute ghoomti hai), bada number,
//      rest ke aakhri 5 second number laal (flame) ho jata hai
//    * Weight aur Reps: do bade card side-by-side (bada number, gole - / + buttons)
//    * To failure: simple bordered row, Finish: seedha text button (koi icon nahi)
//    * Rest: -15s / +15s patli pills, neeche bada SKIP REST button
//    * Sheet ab scroll hoti hai (chhoti screen par overflow nahi)
// 2) Coach tip (workout_screen.dart): lamba message ab poora dikhta hai
//    (3 lines + MORE/LESS tap), violet neon card ki jagah normal card, sparkle icon nahi
// 3) Buttons se icon hata diye (Start Workout, SET n pill, hub ka START pill)
//
// Chalane ka tareeqa (project root mein):
//   git add -A && git commit -m "before set sheet redesign"
//   cp ~/Downloads/apply_set_sheet_redesign.dart .
//   dart apply_set_sheet_redesign.dart
//   dart format lib/screens lib/widgets
//   dart analyze lib/screens lib/widgets
//   flutter run
//
// Backup: ~/fitgenie_backups/*.bak

import 'dart:io';

const _sheetPath = 'lib/widgets/active_set_sheet.dart';
const _timerPath = 'lib/widgets/set_timer_widgets.dart';
const _screenPath = 'lib/screens/workout_screen.dart';

int _skipString(String s, int i) {
  final q = s[i];
  i++;
  while (i < s.length) {
    final c = s[i];
    if (c == r'\') {
      i += 2;
      continue;
    }
    if (c == q) return i + 1;
    if (c == r'$' && i + 1 < s.length && s[i + 1] == '{') {
      final end = _skipBlock(s, i + 1);
      if (end == -1) return s.length;
      i = end;
      continue;
    }
    i++;
  }
  return i;
}

int _skipBlock(String s, int open) {
  var depth = 0;
  var i = open;
  while (i < s.length) {
    final c = s[i];
    if (c == '/' && i + 1 < s.length && s[i + 1] == '/') {
      while (i < s.length && s[i] != '\n') {
        i++;
      }
      continue;
    }
    if (c == '/' && i + 1 < s.length && s[i + 1] == '*') {
      final e = s.indexOf('*/', i + 2);
      i = e == -1 ? s.length : e + 2;
      continue;
    }
    if (c == "'" || c == '"') {
      i = _skipString(s, i);
      continue;
    }
    if (c == '{') depth++;
    if (c == '}') {
      depth--;
      if (depth == 0) return i + 1;
    }
    i++;
  }
  return -1;
}

List<int>? _findMethod(String src, String signature) {
  final start = src.indexOf(signature);
  if (start == -1) return null;
  final p = src.indexOf('(', start);
  if (p == -1) return null;
  var depth = 0;
  var i = p;
  while (i < src.length) {
    final c = src[i];
    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) {
        i++;
        break;
      }
    }
    i++;
  }
  final open = src.indexOf('{', i);
  if (open == -1) return null;
  final end = _skipBlock(src, open);
  if (end == -1) return null;
  return [start, end];
}

List<int>? _findClass(String src, String header) {
  final start = src.indexOf(header);
  if (start == -1) return null;
  final open = src.indexOf('{', start);
  if (open == -1) return null;
  final end = _skipBlock(src, open);
  if (end == -1) return null;
  return [start, end];
}

String _indent(String code) =>
    code.split('\n').map((l) => l.trim().isEmpty ? l : '  $l').join('\n');

void _backup(String path, String content) {
  final home = Platform.environment['HOME'] ?? '.';
  final dir = Directory('$home/fitgenie_backups')..createSync(recursive: true);
  File('${dir.path}/${path.split('/').last}.bak').writeAsStringSync(content);
}

/// Replace a method inside a class (indented by 2). Returns new source or null.
String? _replaceMethod(String src, String signature, String code) {
  final r = _findMethod(src, signature);
  if (r == null) return null;
  return src.substring(0, r[0]) +
      _indent(code).trimLeft() +
      src.substring(r[1]);
}

void main() {
  var failed = 0;

  // ===============================================================
  // 1) active_set_sheet.dart
  // ===============================================================
  final sheetFile = File(_sheetPath);
  if (!sheetFile.existsSync()) {
    stderr.writeln(
        '❌ $_sheetPath nahi mili. Script ko project root (jahan pubspec.yaml hai) mein rakh kar chalao.');
    exit(1);
  }
  var sheet = sheetFile.readAsStringSync();

  if (sheet.contains('// set-sheet-v2')) {
    stdout.writeln('ℹ️  Set sheet redesign pehle se lagi hui hai, kuch nahi kiya');
    exit(0);
  }

  _backup(_sheetPath, sheet);
  stdout.writeln('💾 Backup: active_set_sheet.dart.bak');

  for (final job in <List<String>>[
    ['Widget build(BuildContext context)', _sheetBuild],
    ['Widget _stepperRow(', _sheetStepper],
    ['Widget _circleIconButton(', _sheetCircleButton],
  ]) {
    final out = _replaceMethod(sheet, job[0], job[1]);
    if (out == null) {
      stdout.writeln('❌ active_set_sheet.dart: ${job[0]} nahi mila');
      failed++;
    } else {
      sheet = out;
      stdout.writeln('✅ active_set_sheet.dart: ${job[0]} badal diya');
    }
  }
  sheetFile.writeAsStringSync(sheet);

  // ===============================================================
  // 2) set_timer_widgets.dart
  // ===============================================================
  final timerFile = File(_timerPath);
  if (!timerFile.existsSync()) {
    stdout.writeln('❌ $_timerPath nahi mili');
    failed++;
  } else {
    var timer = timerFile.readAsStringSync();
    if (timer.contains('// timer-v2')) {
      stdout.writeln('ℹ️  set_timer_widgets.dart pehle se naya hai');
    } else {
      _backup(_timerPath, timer);
      stdout.writeln('💾 Backup: set_timer_widgets.dart.bak');

      for (final job in <List<String>>[
        [
          'class CircularStopwatchState extends State<CircularStopwatch>',
          _stopwatchClass
        ],
        [
          'class _CircularRestTimerState extends State<CircularRestTimer>',
          _restTimerClass
        ],
      ]) {
        final r = _findClass(timer, job[0]);
        if (r == null) {
          stdout.writeln('❌ set_timer_widgets.dart: ${job[0]} nahi mili');
          failed++;
        } else {
          timer = timer.substring(0, r[0]) + job[1] + timer.substring(r[1]);
          stdout.writeln('✅ set_timer_widgets.dart: ${job[0].split(' ')[1]} badal di');
        }
      }

      if (!timer.contains("import 'dart:math' as math;")) {
        timer = timer.replaceFirst("import 'dart:async';",
            "import 'dart:async';\nimport 'dart:math' as math;");
      }
      timer = '${timer.trimRight()}\n\n$_ringPainter\n';
      timerFile.writeAsStringSync(timer);
      stdout.writeln('✅ set_timer_widgets.dart: ring painter joda');
    }
  }

  // ===============================================================
  // 3) workout_screen.dart: coach tip + button icons
  // ===============================================================
  final screenFile = File(_screenPath);
  if (!screenFile.existsSync()) {
    stdout.writeln('❌ $_screenPath nahi mili');
    failed++;
  } else {
    var screen = screenFile.readAsStringSync();
    if (screen.contains('// coach-tip-v2')) {
      stdout.writeln('ℹ️  Coach tip pehle se naya hai');
    } else if (!screen.contains('// active-workout-v2')) {
      stdout.writeln(
          '⚠️  workout_screen.dart mein active-workout redesign nahi mila, pehle apply_active_workout_redesign.dart chalao. Coach tip skip.');
      failed++;
    } else {
      _backup(_screenPath, screen);
      stdout.writeln('💾 Backup: workout_screen.dart.bak');

      // state field
      const tipField = 'bool _tipLoading = true;';
      if (screen.contains(tipField) && !screen.contains('_tipExpanded')) {
        screen = screen.replaceFirst(
            tipField, '$tipField\n  bool _tipExpanded = false;');
        stdout.writeln('✅ _tipExpanded field joda');
      }

      for (final job in <List<String>>[
        ['Widget _buildCoachTip()', _coachTipCode],
        ['Widget _buildBottomBar()', _bottomBarCode],
      ]) {
        final out = _replaceMethod(screen, job[0], job[1]);
        if (out == null) {
          stdout.writeln('❌ workout_screen.dart: ${job[0]} nahi mila');
          failed++;
        } else {
          screen = out;
          stdout.writeln('✅ workout_screen.dart: ${job[0]} badal diya');
        }
      }

      // "SET n" pill: play icon hatao
      final setPill = RegExp(
          r'const Icon\(\s*Icons\.play_arrow_rounded,[^)]*\),\s*const SizedBox\(width: 4\),\s*');
      if (setPill.hasMatch(screen)) {
        screen = screen.replaceFirst(setPill, '');
        stdout.writeln('✅ "SET n" pill se icon hata diya');
      }

      // Hub Quick Start "START" pill: play icon hatao
      final quickPill = RegExp(
          r'const Icon\(\s*Icons\.play_arrow_rounded,\s*color: FitGenieTheme\.primary,\s*size: 20\),\s*const SizedBox\(width: 6\),\s*');
      if (quickPill.hasMatch(screen)) {
        screen = screen.replaceFirst(quickPill, '');
        stdout.writeln('✅ Hub Quick Start pill se icon hata diya');
      }

      screenFile.writeAsStringSync(screen);
    }
  }

  stdout.writeln('');
  if (failed == 0) {
    stdout.writeln(
        '🎉 Ho gaya. Ab: dart format lib/screens lib/widgets && dart analyze lib/screens lib/widgets && flutter run');
  } else {
    stdout.writeln(
        '⚠️  $failed hissa nahi laga. Wapas jaane ke liye: git checkout -- lib/');
  }
}

// ===============================================================
// Naya code: active_set_sheet.dart
// ===============================================================

const _sheetBuild = r'''
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
                      value: _weight.toStringAsFixed(_weight % 1 == 0 ? 0 : 1),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
}''';

const _sheetStepper = r'''
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
}''';

const _sheetCircleButton = r'''
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
}''';

// ===============================================================
// Naya code: set_timer_widgets.dart
// ===============================================================

const _stopwatchClass = r'''
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
}''';

const _restTimerClass = r'''
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
}''';

const _ringPainter = r'''
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
}''';

// ===============================================================
// Naya code: workout_screen.dart
// ===============================================================

const _coachTipCode = r'''
Widget _buildCoachTip() {
  // coach-tip-v2
  final tip = _coachTip ?? '';
  if (!_tipLoading && tip.isEmpty) return const SizedBox.shrink();

  final isLong = tip.length > 120;

  Widget bar(double? width) => Container(
        width: width,
        height: 10,
        decoration: BoxDecoration(
          color: FitGenieTheme.border,
          borderRadius: BorderRadius.circular(5),
        ),
      );

  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: FGCard(
      padding: const EdgeInsets.all(16),
      onTap: (!_tipLoading && isLong)
          ? () => setState(() => _tipExpanded = !_tipExpanded)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'COACH TIP',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              if (!_tipLoading && isLong)
                Text(
                  _tipExpanded ? 'LESS' : 'MORE',
                  style: const TextStyle(
                    color: FitGenieTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_tipLoading) ...[
            bar(double.infinity),
            const SizedBox(height: 8),
            bar(160),
          ] else
            AnimatedSize(
              duration: FitGenieTheme.animNormal,
              alignment: Alignment.topCenter,
              child: Text(
                tip,
                maxLines: _tipExpanded ? null : 3,
                overflow:
                    _tipExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: FitGenieTheme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}''';

const _bottomBarCode = r'''
Widget _buildBottomBar() {
  final allDone = _started && _currentIndex == -1;

  final Widget button;
  if (!_started) {
    button = FilledButton(
      onPressed: _starting ? null : _startWorkout,
      child: _starting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(AppStrings.get('workout_start').toUpperCase()),
    );
  } else if (allDone) {
    button = FilledButton(
      onPressed: _finishing ? null : _finishWorkout,
      child: Text(AppStrings.get('workout_finish').toUpperCase()),
    );
  } else {
    button = OutlinedButton(
      onPressed: _finishing ? null : _finishWorkout,
      child: Text(AppStrings.get('workout_finish').toUpperCase()),
    );
  }

  return SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: FitGenieTheme.bg,
        border: Border(top: BorderSide(color: FitGenieTheme.border)),
      ),
      child: button,
    ),
  );
}''';
