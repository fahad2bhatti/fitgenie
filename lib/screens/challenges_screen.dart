// lib/screens/challenges_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../app/fitgenie_theme.dart';
import '../widgets/fg_card.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late TabController _tabController;
  bool _loading = true;

  // User Stats
  int _totalWorkouts = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalCaloriesLogged = 0;
  int _totalProteinLogged = 0;
  int _totalPoints = 0;
  int _level = 1;

  // Today's Progress
  int _todayCalories = 0;
  int _todayProtein = 0;
  int _todayWorkouts = 0;
  int _todayWater = 0;

  // Goals
  int _caloriesGoal = 2400;
  int _proteinGoal = 180;
  int _waterGoal = 8;

  // Achievements
  List<Achievement> _unlockedAchievements = [];
  List<Achievement> _lockedAchievements = [];

  // Challenges
  List<Challenge> _dailyChallenges = [];
  List<Challenge> _weeklyChallenges = [];

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');
    return user.uid;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);

    await Future.wait([
      _loadUserStats(),
      _loadTodayProgress(),
      _loadGoals(),
    ]);

    _generateChallenges();
    _checkAchievements();
    _calculateLevel();

    setState(() => _loading = false);
  }

  Future<void> _loadUserStats() async {
    try {
      // Load user document
      final userDoc = await _db.collection('users').doc(_uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _totalPoints = (data['totalPoints'] as num?)?.toInt() ?? 0;
        _longestStreak = (data['longestStreak'] as num?)?.toInt() ?? 0;
      }

      // Count total workouts
      final workoutsSnap = await _db
          .collection('users')
          .doc(_uid)
          .collection('workouts')
          .get();
      _totalWorkouts = workoutsSnap.docs.length;

      // Calculate streak
      _currentStreak = await _calculateStreak();

      // Update longest streak
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
        await _db.collection('users').doc(_uid).update({
          'longestStreak': _longestStreak,
        });
      }

      // Calculate total calories and protein logged
      final logsSnap = await _db
          .collection('users')
          .doc(_uid)
          .collection('dailyLogs')
          .get();

      int totalCal = 0;
      int totalPro = 0;
      for (var doc in logsSnap.docs) {
        final data = doc.data();
        totalCal += (data['calories'] as num?)?.toInt() ?? 0;
        totalPro += (data['protein'] as num?)?.toInt() ?? 0;
      }
      _totalCaloriesLogged = totalCal;
      _totalProteinLogged = totalPro;
    } catch (e) {
      debugPrint('Error loading user stats: $e');
    }
  }

  Future<int> _calculateStreak() async {
    int streak = 0;
    final now = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final logDoc = await _db
          .collection('users')
          .doc(_uid)
          .collection('dailyLogs')
          .doc(dateStr)
          .get();

      if (logDoc.exists) {
        final data = logDoc.data()!;
        final calories = (data['calories'] as num?)?.toInt() ?? 0;
        if (calories > 0) {
          streak++;
        } else {
          break;
        }
      } else {
        if (i > 0) break; // Allow today to be empty
      }
    }

    return streak;
  }

  Future<void> _loadTodayProgress() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final logDoc = await _db
          .collection('users')
          .doc(_uid)
          .collection('dailyLogs')
          .doc(today)
          .get();

      if (logDoc.exists) {
        final data = logDoc.data()!;
        _todayCalories = (data['calories'] as num?)?.toInt() ?? 0;
        _todayProtein = (data['protein'] as num?)?.toInt() ?? 0;
        _todayWater = (data['water'] as num?)?.toInt() ?? 0;
      }

      // Count today's workouts
      final startOfDay = DateTime.now();
      final start = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);
      final end = start.add(const Duration(days: 1));

      final workoutsSnap = await _db
          .collection('users')
          .doc(_uid)
          .collection('workouts')
          .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startedAt', isLessThan: Timestamp.fromDate(end))
          .get();

      _todayWorkouts = workoutsSnap.docs.length;
    } catch (e) {
      debugPrint('Error loading today progress: $e');
    }
  }

  Future<void> _loadGoals() async {
    try {
      final goalsDoc = await _db
          .collection('users')
          .doc(_uid)
          .collection('goals')
          .doc('main')
          .get();

      if (goalsDoc.exists) {
        final data = goalsDoc.data()!;
        _caloriesGoal = (data['caloriesGoal'] as num?)?.toInt() ?? 2400;
        _proteinGoal = (data['proteinGoal'] as num?)?.toInt() ?? 180;
        _waterGoal = (data['waterGoal'] as num?)?.toInt() ?? 8;
      }
    } catch (e) {
      debugPrint('Error loading goals: $e');
    }
  }

  void _generateChallenges() {
    // Daily Challenges
    _dailyChallenges = [
      Challenge(
        id: 'daily_calories',
        title: 'Hit Calorie Goal',
        description: 'Reach your daily calorie target',
        icon: '🔥',
        targetValue: _caloriesGoal,
        currentValue: _todayCalories,
        points: 50,
        type: ChallengeType.daily,
      ),
      Challenge(
        id: 'daily_protein',
        title: 'Protein Power',
        description: 'Reach your protein goal',
        icon: '💪',
        targetValue: _proteinGoal,
        currentValue: _todayProtein,
        points: 50,
        type: ChallengeType.daily,
      ),
      Challenge(
        id: 'daily_workout',
        title: 'Workout Warrior',
        description: 'Complete at least 1 workout',
        icon: '🏋️',
        targetValue: 1,
        currentValue: _todayWorkouts,
        points: 100,
        type: ChallengeType.daily,
      ),
      Challenge(
        id: 'daily_water',
        title: 'Stay Hydrated',
        description: 'Drink ${_waterGoal} glasses of water',
        icon: '💧',
        targetValue: _waterGoal,
        currentValue: _todayWater,
        points: 30,
        type: ChallengeType.daily,
      ),
      Challenge(
        id: 'daily_log',
        title: 'Track Everything',
        description: 'Log calories, protein & water',
        icon: '📝',
        targetValue: 3,
        currentValue: (_todayCalories > 0 ? 1 : 0) +
            (_todayProtein > 0 ? 1 : 0) +
            (_todayWater > 0 ? 1 : 0),
        points: 25,
        type: ChallengeType.daily,
      ),
    ];

    // Weekly Challenges
    _weeklyChallenges = [
      Challenge(
        id: 'weekly_workouts',
        title: '5 Day Warrior',
        description: 'Complete 5 workouts this week',
        icon: '🔥',
        targetValue: 5,
        currentValue: _totalWorkouts.clamp(0, 5),
        points: 200,
        type: ChallengeType.weekly,
      ),
      Challenge(
        id: 'weekly_streak',
        title: 'Consistency King',
        description: 'Maintain a 7 day streak',
        icon: '👑',
        targetValue: 7,
        currentValue: _currentStreak.clamp(0, 7),
        points: 300,
        type: ChallengeType.weekly,
      ),
      Challenge(
        id: 'weekly_protein',
        title: 'Protein Champion',
        description: 'Hit protein goal 5 days',
        icon: '🥩',
        targetValue: 5,
        currentValue: 3, // TODO: Calculate from logs
        points: 250,
        type: ChallengeType.weekly,
      ),
    ];
  }

  void _checkAchievements() {
    final allAchievements = [
      // Workout Achievements
      Achievement(
        id: 'first_workout',
        title: 'First Step',
        description: 'Complete your first workout',
        icon: '🎯',
        requirement: 1,
        currentProgress: _totalWorkouts,
        category: AchievementCategory.workout,
        points: 50,
      ),
      Achievement(
        id: 'workout_10',
        title: 'Getting Strong',
        description: 'Complete 10 workouts',
        icon: '💪',
        requirement: 10,
        currentProgress: _totalWorkouts,
        category: AchievementCategory.workout,
        points: 100,
      ),
      Achievement(
        id: 'workout_50',
        title: 'Fitness Freak',
        description: 'Complete 50 workouts',
        icon: '🔥',
        requirement: 50,
        currentProgress: _totalWorkouts,
        category: AchievementCategory.workout,
        points: 300,
      ),
      Achievement(
        id: 'workout_100',
        title: 'Iron Man',
        description: 'Complete 100 workouts',
        icon: '🦾',
        requirement: 100,
        currentProgress: _totalWorkouts,
        category: AchievementCategory.workout,
        points: 500,
      ),

      // Streak Achievements
      Achievement(
        id: 'streak_3',
        title: 'On Fire',
        description: 'Maintain a 3 day streak',
        icon: '🔥',
        requirement: 3,
        currentProgress: _longestStreak,
        category: AchievementCategory.streak,
        points: 75,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Week Warrior',
        description: 'Maintain a 7 day streak',
        icon: '⚡',
        requirement: 7,
        currentProgress: _longestStreak,
        category: AchievementCategory.streak,
        points: 150,
      ),
      Achievement(
        id: 'streak_30',
        title: 'Unstoppable',
        description: 'Maintain a 30 day streak',
        icon: '👑',
        requirement: 30,
        currentProgress: _longestStreak,
        category: AchievementCategory.streak,
        points: 500,
      ),
      Achievement(
        id: 'streak_100',
        title: 'Legend',
        description: 'Maintain a 100 day streak',
        icon: '🏆',
        requirement: 100,
        currentProgress: _longestStreak,
        category: AchievementCategory.streak,
        points: 1000,
      ),

      // Nutrition Achievements
      Achievement(
        id: 'calories_10000',
        title: 'Fuel Master',
        description: 'Log 10,000 total calories',
        icon: '🍽️',
        requirement: 10000,
        currentProgress: _totalCaloriesLogged,
        category: AchievementCategory.nutrition,
        points: 100,
      ),
      Achievement(
        id: 'calories_100000',
        title: 'Nutrition Pro',
        description: 'Log 100,000 total calories',
        icon: '🥗',
        requirement: 100000,
        currentProgress: _totalCaloriesLogged,
        category: AchievementCategory.nutrition,
        points: 400,
      ),
      Achievement(
        id: 'protein_1000',
        title: 'Protein Lover',
        description: 'Log 1,000g protein',
        icon: '🥩',
        requirement: 1000,
        currentProgress: _totalProteinLogged,
        category: AchievementCategory.nutrition,
        points: 150,
      ),
      Achievement(
        id: 'protein_10000',
        title: 'Muscle Builder',
        description: 'Log 10,000g protein',
        icon: '💪',
        requirement: 10000,
        currentProgress: _totalProteinLogged,
        category: AchievementCategory.nutrition,
        points: 500,
      ),

      // Special Achievements
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Log breakfast before 8 AM',
        icon: '🌅',
        requirement: 1,
        currentProgress: 0, // TODO: Track this
        category: AchievementCategory.special,
        points: 50,
      ),
      Achievement(
        id: 'perfect_day',
        title: 'Perfect Day',
        description: 'Hit all daily goals in one day',
        icon: '⭐',
        requirement: 1,
        currentProgress: (_todayCalories >= _caloriesGoal &&
            _todayProtein >= _proteinGoal &&
            _todayWorkouts >= 1)
            ? 1
            : 0,
        category: AchievementCategory.special,
        points: 200,
      ),
    ];

    _unlockedAchievements = allAchievements
        .where((a) => a.currentProgress >= a.requirement)
        .toList();

    _lockedAchievements = allAchievements
        .where((a) => a.currentProgress < a.requirement)
        .toList();

    // Sort by progress percentage
    _lockedAchievements.sort((a, b) {
      final aProgress = a.currentProgress / a.requirement;
      final bProgress = b.currentProgress / b.requirement;
      return bProgress.compareTo(aProgress);
    });
  }

  void _calculateLevel() {
    // Calculate total points from achievements
    int points = 0;
    for (var achievement in _unlockedAchievements) {
      points += achievement.points;
    }
    _totalPoints = points;

    // Calculate level (every 500 points = 1 level)
    _level = (_totalPoints / 500).floor() + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitGenieTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('🎯 Challenges'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: FitGenieTheme.primary,
          labelColor: FitGenieTheme.primary,
          unselectedLabelColor: FitGenieTheme.muted,
          tabs: const [
            Tab(text: '🎯 Daily'),
            Tab(text: '📅 Weekly'),
            Tab(text: '🏆 Badges'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // User Stats Header
          _buildStatsHeader(),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDailyChallenges(),
                _buildWeeklyChallenges(),
                _buildAchievements(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📊 STATS HEADER
  // ==========================================
  Widget _buildStatsHeader() {
    final progressToNextLevel = (_totalPoints % 500) / 500;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FitGenieTheme.primary.withOpacity(0.2),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FitGenieTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Level Badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [FitGenieTheme.primary, Colors.purple],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: FitGenieTheme.primary.withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$_level',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $_level',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalPoints XP',
                      style: TextStyle(
                        color: FitGenieTheme.muted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressToNextLevel,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FitGenieTheme.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${500 - (_totalPoints % 500)} XP to Level ${_level + 1}',
                      style: TextStyle(
                        color: FitGenieTheme.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('🔥', '$_currentStreak', 'Streak'),
              _buildMiniStat('🏋️', '$_totalWorkouts', 'Workouts'),
              _buildMiniStat('🏆', '${_unlockedAchievements.length}', 'Badges'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: FitGenieTheme.muted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 🎯 DAILY CHALLENGES
  // ==========================================
  Widget _buildDailyChallenges() {
    final completed =
        _dailyChallenges.where((c) => c.currentValue >= c.targetValue).length;
    final total = _dailyChallenges.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Header
          FGCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$completed / $total',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 16,
                        color: FitGenieTheme.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completed / total,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completed == total ? Colors.green : FitGenieTheme.primary,
                    ),
                    minHeight: 10,
                  ),
                ),
                if (completed == total)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('🎉', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 8),
                        Text(
                          'All challenges completed!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Challenge Cards
          ..._dailyChallenges.map((challenge) => _buildChallengeCard(challenge)),
        ],
      ),
    );
  }

  // ==========================================
  // 📅 WEEKLY CHALLENGES
  // ==========================================
  Widget _buildWeeklyChallenges() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week info
          FGCard(
            child: Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This Week\'s Challenges',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Resets every Monday',
                      style: TextStyle(
                        color: FitGenieTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Challenge Cards
          ..._weeklyChallenges.map((challenge) => _buildChallengeCard(challenge)),
        ],
      ),
    );
  }

  // ==========================================
  // 🏆 ACHIEVEMENTS
  // ==========================================
  Widget _buildAchievements() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unlocked Section
          if (_unlockedAchievements.isNotEmpty) ...[
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Unlocked (${_unlockedAchievements.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _unlockedAchievements
                  .map((a) => _buildAchievementBadge(a, unlocked: true))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Locked Section
          if (_lockedAchievements.isNotEmpty) ...[
            Row(
              children: [
                const Text('🔒', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Locked (${_lockedAchievements.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._lockedAchievements
                .take(6) // Show only first 6
                .map((a) => _buildLockedAchievementCard(a)),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 🎯 CHALLENGE CARD
  // ==========================================
  Widget _buildChallengeCard(Challenge challenge) {
    final progress = (challenge.currentValue / challenge.targetValue).clamp(0.0, 1.0);
    final isCompleted = challenge.currentValue >= challenge.targetValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withOpacity(0.1)
            : FitGenieTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.2)
                      : FitGenieTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    challenge.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isCompleted ? Colors.green : Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withOpacity(0.2)
                                : Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${challenge.points} XP',
                            style: TextStyle(
                              color: isCompleted ? Colors.green : Colors.amber,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.description,
                      style: TextStyle(
                        color: FitGenieTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? Colors.green : FitGenieTheme.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${challenge.currentValue}/${challenge.targetValue}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.green : Colors.white,
                ),
              ),
              if (isCompleted)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🏆 ACHIEVEMENT BADGE
  // ==========================================
  Widget _buildAchievementBadge(Achievement achievement, {bool unlocked = false}) {
    return GestureDetector(
      onTap: () => _showAchievementDetails(achievement),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unlocked
              ? Colors.amber.withOpacity(0.1)
              : FitGenieTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? Colors.amber.withOpacity(0.5)
                : Colors.white.withOpacity(0.06),
            width: unlocked ? 2 : 1,
          ),
          boxShadow: unlocked
              ? [
            BoxShadow(
              color: Colors.amber.withOpacity(0.2),
              blurRadius: 8,
            ),
          ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              achievement.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🔒 LOCKED ACHIEVEMENT CARD
  // ==========================================
  Widget _buildLockedAchievementCard(Achievement achievement) {
    final progress = (achievement.currentProgress / achievement.requirement).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FitGenieTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: FitGenieTheme.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amber.withOpacity(0.7),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: FitGenieTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              const Icon(Icons.lock, color: Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(
                '+${achievement.points}',
                style: TextStyle(
                  color: FitGenieTheme.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📋 ACHIEVEMENT DETAILS DIALOG
  // ==========================================
  void _showAchievementDetails(Achievement achievement) {
    final isUnlocked = achievement.currentProgress >= achievement.requirement;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitGenieTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Colors.amber.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked ? Colors.amber : Colors.grey,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              style: TextStyle(color: FitGenieTheme.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Colors.green.withOpacity(0.2)
                    : Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isUnlocked ? '✅ Unlocked!' : '+${achievement.points} XP',
                style: TextStyle(
                  color: isUnlocked ? Colors.green : Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: 12),
              Text(
                'Progress: ${achievement.currentProgress}/${achievement.requirement}',
                style: TextStyle(color: FitGenieTheme.muted, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 📦 MODELS
// ==========================================

enum ChallengeType { daily, weekly }

class Challenge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int targetValue;
  final int currentValue;
  final int points;
  final ChallengeType type;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetValue,
    required this.currentValue,
    required this.points,
    required this.type,
  });
}

enum AchievementCategory { workout, streak, nutrition, special }

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requirement;
  final int currentProgress;
  final AchievementCategory category;
  final int points;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requirement,
    required this.currentProgress,
    required this.category,
    required this.points,
  });
}