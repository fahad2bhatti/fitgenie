// lib/screens/workout_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app/fitgenie_theme.dart';
import '../widgets/fg_card.dart';
import '../services/ai_service.dart';
import '../data/exercise_data.dart';
import '../data/workout_plans_data.dart';
import 'muscle_group_exercises_screen.dart';
import 'workout_plan_screen.dart';
import 'my_library_screen.dart';
import 'workout_detail_screen.dart';

// ============================================================
// 🏋️ MAIN WORKOUT SCREEN (HUB)
// ============================================================

class WorkoutScreen extends StatefulWidget {
  final String userId;

  const WorkoutScreen({super.key, required this.userId});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            const Text(
              'Workout',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose your training style 💪',
              style: TextStyle(color: FitGenieTheme.muted, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // ── 1. Quick Start (AI) ──
            _buildSectionLabel('⚡', 'Quick Start', 'AI powered workout'),
            const SizedBox(height: 10),
            _buildQuickStartCard(),
            const SizedBox(height: 28),

            // ── 2. Muscle Groups ──
            _buildSectionLabel('💪', 'Muscle Groups', 'Exercises with animated demos'),
            const SizedBox(height: 10),
            _buildMuscleGroupsGrid(),
            const SizedBox(height: 28),

            // ── 3. Workout Plans ──
            _buildSectionLabel('📋', 'Workout Plans', 'Push, Pull, Legs & more'),
            const SizedBox(height: 10),
            _buildWorkoutPlans(),
            const SizedBox(height: 28),

            // ── 4. Full Body ──
            _buildSectionLabel('🏆', 'Full Body Workout', 'All muscles in one session'),
            const SizedBox(height: 10),
            _buildFullBodyCard(),
            const SizedBox(height: 28),

            // ── 5. My Library ──
            _buildSectionLabel('📚', 'My Library', 'Your custom workouts'),
            const SizedBox(height: 10),
            _buildMyLibraryCard(),
            const SizedBox(height: 28),

            // ── 6. Recent Workouts ──
            _buildSectionLabel('🕐', 'Recent Workouts', 'Your training history'),
            const SizedBox(height: 10),
            _buildRecentWorkouts(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🏷️ SECTION LABEL
  // ============================================================
  Widget _buildSectionLabel(String emoji, String title, String subtitle) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: FitGenieTheme.muted)),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // 1️⃣ QUICK START (AI)
  // ============================================================
  Widget _buildQuickStartCard() {
    final todayInfo = WorkoutPlansData.getTodayInfo();
    final isRestDay = todayInfo['tag'] == 'rest';

    return GestureDetector(
      onTap: isRestDay
          ? null
          : () {
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
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isRestDay
                ? [Colors.grey.shade800, Colors.grey.shade700]
                : [FitGenieTheme.primary, FitGenieTheme.primary.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isRestDay
              ? []
              : [
            BoxShadow(
              color: FitGenieTheme.primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                todayInfo['emoji'] ?? '🏋️',
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayInfo['day'] ?? 'Today',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRestDay ? 'Rest Day 😴' : todayInfo['type'] ?? 'Workout',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRestDay
                        ? 'Recovery & stretch karo aaj'
                        : 'AI will generate your workout plan',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                ],
              ),
            ),
            if (!isRestDay)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 2️⃣ MUSCLE GROUPS GRID
  // ============================================================
  Widget _buildMuscleGroupsGrid() {
    final groups = [
      {'name': 'Chest', 'emoji': '🏋️', 'color': Colors.red, 'count': ExerciseData.chest.length},
      {'name': 'Back', 'emoji': '🔙', 'color': Colors.blue, 'count': ExerciseData.back.length},
      {'name': 'Legs', 'emoji': '🦵', 'color': Colors.green, 'count': ExerciseData.legs.length},
      {'name': 'Arms', 'emoji': '💪', 'color': Colors.orange, 'count': ExerciseData.biceps.length + ExerciseData.triceps.length},
      {'name': 'Shoulders', 'emoji': '🎯', 'color': Colors.purple, 'count': ExerciseData.shoulders.length},
      {'name': 'Core', 'emoji': '🔥', 'color': Colors.teal, 'count': ExerciseData.core.length},
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isSmallScreen ? 1.05 : 0.82,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _buildMuscleGroupCard(
          name: group['name'] as String,
          emoji: group['emoji'] as String,
          color: group['color'] as Color,
          count: group['count'] as int,
        );
      },
    );
  }

  Widget _buildMuscleGroupCard({
    required String name,
    required String emoji,
    required Color color,
    required int count,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MuscleGroupExercisesScreen(
              bodyPart: name,
              emoji: emoji,
              color: color,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FitGenieTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            FittedBox(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count ex',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 3️⃣ WORKOUT PLANS
  // ============================================================
  Widget _buildWorkoutPlans() {
    final plans = [
      WorkoutPlansData.pushDay,
      WorkoutPlansData.pullDay,
      WorkoutPlansData.legDay,
      WorkoutPlansData.upperBody,
      WorkoutPlansData.lowerBody,
      WorkoutPlansData.armsDay,
      WorkoutPlansData.cardioCore,
    ];

    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return _buildPlanCard(plan);
        },
      ),
    );
  }

  Widget _buildPlanCard(WorkoutPlan plan) {
    final color = Color(plan.color);

    return GestureDetector(
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
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FitGenieTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(plan.emoji, style: const TextStyle(fontSize: 26)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '~${plan.estimatedMinutes} min',
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              plan.subtitle,
              style: TextStyle(fontSize: 11, color: FitGenieTheme.muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.fitness_center, size: 12, color: FitGenieTheme.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${plan.totalExercises} exercises',
                    style: TextStyle(fontSize: 11, color: FitGenieTheme.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 4️⃣ FULL BODY WORKOUT
  // ============================================================
  Widget _buildFullBodyCard() {
    final fullBodyPlan = WorkoutPlansData.fullBody;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutPlanScreen(
              plan: fullBodyPlan,
              userId: widget.userId,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF6F00).withOpacity(0.3),
              const Color(0xFFFF6F00).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFF6F00).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6F00).withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('🏆', style: TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Full Body Workout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${fullBodyPlan.totalExercises} exercises • ~${fullBodyPlan.estimatedMinutes} min',
                    style: TextStyle(color: FitGenieTheme.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All muscles covered in one session',
                    style: TextStyle(color: FitGenieTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFFFF6F00), size: 18),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 5️⃣ MY LIBRARY
  // ============================================================
  Widget _buildMyLibraryCard() {
    return Column(
      children: [
        // Saved workouts from Firestore
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

            return Column(
              children: [
                if (hasData)
                  ...snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'My Workout';
                    final exerciseCount = (data['exercises'] as List?)?.length ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: FGCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyLibraryScreen(
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: FitGenieTheme.teal.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.bookmark, color: FitGenieTheme.teal, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(
                                    '$exerciseCount exercises',
                                    style: TextStyle(color: FitGenieTheme.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 14, color: FitGenieTheme.muted),
                          ],
                        ),
                      ),
                    );
                  }),

                if (!hasData)
                  FGCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Icon(Icons.library_add, size: 36, color: FitGenieTheme.muted),
                            const SizedBox(height: 8),
                            Text(
                              'No custom workouts yet',
                              style: TextStyle(color: FitGenieTheme.muted, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Create your own routine! 🎯',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),

        // Create + View All buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
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
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: FitGenieTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FitGenieTheme.primary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: FitGenieTheme.primary, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Create New',
                        style: TextStyle(
                          color: FitGenieTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyLibraryScreen(userId: widget.userId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: FitGenieTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books, color: FitGenieTheme.muted, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'View All',
                        style: TextStyle(
                          color: FitGenieTheme.muted,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // 6️⃣ RECENT WORKOUTS
  // ============================================================
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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(Icons.fitness_center, size: 40, color: FitGenieTheme.muted),
                    const SizedBox(height: 8),
                    Text('No workouts yet', style: TextStyle(color: FitGenieTheme.muted)),
                    const SizedBox(height: 4),
                    const Text('Start your first workout above! 💪'),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'] ?? 'Workout';
            final sets = data['totalSets'] ?? 0;
            final duration = data['duration'] ?? 0;
            final status = data['status'] ?? 'completed';
            final startedAt = data['startedAt'] as Timestamp?;
            // ignore: unused_local_variable
            final workoutSets = data['sets'] as List<dynamic>? ?? [];

            String dateStr = 'Recently';
            if (startedAt != null) {
              final date = startedAt.toDate();
              final diff = DateTime.now().difference(date);
              if (diff.inDays == 0) {
                dateStr = 'Today';
              } else if (diff.inDays == 1) {
                dateStr = 'Yesterday';
              } else if (diff.inDays < 7) {
                dateStr = '${diff.inDays} days ago';
              } else {
                dateStr = '${date.day}/${date.month}/${date.year}';
              }
            }

            // Get emoji based on type
            String emoji = '🏋️';
            if (type.toLowerCase().contains('chest')) emoji = '🏋️';
            if (type.toLowerCase().contains('back')) emoji = '🔙';
            if (type.toLowerCase().contains('leg')) emoji = '🦵';
            if (type.toLowerCase().contains('shoulder')) emoji = '🎯';
            if (type.toLowerCase().contains('arm')) emoji = '💪';
            if (type.toLowerCase().contains('core')) emoji = '🔥';
            if (type.toLowerCase().contains('push')) emoji = '🔴';
            if (type.toLowerCase().contains('pull')) emoji = '🔵';
            if (type.toLowerCase().contains('full')) emoji = '🏆';
            if (type.toLowerCase().contains('cardio')) emoji = '🏃';

            return GestureDetector(
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
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: FGCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: FitGenieTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildMiniStat(Icons.repeat, '$sets sets'),
                                if (duration > 0) ...[
                                  const SizedBox(width: 12),
                                  _buildMiniStat(Icons.timer_outlined, '$duration min'),
                                ],
                                const SizedBox(width: 12),
                                _buildMiniStat(Icons.calendar_today, dateStr),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Icon(
                            status == 'completed' ? Icons.check_circle : Icons.access_time,
                            color: status == 'completed' ? Colors.green : Colors.orange,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Details →',
                            style: TextStyle(
                              fontSize: 10,
                              color: FitGenieTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: FitGenieTheme.muted),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: FitGenieTheme.muted),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ============================================================
// 🏃 ACTIVE WORKOUT SCREEN (Existing — Updated)
// ============================================================

class ActiveWorkoutScreen extends StatefulWidget {
  final String userId;
  final String workoutType;
  final String workoutTitle;

  const ActiveWorkoutScreen({
    super.key,
    required this.userId,
    required this.workoutType,
    required this.workoutTitle,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final AIService _aiService = AIService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _workoutPlan = '';
  String? _sessionId;
  final List<Map<String, dynamic>> _loggedSets = [];
  DateTime? _startTime;
  bool _isWorkoutStarted = false;

  late List<Exercise> _availableExercises;

  @override
  void initState() {
    super.initState();
    _availableExercises = ExerciseData.getByBodyPart(widget.workoutType);
    _loadWorkoutPlan();
  }

  Future<void> _loadWorkoutPlan() async {
    setState(() => _isLoading = true);
    try {
      final plan = await _aiService.generateWorkout(
        uid: widget.userId,
        workoutType: widget.workoutType,
      );
      if (mounted) {
        setState(() {
          _workoutPlan = plan;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _workoutPlan = 'Could not generate plan. Start manually! 💪';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startWorkout() async {
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

    setState(() {
      _sessionId = docRef.id;
      _startTime = DateTime.now();
      _isWorkoutStarted = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout started! 🔥'), backgroundColor: Colors.green),
      );
    }
  }

  void _showLogSetDialog() {
    Exercise? selectedExercise;
    int selectedSets = 3;
    int selectedReps = 12;
    final weightController = TextEditingController(text: '20');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FitGenieTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🏋️ Log Set', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),

                // Exercise Selector
                const Text('Select Exercise', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: FitGenieTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FitGenieTheme.primary.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Exercise>(
                      isExpanded: true,
                      value: selectedExercise,
                      hint: Text('Choose exercise...', style: TextStyle(color: FitGenieTheme.muted)),
                      dropdownColor: FitGenieTheme.cardDark,
                      items: _availableExercises.map((exercise) {
                        return DropdownMenuItem(value: exercise, child: Text(exercise.name, style: const TextStyle(fontSize: 14)));
                      }).toList(),
                      onChanged: (value) => setModalState(() => selectedExercise = value),
                    ),
                  ),
                ),

                // GIF Preview
                if (selectedExercise != null && selectedExercise!.hasGif) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FitGenieTheme.primary.withOpacity(0.2)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: selectedExercise!.gifUrl,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Container(
                          color: FitGenieTheme.background,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (c, u, e) => Container(
                          color: FitGenieTheme.background,
                          child: const Center(child: Icon(Icons.fitness_center, color: Colors.white24)),
                        ),
                      ),
                    ),
                  ),
                ],

                if (selectedExercise != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: selectedExercise!.musclesWorked.map((m) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                      child: Text('💪 $m', style: const TextStyle(fontSize: 11, color: Colors.green)),
                    )).toList(),
                  ),
                ],

                const SizedBox(height: 20),

                // Sets
                const Text('Sets', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: ExerciseData.setsOptions.map((s) {
                    final sel = selectedSets == s;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedSets = s),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: sel ? FitGenieTheme.primary : FitGenieTheme.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? FitGenieTheme.primary : Colors.white24),
                          ),
                          child: Center(child: Text('$s', style: TextStyle(fontWeight: FontWeight.bold, color: sel ? Colors.white : FitGenieTheme.muted))),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Reps
                const Text('Reps', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExerciseData.repsOptions.map((r) {
                    final sel = selectedReps == r;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedReps = r),
                      child: Container(
                        width: 50,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? FitGenieTheme.teal : FitGenieTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? FitGenieTheme.teal : Colors.white24),
                        ),
                        child: Center(child: Text('$r', style: TextStyle(fontWeight: FontWeight.bold, color: sel ? Colors.white : FitGenieTheme.muted))),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Weight
                const Text('Weight (kg)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        final c = double.tryParse(weightController.text) ?? 0;
                        if (c > 0) weightController.text = (c - 2.5).clamp(0, 500).toString();
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: FitGenieTheme.hot.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.remove, color: FitGenieTheme.hot),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          filled: true, fillColor: FitGenieTheme.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          suffixText: 'kg', suffixStyle: TextStyle(color: FitGenieTheme.muted),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final c = double.tryParse(weightController.text) ?? 0;
                        weightController.text = (c + 2.5).toString();
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.add, color: Colors.green),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Save
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedExercise == null ? null : () async {
                      for (int i = 0; i < selectedSets; i++) {
                        await _logSet(selectedExercise!.name, double.tryParse(weightController.text) ?? 0, selectedReps);
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$selectedSets sets logged! 💪'), duration: const Duration(seconds: 1)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedExercise == null ? Colors.grey : FitGenieTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      selectedExercise == null ? 'Select Exercise First' : 'Save $selectedSets Sets ✓',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logSet(String exercise, double weight, int reps) async {
    final setData = {'exercise': exercise, 'weight': weight, 'reps': reps, 'timestamp': DateTime.now().toIso8601String()};
    setState(() => _loggedSets.add(setData));
    if (_sessionId != null) {
      await _firestore.collection('users').doc(widget.userId).collection('workouts').doc(_sessionId).update({
        'sets': FieldValue.arrayUnion([setData]),
        'totalSets': _loggedSets.length,
      });
    }
  }

  Future<void> _finishWorkout() async {
    if (_sessionId == null) return;
    final duration = _startTime != null ? DateTime.now().difference(_startTime!).inMinutes : 0;
    await _firestore.collection('users').doc(widget.userId).collection('workouts').doc(_sessionId).update({
      'endedAt': FieldValue.serverTimestamp(),
      'status': 'completed',
      'duration': duration,
      'totalSets': _loggedSets.length,
    });
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: FitGenieTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('🎉 Workout Complete!', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Great job bhai!', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _completionStat('💪', '${_loggedSets.length}', 'Sets'),
                  _completionStat('⏱️', '$duration', 'Minutes'),
                ],
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(backgroundColor: FitGenieTheme.primary),
                child: const Text('Done! 💪', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _completionStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FitGenieTheme.primary)),
        Text(label, style: TextStyle(color: FitGenieTheme.muted, fontSize: 12)),
      ],
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitGenieTheme.cardDark,
        title: const Text('Exit Workout?'),
        content: const Text('Save or discard your progress?'),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _finishWorkout(); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Save & Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitGenieTheme.background,
      appBar: AppBar(
        backgroundColor: FitGenieTheme.cardDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (_isWorkoutStarted && _loggedSets.isNotEmpty) {
              _showExitConfirmation();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text('${widget.workoutTitle} Workout', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_isWorkoutStarted)
            TextButton(
              onPressed: _finishWorkout,
              child: const Text('FINISH', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: FitGenieTheme.primary),
            const SizedBox(height: 20),
            const Text('AI workout generate kar raha hai... 🤖'),
            const SizedBox(height: 8),
            Text('Thoda wait karo', style: TextStyle(color: FitGenieTheme.muted)),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Plan
            FGCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.smart_toy, color: Colors.purple, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text('AI Suggested Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _loadWorkoutPlan),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: FitGenieTheme.background, borderRadius: BorderRadius.circular(12)),
                    child: Text(_workoutPlan, style: const TextStyle(height: 1.6)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (!_isWorkoutStarted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startWorkout,
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text('Start Workout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

            if (_isWorkoutStarted) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Logged Sets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        StreamBuilder(
                          stream: Stream.periodic(const Duration(seconds: 1)),
                          builder: (c, s) {
                            final d = _startTime != null ? DateTime.now().difference(_startTime!).inMinutes : 0;
                            return Text('$d min', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_loggedSets.isEmpty)
                FGCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Icon(Icons.add_circle_outline, size: 40, color: FitGenieTheme.muted),
                          const SizedBox(height: 8),
                          Text('No sets logged yet', style: TextStyle(color: FitGenieTheme.muted)),
                          const SizedBox(height: 4),
                          const Text('Tap + to log a set 💪'),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...List.generate(_loggedSets.length, (i) {
                  final s = _loggedSets[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: FGCard(
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: FitGenieTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: Center(child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: FitGenieTheme.primary))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['exercise'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('${s['weight']} kg × ${s['reps']} reps', style: TextStyle(color: FitGenieTheme.muted, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle, color: Colors.green, size: 22),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showLogSetDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Log Set', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FitGenieTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _finishWorkout,
                  icon: const Icon(Icons.check, color: Colors.green),
                  label: const Text('Finish Workout', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}