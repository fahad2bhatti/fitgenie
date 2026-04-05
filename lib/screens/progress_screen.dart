// lib/screens/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../app/fitgenie_theme.dart';
import '../widgets/fg_card.dart';
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

  bool _isLoading = true;
  String _aiInsight = '';
  bool _loadingInsight = false;

  // Stats data
  int _totalWorkouts = 0;
  int _thisWeekWorkouts = 0;
  int _totalCaloriesBurned = 0;
  int _currentStreak = 0;
  List<double> _weeklyCalories = [0, 0, 0, 0, 0, 0, 0];
  List<double> _weeklyWorkouts = [0, 0, 0, 0, 0, 0, 0];
  List<double> _weeklyProtein = [0, 0, 0, 0, 0, 0, 0];
  double _currentWeight = 75.0;

  // ✅ NEW: Weekly Report Data
  List<DailyData> _weekData = [];
  int _caloriesGoal = 2400;
  int _proteinGoal = 180;
  int _totalProtein = 0;
  int _avgCalories = 0;
  int _avgProtein = 0;
  DailyData? _bestDay;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _loadWorkoutStats(),
      _loadNutritionStats(),
      _loadWeightHistory(),
      _loadGoals(),
    ]);

    _calculateWeeklyReport();

    setState(() => _isLoading = false);
  }

  // ✅ NEW: Load Goals
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

      _totalWorkouts = workoutsSnapshot.docs.length;

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      int thisWeek = 0;
      List<double> weeklyData = [0, 0, 0, 0, 0, 0, 0];

      for (var doc in workoutsSnapshot.docs) {
        final data = doc.data();
        final startedAt = data['startedAt'] as Timestamp?;

        if (startedAt != null) {
          final workoutDate = startedAt.toDate();

          if (workoutDate.isAfter(weekStart)) {
            thisWeek++;

            final dayIndex = workoutDate.weekday - 1;
            if (dayIndex >= 0 && dayIndex < 7) {
              weeklyData[dayIndex]++;
            }
          }
        }
      }

      setState(() {
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
      List<double> weeklyCalories = [0, 0, 0, 0, 0, 0, 0];
      List<double> weeklyProtein = [0, 0, 0, 0, 0, 0, 0];
      List<DailyData> weekData = [];
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
          cals = (data['calories'] ?? 0) as int;
          pro = (data['protein'] ?? 0) as int;
        }

        // Get workouts for this day
        int workouts = 0;
        try {
          final startOfDay = DateTime(date.year, date.month, date.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));

          final workoutsQuery = await _firestore
              .collection('users')
              .doc(widget.userId)
              .collection('workouts')
              .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
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

  // ✅ NEW: Calculate Weekly Report
  void _calculateWeeklyReport() {
    if (_weekData.isEmpty) return;

    final daysWithData = _weekData.where((d) => d.calories > 0).length;
    _avgCalories = daysWithData > 0 ? (_totalCaloriesBurned / daysWithData).round() : 0;
    _avgProtein = daysWithData > 0 ? (_totalProtein / daysWithData).round() : 0;

    // Find best day
    _bestDay = _weekData.reduce((a, b) {
      final aScore = a.calories / _caloriesGoal + a.protein / _proteinGoal;
      final bScore = b.calories / _caloriesGoal + b.protein / _proteinGoal;
      return aScore > bScore ? a : b;
    });
  }

  Future<void> _loadWeightHistory() async {
    try {
      final weightSnapshot = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('weightLogs')
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> history = [];

      for (var doc in weightSnapshot.docs) {
        history.add(doc.data());
      }

      if (history.isNotEmpty) {
        setState(() {
          _currentWeight = (history.first['weight'] ?? 75.0).toDouble();
        });
      }
    } catch (e) {
      debugPrint('Weight history error: $e');
    }
  }

  Future<void> _getAIInsight() async {
    setState(() => _loadingInsight = true);

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

    setState(() {
      _aiInsight = insight;
      _loadingInsight = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Weekly Report',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Track your fitness journey',
                      style: TextStyle(
                        fontSize: 14,
                        color: FitGenieTheme.muted,
                      ),
                    ),
                  ],
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ✅ NEW: Date Range
            _buildDateRange(),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.fitness_center,
                  value: '$_thisWeekWorkouts',
                  label: 'Workouts',
                  color: FitGenieTheme.primary,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  icon: Icons.local_fire_department,
                  value: '$_totalCaloriesBurned',
                  label: 'Calories',
                  color: FitGenieTheme.hot,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  icon: Icons.bolt,
                  value: '${_totalProtein}g',
                  label: 'Protein',
                  color: FitGenieTheme.teal,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ✅ NEW: Averages Card
            _buildAveragesCard(),
            const SizedBox(height: 16),

            // Weekly Activity Chart
            FGCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: FitGenieTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Workouts This Week',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: FitGenieTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_thisWeekWorkouts total',
                          style: const TextStyle(
                            color: FitGenieTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _weeklyWorkouts.reduce((a, b) => a > b ? a : b) + 2,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    days[value.toInt()],
                                    style: TextStyle(
                                      color: FitGenieTheme.muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(7, (index) {
                          final hasWorkout = _weeklyWorkouts[index] > 0;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: _weeklyWorkouts[index] > 0 ? _weeklyWorkouts[index] : 0.3,
                                color: hasWorkout
                                    ? FitGenieTheme.primary
                                    : FitGenieTheme.primary.withOpacity(0.2),
                                width: 28,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Calories Chart
            FGCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, color: FitGenieTheme.hot, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Calories This Week',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: FitGenieTheme.hot.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Goal: $_caloriesGoal',
                          style: const TextStyle(
                            color: FitGenieTheme.hot,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (_caloriesGoal * 1.2).toDouble(),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toInt()} cal',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    days[value.toInt()],
                                    style: TextStyle(color: FitGenieTheme.muted, fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _caloriesGoal / 4,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.white.withOpacity(0.1),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(7, (index) {
                          final cals = _weeklyCalories[index];
                          final percentage = cals / _caloriesGoal;

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: cals > 0 ? cals : 50,
                                color: cals == 0
                                    ? FitGenieTheme.hot.withOpacity(0.2)
                                    : percentage >= 1.0
                                    ? Colors.green
                                    : percentage >= 0.7
                                    ? FitGenieTheme.hot
                                    : FitGenieTheme.hot.withOpacity(0.6),
                                width: 28,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ✅ NEW: Protein Chart
            FGCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant, color: FitGenieTheme.teal, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Protein This Week',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: FitGenieTheme.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Goal: ${_proteinGoal}g',
                          style: const TextStyle(
                            color: FitGenieTheme.teal,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: (_proteinGoal * 1.3).toDouble(),
                        lineBarsData: [
                          // Actual protein line
                          LineChartBarData(
                            spots: List.generate(7, (index) {
                              return FlSpot(index.toDouble(), _weeklyProtein[index]);
                            }),
                            isCurved: true,
                            color: FitGenieTheme.teal,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 5,
                                  color: FitGenieTheme.teal,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: FitGenieTheme.teal.withOpacity(0.2),
                            ),
                          ),
                          // Goal line
                          LineChartBarData(
                            spots: List.generate(7, (index) {
                              return FlSpot(index.toDouble(), _proteinGoal.toDouble());
                            }),
                            isCurved: false,
                            color: Colors.white.withOpacity(0.3),
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            dashArray: [5, 5],
                          ),
                        ],
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    days[value.toInt()],
                                    style: TextStyle(color: FitGenieTheme.muted, fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _proteinGoal / 4,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.white.withOpacity(0.1),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ✅ NEW: Best Day Card
            if (_bestDay != null && (_bestDay!.calories > 0 || _bestDay!.protein > 0))
              _buildBestDayCard(),

            if (_bestDay != null && (_bestDay!.calories > 0 || _bestDay!.protein > 0))
              const SizedBox(height: 16),

            // Weight Card
            FGCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.monitor_weight, color: FitGenieTheme.teal, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Current Weight',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: FitGenieTheme.primary),
                        onPressed: _showAddWeightDialog,
                        tooltip: 'Log Weight',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '${_currentWeight.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tap + to log new weight',
                          style: TextStyle(color: FitGenieTheme.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ✅ NEW: Daily Breakdown
            _buildDailyBreakdown(),
            const SizedBox(height: 16),

            // AI Insights
            FGCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.smart_toy, color: Colors.purple, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'AI Insights',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _loadingInsight ? null : _getAIInsight,
                        icon: _loadingInsight
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(_loadingInsight ? 'Loading...' : 'Get Insight'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_aiInsight.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.lightbulb_outline, size: 40, color: Colors.purple.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text(
                            'Tap "Get Insight" for AI analysis',
                            style: TextStyle(color: FitGenieTheme.muted),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _aiInsight,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Total Stats
            FGCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏆 All Time Stats',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildAllTimeRow(Icons.fitness_center, 'Total Workouts', '$_totalWorkouts'),
                  const Divider(height: 24, color: Colors.white12),
                  _buildAllTimeRow(Icons.calendar_today, 'Current Streak', '$_currentStreak days'),
                  const Divider(height: 24, color: Colors.white12),
                  _buildAllTimeRow(Icons.emoji_events, 'Best Streak', '7 days'),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Date Range Widget
  Widget _buildDateRange() {
    if (_weekData.isEmpty) return const SizedBox();

    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 6));
    final startDate = DateFormat('MMM d').format(weekStart);
    final endDate = DateFormat('MMM d, yyyy').format(now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: FitGenieTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FitGenieTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, color: FitGenieTheme.primary, size: 18),
          const SizedBox(width: 10),
          Text(
            '$startDate - $endDate',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: FitGenieTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Averages Card
  Widget _buildAveragesCard() {
    return FGCard(
      child: Row(
        children: [
          Expanded(
            child: _buildAvgTile(
              icon: '🔥',
              label: 'Avg Calories',
              value: '$_avgCalories',
              sub: 'per day',
              color: FitGenieTheme.hot,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white12),
          Expanded(
            child: _buildAvgTile(
              icon: '💪',
              label: 'Avg Protein',
              value: '${_avgProtein}g',
              sub: 'per day',
              color: FitGenieTheme.teal,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white12),
          Expanded(
            child: _buildAvgTile(
              icon: '⚡',
              label: 'Streak',
              value: '$_currentStreak',
              sub: 'days',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvgTile({
    required String icon,
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          sub,
          style: TextStyle(
            fontSize: 10,
            color: FitGenieTheme.muted,
          ),
        ),
      ],
    );
  }

  // ✅ NEW: Best Day Card
  Widget _buildBestDayCard() {
    final dayName = DateFormat('EEEE, MMM d').format(_bestDay!.date);
    final calPercent = ((_bestDay!.calories / _caloriesGoal) * 100).round();
    final proPercent = ((_bestDay!.protein / _proteinGoal) * 100).round();

    return FGCard(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity(0.1),
              Colors.orange.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🏆', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Text(
                  'Best Day This Week!',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              dayName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniStat('🔥', '${_bestDay!.calories}', 'cal ($calPercent%)'),
                const SizedBox(width: 24),
                _buildMiniStat('💪', '${_bestDay!.protein}g', 'protein ($proPercent%)'),
                if (_bestDay!.workouts > 0) ...[
                  const SizedBox(width: 24),
                  _buildMiniStat('🏋️', '${_bestDay!.workouts}', 'workouts'),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: FitGenieTheme.muted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ✅ NEW: Daily Breakdown
  Widget _buildDailyBreakdown() {
    if (_weekData.isEmpty) return const SizedBox();

    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Daily Breakdown',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 14),
          ..._weekData.reversed.map((data) {
            final dayName = DateFormat('EEE, MMM d').format(data.date);
            final isToday = DateFormat('yyyy-MM-dd').format(data.date) ==
                DateFormat('yyyy-MM-dd').format(DateTime.now());

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isToday
                    ? FitGenieTheme.primary.withOpacity(0.1)
                    : FitGenieTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: isToday
                    ? Border.all(color: FitGenieTheme.primary.withOpacity(0.3))
                    : null,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                              color: isToday ? FitGenieTheme.primary : Colors.white,
                            ),
                          ),
                          if (isToday)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: FitGenieTheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'TODAY',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (data.workouts > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: FitGenieTheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '🏋️ ${data.workouts} workout${data.workouts > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: FitGenieTheme.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${data.calories} cal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: data.calories > 0 ? FitGenieTheme.hot : FitGenieTheme.muted,
                        ),
                      ),
                      Text(
                        '${data.protein}g protein',
                        style: TextStyle(
                          fontSize: 12,
                          color: data.protein > 0 ? FitGenieTheme.teal : FitGenieTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FitGenieTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: FitGenieTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTimeRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: FitGenieTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(color: FitGenieTheme.muted)),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  void _showAddWeightDialog() {
    final controller = TextEditingController(text: _currentWeight.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitGenieTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Weight'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Weight (kg)',
            labelStyle: TextStyle(color: FitGenieTheme.muted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: FitGenieTheme.background,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final weight = double.tryParse(controller.text);
              if (weight != null && weight > 0) {
                await _saveWeight(weight);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FitGenieTheme.primary,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWeight(double weight) async {
    try {
      final today = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(today);

      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('weightLogs')
          .doc(dateStr)
          .set({
        'weight': weight,
        'date': FieldValue.serverTimestamp(),
      });

      setState(() {
        _currentWeight = weight;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight logged! 💪')),
      );
    } catch (e) {
      debugPrint('Save weight error: $e');
    }
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