// apply_active_workout_redesign.dart
//
// Workout start ka flow naye tareeqe se (guided workout):
//  * Plan ki exercises ki ordered list (naam, sets x reps, rest, progress segments)
//  * Start Workout -> pehli exercise "current"; exercise par tap -> stopwatch/rest
//    sheet seedha khulti hai, sets/reps/rest plan se, weight pichli baar wala
//  * Set khatam hote hi agla set, aakhri set par exercise tick, agli current
//  * AI ab chhota "Coach tip" card hai (plan ka order AI par depend nahi)
//  * "+ Add exercise" se extra exercise list mein judti hai
//  * Back/Discard par khali "active" session Firestore mein nahi rehta
//
// Teen files badalti hai (backup ke saath):
//   lib/screens/workout_screen.dart       (ActiveWorkoutScreen + Quick Start)
//   lib/screens/workout_plan_screen.dart  (Start button ab plan bhejta hai)
//   lib/widgets/active_set_sheet.dart     (plan ka rest time use karne ka option)
//
// Chalane ka tareeqa (project root mein):
//   git add -A && git commit -m "before active workout redesign"
//   cp ~/Downloads/apply_active_workout_redesign.dart .
//   dart apply_active_workout_redesign.dart
//   dart format lib/screens/workout_screen.dart lib/screens/workout_plan_screen.dart lib/widgets/active_set_sheet.dart
//   dart analyze lib/screens lib/widgets
//   flutter run
//
// Backup: ~/fitgenie_backups/*.bak

import 'dart:io';

const _screenPath = 'lib/screens/workout_screen.dart';
const _planPath = 'lib/screens/workout_plan_screen.dart';
const _sheetPath = 'lib/widgets/active_set_sheet.dart';

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

List<int>? _findClass(String src, String header) {
  final start = src.indexOf(header);
  if (start == -1) return null;
  final open = src.indexOf('{', start);
  if (open == -1) return null;
  final end = _skipBlock(src, open);
  if (end == -1) return null;
  return [start, end];
}

void _backup(String path, String content) {
  final home = Platform.environment['HOME'] ?? '.';
  final dir = Directory('$home/fitgenie_backups')..createSync(recursive: true);
  final name = path.split('/').last;
  File('${dir.path}/$name.bak').writeAsStringSync(content);
}

void main() {
  final screenFile = File(_screenPath);
  if (!screenFile.existsSync()) {
    stderr.writeln(
        '❌ $_screenPath nahi mili. Script ko project root (jahan pubspec.yaml hai) mein rakh kar chalao.');
    exit(1);
  }

  var screen = screenFile.readAsStringSync();

  if (screen.contains('// active-workout-v2')) {
    stdout.writeln(
        'ℹ️  Active workout redesign pehle se lagi hui hai, kuch nahi kiya');
    exit(0);
  }

  if (!screen.contains('class ActiveWorkoutScreen extends StatefulWidget') ||
      !screen.contains(
          'class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>')) {
    stderr.writeln(
        '❌ ActiveWorkoutScreen workout_screen.dart mein nahi mili. Kuch nahi badla.');
    exit(1);
  }

  _backup(_screenPath, screen);
  stdout.writeln('💾 Backup: workout_screen.dart.bak');

  var failed = 0;

  // ---------------------------------------------------------------
  // 1) active_set_sheet.dart: optional restSeconds (plan ka rest time)
  // ---------------------------------------------------------------
  var restParamOk = false;
  final sheetFile = File(_sheetPath);
  if (sheetFile.existsSync()) {
    var sheet = sheetFile.readAsStringSync();
    if (sheet.contains('widget.restSeconds')) {
      restParamOk = true;
      stdout.writeln('ℹ️  active_set_sheet.dart mein restSeconds pehle se hai');
    } else {
      const fieldOld = 'final String setLabel;';
      const ctorOld = 'required this.onSetLogged,';
      const restOld = '_restSeconds = suggestedRestSeconds(';
      if (sheet.contains(fieldOld) &&
          sheet.contains(ctorOld) &&
          sheet.contains(restOld)) {
        _backup(_sheetPath, sheet);
        sheet = sheet.replaceFirst(fieldOld,
            '$fieldOld\n\n  /// Rest between sets (from the workout plan). When null, a\n  /// difficulty-based suggestion is used.\n  final int? restSeconds;');
        sheet = sheet.replaceFirst(ctorOld, '$ctorOld\n    this.restSeconds,');
        sheet = sheet.replaceFirst(
            restOld, '_restSeconds = widget.restSeconds ??\n        suggestedRestSeconds(');
        sheetFile.writeAsStringSync(sheet);
        restParamOk = true;
        stdout.writeln('✅ active_set_sheet.dart: restSeconds joda');
      } else {
        stdout.writeln(
            '⚠️  active_set_sheet.dart ka structure alag hai, restSeconds nahi joda (rest time difficulty se hi rahega)');
      }
    }
  } else {
    stdout.writeln('⚠️  $_sheetPath nahi mili, restSeconds skip');
  }

  // ---------------------------------------------------------------
  // 2) workout_screen.dart: naye classes
  // ---------------------------------------------------------------
  var stateCode = _stateCode;
  if (!restParamOk) {
    stateCode = stateCode.replaceAll(
        RegExp(r'[ \t]*restSeconds: item\.restSeconds,[^\n]*\n'), '');
  }

  final stateRange = _findClass(screen,
      'class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>');
  if (stateRange == null) {
    stdout.writeln('❌ _ActiveWorkoutScreenState nahi mili');
    failed++;
  } else {
    screen = screen.substring(0, stateRange[0]) +
        stateCode +
        screen.substring(stateRange[1]);
    stdout.writeln('✅ _ActiveWorkoutScreenState badal diya');
  }

  final widgetRange =
      _findClass(screen, 'class ActiveWorkoutScreen extends StatefulWidget');
  if (widgetRange == null) {
    stdout.writeln('❌ ActiveWorkoutScreen nahi mili');
    failed++;
  } else {
    screen = screen.substring(0, widgetRange[0]) +
        _widgetCode +
        screen.substring(widgetRange[1]);
    stdout.writeln('✅ ActiveWorkoutScreen badal diya (plan parameter ke saath)');
  }

  // Quick Start: plan bhi bhejo
  final quick = RegExp(r'workoutTitle:\s*plan\.name,');
  if (quick.hasMatch(screen)) {
    screen = screen.replaceFirst(
        quick, 'workoutTitle: plan.name,\n              plan: plan,');
    stdout.writeln('✅ Quick Start ab plan bhejta hai');
  } else {
    stdout.writeln('⚠️  Quick Start ka "workoutTitle: plan.name," nahi mila');
    failed++;
  }

  // Timer ke liye dart:async
  if (!screen.contains("import 'dart:async';")) {
    screen = screen.replaceFirst("import 'package:flutter/material.dart';",
        "import 'dart:async';\n\nimport 'package:flutter/material.dart';");
    stdout.writeln('✅ dart:async import joda');
  }

  screenFile.writeAsStringSync(screen);

  // ---------------------------------------------------------------
  // 3) workout_plan_screen.dart: Start button plan bhejta hai
  // ---------------------------------------------------------------
  final planFile = File(_planPath);
  if (planFile.existsSync()) {
    var plan = planFile.readAsStringSync();
    if (plan.contains('plan: widget.plan,')) {
      stdout.writeln('ℹ️  workout_plan_screen.dart pehle se plan bhejta hai');
    } else {
      final re = RegExp(r'workoutTitle:\s*widget\.plan\.name,');
      if (re.hasMatch(plan)) {
        _backup(_planPath, plan);
        plan = plan.replaceFirst(re,
            'workoutTitle: widget.plan.name,\n                plan: widget.plan,');
        planFile.writeAsStringSync(plan);
        stdout.writeln('✅ workout_plan_screen.dart: Start button ab plan bhejta hai');
      } else {
        stdout.writeln(
            '⚠️  workout_plan_screen.dart mein "workoutTitle: widget.plan.name," nahi mila. Wahan ActiveWorkoutScreen(...) mein "plan: widget.plan," haath se jod do');
        failed++;
      }
    }
  } else {
    stdout.writeln('⚠️  $_planPath nahi mili');
    failed++;
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
// Naya code
// ===============================================================

const _widgetCode = r'''
class ActiveWorkoutScreen extends StatefulWidget {
  final String userId;
  final String workoutType;
  final String workoutTitle;

  /// Structured plan (exercises, sets, reps, rest). When null, a short list
  /// is built from [workoutType] so older callers keep working.
  final WorkoutPlan? plan;

  const ActiveWorkoutScreen({
    super.key,
    required this.userId,
    required this.workoutType,
    required this.workoutTitle,
    this.plan,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}''';

const _stateCode = r'''
class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  // active-workout-v2
  final AIService _aiService = AIService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final List<_WorkoutItem> _items;
  final List<Map<String, dynamic>> _loggedSets = [];
  final Map<String, double> _lastWeights = {};
  final ValueNotifier<int> _elapsed = ValueNotifier<int>(0);

  Timer? _ticker;
  String? _sessionId;
  DateTime? _startTime;
  bool _started = false;
  bool _starting = false;
  bool _finishing = false;

  String? _coachTip;
  bool _tipLoading = true;

  @override
  void initState() {
    super.initState();
    showWorkoutInjuryWarningIfNeeded(context);
    _items = _buildItems();
    AdsService.instance.loadInterstitialAd();
    _loadLastWeights();
    _loadCoachTip();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _elapsed.dispose();
    super.dispose();
  }

  // ============================================================
  // 📋 ITEMS
  // ============================================================

  double _defaultWeight(Exercise? ex) {
    final eq = (ex?.equipment ?? '').toLowerCase();
    const noLoad = ['bodyweight', 'pull-up', 'dip', 'treadmill', 'bike'];
    if (noLoad.any((k) => eq.contains(k))) return 0;
    return 20;
  }

  double _weightFor(Exercise? ex) {
    if (ex != null && _lastWeights.containsKey(ex.name)) {
      return _lastWeights[ex.name]!;
    }
    return _defaultWeight(ex);
  }

  List<_WorkoutItem> _buildItems() {
    final all = ExerciseData.getAllExercises();

    Exercise? byId(String id) {
      for (final e in all) {
        if (e.id == id) return e;
      }
      return null;
    }

    final plan = widget.plan;
    if (plan != null && plan.exercises.isNotEmpty) {
      return plan.exercises.map((pe) {
        final ex = byId(pe.exerciseId);
        return _WorkoutItem(
          name: ex?.name ?? pe.exerciseId,
          exercise: ex,
          sets: pe.sets,
          reps: pe.reps,
          restSeconds: pe.restSeconds,
          notes: pe.notes,
          weight: _weightFor(ex),
        );
      }).toList();
    }

    // Fallback: no structured plan -> first few exercises of the body part
    return ExerciseData.getByBodyPart(widget.workoutType)
        .take(5)
        .map((ex) => _WorkoutItem(
              name: ex.name,
              exercise: ex,
              sets: 3,
              reps: '12',
              restSeconds: 60,
              weight: _weightFor(ex),
            ))
        .toList();
  }

  int get _currentIndex => _items.indexWhere((e) => !e.isDone);

  String _fmtWeight(double w) => w % 1 == 0 ? '${w.toInt()}' : w.toStringAsFixed(1);

  // ============================================================
  // 📡 DATA
  // ============================================================

  Future<void> _loadLastWeights() async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('workouts')
          .orderBy('startedAt', descending: true)
          .limit(10)
          .get();

      for (final doc in snap.docs) {
        if (doc.id == _sessionId) continue;
        final sets = (doc.data()['sets'] as List?) ?? const [];
        for (final s in sets.reversed) {
          if (s is! Map) continue;
          final name = s['exercise'];
          final w = s['weight'];
          if (name is String && w is num && !_lastWeights.containsKey(name)) {
            _lastWeights[name] = w.toDouble();
          }
        }
      }

      if (!mounted) return;
      setState(() {
        for (final item in _items) {
          final w = _lastWeights[item.name];
          if (w != null && item.doneSets == 0) item.weight = w;
        }
      });
    } catch (e) {
      debugPrint('Last weights error: $e');
    }
  }

  Future<void> _loadCoachTip() async {
    try {
      final names = _items.map((e) => e.name).join(', ');
      final tip = await _aiService.chat(
        uid: widget.userId,
        userMessage:
            'Aaj ka workout: ${widget.workoutTitle} ($names). Sirf 2 chhoti lines mein ek practical coach tip do (warm-up ya form ke baare mein). Koi list ya emoji nahi.',
      );
      if (!mounted) return;
      setState(() {
        _coachTip = tip.trim();
        _tipLoading = false;
      });
    } catch (e) {
      debugPrint('Coach tip error: $e');
      if (!mounted) return;
      setState(() => _tipLoading = false);
    }
  }

  // ============================================================
  // ▶️ WORKOUT FLOW
  // ============================================================

  Future<void> _startWorkout() async {
    if (_started || _starting) return;
    setState(() => _starting = true);

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('workouts')
          .add({
        'type': widget.workoutTitle,
        'startedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'sets': [],
        'totalSets': 0,
      });

      if (!mounted) return;

      _startTime = DateTime.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        final st = _startTime;
        if (st != null) {
          _elapsed.value = DateTime.now().difference(st).inSeconds;
        }
      });

      setState(() {
        _sessionId = docRef.id;
        _started = true;
        _starting = false;
      });
    } catch (e) {
      debugPrint('Start workout error: $e');
      if (!mounted) return;
      setState(() => _starting = false);
      AppSnackbar.showError(context, '$e');
    }
  }

  Future<void> _openExercise(int index) async {
    final item = _items[index];
    if (item.isDone) return;

    if (!_started) {
      await _startWorkout();
      if (!_started || !mounted) return;
    }
    _showSetSheet(item);
  }

  void _showSetSheet(_WorkoutItem item) {
    if (!mounted) return;
    final setNo = item.doneSets + 1;

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ActiveSetSheet(
        exercise: item.exercise,
        exerciseNameFallback: item.name,
        initialWeight: item.weight,
        initialReps: item.reps,
        setLabel: AppStrings.get('workout_set_label', params: {
          'current': '$setNo',
          'total': '${item.sets}',
        }),
        restSeconds: item.restSeconds, // REST_PARAM
        onSetLogged: (weight, reps, durationSeconds, toFailure) async {
          await _logSet(item, weight, reps, durationSeconds);
        },
      ),
    ).then((completed) {
      if (!mounted) return;
      if (completed == true && !item.isDone) {
        _showSetSheet(item);
      }
    });
  }

  Future<void> _logSet(
    _WorkoutItem item,
    double weight,
    String reps,
    int durationSeconds,
  ) async {
    // Timed exercises (e.g. "60 sec") are stored as 1 rep + durationSeconds.
    final repsNum = item.isTimed
        ? 1
        : (int.tryParse(reps.replaceAll(RegExp(r'[^0-9]'), '')) ?? 12);

    final setData = {
      'exercise': item.name,
      'weight': weight,
      'reps': repsNum,
      'durationSeconds': durationSeconds,
      'timestamp': DateTime.now().toIso8601String(),
    };

    item.weight = weight;
    item.doneSets++;
    if (mounted) setState(() => _loggedSets.add(setData));

    final id = _sessionId;
    if (id != null) {
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('workouts')
          .doc(id)
          .update({
        'sets': FieldValue.arrayUnion([setData]),
        'totalSets': _loggedSets.length,
      });
    }
  }

  void _showAddExerciseSheet() {
    var pool = ExerciseData.getByBodyPart(widget.workoutType);
    if (pool.isEmpty) pool = ExerciseData.getAllExercises();
    final used = _items.map((e) => e.exercise?.id).toSet();
    final options = pool.where((e) => !used.contains(e.id)).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  AppStrings.get('workout_choose_exercise'),
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final ex = options[i];
                    return ListTile(
                      title: Text(
                        ex.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        ex.equipment,
                        style: const TextStyle(
                            color: FitGenieTheme.muted, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _addExtra(ex);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addExtra(Exercise ex) {
    final item = _WorkoutItem(
      name: ex.name,
      exercise: ex,
      sets: 3,
      reps: '12',
      restSeconds: 60,
      weight: _weightFor(ex),
    );
    setState(() => _items.add(item));
    _openExercise(_items.length - 1);
  }

  // ============================================================
  // 🏁 FINISH / EXIT
  // ============================================================

  Future<void> _discardSession() async {
    _ticker?.cancel();
    final id = _sessionId;
    if (id == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('workouts')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Discard session error: $e');
    }
  }

  Future<void> _handleBack() async {
    if (!_started) {
      Navigator.pop(context);
      return;
    }
    if (_loggedSets.isEmpty) {
      await _discardSession();
      if (mounted) Navigator.pop(context);
      return;
    }
    _showExitConfirmation();
  }

  Future<void> _finishWorkout() async {
    final id = _sessionId;
    if (id == null || _finishing) return;

    // Nothing logged -> nothing to save
    if (_loggedSets.isEmpty) {
      await _discardSession();
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _finishing = true);
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inMinutes
        : 0;

    try {
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('workouts')
          .doc(id)
          .update({
        'endedAt': FieldValue.serverTimestamp(),
        'status': 'completed',
        'duration': duration,
        'totalSets': _loggedSets.length,
      });
    } catch (e) {
      debugPrint('Finish workout error: $e');
      if (!mounted) return;
      setState(() => _finishing = false);
      AppSnackbar.showError(context, '$e');
      return;
    }

    _ticker?.cancel();
    if (!mounted) return;
    _showCompleteDialog(duration);
  }

  void _showCompleteDialog(int duration) {
    final t = Theme.of(context).textTheme;

    Widget stat(String value, String label) => Column(
          children: [
            Text(value,
                style: t.displaySmall?.copyWith(color: FitGenieTheme.primary)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: t.labelSmall),
          ],
        );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          AppStrings.get('workout_complete'),
          textAlign: TextAlign.center,
          style: t.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.get('workout_great_job'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: FitGenieTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                stat('${_loggedSets.length}',
                    AppStrings.get('workout_stat_sets')),
                stat('$duration', AppStrings.get('workout_stat_minutes')),
              ],
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                AdsService.instance.showInterstitialAd(
                  onDismissed: () {
                    if (mounted) Navigator.pop(context);
                  },
                );
              },
              child: Text(AppStrings.get('done')),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.get('workout_exit_confirm')),
        content: Text(AppStrings.get('workout_exit_sub')),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _discardSession();
              if (mounted) Navigator.pop(context);
            },
            child: Text(
              AppStrings.get('workout_discard'),
              style: const TextStyle(color: FitGenieTheme.error),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _finishWorkout();
            },
            style: FilledButton.styleFrom(minimumSize: const Size(96, 46)),
            child: Text(AppStrings.get('workout_save_exit')),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🧱 BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_started,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: FitGenieTheme.bg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: _handleBack,
          ),
          title: Text(
            widget.workoutTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (_started)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: _buildElapsedChip()),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            FitGenieTheme.screenPadding,
            4,
            FitGenieTheme.screenPadding,
            24,
          ),
          children: [
            _buildSummary(),
            _buildCoachTip(),
            const SizedBox(height: 22),
            _sectionLabel('Exercises'),
            const SizedBox(height: 10),
            ...List.generate(_items.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildExerciseTile(i),
              );
            }),
            const SizedBox(height: 2),
            _buildAddExercise(),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
    );
  }

  Widget _buildElapsedChip() {
    return ValueListenableBuilder<int>(
      valueListenable: _elapsed,
      builder: (_, secs, __) {
        final m = (secs ~/ 60).toString().padLeft(2, '0');
        final s = (secs % 60).toString().padLeft(2, '0');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FitGenieTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined,
                  size: 14, color: FitGenieTheme.primary),
              const SizedBox(width: 6),
              Text(
                '$m:$s',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummary() {
    final t = Theme.of(context).textTheme;
    final totalSets = _items.fold<int>(0, (sum, e) => sum + e.sets);
    final doneSets = _items.fold<int>(
        0, (sum, e) => sum + (e.doneSets > e.sets ? e.sets : e.doneSets));
    final doneEx = _items.where((e) => e.isDone).length;
    final minutes = widget.plan?.estimatedMinutes;
    final progress = totalSets == 0 ? 0.0 : doneSets / totalSets;

    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$doneEx',
                  style:
                      t.displaySmall?.copyWith(color: FitGenieTheme.primary)),
              Text(' / ${_items.length}',
                  style:
                      t.headlineSmall?.copyWith(color: FitGenieTheme.muted)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('EXERCISES', style: t.labelSmall),
              ),
              const Spacer(),
              if (minutes != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: FitGenieTheme.border),
                  ),
                  child: Text(
                    '~$minutes MIN',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: FitGenieTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: FitGenieTheme.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(FitGenieTheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$doneSets / $totalSets sets',
            style: const TextStyle(color: FitGenieTheme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachTip() {
    final hasTip = _coachTip != null && _coachTip!.isNotEmpty;
    if (!_tipLoading && !hasTip) return const SizedBox.shrink();

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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FitGenieTheme.ai.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
          border: Border.all(color: FitGenieTheme.ai.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 16, color: FitGenieTheme.ai),
                const SizedBox(width: 8),
                Text(
                  'COACH TIP',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: FitGenieTheme.ai),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_tipLoading) ...[
              bar(double.infinity),
              const SizedBox(height: 8),
              bar(160),
            ] else
              Text(
                _coachTip!,
                style: const TextStyle(fontSize: 13, height: 1.5),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTile(int index) {
    final item = _items[index];
    final done = item.isDone;
    final isCurrent = _started && index == _currentIndex;
    final hasNotes = item.notes != null && item.notes!.isNotEmpty;

    final String subtitle = done
        ? '${item.sets} × ${item.reps} · ${_fmtWeight(item.weight)} kg'
        : '${item.sets} × ${item.reps} · rest ${item.restSeconds}s';

    Widget trailing;
    if (done) {
      trailing = const SizedBox.shrink();
    } else if (isCurrent) {
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: FitGenieTheme.primary,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow_rounded,
                size: 16, color: FitGenieTheme.onPrimary),
            const SizedBox(width: 4),
            Text(
              'SET ${item.doneSets + 1}',
              style: const TextStyle(
                color: FitGenieTheme.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else {
      trailing = const Icon(Icons.chevron_right_rounded,
          size: 22, color: FitGenieTheme.muted);
    }

    return FGCard(
      onTap: done ? null : () => _openExercise(index),
      color: isCurrent ? FitGenieTheme.primary.withValues(alpha: 0.08) : null,
      border: Border.all(
        color: isCurrent
            ? FitGenieTheme.primary.withValues(alpha: 0.6)
            : FitGenieTheme.border,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _buildNumberBadge(index, done, isCurrent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: done ? FitGenieTheme.muted : FitGenieTheme.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: FitGenieTheme.muted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isCurrent && hasNotes) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.notes!,
                    style: const TextStyle(
                      color: FitGenieTheme.textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: List.generate(item.sets, (s) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                            right: s == item.sets - 1 ? 0 : 4),
                        decoration: BoxDecoration(
                          color: s < item.doneSets
                              ? FitGenieTheme.primary
                              : FitGenieTheme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }

  Widget _buildNumberBadge(int index, bool done, bool isCurrent) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? FitGenieTheme.primary : Colors.transparent,
        border: Border.all(
          color: done
              ? FitGenieTheme.primary
              : (isCurrent ? FitGenieTheme.primary : FitGenieTheme.border),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check_rounded,
                size: 18, color: FitGenieTheme.onPrimary)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color:
                      isCurrent ? FitGenieTheme.primary : FitGenieTheme.muted,
                ),
              ),
      ),
    );
  }

  Widget _buildAddExercise() {
    return InkWell(
      onTap: _showAddExerciseSheet,
      borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
          border: Border.all(color: FitGenieTheme.border),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 18, color: FitGenieTheme.primary),
              SizedBox(width: 6),
              Text(
                'Add exercise',
                style: TextStyle(
                  color: FitGenieTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final allDone = _started && _currentIndex == -1;

    final Widget button;
    if (!_started) {
      button = FilledButton.icon(
        onPressed: _starting ? null : _startWorkout,
        icon: _starting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.play_arrow_rounded),
        label: Text(AppStrings.get('workout_start').toUpperCase()),
      );
    } else if (allDone) {
      button = FilledButton.icon(
        onPressed: _finishing ? null : _finishWorkout,
        icon: const Icon(Icons.check_rounded),
        label: Text(AppStrings.get('workout_finish').toUpperCase()),
      );
    } else {
      button = OutlinedButton.icon(
        onPressed: _finishing ? null : _finishWorkout,
        icon: const Icon(Icons.check_rounded),
        label: Text(AppStrings.get('workout_finish').toUpperCase()),
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
  }
}

// ============================================================
// 📋 One exercise in the live workout list
// ============================================================

class _WorkoutItem {
  final String name;
  final Exercise? exercise;
  final int sets;
  final String reps;
  final int restSeconds;
  final String? notes;
  double weight;
  int doneSets = 0;

  _WorkoutItem({
    required this.name,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.weight,
    this.notes,
  });

  bool get isDone => doneSets >= sets;

  bool get isTimed {
    final r = reps.toLowerCase();
    return r.contains('sec') || r.contains('min');
  }
}''';
