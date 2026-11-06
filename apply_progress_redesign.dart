// apply_progress_redesign.dart
//
// Progress (progress_screen.dart) ko concise banata hai: 10 cards -> 4.
//  * Hero: bada workouts number, streak chip, 7 gol dots (hub ki week strip jaisi),
//    neeche avg kcal (goal %) + protein + total workouts
//  * AI Insight hero ke seedha neeche (violet card, ab sabse upar nazar aati hai)
//  * Calories | Protein: ek hi chart, upar toggle, dashed goal line
//  * Weight: bada number + chhoti sparkline (axis labels ke baghair)
//  * Daily breakdown: collapsed tile, kholne par poori list
//  * Hata diye: alag workouts chart, protein chart, stat tiles, Best Day card,
//    All-time stats card (total workouts ab hero ke andar hai)
//
// Chalane ka tareeqa (project root mein):
//   cp ~/Downloads/apply_progress_redesign.dart .
//   dart apply_progress_redesign.dart
//   dart format lib/screens/progress_screen.dart
//   dart analyze lib/screens/progress_screen.dart
//   flutter run
//
// Backup: ~/fitgenie_backups/progress_screen.dart.bak  (aur git)

import 'dart:io';

const _target = 'lib/screens/progress_screen.dart';

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

  if (src.contains('// progress-v2')) {
    stdout.writeln('ℹ️  Progress redesign pehle se lagi hui hai, kuch nahi kiya');
    exit(0);
  }

  if (!src.contains('Widget _buildWeekHero()') ||
      !src.contains('Widget _buildCaloriesChart()')) {
    stderr.writeln(
        '❌ Yeh progress_screen.dart ka woh version nahi lagta jis par patch bana hai. Kuch nahi badla.');
    exit(1);
  }

  final home = Platform.environment['HOME'] ?? '.';
  final backupDir = Directory('$home/fitgenie_backups')
    ..createSync(recursive: true);
  File('${backupDir.path}/progress_screen.dart.bak').writeAsStringSync(src);
  stdout.writeln('💾 Backup bana: ${backupDir.path}/progress_screen.dart.bak');

  var failed = 0;

  // ---- 1) State field: trend toggle ----
  const insightField = 'bool _loadingInsight = false;';
  if (src.contains(insightField)) {
    src = src.replaceFirst(insightField,
        '$insightField\n  int _trendMode = 0; // 0 = calories, 1 = protein');
    stdout.writeln('✅ _trendMode field joda');
  } else {
    stdout.writeln('❌ _loadingInsight field nahi mila');
    failed++;
  }

  // ---- 2) Best-day field hata do (ab use nahi hota) ----
  final bestField = RegExp(r'^[ \t]*DailyData\? _bestDay;[ \t]*\n', multiLine: true);
  if (bestField.hasMatch(src)) {
    src = src.replaceFirst(bestField, '');
    stdout.writeln('✅ _bestDay field hata diya');
  }

  // ---- 3) Replace jobs ----
  final jobs = <List<String>>[
    ['Widget build(BuildContext context)', _buildCode],
    ['void _calculateWeeklyReport()', _reportCode],
    ['Widget _buildWeekHero()', _heroCode],
    ['Widget _buildCaloriesChart()', _trendCode],
    ['Widget _buildWeightCard()', _weightCardCode],
    ['Widget _buildWeightTrendChart()', _weightChartCode],
    ['Widget _buildDailyBreakdown()', _dailyCode],
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

  // ---- 4) Purane methods jo ab use nahi hote ----
  const removals = [
    'Widget _buildProteinChart()',
    'Widget _buildWorkoutsChart()',
    'Widget _buildTotalsRow()',
    'Widget _buildStatTile(',
    'Widget _buildBestDayCard()',
    'Widget _buildBestStat(',
    'Widget _buildAllTimeCard()',
    'Widget _buildAllTimeRow(',
    'Widget _chartCard(',
  ];
  for (final sig in removals) {
    final r = _findMethod(src, sig);
    if (r != null) {
      src = _removeRange(src, r);
      stdout.writeln('✅ Hata diya: $sig');
    } else {
      stdout.writeln('ℹ️  $sig nahi mila (skip)');
    }
  }

  // _hasBestDay getter
  final bestGetter =
      RegExp(r'[ \t]*bool get _hasBestDay\s*=>[^;]*;[ \t]*\n');
  if (bestGetter.hasMatch(src)) {
    src = src.replaceFirst(bestGetter, '');
    stdout.writeln('✅ _hasBestDay hata diya');
  }

  // Ab-lawaris section banners
  final banners = RegExp(
      r'[ \t]*// =+\n[ \t]*//[^\n]*(?:TOTALS|BEST DAY|ALL-TIME STATS)[^\n]*\n[ \t]*// =+\n\n?');
  src = src.replaceAll(banners, '');

  file.writeAsStringSync(src);
  stdout.writeln('');
  if (failed == 0) {
    stdout.writeln(
        '🎉 Ho gaya. Ab: dart format lib/screens/progress_screen.dart && dart analyze lib/screens/progress_screen.dart && flutter run');
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
  // progress-v2
  final t = Theme.of(context).textTheme;

  return RefreshIndicator(
    color: FitGenieTheme.primary,
    backgroundColor: FitGenieTheme.card,
    onRefresh: _loadAllData,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(FitGenieTheme.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.get('progress_title'),
                        style: t.displaySmall),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.get('progress_sub'),
                      style: const TextStyle(
                          color: FitGenieTheme.muted, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          _buildDateRange(),
          if (_weekData.isNotEmpty) const SizedBox(height: 14),

          _buildWeekHero(),
          const SizedBox(height: 12),

          _buildAIInsightCard(),
          const SizedBox(height: 12),

          _buildTrendChart(),
          const SizedBox(height: 12),

          _buildWeightCard(),
          const SizedBox(height: 12),

          _buildDailyBreakdown(),
          const SizedBox(height: 40),
        ],
      ),
    ),
  );
}''';

const _reportCode = r'''
void _calculateWeeklyReport() {
  if (_weekData.isEmpty) return;

  final daysWithData = _weekData.where((d) => d.calories > 0).length;
  _avgCalories =
      daysWithData > 0 ? (_totalCaloriesBurned / daysWithData).round() : 0;
  _avgProtein = daysWithData > 0 ? (_totalProtein / daysWithData).round() : 0;
}''';

const _heroCode = r'''
Widget _buildWeekHero() {
  final t = Theme.of(context).textTheme;
  final now = DateTime.now();
  final ghost = DateFormat('MMM').format(now).toUpperCase();
  final todayIdx = now.weekday - 1;
  final pct = _caloriesGoal > 0
      ? ((_avgCalories / _caloriesGoal) * 100).round()
      : 0;

  return SizedBox(
    width: double.infinity,
    child: Material(
      color: FitGenieTheme.primary,
      borderRadius: BorderRadius.circular(FitGenieTheme.radiusXL),
      clipBehavior: Clip.antiAlias,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.get('progress_workouts').toUpperCase(),
                        style: t.labelSmall?.copyWith(
                          color:
                              FitGenieTheme.onPrimary.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            FitGenieTheme.onPrimary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded,
                              size: 14, color: FitGenieTheme.onPrimary),
                          const SizedBox(width: 4),
                          Text(
                            '$_currentStreak ${AppStrings.get('progress_days')}',
                            style: const TextStyle(
                              color: FitGenieTheme.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$_thisWeekWorkouts',
                  style:
                      t.displayLarge?.copyWith(color: FitGenieTheme.onPrimary),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final done = _weeklyWorkouts[i] > 0;
                    final isToday = i == todayIdx;
                    return Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done
                                ? FitGenieTheme.onPrimary
                                : Colors.transparent,
                            border: Border.all(
                              color: done
                                  ? FitGenieTheme.onPrimary
                                  : FitGenieTheme.onPrimary.withValues(
                                      alpha: isToday ? 0.9 : 0.35),
                              width: isToday ? 1.5 : 1,
                            ),
                          ),
                          child: done
                              ? const Icon(Icons.check_rounded,
                                  size: 17, color: FitGenieTheme.primary)
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _dayLabels[i].substring(0, 1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isToday ? FontWeight.w800 : FontWeight.w600,
                            color: FitGenieTheme.onPrimary.withValues(
                                alpha: isToday ? 1.0 : 0.7),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_avgCalories kcal ($pct%) · ${_avgProtein}g protein ${AppStrings.get('progress_per_day')}',
                  style: TextStyle(
                    color: FitGenieTheme.onPrimary.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppStrings.get('progress_total')}: $_totalWorkouts',
                  style: TextStyle(
                    color: FitGenieTheme.onPrimary.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}''';

const _trendCode = r'''
Widget _buildTrendChart() {
  final isCal = _trendMode == 0;
  final accent = isCal ? FitGenieTheme.hot : FitGenieTheme.teal;
  final goal = (isCal ? _caloriesGoal : _proteinGoal).toDouble();
  final values = isCal ? _weeklyCalories : _weeklyProtein;
  final unit = isCal ? 'kcal' : 'g';

  Widget tab(String label, int mode) {
    final selected = _trendMode == mode;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _trendMode = mode),
        child: AnimatedContainer(
          duration: FitGenieTheme.animFast,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? FitGenieTheme.border : Colors.transparent,
            borderRadius: BorderRadius.circular(FitGenieTheme.radiusSM),
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: selected ? FitGenieTheme.text : FitGenieTheme.muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  final goalLabel = isCal
      ? AppStrings.get('progress_goal_calories',
          params: {'value': '$_caloriesGoal'})
      : AppStrings.get('progress_goal_protein',
          params: {'value': '$_proteinGoal'});

  return FGCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(FitGenieTheme.radiusSM + 3),
                  border: Border.all(color: FitGenieTheme.border),
                ),
                child: Row(
                  children: [
                    tab(AppStrings.get('progress_calories'), 0),
                    tab(AppStrings.get('progress_protein'), 1),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _pill(goalLabel, accent),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 170,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: goal * 1.3,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => FitGenieTheme.card2,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${values[group.x].toInt()} $unit',
                      const TextStyle(
                        color: FitGenieTheme.text,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ),
              titlesData: _dayTitles(),
              gridData: _grid(goal / 4),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: goal,
                    color: FitGenieTheme.text.withValues(alpha: 0.25),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ],
              ),
              barGroups: List.generate(7, (i) {
                final v = values[i];
                final pct = goal > 0 ? v / goal : 0.0;

                final Color barColor;
                if (v == 0) {
                  barColor = FitGenieTheme.border;
                } else if (pct >= 1.0) {
                  barColor = FitGenieTheme.success;
                } else if (pct >= 0.7) {
                  barColor = accent;
                } else {
                  barColor = accent.withValues(alpha: 0.6);
                }

                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: v > 0 ? v : goal * 0.03,
                      color: barColor,
                      width: 22,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    ),
  );
}''';

const _weightCardCode = r'''
Widget _buildWeightCard() {
  final t = Theme.of(context).textTheme;
  final hasTrend = _weightHistory.length >= 2;

  return FGCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(AppStrings.get('progress_weight')),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(_currentWeight.toStringAsFixed(1),
                          style: t.displayMedium),
                      const SizedBox(width: 6),
                      const Text(
                        'kg',
                        style: TextStyle(
                          color: FitGenieTheme.muted,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasTrend
                        ? _weightTrendLabel()
                        : AppStrings.get('progress_tap_log'),
                    style: TextStyle(
                      color:
                          hasTrend ? _weightTrendColor() : FitGenieTheme.muted,
                      fontSize: 12,
                      fontWeight: hasTrend ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _showAddWeightDialog,
              tooltip: AppStrings.get('progress_log_weight'),
              icon: const Icon(Icons.add_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: FitGenieTheme.primary,
                foregroundColor: FitGenieTheme.onPrimary,
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (hasTrend) ...[
          const SizedBox(height: 14),
          _buildWeightTrendChart(),
        ],
      ],
    ),
  );
}''';

const _weightChartCode = r'''
Widget _buildWeightTrendChart() {
  final weights = _weightHistory.map((e) => e.weight).toList();
  final minW = weights.reduce((a, b) => a < b ? a : b);
  final maxW = weights.reduce((a, b) => a > b ? a : b);
  final padding = (maxW - minW).abs() < 2 ? 2.0 : (maxW - minW) * 0.2;
  final lastIndex = (_weightHistory.length - 1).toDouble();

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: 90,
        child: LineChart(
          LineChartData(
            minY: minW - padding,
            maxY: maxW + padding,
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => FitGenieTheme.card2,
                getTooltipItems: (spots) => spots.map((s) {
                  return LineTooltipItem(
                    '${s.y.toStringAsFixed(1)} kg',
                    const TextStyle(
                      color: FitGenieTheme.text,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  _weightHistory.length,
                  (i) => FlSpot(i.toDouble(), _weightHistory[i].weight),
                ),
                isCurved: true,
                color: FitGenieTheme.teal,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, barData) => spot.x == lastIndex,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: FitGenieTheme.teal,
                      strokeWidth: 2,
                      strokeColor: FitGenieTheme.card,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      FitGenieTheme.teal.withValues(alpha: 0.22),
                      FitGenieTheme.teal.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
            titlesData: const FlTitlesData(show: false),
            gridData: const FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: _weightGridLine,
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMM d').format(_weightHistory.first.date),
            style: const TextStyle(
              color: FitGenieTheme.muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            DateFormat('MMM d').format(_weightHistory.last.date),
            style: const TextStyle(
              color: FitGenieTheme.muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ],
  );
}''';

const _dailyCode = r'''
Widget _buildDailyBreakdown() {
  if (_weekData.isEmpty) return const SizedBox.shrink();

  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final rows = _weekData.reversed.toList();

  return FGCard(
    padding: EdgeInsets.zero,
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        iconColor: FitGenieTheme.muted,
        collapsedIconColor: FitGenieTheme.muted,
        shape: const Border(),
        collapsedShape: const Border(),
        title: _label(AppStrings.get('progress_daily_breakdown')),
        children: List.generate(rows.length, (i) {
          final data = rows[i];
          final isToday = DateFormat('yyyy-MM-dd').format(data.date) == todayStr;
          return _buildDailyRow(data, isToday,
              showDivider: i != rows.length - 1);
        }),
      ),
    ),
  );
}''';
