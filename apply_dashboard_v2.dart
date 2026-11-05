// apply_dashboard_v2.dart
//
// Dashboard ko halka karta hai:
//   Pehle : Steps, Calories Burned, Daily Goals, Weekly, Quick Actions (6 tiles), Quick Log
//   Ab    : Steps, Aaj ka hisaab (burned + goals ek card), Log karo (4 buttons),
//           Weekly (patla strip), Explore (AI Coach / Exercises / Challenges list)
//
// Chalane ka tareeqa (project root mein, jahan pubspec.yaml hai):
//   cp ~/Downloads/apply_dashboard_v2.dart .
//   dart apply_dashboard_v2.dart
//   flutter run
//
// Backup: lib/screens/dashboard_screen.dart.bak2

import 'dart:io';

const _target = 'lib/screens/dashboard_screen.dart';

// ---------------------------------------------------------------
// Brace matching jo strings, ${} aur comments samajhti hai
// ---------------------------------------------------------------
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

/// Method: signature dhoondo, parameters ka ( ) chhodo, phir body { }.
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

/// Class: header mein koi { nahi hota, seedha pehli { se body.
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

String _removeRange(String src, List<int> r) {
  final lineStart = src.lastIndexOf('\n', r[0]) + 1;
  var e = r[1];
  while (e < src.length && (src[e] == '\n' || src[e] == '\r')) {
    e++;
  }
  return '${src.substring(0, lineStart)}\n${src.substring(e)}';
}

int _count(String s, String needle) {
  var n = 0;
  var i = 0;
  while (true) {
    i = s.indexOf(needle, i);
    if (i == -1) return n;
    n++;
    i += needle.length;
  }
}

void main() {
  final file = File(_target);
  if (!file.existsSync()) {
    stderr.writeln(
        '❌ $_target nahi mili. Script ko project root (jahan pubspec.yaml hai) mein rakh kar chalao.');
    exit(1);
  }

  var src = file.readAsStringSync();
  File('$_target.bak2').writeAsStringSync(src);
  stdout.writeln('💾 Backup bana: $_target.bak2');

  var failed = 0;
  void ok(String m) => stdout.writeln('✅ $m');
  void bad(String m) {
    stdout.writeln('❌ $m');
    failed++;
  }

  // 1) Naye methods: _buildCaloriesBurnedCard ki jagah par daalo
  if (src.contains('Widget _buildTodayCard(')) {
    stdout.writeln('ℹ️  Naye cards pehle se lage hain, skip');
  } else {
    final r = _findMethod(src, 'Widget _buildCaloriesBurnedCard()');
    if (r == null) {
      bad('_buildCaloriesBurnedCard nahi mila');
    } else {
      src = src.substring(0, r[0]) +
          _indent(_newMethods).trimLeft() +
          src.substring(r[1]);
      ok('Naye methods add hue (Today card, Log row, Explore list)');
    }
  }

  // 2) Weekly card replace
  {
    final r = _findMethod(src, 'Widget _buildWeeklyActivityCard()');
    if (r == null) {
      bad('_buildWeeklyActivityCard nahi mila');
    } else {
      src = src.substring(0, r[0]) +
          _indent(_weeklyCode).trimLeft() +
          src.substring(r[1]);
      ok('Weekly card patla kar diya');
    }
  }

  // 3) build() replace
  {
    final r = _findMethod(src, 'Widget build(BuildContext context)');
    if (r == null) {
      bad('build() nahi mila');
    } else {
      src = src.substring(0, r[0]) +
          _indent(_buildCode).trimLeft() +
          src.substring(r[1]);
      ok('build() ka naya order lag gaya');
    }
  }

  // 4) Purane methods hatao
  for (final sig in [
    'Widget _buildDailyGoalsCard()',
    'Widget _buildGoalRow(',
    'Widget _buildQuickActions()',
    'Widget _buildQuickLogSection()',
    'Widget _buildQuickLogButton(',
  ]) {
    final r = _findMethod(src, sig);
    if (r == null) {
      stdout.writeln('ℹ️  $sig pehle se nahi hai');
    } else {
      src = _removeRange(src, r);
      ok('Purana hata diya: $sig');
    }
  }

  // 5) Ab unused cheezein: ring painter aur mini stat
  if (!src.contains('painter: _StepRingPainter(')) {
    final r = _findClass(src, 'class _StepRingPainter extends CustomPainter');
    if (r != null) {
      src = _removeRange(src, r);
      ok('_StepRingPainter hata diya');
    }
  }
  if (_count(src, '_buildMiniStat(') == 1) {
    final r = _findMethod(src, 'Widget _buildMiniStat(');
    if (r != null) {
      src = _removeRange(src, r);
      ok('_buildMiniStat hata diya');
    }
  }

  // 6) Hardcoded rang theme se jodo (dialogs wagera)
  var n = 0;
  String swap(String text, Pattern from, String to) {
    final c = from is RegExp
        ? from.allMatches(text).length
        : _count(text, from as String);
    n += c;
    return text.replaceAll(from, to);
  }

  src = swap(src, 'const Color(0xFF1A1A1A)', 'FitGenieTheme.card');
  src = swap(src, 'const Color(0xFF0D0D0D)', 'FitGenieTheme.card2');
  src = swap(src, RegExp(r'Colors\.blue\b'), 'FitGenieTheme.teal');
  ok('Hardcoded rang badle ($n jagah)');

  // 7) Unused imports hatao
  if (!src.contains('FGLinearProgress')) {
    src = src.replaceAll("import '../widgets/fg_progress.dart';\n", '');
    ok('fg_progress import hata diya');
  }
  if (!src.contains('QuickActionTile')) {
    src = src.replaceAll("import '../widgets/quick_action_tile.dart';\n", '');
    ok('quick_action_tile import hata diya');
  }

  file.writeAsStringSync(src);
  stdout.writeln('');
  if (failed == 0) {
    stdout.writeln('🎉 Ho gaya. Ab: dart analyze lib/screens/dashboard_screen.dart && flutter run');
  } else {
    stdout.writeln(
        '⚠️  $failed hissa nahi laga. Wapas jaane ke liye: cp $_target.bak2 $_target');
  }
}

// ===============================================================
// Naya code
// ===============================================================

const _buildCode = r'''
Widget build(BuildContext context) {
  final name =
      widget.userName.trim().isEmpty ? 'User' : widget.userName.trim();

  return Scaffold(
    backgroundColor: FitGenieTheme.bg,
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: FitGenieTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            FitGenieTheme.screenPadding,
            10,
            FitGenieTheme.screenPadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(name),
              const SizedBox(height: 10),
              const MedicalDisclaimerBanner(compact: true),
              const SizedBox(height: 18),
              _buildStepsCard(),
              const SizedBox(height: 12),
              _buildTodayCard(),
              const SizedBox(height: 12),
              _buildLogRow(),
              const SizedBox(height: 12),
              _buildWeeklyActivityCard(),
              const SizedBox(height: 12),
              _buildExploreCard(),
            ],
          ),
        ),
      ),
    ),
  );
}''';

const _weeklyCode = r'''
Widget _buildWeeklyActivityCard() {
  final t = Theme.of(context).textTheme;
  final maxW = _weeklyWorkouts.reduce((a, b) => a > b ? a : b);
  final todayIndex = DateTime.now().weekday - 1;
  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
              '$_thisWeekWorkoutCount workouts',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: FitGenieTheme.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 76,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final count = _weeklyWorkouts[i];
              final isToday = i == todayIndex;
              final double barH =
                  (count > 0 && maxW > 0) ? 8 + 36 * (count / maxW) : 8.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 26,
                    height: barH,
                    decoration: BoxDecoration(
                      color: count > 0
                          ? FitGenieTheme.primary
                          : FitGenieTheme.border,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
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
        ),
      ],
    ),
  );
}''';

const _newMethods = r'''
// ==========================================
// 📋 AAJ KA HISAAB (burned + goals, ek card)
// ==========================================
Widget _buildTodayCard() {
  final t = Theme.of(context).textTheme;
  double frac(int value, int goal) =>
      goal > 0 ? (value / goal).clamp(0.0, 1.0).toDouble() : 0.0;

  return FGCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.get('dashboard_daily_goals').toUpperCase(),
              style: t.labelSmall,
            ),
            const Spacer(),
            Tooltip(
              message: AppStrings.get('dashboard_calories_burned'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: FitGenieTheme.hot, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatNumber(_todayCaloriesBurned)} ${AppStrings.get('dashboard_kcal')}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: FitGenieTheme.hot,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _goalLine(
          AppStrings.get('dashboard_calories_intake'),
          '$_todayCalories/$_caloriesGoal kcal',
          frac(_todayCalories, _caloriesGoal),
          FitGenieTheme.hot,
        ),
        const SizedBox(height: 14),
        _goalLine(
          AppStrings.get('dashboard_protein_intake'),
          '$_todayProtein/$_proteinGoal g',
          frac(_todayProtein, _proteinGoal),
          FitGenieTheme.primary,
        ),
        const SizedBox(height: 14),
        _goalLine(
          AppStrings.get('dashboard_water_glasses'),
          '$_todayWater/$_waterGoal',
          frac(_todayWater, _waterGoal),
          FitGenieTheme.teal,
          onTap: _showAddWaterDialog,
        ),
        const SizedBox(height: 14),
        _goalLine(
          AppStrings.get('dashboard_active_minutes'),
          '$_todayActiveMinutes/$_activeMinutesGoal',
          frac(_todayActiveMinutes, _activeMinutesGoal),
          FitGenieTheme.warning,
        ),
      ],
    ),
  );
}

Widget _goalLine(String title, String valueText, double value, Color color,
    {VoidCallback? onTap}) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    color: FitGenieTheme.textSecondary, fontSize: 13),
              ),
            ),
            Text(
              valueText,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.add_circle_outline_rounded, size: 16, color: color),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: FitGenieTheme.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    ),
  );
}

// ==========================================
// ⚡ LOG KARO (4 chhote buttons, ek hi rang)
// ==========================================
Widget _buildLogRow() {
  final t = Theme.of(context).textTheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppStrings.get('dashboard_quick_log').toUpperCase(),
        style: t.labelSmall,
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _logButton(
                Icons.water_drop_rounded, 'Water', _showAddWaterDialog),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _logButton(
                Icons.directions_walk_rounded, 'Steps', _showAddStepsDialog),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _logButton(
                Icons.timer_rounded, 'Active', _showAddActiveMinutesDialog),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _logButton(Icons.document_scanner_rounded, 'Scan',
                _openMealScanner),
          ),
        ],
      ),
    ],
  );
}

Widget _logButton(IconData icon, String label, VoidCallback onTap) {
  return FGCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Column(
      children: [
        Icon(icon, color: FitGenieTheme.primary, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: FitGenieTheme.textSecondary,
          ),
        ),
      ],
    ),
  );
}

// ==========================================
// 🧭 EXPLORE (AI Coach / Exercises / Challenges)
// ==========================================
Widget _buildExploreCard() {
  return FGCard(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      children: [
        _exploreRow(
          Icons.auto_awesome_rounded,
          AppStrings.get('dashboard_ai_coach'),
          FitGenieTheme.ai,
          widget.onTapAICoach ?? () {},
        ),
        const Divider(height: 1),
        _exploreRow(
          Icons.fitness_center_rounded,
          AppStrings.get('label_exercises'),
          FitGenieTheme.textSecondary,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
            );
          },
        ),
        const Divider(height: 1),
        _exploreRow(
          Icons.emoji_events_rounded,
          AppStrings.get('dashboard_challenges'),
          FitGenieTheme.textSecondary,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChallengesScreen()),
            );
          },
        ),
      ],
    ),
  );
}

Widget _exploreRow(
    IconData icon, String title, Color color, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: FitGenieTheme.muted, size: 22),
        ],
      ),
    ),
  );
}''';
