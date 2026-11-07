// lib/screens/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../app/fitgenie_theme.dart';
import '../core/app_strings.dart';
import '../widgets/fg_card.dart';
import '../widgets/app_snackbar.dart';
import '../services/ai_service.dart';

class ProgressScreen extends StatefulWidget {
  final String userId;

  const ProgressScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIService _aiService = AIService();

  // l10n-r1a: weekday labels follow the selected language
  static List<String> get _dayLabels =>
      AppStrings.get('progress_weekdays_short').split(',');

  bool _isLoading = true;
  String _aiInsight = '';
  bool _loadingInsight = false;
  int _trendMode = 0; // 0 = calories, 1 = protein

  // Stats data
  int _totalWorkouts = 0;
  int _thisWeekWorkouts = 0;
  int _totalCaloriesBurned = 0;
  int _currentStreak = 0;
  List<double> _weeklyCalories = [0, 0, 0, 0, 0, 0, 0];
  List<double> _weeklyWorkouts = [0, 0, 0, 0, 0, 0, 0];
  List<double> _weeklyProtein = [0, 0, 0, 0, 0, 0, 0];
  double _currentWeight = 75.0;

  // Weight trend history (chronological, oldest -> newest)
  List<WeightEntry> _weightHistory = [];

  // Weekly report data
  List<DailyData> _weekData = [];
  int _caloriesGoal = 2400;
  int _proteinGoal = 180;
  int _totalProtein = 0;
  int _avgCalories = 0;
  int _avgProtein = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // ============================================================
  // 📡 DATA LOADING
  // ============================================================

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _loadWorkoutStats(),
      _loadNutritionStats(),
      _loadWeightHistory(),
      _loadGoals(),
    ]);

    if (!mounted) return;
    _calculateWeeklyReport();
    setState(() => _isLoading = false);
  }

  Future<void> _loadGoals() async {
    try {
      final goalsDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('goals')
          .doc('main')
          .get();

      if (goalsDoc.exists) {
        final data = goalsDoc.data()!;
        _caloriesGoal = (data['caloriesGoal'] as num?)?.toInt() ?? 2400;
        _proteinGoal = (data['proteinGoal'] as num?)?.toInt() ?? 180;
      }
    } catch (e) {
      debugPrint('Goals load error: $e');
    }
  }

  Future<void> _loadWorkoutStats() async {
    try {
      final workoutsSnapshot = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('workouts')
          .orderBy('startedAt', descending: true)
          .get();

      final total = workoutsSnapshot.docs.length;

      // Monday 00:00 of this week (the old version used "now minus N days",
      // which silently dropped Monday workouts done earlier in the day).
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));

      int thisWeek = 0;
      final List<double> weeklyData = [0, 0, 0, 0, 0, 0, 0];

      for (final doc in workoutsSnapshot.docs) {
        final data = doc.data();
        final startedAt = data['startedAt'] as Timestamp?;
        if (startedAt == null) continue;

        final workoutDate = startedAt.toDate();
        if (!workoutDate.isBefore(weekStart)) {
          thisWeek++;
          final dayIndex = workoutDate.weekday - 1;
          if (dayIndex >= 0 && dayIndex < 7) {
            weeklyData[dayIndex]++;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _totalWorkouts = total;
        _thisWeekWorkouts = thisWeek;
        _weeklyWorkouts = weeklyData;
      });
    } catch (e) {
      debugPrint('Workout stats error: $e');
    }
  }

  Future<void> _loadNutritionStats() async {
    try {
      final now = DateTime.now();
      final List<double> weeklyCalories = [0, 0, 0, 0, 0, 0, 0];
      final List<double> weeklyProtein = [0, 0, 0, 0, 0, 0, 0];
      final List<DailyData> weekData = [];
      int totalCals = 0;
      int totalPro = 0;
      int streak = 0;

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        final logDoc = await _firestore
            .collection('users')
            .doc(widget.userId)
            .collection('dailyLogs')
            .doc(dateStr)
            .get();

        int cals = 0;
        int pro = 0;

        if (logDoc.exists) {
          final data = logDoc.data() ?? {};
          // num -> int, so a double in Firestore can't crash the whole load
          cals = (data['calories'] as num?)?.toInt() ?? 0;
          pro = (data['protein'] as num?)?.toInt() ?? 0;
        }

        // Workouts for this day
        int workouts = 0;
        try {
          final startOfDay = DateTime(date.year, date.month, date.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));

          final workoutsQuery = await _firestore
              .collection('users')
              .doc(widget.userId)
              .collection('workouts')
              .where('startedAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
              .where('startedAt', isLessThan: Timestamp.fromDate(endOfDay))
              .get();
          workouts = workoutsQuery.docs.length;
        } catch (_) {}

        final weekdayIndex = date.weekday - 1;
        if (weekdayIndex >= 0 && weekdayIndex < 7) {
          weeklyCalories[weekdayIndex] = cals.toDouble();
          weeklyProtein[weekdayIndex] = pro.toDouble();
        }

        totalCals += cals;
        totalPro += pro;

        if (cals > 0) streak++;

        weekData.add(DailyData(
          date: date,
          calories: cals,
          protein: pro,
          workouts: workouts,
        ));
      }

      if (!mounted) return;
      setState(() {
        _weeklyCalories = weeklyCalories;
        _weeklyProtein = weeklyProtein;
        _totalCaloriesBurned = totalCals;
        _totalProtein = totalPro;
        _currentStreak = streak;
        _weekData = weekData;
      });
    } catch (e) {
      debugPrint('Nutrition stats error: $e');
    }
  }

  void _calculateWeeklyReport() {
    if (_weekData.isEmpty) return;

    final daysWithData = _weekData.where((d) => d.calories > 0).length;
    _avgCalories =
        daysWithData > 0 ? (_totalCaloriesBurned / daysWithData).round() : 0;
    _avgProtein = daysWithData > 0 ? (_totalProtein / daysWithData).round() : 0;
  }

  Future<void> _loadWeightHistory() async {
    try {
      final weightSnapshot = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('weightLogs')
          .orderBy('date', descending: true)
          .limit(15)
          .get();

      final List<WeightEntry> history = [];

      for (final doc in weightSnapshot.docs) {
        final data = doc.data();
        final ts = data['date'] as Timestamp?;
        final w = (data['weight'] as num?)?.toDouble();
        if (w != null) {
          history.add(
              WeightEntry(date: ts?.toDate() ?? DateTime.now(), weight: w));
        }
      }

      if (history.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _currentWeight = history.first.weight; // list is descending
          _weightHistory = history.reversed.toList(); // oldest -> newest
        });
        return;
      }

      // Fallback: no weightLogs yet -> use the weight saved on the profile.
      final userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      final profileWeight = (userDoc.data()?['weight'] as num?)?.toDouble();
      if (profileWeight != null) {
        if (!mounted) return;
        setState(() {
          _currentWeight = profileWeight;
          _weightHistory = [];
        });
      }
    } catch (e) {
      debugPrint('Weight history error: $e');
    }
  }

  Future<void> _getAIInsight() async {
    setState(() => _loadingInsight = true);

    try {
      final insight = await _aiService.chat(
        uid: widget.userId,
        userMessage: '''Mera is week ka progress analyze karo:
- Workouts: $_thisWeekWorkouts
- Total calories: $_totalCaloriesBurned
- Total protein: ${_totalProtein}g
- Avg calories: $_avgCalories/day
- Streak: $_currentStreak days
- Current weight: $_currentWeight kg

Short motivating feedback do (2-3 lines max) with tips.''',
      );

      if (!mounted) return;
      setState(() {
        _aiInsight = insight;
        _loadingInsight = false;
      });
    } catch (e) {
      debugPrint('AI insight error: $e');
      if (!mounted) return;
      setState(() => _loadingInsight = false);
      AppSnackbar.showError(context, AppStrings.get('snackbar_error'));
    }
  }

  // ============================================================
  // 🧱 BUILD
  // ============================================================

  @override
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
  }

  // ============================================================
  // 🏷️ SHARED PIECES
  // ============================================================

  Widget _label(String text, {Color? color}) {
    final base = Theme.of(context).textTheme.labelSmall;
    return Text(
      text.toUpperCase(),
      style: color == null ? base : base?.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _pill(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  FlTitlesData _dayTitles() {
    final todayIdx = DateTime.now().weekday - 1;

    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i > 6) return const SizedBox.shrink();
            final isToday = i == todayIdx;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _dayLabels[i],
                style: TextStyle(
                  color: isToday ? FitGenieTheme.text : FitGenieTheme.muted,
                  fontSize: 10,
                  letterSpacing: 0.4,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  FlGridData _grid(double interval) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (value) => const FlLine(
        color: FitGenieTheme.divider,
        strokeWidth: 1,
      ),
    );
  }

  // ============================================================
  // 📅 DATE RANGE
  // ============================================================

  Widget _buildDateRange() {
    if (_weekData.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final start = DateFormat('MMM d').format(now.subtract(
      const Duration(days: 6),
    ));
    final end = DateFormat('MMM d, yyyy').format(now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FitGenieTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 14, color: FitGenieTheme.muted),
          const SizedBox(width: 8),
          Text(
            '$start - $end',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: FitGenieTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 1️⃣ HERO (this week's workouts + streak)
  // ============================================================

  Widget _buildWeekHero() {
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    final ghost = DateFormat('MMM').format(now).toUpperCase();
    final todayIdx = now.weekday - 1;
    final pct =
        _caloriesGoal > 0 ? ((_avgCalories / _caloriesGoal) * 100).round() : 0;

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
                    style: t.displayLarge
                        ?.copyWith(color: FitGenieTheme.onPrimary),
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
                              color: FitGenieTheme.onPrimary
                                  .withValues(alpha: isToday ? 1.0 : 0.7),
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
  }

  // ============================================================
  // 3️⃣ CHARTS
  // ============================================================

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
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
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
  }

  // ============================================================
  // 5️⃣ WEIGHT
  // ============================================================

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
                        color: hasTrend
                            ? _weightTrendColor()
                            : FitGenieTheme.muted,
                        fontSize: 12,
                        fontWeight:
                            hasTrend ? FontWeight.w700 : FontWeight.w500,
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
  }

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
  }

  static FlLine _weightGridLine(double value) =>
      const FlLine(color: FitGenieTheme.divider, strokeWidth: 1);

  String _weightTrendLabel() {
    final diff = _weightHistory.last.weight - _weightHistory.first.weight;
    final arrow = diff > 0 ? '↑' : (diff < 0 ? '↓' : '→');
    return AppStrings.get('progress_weight_since', params: {
      'arrow': arrow,
      'kg': diff.abs().toStringAsFixed(1),
      'date': DateFormat('MMM d').format(_weightHistory.first.date),
    });
  }

  Color _weightTrendColor() {
    final diff = _weightHistory.last.weight - _weightHistory.first.weight;
    if (diff == 0) return FitGenieTheme.muted;
    return diff < 0 ? FitGenieTheme.success : FitGenieTheme.warning;
  }

  // ============================================================
  // 6️⃣ DAILY BREAKDOWN
  // ============================================================

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
            final isToday =
                DateFormat('yyyy-MM-dd').format(data.date) == todayStr;
            return _buildDailyRow(data, isToday,
                showDivider: i != rows.length - 1);
          }),
        ),
      ),
    );
  }

  Widget _buildDailyRow(DailyData data, bool isToday,
      {required bool showDivider}) {
    final dayName = DateFormat('EEE, MMM d').format(data.date);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: FitGenieTheme.divider))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        dayName,
                        style: TextStyle(
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w600,
                          color: isToday
                              ? FitGenieTheme.primary
                              : FitGenieTheme.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FitGenieTheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppStrings.get('progress_today'),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: FitGenieTheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                if (data.workouts > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fitness_center_rounded,
                            size: 12, color: FitGenieTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${data.workouts}× ${AppStrings.get('progress_workouts')}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: FitGenieTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data.calories} cal',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: data.calories > 0
                      ? FitGenieTheme.hot
                      : FitGenieTheme.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${data.protein}g protein',
                style: TextStyle(
                  fontSize: 12,
                  color: data.protein > 0
                      ? FitGenieTheme.teal
                      : FitGenieTheme.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 7️⃣ AI INSIGHT (violet = AI only)
  // ============================================================

  Widget _buildAIInsightCard() {
    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: FitGenieTheme.ai),
              const SizedBox(width: 8),
              Expanded(
                child: _label(AppStrings.get('progress_insight'),
                    color: FitGenieTheme.ai),
              ),
              TextButton.icon(
                onPressed: _loadingInsight ? null : _getAIInsight,
                icon: _loadingInsight
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: FitGenieTheme.ai,
                        ),
                      )
                    : const Icon(Icons.bolt_rounded, size: 18),
                label: Text(
                  _loadingInsight
                      ? AppStrings.get('progress_loading')
                      : AppStrings.get('progress_get'),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: FitGenieTheme.ai,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_aiInsight.isEmpty)
            SizedBox(
              width: double.infinity,
              child: Text(
                AppStrings.get('progress_tap_insight'),
                style: const TextStyle(
                  color: FitGenieTheme.muted,
                  fontSize: 13,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FitGenieTheme.ai.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(FitGenieTheme.radiusMD),
                border:
                    Border.all(color: FitGenieTheme.ai.withValues(alpha: 0.25)),
              ),
              child: Text(
                _aiInsight,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ⚖️ LOG WEIGHT
  // ============================================================

  Future<void> _showAddWeightDialog() async {
    final weight = await showDialog<double>(
      context: context,
      builder: (_) => _WeightDialog(initialWeight: _currentWeight),
    );

    if (weight == null || !mounted) return;
    await _saveWeight(weight);
  }

  Future<void> _saveWeight(double weight) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('weightLogs')
          .doc(dateStr)
          .set({
        'weight': weight,
        'date': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Keep the profile's weight field in sync too.
      await _firestore.collection('users').doc(widget.userId).set({
        'weight': weight,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() => _currentWeight = weight);
      AppSnackbar.showSuccess(
          context, AppStrings.get('progress_weight_logged'));

      // Refresh trend chart with the new entry
      await _loadWeightHistory();
    } catch (e) {
      debugPrint('Save weight error: $e');
      if (mounted) {
        AppSnackbar.showError(context, AppStrings.get('snackbar_error'));
      }
    }
  }
}

// ==========================================
// ⚖️ WEIGHT DIALOG (owns its controller, so it is disposed safely)
// ==========================================
class _WeightDialog extends StatefulWidget {
  final double initialWeight;

  const _WeightDialog({required this.initialWeight});

  @override
  State<_WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<_WeightDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialWeight.toStringAsFixed(1),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    // Accept both "75.5" and "75,5"
    final weight = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (weight != null && weight > 0) {
      Navigator.pop(context, weight);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppStrings.get('progress_log_weight'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: Theme.of(context).textTheme.headlineSmall,
        decoration: InputDecoration(
          labelText: AppStrings.get('progress_weight_kg'),
          suffixText: 'kg',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.get('cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(minimumSize: const Size(96, 46)),
          child: Text(AppStrings.get('save')),
        ),
      ],
    );
  }
}

// ==========================================
// 📅 DAILY DATA MODEL
// ==========================================
class DailyData {
  final DateTime date;
  final int calories;
  final int protein;
  final int workouts;

  DailyData({
    required this.date,
    required this.calories,
    required this.protein,
    required this.workouts,
  });
}

// ==========================================
// ⚖️ WEIGHT ENTRY MODEL (for trend chart)
// ==========================================
class WeightEntry {
  final DateTime date;
  final double weight;

  WeightEntry({required this.date, required this.weight});
}
