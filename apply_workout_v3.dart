// apply_workout_v3.dart
//
// Workout screen ko jaandar banata hai (v2 ke upar lagti hai):
//  * Hero: solid blue poster-card, bara naam, peeche bara halka din ka naam, safed START pill
//  * "Is hafte" strip: 7 din ke gole, kiye hue din blue + tick (Firestore se)
//  * Muscle cards: peeche us muscle ki asli exercise GIF + neeche andhera gradient + naam
//  * Plan cards: peeche bara halka exercises ka number + "~60 MIN" pill
//
// Chalane ka tareeqa (project root mein):
//   cp ~/Downloads/apply_workout_v3.dart .
//   dart apply_workout_v3.dart
//   dart analyze lib/screens/workout_screen.dart
//   flutter run
//
// Backup: ~/fitgenie_backups/workout_screen.dart.v3bak  (aur git)

import 'dart:io';

const _target = 'lib/screens/workout_screen.dart';

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

String _indent(String code) =>
    code.split('\n').map((l) => l.trim().isEmpty ? l : '  $l').join('\n');

void main() {
  final file = File(_target);
  if (!file.existsSync()) {
    stderr.writeln(
        '❌ $_target nahi mili. Script ko project root (jahan pubspec.yaml hai) mein rakh kar chalao.');
    exit(1);
  }

  var src = file.readAsStringSync();

  if (src.contains('// workout-v3')) {
    stdout.writeln('ℹ️  v3 pehle se lagi hui hai, kuch nahi kiya');
    exit(0);
  }
  if (!src.contains('// workout-v2')) {
    stdout.writeln(
        '❌ Pehle apply_workout_redesign.dart (v2) lagni chahiye. Kuch nahi badla.');
    exit(1);
  }

  final home = Platform.environment['HOME'] ?? '.';
  final backupDir = Directory('$home/fitgenie_backups')
    ..createSync(recursive: true);
  File('${backupDir.path}/workout_screen.dart.v3bak').writeAsStringSync(src);
  stdout.writeln('💾 Backup bana: ${backupDir.path}/workout_screen.dart.v3bak');

  var failed = 0;

  final jobs = <List<String>>[
    ['Widget build(BuildContext context)', _buildCode],
    ['Widget _buildQuickStartCard()', '$_quickStartCode\n\n$_weekStripCode'],
    ['Widget _buildMuscleGroupsGrid()', _gridCode],
    ['Widget _buildMuscleGroupCard(', _muscleCardCode],
    ['Widget _buildPlanCard(', _planCardCode],
  ];

  for (final job in jobs) {
    final r = _findMethod(src, job[0]);
    if (r == null) {
      stdout.writeln('❌ ${job[0]} nahi mila');
      failed++;
      continue;
    }
    src = src.substring(0, r[0]) +
        _indent(job[1]).trimLeft() +
        src.substring(r[1]);
    stdout.writeln('✅ ${job[0]} badal diya');
  }

  file.writeAsStringSync(src);
  stdout.writeln('');
  if (failed == 0) {
    stdout.writeln(
        '🎉 Ho gaya. Ab: dart analyze lib/screens/workout_screen.dart && flutter run');
  } else {
    stdout.writeln(
        '⚠️  $failed hissa nahi laga. Wapas jaane ke liye: git checkout -- $_target');
  }
}

// ===============================================================
// Naya code
// ===============================================================

const _buildCode = r'''
Widget build(BuildContext context) {
  // workout-v3
  final t = Theme.of(context).textTheme;
  return FadeTransition(
    opacity: _fadeAnim,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(FitGenieTheme.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.get('workout_title'), style: t.displaySmall),
          const SizedBox(height: 4),
          Text(
            AppStrings.get('workout_sub'),
            style: const TextStyle(color: FitGenieTheme.muted, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const MedicalDisclaimerBanner(compact: true),
          const SizedBox(height: 20),

          _buildQuickStartCard(),
          const SizedBox(height: 12),
          _buildWeekStrip(),
          const SizedBox(height: 26),

          _buildSectionLabel('', AppStrings.get('workout_muscle'), ''),
          const SizedBox(height: 10),
          _buildMuscleGroupsGrid(),
          const SizedBox(height: 26),

          _buildSectionLabel('', AppStrings.get('workout_plans'), ''),
          const SizedBox(height: 10),
          _buildWorkoutPlans(),
          const SizedBox(height: 26),

          _buildSectionLabel('', AppStrings.get('workout_library'), ''),
          const SizedBox(height: 10),
          _buildMyLibraryCard(),
          const SizedBox(height: 26),

          _buildSectionLabel('', AppStrings.get('workout_recent'), ''),
          const SizedBox(height: 10),
          _buildRecentWorkouts(),
          const SizedBox(height: 40),
        ],
      ),
    ),
  );
}''';

const _quickStartCode = r'''
Widget _buildQuickStartCard() {
  final t = Theme.of(context).textTheme;
  final todayInfo = WorkoutPlansData.getTodayInfo();
  final isRestDay = todayInfo['tag'] == 'rest';
  final dayLabel =
      '${todayInfo['day'] ?? AppStrings.get('workout_today')}'.toUpperCase();
  final ghost = dayLabel.length >= 3 ? dayLabel.substring(0, 3) : dayLabel;

  void start() {
    final plan = WorkoutPlansData.getTodaysPlan();
    if (plan != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveWorkoutScreen(
            userId: widget.userId,
            workoutType: plan.category,
            workoutTitle: plan.name,
          ),
        ),
      );
    }
  }

  // Rest day: dark, shaant card
  if (isRestDay) {
    return FGCard(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dayLabel, style: t.labelSmall),
            const SizedBox(height: 6),
            Text(
              AppStrings.get('workout_rest'),
              style: t.displaySmall?.copyWith(color: FitGenieTheme.muted),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.get('workout_rest_subtitle'),
              style: const TextStyle(color: FitGenieTheme.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // Training day: poster-card
  return SizedBox(
    width: double.infinity,
    child: Material(
      color: FitGenieTheme.primary,
      borderRadius: BorderRadius.circular(FitGenieTheme.radiusXL),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: start,
        child: Stack(
          children: [
            Positioned(
              right: -6,
              bottom: -20,
              child: Text(
                ghost,
                style: t.displayLarge?.copyWith(
                  fontSize: 120,
                  color: FitGenieTheme.onPrimary.withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayLabel,
                    style: t.labelSmall?.copyWith(
                      color: FitGenieTheme.onPrimary.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${todayInfo['type'] ?? AppStrings.get('workout_fallback_type')}',
                    style: t.displayMedium
                        ?.copyWith(color: FitGenieTheme.onPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.get('workout_ai_subtitle'),
                    style: TextStyle(
                      color: FitGenieTheme.onPrimary.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: FitGenieTheme.onPrimary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow_rounded,
                            color: FitGenieTheme.primary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.get('workout_start').toUpperCase(),
                          style: const TextStyle(
                            color: FitGenieTheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}''';

const _weekStripCode = r'''
Widget _buildWeekStrip() {
  final t = Theme.of(context).textTheme;
  final now = DateTime.now();
  final monday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('workouts')
        .where('startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monday))
        .snapshots(),
    builder: (context, snapshot) {
      final done = <int>{};
      if (snapshot.hasData) {
        for (final doc in snapshot.data!.docs) {
          final ts =
              (doc.data() as Map<String, dynamic>)['startedAt'] as Timestamp?;
          if (ts != null) done.add(ts.toDate().weekday - 1);
        }
      }

      return FGCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppStrings.get('dashboard_weekly_activity').toUpperCase(),
                  style: t.labelSmall,
                ),
                const Spacer(),
                Text(
                  '${done.length}/7',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: FitGenieTheme.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final isDone = done.contains(i);
                final isToday = i == now.weekday - 1;
                return Column(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isDone ? FitGenieTheme.primary : Colors.transparent,
                        border: Border.all(
                          color: isDone
                              ? FitGenieTheme.primary
                              : (isToday
                                  ? FitGenieTheme.text
                                  : FitGenieTheme.border),
                          width: isToday ? 1.5 : 1,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check_rounded,
                              size: 18, color: FitGenieTheme.onPrimary)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                        color:
                            isToday ? FitGenieTheme.text : FitGenieTheme.muted,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      );
    },
  );
}''';

const _gridCode = r'''
Widget _buildMuscleGroupsGrid() {
  final groups = <Map<String, Object>>[
    {'name': 'Chest', 'emoji': '🏋️', 'list': ExerciseData.chest},
    {'name': 'Back', 'emoji': '🔙', 'list': ExerciseData.back},
    {'name': 'Legs', 'emoji': '🦵', 'list': ExerciseData.legs},
    {
      'name': 'Arms',
      'emoji': '💪',
      'list': [...ExerciseData.biceps, ...ExerciseData.triceps]
    },
    {'name': 'Shoulders', 'emoji': '🎯', 'list': ExerciseData.shoulders},
    {'name': 'Core', 'emoji': '🔥', 'list': ExerciseData.core},
  ];

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
    ),
    itemCount: groups.length,
    itemBuilder: (context, index) {
      final group = groups[index];
      return _buildMuscleGroupCard(
        name: group['name'] as String,
        emoji: group['emoji'] as String,
        exercises: group['list'] as List<Exercise>,
      );
    },
  );
}''';

const _muscleCardCode = r'''
Widget _buildMuscleGroupCard({
  required String name,
  required String emoji,
  required List<Exercise> exercises,
}) {
  final t = Theme.of(context).textTheme;
  final withGif = exercises.where((e) => e.hasGif).toList();
  final imagePath = withGif.isNotEmpty ? withGif.first.gifAsset : null;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MuscleGroupExercisesScreen(
            bodyPart: name,
            emoji: emoji,
            color: FitGenieTheme.primary,
          ),
        ),
      );
    },
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
        border: Border.all(color: FitGenieTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: FitGenieTheme.card),
            if (imagePath != null)
              Opacity(
                opacity: 0.5,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  cacheWidth: 400,
                  gaplessPlayback: true,
                  errorBuilder: (c, e, s) => const SizedBox.shrink(),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    FitGenieTheme.bg.withValues(alpha: 0.92),
                  ],
                  stops: const [0.25, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toUpperCase(),
                    style: t.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${exercises.length} exercises',
                    style: const TextStyle(
                        color: FitGenieTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}''';

const _planCardCode = r'''
Widget _buildPlanCard(WorkoutPlan plan) {
  final t = Theme.of(context).textTheme;

  return Container(
    width: 200,
    margin: const EdgeInsets.only(right: 12),
    child: FGCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutPlanScreen(
              plan: plan,
              userId: widget.userId,
            ),
          ),
        );
      },
      padding: const EdgeInsets.all(16),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -4,
            bottom: -26,
            child: Text(
              '${plan.totalExercises}',
              style: t.displayLarge?.copyWith(
                fontSize: 96,
                color: FitGenieTheme.text.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FitGenieTheme.border),
                ),
                child: Text(
                  '~${plan.estimatedMinutes} MIN',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: FitGenieTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                plan.name.toUpperCase(),
                style: t.headlineSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                plan.subtitle,
                style:
                    const TextStyle(color: FitGenieTheme.muted, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '${plan.totalExercises} exercises',
                style:
                    const TextStyle(color: FitGenieTheme.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}''';
