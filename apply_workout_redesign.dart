// apply_workout_redesign.dart
//
// Workout hub ko dobara banata hai:
//  * Section labels: emoji + subtitle hata kar chhote capital label
//  * Quick Start: gradient + glow + emoji ki jagah flat card, sirf play button blue
//  * Muscle groups: 6 rang-birange emoji cards ki jagah 2 column ke text cards
//  * Plans: rangeen border + emoji hata diye; Full Body ab plans ki list mein pehla card
//  * Library / Recent: icons aur emoji boxes hata diye, "Create" bara button
//  * Active Workout screen: purple icon aur hara Start button -> blue
//
// Chalane ka tareeqa (project root mein):
//   cp ~/Downloads/apply_workout_redesign.dart .
//   dart apply_workout_redesign.dart
//   flutter run
//
// Backup: ~/fitgenie_backups/workout_screen.dart.bak   (aur git)

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

String _removeRange(String src, List<int> r) {
  final lineStart = src.lastIndexOf('\n', r[0]) + 1;
  var e = r[1];
  while (e < src.length && (src[e] == '\n' || src[e] == '\r')) {
    e++;
  }
  return '${src.substring(0, lineStart)}\n${src.substring(e)}';
}

void main() {
  final file = File(_target);
  if (!file.existsSync()) {
    stderr.writeln(
        '❌ $_target nahi mili. Script ko project root (jahan pubspec.yaml hai) mein rakh kar chalao.');
    exit(1);
  }

  var src = file.readAsStringSync();

  if (src.contains('// workout-v2')) {
    stdout
        .writeln('ℹ️  Workout redesign pehle se lagi hui hai, kuch nahi kiya');
    exit(0);
  }

  final home = Platform.environment['HOME'] ?? '.';
  final backupDir = Directory('$home/fitgenie_backups')
    ..createSync(recursive: true);
  File('${backupDir.path}/workout_screen.dart.bak').writeAsStringSync(src);
  stdout.writeln('💾 Backup bana: ${backupDir.path}/workout_screen.dart.bak');

  var failed = 0;

  // Pehli build() hub ki hai (ActiveWorkoutScreen ki build baad mein aati hai)
  final jobs = <List<String>>[
    ['Widget build(BuildContext context)', _buildCode],
    ['Widget _buildSectionLabel(', _sectionLabelCode],
    ['Widget _buildQuickStartCard()', _quickStartCode],
    ['Widget _buildMuscleGroupsGrid()', _gridCode],
    ['Widget _buildMuscleGroupCard(', _muscleCardCode],
    ['Widget _buildWorkoutPlans()', _plansCode],
    ['Widget _buildPlanCard(', _planCardCode],
    ['Widget _buildMyLibraryCard()', _libraryCode],
    ['Widget _buildRecentWorkouts()', _recentCode],
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

  // Full Body card ab plans list mein hai, alag method hata do
  final fb = _findMethod(src, 'Widget _buildFullBodyCard()');
  if (fb != null) {
    src = _removeRange(src, fb);
    stdout.writeln('✅ _buildFullBodyCard hata diya (ab plans mein hai)');
  }

  // Active Workout screen ke chhote rang
  var n = 0;
  String rep(String text, RegExp re, String to) {
    final m = re.allMatches(text).length;
    n += m;
    return m == 0 ? text : text.replaceAll(re, to);
  }

  src = rep(src, RegExp(r'Colors\.purple\b'), 'FitGenieTheme.primary');
  src = rep(
    src,
    RegExp(
        r'backgroundColor:\s*FitGenieTheme\.success,(\s*)padding:\s*const EdgeInsets\.symmetric\(vertical: 16\)'),
    r'backgroundColor: FitGenieTheme.primary,$1padding: const EdgeInsets.symmetric(vertical: 16)',
  );
  src = rep(src, RegExp(r"Text\('💪 \$m',"), 'Text(m,');
  stdout.writeln('✅ Active Workout ke rang/emoji theek kiye ($n jagah)');

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
  // workout-v2
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
          const SizedBox(height: 22),

          _buildSectionLabel('', AppStrings.get('workout_quick'), ''),
          const SizedBox(height: 10),
          _buildQuickStartCard(),
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

const _sectionLabelCode = r'''
Widget _buildSectionLabel(String emoji, String title, String subtitle) {
  return Text(
    title.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}''';

const _quickStartCode = r'''
Widget _buildQuickStartCard() {
  final t = Theme.of(context).textTheme;
  final todayInfo = WorkoutPlansData.getTodayInfo();
  final isRestDay = todayInfo['tag'] == 'rest';

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

  return FGCard(
    onTap: isRestDay ? null : start,
    padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${todayInfo['day'] ?? AppStrings.get('workout_today')}'
                    .toUpperCase(),
                style: t.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                '${isRestDay ? AppStrings.get('workout_rest') : (todayInfo['type'] ?? AppStrings.get('workout_fallback_type'))}',
                style: t.displaySmall?.copyWith(
                  color: isRestDay ? FitGenieTheme.muted : FitGenieTheme.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                isRestDay
                    ? AppStrings.get('workout_rest_subtitle')
                    : AppStrings.get('workout_ai_subtitle'),
                style: const TextStyle(
                    color: FitGenieTheme.muted, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (!isRestDay) ...[
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: FitGenieTheme.primary,
              borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: FitGenieTheme.onPrimary, size: 30),
          ),
        ],
      ],
    ),
  );
}''';

const _gridCode = r'''
Widget _buildMuscleGroupsGrid() {
  final groups = [
    {'name': 'Chest', 'emoji': '🏋️', 'count': ExerciseData.chest.length},
    {'name': 'Back', 'emoji': '🔙', 'count': ExerciseData.back.length},
    {'name': 'Legs', 'emoji': '🦵', 'count': ExerciseData.legs.length},
    {
      'name': 'Arms',
      'emoji': '💪',
      'count': ExerciseData.biceps.length + ExerciseData.triceps.length
    },
    {'name': 'Shoulders', 'emoji': '🎯', 'count': ExerciseData.shoulders.length},
    {'name': 'Core', 'emoji': '🔥', 'count': ExerciseData.core.length},
  ];

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.1,
    ),
    itemCount: groups.length,
    itemBuilder: (context, index) {
      final group = groups[index];
      return _buildMuscleGroupCard(
        name: group['name'] as String,
        emoji: group['emoji'] as String,
        count: group['count'] as int,
      );
    },
  );
}''';

const _muscleCardCode = r'''
Widget _buildMuscleGroupCard({
  required String name,
  required String emoji,
  required int count,
}) {
  final t = Theme.of(context).textTheme;
  return FGCard(
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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.toUpperCase(),
          style: t.headlineSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '$count exercises',
          style: const TextStyle(color: FitGenieTheme.muted, fontSize: 12),
        ),
      ],
    ),
  );
}''';

const _plansCode = r'''
Widget _buildWorkoutPlans() {
  final plans = [
    WorkoutPlansData.fullBody,
    WorkoutPlansData.pushDay,
    WorkoutPlansData.pullDay,
    WorkoutPlansData.legDay,
    WorkoutPlansData.upperBody,
    WorkoutPlansData.lowerBody,
    WorkoutPlansData.armsDay,
    WorkoutPlansData.cardioCore,
  ];

  return SizedBox(
    height: 150,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: plans.length,
      itemBuilder: (context, index) => _buildPlanCard(plans[index]),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.name.toUpperCase(),
            style: t.headlineSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            plan.subtitle,
            style: const TextStyle(color: FitGenieTheme.muted, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${plan.totalExercises} exercises · ~${plan.estimatedMinutes} min',
                  style: const TextStyle(
                      color: FitGenieTheme.muted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: FitGenieTheme.primary),
            ],
          ),
        ],
      ),
    ),
  );
}''';

const _libraryCode = r'''
Widget _buildMyLibraryCard() {
  return Column(
    children: [
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('customWorkouts')
            .orderBy('createdAt', descending: true)
            .limit(3)
            .snapshots(),
        builder: (context, snapshot) {
          final hasData = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

          if (!hasData) {
            return FGCard(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('library_empty'),
                      style: const TextStyle(
                          color: FitGenieTheme.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.get('library_empty_sub'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ??
                  AppStrings.get('workout_my_workout_fallback');
              final exerciseCount = (data['exercises'] as List?)?.length ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: FGCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MyLibraryScreen(userId: widget.userId),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$name',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$exerciseCount exercises',
                              style: const TextStyle(
                                  color: FitGenieTheme.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: FitGenieTheme.muted),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: Material(
              color: FitGenieTheme.primary,
              borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
              child: InkWell(
                borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyLibraryScreen(
                        userId: widget.userId,
                        openCreate: true,
                      ),
                    ),
                  );
                },
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: FitGenieTheme.onPrimary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.get('library_create'),
                        style: const TextStyle(
                          color: FitGenieTheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FGCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MyLibraryScreen(userId: widget.userId),
                  ),
                );
              },
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  AppStrings.get('workout_view_all'),
                  style: const TextStyle(
                    color: FitGenieTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}''';

const _recentCode = r'''
Widget _buildRecentWorkouts() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('workouts')
        .orderBy('startedAt', descending: true)
        .limit(5)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return FGCard(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get('workout_no_sets'),
                  style: const TextStyle(color: FitGenieTheme.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.get('workout_tap_to_log'),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['type'] ?? AppStrings.get('workout_fallback_type');
          final sets = data['totalSets'] ?? 0;
          final duration = data['duration'] ?? 0;
          final status = data['status'] ?? 'completed';
          final startedAt = data['startedAt'] as Timestamp?;

          String dateStr = AppStrings.get('workout_recently');
          if (startedAt != null) {
            final date = startedAt.toDate();
            final diff = DateTime.now().difference(date);
            if (diff.inDays == 0) {
              dateStr = AppStrings.get('workout_today');
            } else if (diff.inDays == 1) {
              dateStr = AppStrings.get('workout_yesterday');
            } else if (diff.inDays < 7) {
              dateStr = AppStrings.get('workout_days_ago',
                  params: {'days': '${diff.inDays}'});
            } else {
              dateStr = '${date.day}/${date.month}/${date.year}';
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: FGCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutDetailScreen(
                      workoutId: doc.id,
                      userId: widget.userId,
                      workoutData: data,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$type',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _buildMiniStat(Icons.repeat, '$sets sets'),
                            if (duration > 0)
                              _buildMiniStat(
                                  Icons.timer_outlined, '$duration min'),
                            _buildMiniStat(Icons.calendar_today, dateStr),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    status == 'completed'
                        ? Icons.check_rounded
                        : Icons.access_time_rounded,
                    color: status == 'completed'
                        ? FitGenieTheme.success
                        : FitGenieTheme.warning,
                    size: 22,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}''';
