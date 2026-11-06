// lib/screens/dashboard_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/fitgenie_theme.dart';
import '../widgets/fg_card.dart';
import '../services/step_counter_service.dart';
import '../services/nutrition_service.dart';
import '../services/ai_service.dart' show MealAnalysis;
import '../widgets/app_snackbar.dart';
import '../core/app_strings.dart';
import 'challenges_screen.dart';
import 'meal_scanner_screen.dart';
import 'exercise_library_screen.dart';
import '../widgets/medical_disclaimer.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final VoidCallback? onTapWorkout;
  final VoidCallback? onTapAICoach;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.onTapWorkout,
    this.onTapAICoach,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StepCounterService _stepCounterService = StepCounterService();
  final NutritionService _nutritionService = NutritionService();

  // Loading state
  bool _isLoading = true;

  // User ID
  late String _userId;

  // Goals (from Firestore)
  int _caloriesGoal = 2000;
  int _proteinGoal = 100;
  int _waterGoal = 8;
  int _stepsGoal = 10000;
  int _activeMinutesGoal = 60;

  // Step Counter States
  bool _stepCounterInitialized = false;
  bool _stepCounterHasPermission = true;
  String _pedestrianStatus = 'unknown';
  double _stepsCalories = 0;
  double _stepsDistance = 0;
  int _stepsActiveMinutes = 0;

  // Today's progress
  int _todayCalories = 0;
  int _todayProtein = 0;
  int _todayWater = 0;
  int _todaySteps = 0;
  int _todayActiveMinutes = 0;
  int _todayCaloriesBurned = 0;

  // Weekly data
  List<double> _weeklyWorkouts = [0, 0, 0, 0, 0, 0, 0];
  int _thisWeekWorkoutCount = 0;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    WidgetsBinding.instance.addObserver(this);
    _loadAllData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepCounterService.forceSave();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('🔄 App resumed → refreshing steps...');
        _refreshStepsOnResume();
        break;
      case AppLifecycleState.paused:
        debugPrint('💾 App paused → saving steps...');
        _stepCounterService.forceSave();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _refreshStepsOnResume() async {
    try {
      await _stepCounterService.refreshSteps();

      if (mounted) {
        setState(() {
          _todaySteps = _stepCounterService.todaySteps;
          _updateStepStats();
        });
      }

      await _loadTodayProgress();

      debugPrint('✅ Steps refreshed on resume: $_todaySteps');
    } catch (e) {
      debugPrint('⚠️ Resume refresh error: $e');
    }
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _loadTodayProgress();
      await _loadGoals();
      await _loadWeeklyActivity();
      await _initStepCounter();
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ==========================================
  // 👣 INIT STEP COUNTER
  // ==========================================
  Future<void> _initStepCounter() async {
    try {
      final success = await _stepCounterService.initialize(widget.userId);

      if (success) {
        final serviceSteps = _stepCounterService.todaySteps;
        if (serviceSteps > _todaySteps) {
          _todaySteps = serviceSteps;
        }

        _stepCounterService.onStepsChanged = (steps) {
          if (mounted) {
            setState(() {
              _todaySteps = steps;
              _updateStepStats();
            });
          }
        };

        _stepCounterService.onStatusChanged = (status) {
          if (mounted) {
            setState(() => _pedestrianStatus = status);
          }
        };

        _stepCounterService.onGoogleFitStatusChanged = (status) {
          if (mounted) {
            debugPrint('📡 Google Fit status: $status');
          }
        };

        if (!mounted) return;
        setState(() {
          _stepCounterInitialized = true;
          _stepCounterHasPermission = true;
          _updateStepStats();
        });

        debugPrint('✅ Step counter initialized with $_todaySteps steps');
        debugPrint(
            '   Source: ${_stepCounterService.isUsingHealthConnect ? "Google Fit" : "Pedometer"}');
      } else {
        if (!mounted) return;
        setState(() {
          _stepCounterHasPermission = false;
        });
        debugPrint('❌ Step counter permission denied');
      }
    } catch (e) {
      debugPrint('❌ Step counter init error: $e');
    }
  }

  void _updateStepStats() {
    final stats = _stepCounterService.getStats(weightKg: 70);
    _stepsCalories = (stats['calories'] as num?)?.toDouble() ?? 0.0;
    _stepsDistance = (stats['distance'] as num?)?.toDouble() ?? 0.0;
    _stepsActiveMinutes = (stats['activeMinutes'] as num?)?.toInt() ?? 0;
  }

  Future<void> _requestStepPermission() async {
    final success = await _stepCounterService.initialize(widget.userId);
    if (!mounted) return;
    if (success) {
      setState(() {
        _stepCounterHasPermission = true;
        _stepCounterInitialized = true;
      });
    }
  }

  // ==========================================
  // 🔄 LOAD DATA
  // ==========================================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (_userId.isEmpty) {
        debugPrint('Error: No user ID provided');
        setState(() => _isLoading = false);
        return;
      }

      await Future.wait([
        _loadGoals(),
        _loadTodayProgress(),
        _loadWeeklyActivity(),
      ]);

      await _stepCounterService.refreshSteps();
      if (mounted) {
        setState(() {
          final serviceSteps = _stepCounterService.todaySteps;
          if (serviceSteps > _todaySteps) {
            _todaySteps = serviceSteps;
          }
          _updateStepStats();
        });
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    }

    setState(() => _isLoading = false);
  }

  // ==========================================
  // 🎯 LOAD GOALS
  // ==========================================
  Future<void> _loadGoals() async {
    if (_userId.isEmpty) return;

    try {
      final goalsDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('goals')
          .doc('main')
          .get();

      if (goalsDoc.exists && goalsDoc.data() != null) {
        final data = goalsDoc.data()!;
        if (mounted) {
          setState(() {
            _caloriesGoal = (data['caloriesGoal'] as num?)?.toInt() ?? 2000;
            _proteinGoal = (data['proteinGoal'] as num?)?.toInt() ?? 100;
            _waterGoal = (data['waterGoal'] as num?)?.toInt() ?? 8;
            _stepsGoal = (data['stepsGoal'] as num?)?.toInt() ?? 10000;
            _activeMinutesGoal =
                (data['activeMinutesGoal'] as num?)?.toInt() ?? 60;
          });
        }
      }
    } catch (e) {
      debugPrint('Load goals error: $e');
    }
  }

  // ==========================================
  // 📊 LOAD TODAY PROGRESS
  // ==========================================
  Future<void> _loadTodayProgress() async {
    if (_userId.isEmpty) return;

    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final logDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(dateStr)
          .get();

      if (logDoc.exists && logDoc.data() != null) {
        final data = logDoc.data()!;

        final savedSteps = (data['steps'] as num?)?.toInt() ?? 0;

        if (mounted) {
          setState(() {
            _todayCalories = (data['calories'] as num?)?.toInt() ?? 0;
            _todayProtein = (data['protein'] as num?)?.toInt() ?? 0;
            _todayWater = (data['water'] as num?)?.toInt() ?? 0;
            _todaySteps = math.max(savedSteps, _todaySteps);
            _todayActiveMinutes = (data['activeMinutes'] as num?)?.toInt() ?? 0;
            _todayCaloriesBurned =
                (data['caloriesBurned'] as num?)?.toInt() ?? 0;
          });
        }

        debugPrint(
            '✅ Loaded from Firestore → Steps: $savedSteps, Using: $_todaySteps');
      }

      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final workoutsToday = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('workouts')
          .where('startedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('startedAt', isLessThan: Timestamp.fromDate(todayEnd))
          .get();

      int caloriesBurned = 0;
      int activeMinutes = 0;

      for (var doc in workoutsToday.docs) {
        final data = doc.data();
        int docCaloriesBurned = (data['caloriesBurned'] as num?)?.toInt() ?? 0;
        int docDuration = (data['duration'] as num?)?.toInt() ?? 0;
        int docTotalSets = (data['totalSets'] as num?)?.toInt() ?? 0;

        caloriesBurned += docCaloriesBurned;
        activeMinutes += docDuration;

        if (docCaloriesBurned == 0 && docDuration > 0) {
          caloriesBurned += docDuration * 10;
        }
        if (docCaloriesBurned == 0 && docDuration == 0 && docTotalSets > 0) {
          caloriesBurned += docTotalSets * 15;
        }
      }

      if (mounted) {
        setState(() {
          _todayCaloriesBurned += caloriesBurned;
          _todayActiveMinutes += activeMinutes;
        });
      }
    } catch (e) {
      debugPrint('Load today progress error: $e');
    }
  }

  // ==========================================
  // 📅 LOAD WEEKLY ACTIVITY
  // ==========================================
  Future<void> _loadWeeklyActivity() async {
    if (_userId.isEmpty) return;

    try {
      final now = DateTime.now();
      List<double> weeklyData = [0, 0, 0, 0, 0, 0, 0];
      int totalWorkouts = 0;

      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final workoutsSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('workouts')
          .where('startedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('startedAt', descending: true)
          .get();

      for (var doc in workoutsSnapshot.docs) {
        final data = doc.data();
        final startedAt = data['startedAt'] as Timestamp?;

        if (startedAt != null) {
          final workoutDate = startedAt.toDate();
          final dayIndex = workoutDate.weekday - 1;

          if (dayIndex >= 0 && dayIndex < 7) {
            weeklyData[dayIndex] += 1;
            totalWorkouts += 1;
          }
        }
      }

      if (mounted) {
        setState(() {
          _weeklyWorkouts = weeklyData;
          _thisWeekWorkoutCount = totalWorkouts;
        });
      }
    } catch (e) {
      debugPrint('Load weekly activity error: $e');
    }
  }

  // ==========================================
  // 📝 UPDATE DAILY LOG
  // ==========================================
  Future<void> _updateDailyLog(
      {int? steps, int? water, int? activeMinutes}) async {
    if (_userId.isEmpty) return;

    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    Map<String, dynamic> updates = {};
    if (steps != null) updates['steps'] = steps;
    if (water != null) updates['water'] = water;
    if (activeMinutes != null) updates['activeMinutes'] = activeMinutes;

    if (updates.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(dateStr)
          .set(updates, SetOptions(merge: true));

      await _loadTodayProgress();
    }
  }

  // ==========================================
  // 📷 MEAL SCANNER (AI photo + barcode) — replaces old "Coming Soon"
  // ==========================================
  Future<void> _openMealScanner() async {
    final analysis = await Navigator.push<MealAnalysis>(
      context,
      MaterialPageRoute(builder: (_) => const MealScannerScreen()),
    );

    if (analysis == null || !mounted) return;

    final mealType = await _pickMealTypeForScan();
    if (mealType == null || !mounted) return;

    final entry = MealEntry(
      name: analysis.foodName,
      quantity: analysis.quantity,
      mealType: mealType,
      calories: analysis.calories,
      protein: analysis.protein,
      carbs: analysis.carbs,
      fats: analysis.fat,
      source: 'scanner',
    );

    await _nutritionService.addMealEntry(
      uid: _userId,
      entry: entry,
      date: DateTime.now(),
    );

    // Refresh dashboard totals so today's calories/protein reflect the scan
    await _loadTodayProgress();

    if (!mounted) return;
    AppSnackbar.showSuccess(
      context,
      AppStrings.get('calories_added_success', params: {'name': entry.name}),
    );
  }

  /// Small bottom sheet asking which meal (breakfast/lunch/dinner/snacks)
  /// the scanned item belongs to. Returns null if the user dismisses it.
  Future<String?> _pickMealTypeForScan() async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: FitGenieTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FitGenieTheme.radiusXL)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kis meal mein add karein? 🍽️',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: {
                'breakfast': '🍳 Breakfast',
                'lunch': '🍲 Lunch',
                'dinner': '🍛 Dinner',
                'snacks': '🍪 Snacks',
              }.entries.map((entry) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context, entry.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: FitGenieTheme.card2,
                      borderRadius:
                          BorderRadius.circular(FitGenieTheme.radiusMD),
                      border: Border.all(color: FitGenieTheme.border),
                    ),
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: FitGenieTheme.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🏗️ BUILD UI
  // ==========================================
  @override
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
                _buildCoachBar(),
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
  }

  // ==========================================
  // 👋 HEADER
  // ==========================================
  Widget _buildHeader(String name) {
    final hour = DateTime.now().hour;
    final t = Theme.of(context).textTheme;

    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = AppStrings.get('dashboard_greeting_morning');
    } else if (hour >= 12 && hour < 17) {
      greeting = AppStrings.get('dashboard_greeting_afternoon');
    } else if (hour >= 17 && hour < 21) {
      greeting = AppStrings.get('dashboard_greeting_evening');
    } else {
      greeting = AppStrings.get('dashboard_greeting_night');
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting.toUpperCase(), style: t.labelSmall),
              const SizedBox(height: 2),
              Text(name,
                  style: t.displaySmall, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (_isLoading)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: FitGenieTheme.primary,
            ),
          )
        else
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FitGenieTheme.card,
              borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
              border: Border.all(color: FitGenieTheme.border),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: FitGenieTheme.text,
              size: 22,
            ),
          ),
      ],
    );
  }

  // ==========================================
  // 👣 STEP COUNTER HELPER METHODS
  // ==========================================
  Widget _buildStatusDot() {
    Color color = _getStepStatusColor();
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  String _getStepStatusText() {
    if (!_stepCounterHasPermission) return 'Tap to enable';
    if (!_stepCounterInitialized) return 'Initializing...';

    if (!_stepCounterService.isSensorAvailable) {
      return 'Sensor unavailable';
    }

    if (_stepCounterService.isUsingHealthConnect) {
      return 'Google Fit • Live';
    }

    switch (_pedestrianStatus) {
      case 'walking':
        return 'Walking • Live';
      case 'stopped':
        return 'Idle';
      case 'unavailable':
        return 'Use real device';
      case 'error':
        return 'Sensor error';
      default:
        return 'Tracking';
    }
  }

  Color _getStepStatusColor() {
    if (!_stepCounterHasPermission) return FitGenieTheme.warning;
    if (!_stepCounterInitialized) return Colors.grey;

    if (_stepCounterService.isUsingHealthConnect) {
      return FitGenieTheme.success;
    }

    switch (_pedestrianStatus) {
      case 'walking':
        return FitGenieTheme.success;
      case 'stopped':
        return Colors.grey;
      default:
        return FitGenieTheme.primary;
    }
  }

  // ==========================================
  // 👣 STEPS CARD
  // ==========================================
  Widget _buildStat(String value, String unit, Color color) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: t.headlineSmall?.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(unit.toUpperCase(), style: t.labelSmall),
      ],
    );
  }

  Widget _buildStepsCard() {
    final t = Theme.of(context).textTheme;
    final double progress = _stepsGoal > 0
        ? (_todaySteps / _stepsGoal).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final goalAchieved = progress >= 1.0;
    final int remaining = math.max(0, _stepsGoal - _todaySteps);

    return FGCard(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppStrings.get('dashboard_step_counter').toUpperCase(),
                style: t.labelSmall,
              ),
              const SizedBox(width: 10),
              _buildStatusDot(),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _getStepStatusText(),
                  style: TextStyle(fontSize: 11, color: _getStepStatusColor()),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              if (!_stepCounterHasPermission)
                IconButton(
                  icon: const Icon(Icons.warning_amber_rounded,
                      color: FitGenieTheme.warning, size: 22),
                  onPressed: _requestStepPermission,
                  tooltip: AppStrings.get('dashboard_enable_step_tracking'),
                )
              else
                IconButton(
                  icon: const Icon(Icons.add_rounded,
                      color: FitGenieTheme.muted, size: 24),
                  onPressed: _showAddStepsDialog,
                  tooltip: AppStrings.get('dashboard_add_steps_manually'),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    _formatNumber(_todaySteps),
                    style: t.displayLarge?.copyWith(
                      color: goalAchieved
                          ? FitGenieTheme.primary
                          : FitGenieTheme.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '/ ${_formatNumber(_stepsGoal)}',
                    style: t.titleMedium?.copyWith(color: FitGenieTheme.muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: FitGenieTheme.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(FitGenieTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            goalAchieved
                ? AppStrings.get('dashboard_goal_achieved')
                : AppStrings.get('dashboard_steps_to_go',
                    params: {'count': _formatNumber(remaining)}),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: goalAchieved ? FitGenieTheme.primary : FitGenieTheme.muted,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat(
                    '${_stepsCalories.round()}', 'kcal', FitGenieTheme.hot),
                _buildStat(_stepsDistance.toStringAsFixed(1), 'km',
                    FitGenieTheme.teal),
                _buildStat('$_stepsActiveMinutes', 'min', FitGenieTheme.text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🔥 CALORIES BURNED CARD
  // ==========================================
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
        // Main kaam: bara, bhara hua button
        Material(
          color: FitGenieTheme.primary,
          borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
          child: InkWell(
            onTap: _openMealScanner,
            borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
            child: SizedBox(
              height: 54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.document_scanner_rounded,
                      color: FitGenieTheme.onPrimary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    AppStrings.get('dashboard_scan_meal'),
                    style: t.labelLarge?.copyWith(
                      color: FitGenieTheme.onPrimary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Baqi: chhote text pills
        Row(
          children: [
            Expanded(child: _logButton('Water', _showAddWaterDialog)),
            const SizedBox(width: 10),
            Expanded(child: _logButton('Steps', _showAddStepsDialog)),
            const SizedBox(width: 10),
            Expanded(child: _logButton('Active', _showAddActiveMinutesDialog)),
          ],
        ),
      ],
    );
  }

  // Chat-input jaisi bar: dekhte hi samajh aaye ke yahan likhna hai
  Widget _buildCoachBar() {
    return FGCard(
      onTap: widget.onTapAICoach ?? () {},
      padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Ask your coach anything',
              style: TextStyle(color: FitGenieTheme.muted, fontSize: 14),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FitGenieTheme.primary,
              borderRadius: BorderRadius.circular(FitGenieTheme.radiusMD),
            ),
            child: const Icon(Icons.arrow_upward_rounded,
                color: FitGenieTheme.onPrimary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _logButton(String label, VoidCallback onTap) {
    return FGCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Center(
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: '+ ',
                style: TextStyle(
                  color: FitGenieTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: label,
                style: const TextStyle(
                  color: FitGenieTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ==========================================
  // 🧭 EXPLORE (AI Coach / Exercises / Challenges)
  // ==========================================
  Widget _buildExploreCard() {
    return FGCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _exploreRow(
            AppStrings.get('label_exercises'),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ExerciseLibraryScreen()),
              );
            },
          ),
          const Divider(height: 1),
          _exploreRow(
            AppStrings.get('dashboard_challenges'),
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

  Widget _exploreRow(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                color: FitGenieTheme.muted, size: 18),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🎯 DAILY GOALS CARD
  // ==========================================

  // ==========================================
  // 📅 WEEKLY ACTIVITY CARD
  // ==========================================
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
  }

  // ==========================================
  // ⚡ QUICK ACTIONS
  // ==========================================

  // ==========================================
  // ⚡ QUICK LOG SECTION
  // ==========================================

  // ==========================================
  // 🗨️ DIALOGS
  // ==========================================
  void _showAddStepsDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitGenieTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.directions_walk, color: FitGenieTheme.primary),
            const SizedBox(width: 8),
            Text(AppStrings.get('dashboard_add_steps')),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppStrings.get('dashboard_enter_steps'),
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: FitGenieTheme.card2,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.get('cancel'))),
          ElevatedButton(
            onPressed: () async {
              final steps = int.tryParse(controller.text);
              if (steps != null && steps > 0) {
                Navigator.pop(context);
                await _stepCounterService.addSteps(steps);
                await _updateDailyLog(steps: _stepCounterService.todaySteps);
                _showSnackbar(
                  AppStrings.get('dashboard_steps_added',
                      params: {'count': '$steps'}),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: FitGenieTheme.primary),
            child: Text(AppStrings.get('save'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddWaterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitGenieTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.water_drop, color: FitGenieTheme.teal),
            const SizedBox(width: 8),
            Text(AppStrings.get('dashboard_add_water')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.get('dashboard_current_water',
                  params: {'current': '$_todayWater', 'goal': '$_waterGoal'}),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 2, 3].map((g) => _buildWaterButton(g)).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.get('close'))),
        ],
      ),
    );
  }

  Widget _buildWaterButton(int glasses) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        await _updateDailyLog(water: _todayWater + glasses);
        _showSnackbar(
          AppStrings.get('dashboard_water_added',
              params: {'count': '$glasses'}),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: FitGenieTheme.teal.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.water_drop, color: FitGenieTheme.teal, size: 28),
            const SizedBox(height: 4),
            Text('+$glasses',
                style: const TextStyle(
                    color: FitGenieTheme.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _showAddActiveMinutesDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitGenieTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.timer, color: FitGenieTheme.hot),
            const SizedBox(width: 8),
            Text(AppStrings.get('dashboard_add_active_minutes')),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppStrings.get('dashboard_enter_minutes'),
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: FitGenieTheme.card2,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.get('cancel'))),
          ElevatedButton(
            onPressed: () async {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                Navigator.pop(context);
                await _updateDailyLog(
                    activeMinutes: _todayActiveMinutes + minutes);
                _showSnackbar(
                  AppStrings.get('dashboard_minutes_added',
                      params: {'count': '$minutes'}),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: FitGenieTheme.hot),
            child: Text(AppStrings.get('save'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    if (mounted) {
      AppSnackbar.showSuccess(context, message);
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    }
    return number.toString();
  }
}

// ==========================================
// 🎯 STEP RING PAINTER
// ==========================================
