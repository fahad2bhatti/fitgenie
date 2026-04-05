// lib/screens/dashboard_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/fitgenie_theme.dart';
import '../widgets/fg_card.dart';
import '../widgets/fg_progress.dart';
import '../widgets/quick_action_tile.dart';
import '../services/step_counter_service.dart';
import 'challenges_screen.dart';
import 'meal_scanner_screen.dart';

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

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StepCounterService _stepCounterService = StepCounterService();

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
    // ✅ NEW: Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    _loadAllData();
  }

  @override
  void dispose() {
    // ✅ NEW: Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    // ✅ NEW: Save steps before disposing
    _stepCounterService.forceSave();
    super.dispose();
  }

  // ✅ NEW: Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
      // App foreground mein aaya — steps refresh karo
        debugPrint('🔄 App resumed — refreshing steps...');
        _refreshStepsOnResume();
        break;
      case AppLifecycleState.paused:
      // App background mein gaya — steps save karo
        debugPrint('💾 App paused — saving steps...');
        _stepCounterService.forceSave();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  // ✅ NEW: Refresh steps when app comes back to foreground
  Future<void> _refreshStepsOnResume() async {
    try {
      // Refresh from Google Fit / Firestore
      await _stepCounterService.refreshSteps();

      if (mounted) {
        setState(() {
          _todaySteps = _stepCounterService.todaySteps;
          _updateStepStats();
        });
      }

      // Also reload today's progress from Firestore
      await _loadTodayProgress();

      debugPrint('✅ Steps refreshed on resume: $_todaySteps');
    } catch (e) {
      debugPrint('⚠️ Resume refresh error: $e');
    }
  }

  // ✅ NEW: Load all data in correct order
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      // Step 1: Load saved data from Firestore FIRST
      await _loadTodayProgress();

      // Step 2: Load goals
      await _loadGoals();

      // Step 3: Load weekly activity
      await _loadWeeklyActivity();

      // Step 4: Initialize step counter WITH saved steps
      await _initStepCounter();
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    }

    setState(() => _isLoading = false);
  }

  // ═══════════════════════════════════════════
  // 👣 INIT STEP COUNTER — FIXED!
  // ═══════════════════════════════════════════
  Future<void> _initStepCounter() async {
    try {
      // ✅ FIX: Step counter is singleton, so saved steps persist
      final success = await _stepCounterService.initialize(widget.userId);

      if (success) {
        // ✅ FIX: After init, check if service has more steps than Firestore
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

        // ✅ NEW: Listen for Google Fit status changes
        _stepCounterService.onGoogleFitStatusChanged = (status) {
          if (mounted) {
            debugPrint('📊 Google Fit status: $status');
          }
        };

        setState(() {
          _stepCounterInitialized = true;
          _stepCounterHasPermission = true;
          _updateStepStats();
        });

        debugPrint('✅ Step counter initialized with $_todaySteps steps');
        debugPrint('   Source: ${_stepCounterService.isUsingHealthConnect ? "Google Fit" : "Pedometer"}');
      } else {
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
    if (success) {
      setState(() {
        _stepCounterHasPermission = true;
        _stepCounterInitialized = true;
      });
    }
  }

  // ═══════════════════════════════════════════
  // 📊 LOAD DATA — FIXED!
  // ═══════════════════════════════════════════
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

      // ✅ NEW: Also refresh steps after loading
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

  // ═══════════════════════════════════════════
  // 🎯 LOAD GOALS
  // ═══════════════════════════════════════════
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
            _activeMinutesGoal = (data['activeMinutesGoal'] as num?)?.toInt() ?? 60;
          });
        }
      }
    } catch (e) {
      debugPrint('Load goals error: $e');
    }
  }

  // ═══════════════════════════════════════════
  // 📈 LOAD TODAY PROGRESS — FIXED!
  // ═══════════════════════════════════════════
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

        // ✅ FIX: Load saved steps and use maximum
        final savedSteps = (data['steps'] as num?)?.toInt() ?? 0;

        if (mounted) {
          setState(() {
            _todayCalories = (data['calories'] as num?)?.toInt() ?? 0;
            _todayProtein = (data['protein'] as num?)?.toInt() ?? 0;
            _todayWater = (data['water'] as num?)?.toInt() ?? 0;
            // ✅ FIX: Use max of saved steps and current steps
            _todaySteps = math.max(savedSteps, _todaySteps);
            _todayActiveMinutes = (data['activeMinutes'] as num?)?.toInt() ?? 0;
            _todayCaloriesBurned = (data['caloriesBurned'] as num?)?.toInt() ?? 0;
          });
        }

        debugPrint('📊 Loaded from Firestore — Steps: $savedSteps, Using: $_todaySteps');
      }

      // Load today's workout calories
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

  // ═══════════════════════════════════════════
  // 📅 LOAD WEEKLY ACTIVITY
  // ═══════════════════════════════════════════
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

  // ═══════════════════════════════════════════
  // 💾 UPDATE DAILY LOG
  // ═══════════════════════════════════════════
  Future<void> _updateDailyLog({int? steps, int? water, int? activeMinutes}) async {
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

  // ═══════════════════════════════════════════
  // 🎨 BUILD UI
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final name = widget.userName.trim().isEmpty ? 'User' : widget.userName.trim();

    return Scaffold(
      backgroundColor: FitGenieTheme.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: FitGenieTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(name),
                const SizedBox(height: 16),
                _buildStepsCard(),
                const SizedBox(height: 14),
                _buildCaloriesBurnedCard(),
                const SizedBox(height: 14),
                _buildDailyGoalsCard(),
                const SizedBox(height: 14),
                _buildWeeklyActivityCard(),
                const SizedBox(height: 16),
                const Text('Quick Actions',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                _buildQuickActions(),
                const SizedBox(height: 16),
                _buildQuickLogSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 👋 HEADER
  // ═══════════════════════════════════════════
  Widget _buildHeader(String name) {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;

    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
      emoji = '☀️';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      emoji = '🌤️';
    } else if (hour >= 17 && hour < 21) {
      greeting = 'Good Evening';
      emoji = '🌅';
    } else {
      greeting = 'Good Night';
      emoji = '🌙';
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting $emoji',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: FitGenieTheme.primary),
          )
        else
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
              border: Border.all(color: FitGenieTheme.primary.withOpacity(0.3)),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: FitGenieTheme.primary, size: 22),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 👣 STEP COUNTER HELPER METHODS
  // ═══════════════════════════════════════════
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
            color: color.withOpacity(0.5),
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

    // ✅ NEW: Show Google Fit status
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
    if (!_stepCounterHasPermission) return Colors.orange;
    if (!_stepCounterInitialized) return Colors.grey;

    if (_stepCounterService.isUsingHealthConnect) {
      return Colors.green;
    }

    switch (_pedestrianStatus) {
      case 'walking':
        return Colors.green;
      case 'stopped':
        return Colors.grey;
      default:
        return FitGenieTheme.primary;
    }
  }

  Widget _buildMiniStat(IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 👣 STEPS CARD
  // ═══════════════════════════════════════════
  Widget _buildStepsCard() {
    final progress =
    _stepsGoal > 0 ? (_todaySteps / _stepsGoal).clamp(0.0, 1.0) : 0.0;
    final goalAchieved = progress >= 1.0;

    // ✅ NEW: Show data source
    final dataSource = _stepCounterService.isUsingHealthConnect
        ? 'Google Fit'
        : 'Pedometer';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FitGenieTheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: FitGenieTheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FitGenieTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _stepCounterService.isUsingHealthConnect
                      ? Icons.favorite
                      : Icons.directions_walk,
                  color: FitGenieTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Step Counter',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_stepCounterService.isUsingHealthConnect)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_done,
                                    size: 10, color: Colors.green),
                                SizedBox(width: 3),
                                Text(
                                  'SYNC',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _buildStatusDot(),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _getStepStatusText(),
                            style: TextStyle(
                                fontSize: 11, color: _getStepStatusColor()),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_stepCounterHasPermission)
                IconButton(
                  icon: const Icon(Icons.warning_amber,
                      color: Colors.orange, size: 22),
                  onPressed: _requestStepPermission,
                  tooltip: 'Enable Step Tracking',
                )
              else
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: FitGenieTheme.primary, size: 22),
                  onPressed: _showAddStepsDialog,
                  tooltip: 'Add Steps Manually',
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Content
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            _formatNumber(_todaySteps),
                            style: const TextStyle(
                                fontSize: 36, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('steps',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[400])),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Goal: ${_formatNumber(_stepsGoal)}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildMiniStat(Icons.local_fire_department,
                            '${_stepsCalories.round()}', 'kcal', Colors.orange),
                        _buildMiniStat(Icons.straighten,
                            _stepsDistance.toStringAsFixed(1), 'km', Colors.blue),
                        _buildMiniStat(Icons.timer, '$_stepsActiveMinutes',
                            'min', Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(90, 90),
                      painter: _StepRingPainter(
                          progress: progress, isGoalAchieved: goalAchieved),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            goalAchieved
                                ? Icons.emoji_events
                                : Icons.directions_walk,
                            color: goalAchieved
                                ? Colors.amber
                                : FitGenieTheme.primary,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: goalAchieved
                                  ? Colors.amber
                                  : FitGenieTheme.primary,
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
          const SizedBox(height: 16),

          // Goal Progress — ✅ FIXED: Show data source
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: goalAchieved
                  ? Colors.green.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  goalAchieved ? Icons.check_circle : Icons.flag,
                  color: goalAchieved ? Colors.green : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    goalAchieved
                        ? '🎉 Goal achieved!'
                        : '${_formatNumber(_stepsGoal - _todaySteps)} steps to go',
                    style: TextStyle(
                      fontSize: 12,
                      color: goalAchieved ? Colors.green : Colors.grey,
                      fontWeight: goalAchieved ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _stepCounterService.isUsingHealthConnect
                        ? Colors.green.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dataSource,
                    style: TextStyle(
                      fontSize: 8,
                      color: _stepCounterService.isUsingHealthConnect
                          ? Colors.green
                          : Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🔥 CALORIES BURNED CARD
  // ═══════════════════════════════════════════
  Widget _buildCaloriesBurnedCard() {
    const caloriesGoal = 2400;
    final progress = caloriesGoal > 0
        ? (_todayCaloriesBurned / caloriesGoal).clamp(0.0, 1.0)
        : 0.0;

    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: FitGenieTheme.hot, size: 20),
              const SizedBox(width: 8),
              const Text('Calories Burned',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Text('Goal: $caloriesGoal',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                _formatNumber(_todayCaloriesBurned),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 6),
              Text('kcal',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              const Spacer(),
              if (_thisWeekWorkoutCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_thisWeekWorkoutCount workouts',
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FGLinearProgress(value: progress, color: FitGenieTheme.hot),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🎯 DAILY GOALS CARD
  // ═══════════════════════════════════════════
  Widget _buildDailyGoalsCard() {
    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes,
                  color: FitGenieTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Daily Goals',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 16),
          _buildGoalRow(
              'Protein Intake',
              '$_todayProtein/$_proteinGoal g',
              _proteinGoal > 0
                  ? (_todayProtein / _proteinGoal).clamp(0.0, 1.0)
                  : 0.0,
              FitGenieTheme.teal),
          const SizedBox(height: 14),
          _buildGoalRow(
              'Water (glasses)',
              '$_todayWater/$_waterGoal',
              _waterGoal > 0
                  ? (_todayWater / _waterGoal).clamp(0.0, 1.0)
                  : 0.0,
              Colors.blue,
              onTap: _showAddWaterDialog),
          const SizedBox(height: 14),
          _buildGoalRow(
              'Active Minutes',
              '$_todayActiveMinutes/$_activeMinutesGoal',
              _activeMinutesGoal > 0
                  ? (_todayActiveMinutes / _activeMinutesGoal).clamp(0.0, 1.0)
                  : 0.0,
              FitGenieTheme.hot),
          const SizedBox(height: 14),
          _buildGoalRow(
              'Calories Intake',
              '$_todayCalories/$_caloriesGoal kcal',
              _caloriesGoal > 0
                  ? (_todayCalories / _caloriesGoal).clamp(0.0, 1.0)
                  : 0.0,
              Colors.orange),
        ],
      ),
    );
  }

  Widget _buildGoalRow(String title, String valueText, double value, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(title,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13))),
              Text(valueText,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.add_circle_outline, size: 16, color: color),
              ],
            ],
          ),
          const SizedBox(height: 8),
          FGLinearProgress(value: value, color: color),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 📅 WEEKLY ACTIVITY CARD
  // ═══════════════════════════════════════════
  Widget _buildWeeklyActivityCard() {
    final maxWorkouts = _weeklyWorkouts.reduce((a, b) => a > b ? a : b);
    final normalizedMax = maxWorkouts > 0 ? maxWorkouts : 1;

    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: FitGenieTheme.primary, size: 18),
              const SizedBox(width: 8),
              const Text('Weekly Activity',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FitGenieTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_thisWeekWorkoutCount workouts',
                  style: const TextStyle(
                      color: FitGenieTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final workoutCount = _weeklyWorkouts[i];
                final heightPercent =
                normalizedMax > 0 ? (workoutCount / normalizedMax) : 0.0;
                final h = heightPercent.clamp(0.08, 1.0);
                final isToday = i == (DateTime.now().weekday - 1);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (workoutCount > 0)
                      Text(
                        '${workoutCount.toInt()}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isToday ? FitGenieTheme.primary : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: workoutCount > 0
                          ? (80 * h).clamp(16.0, 80.0)
                          : 16,
                      decoration: BoxDecoration(
                        gradient: isToday || workoutCount > 0
                            ? LinearGradient(
                          colors: [
                            FitGenieTheme.primary,
                            FitGenieTheme.primary.withOpacity(0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                            : null,
                        color: workoutCount > 0
                            ? null
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                      style: TextStyle(
                        color: isToday ? FitGenieTheme.primary : Colors.grey,
                        fontSize: 12,
                        fontWeight:
                        isToday ? FontWeight.bold : FontWeight.normal,
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

  // ═══════════════════════════════════════════
  // ⚡ QUICK ACTIONS
  // ═══════════════════════════════════════════
  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: QuickActionTile(
                icon: Icons.fitness_center,
                title: 'Workouts',
                onTap: widget.onTapWorkout ?? () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickActionTile(
                icon: Icons.restaurant_menu,
                title: 'Nutrition',
                color: Colors.green,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickActionTile(
                icon: Icons.smart_toy,
                title: 'AI Coach',
                color: Colors.purple,
                onTap: widget.onTapAICoach ?? () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: QuickActionTile(
                icon: Icons.bar_chart,
                title: 'Progress',
                color: Colors.blue,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickActionTile(
                icon: Icons.emoji_events,
                title: 'Challenges',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChallengesScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickActionTile(
                icon: Icons.camera_alt,
                title: 'Scan Meal',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MealScannerScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // 📝 QUICK LOG SECTION
  // ═══════════════════════════════════════════
  Widget _buildQuickLogSection() {
    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('Quick Log',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _buildQuickLogButton(
                      Icons.directions_walk,
                      'Steps',
                      _formatNumber(_todaySteps),
                      FitGenieTheme.primary,
                      _showAddStepsDialog)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildQuickLogButton(
                      Icons.water_drop,
                      'Water',
                      '$_todayWater glasses',
                      Colors.blue,
                      _showAddWaterDialog)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildQuickLogButton(
                      Icons.timer,
                      'Active',
                      '$_todayActiveMinutes min',
                      FitGenieTheme.hot,
                      _showAddActiveMinutesDialog)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLogButton(IconData icon, String label, String value,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 💬 DIALOGS
  // ═══════════════════════════════════════════
  void _showAddStepsDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.directions_walk, color: FitGenieTheme.primary),
            SizedBox(width: 8),
            Text('Add Steps'),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter steps',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF0D0D0D),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final steps = int.tryParse(controller.text);
              if (steps != null && steps > 0) {
                Navigator.pop(context);
                // ✅ FIX: Add steps through service so it persists
                await _stepCounterService.addSteps(steps);
                await _updateDailyLog(steps: _stepCounterService.todaySteps);
                _showSnackbar('Added $steps steps! 🚶');
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: FitGenieTheme.primary),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddWaterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.water_drop, color: Colors.blue),
            SizedBox(width: 8),
            Text('Add Water'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: $_todayWater / $_waterGoal glasses',
                style: const TextStyle(color: Colors.grey)),
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
              child: const Text('Close')),
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
            'Added $glasses glass${glasses > 1 ? 'es' : ''} of water! 💧');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.water_drop, color: Colors.blue, size: 28),
            const SizedBox(height: 4),
            Text('+$glasses',
                style: const TextStyle(
                    color: Colors.blue,
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
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.timer, color: FitGenieTheme.hot),
            SizedBox(width: 8),
            Text('Add Active Minutes'),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter minutes',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF0D0D0D),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                Navigator.pop(context);
                await _updateDailyLog(
                    activeMinutes: _todayActiveMinutes + minutes);
                _showSnackbar('Added $minutes active minutes! 🔥');
              }
            },
            style:
            ElevatedButton.styleFrom(backgroundColor: FitGenieTheme.hot),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    }
    return number.toString();
  }
}

// ═══════════════════════════════════════════
// 🎨 STEP RING PAINTER
// ═══════════════════════════════════════════
class _StepRingPainter extends CustomPainter {
  final double progress;
  final bool isGoalAchieved;

  _StepRingPainter({required this.progress, this.isGoalAchieved = false});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final bg = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);

    final progressColor =
    isGoalAchieved ? Colors.amber : FitGenieTheme.primary;
    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        colors: [progressColor.withOpacity(0.6), progressColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _StepRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isGoalAchieved != isGoalAchieved;
  }
}