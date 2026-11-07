// lib/screens/workout_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ads_service.dart';
import '../app/fitgenie_theme.dart';
import '../widgets/fg_card.dart';
import '../widgets/app_snackbar.dart';
import '../core/app_strings.dart';
import '../services/ai_service.dart';
import '../data/exercise_data.dart';
import '../data/workout_plans_data.dart';
import 'muscle_group_exercises_screen.dart';
import 'workout_plan_screen.dart';
import 'my_library_screen.dart';
import 'workout_detail_screen.dart';
import '../widgets/active_set_sheet.dart';
import '../widgets/medical_disclaimer.dart';

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
  }

  // ============================================================
  // 🏷️ SECTION LABEL
  // ============================================================
  Widget _buildSectionLabel(String emoji, String title, String subtitle) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ============================================================
  // 1️⃣ QUICK START (AI)
  // ============================================================
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
              plan: plan,
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
                style:
                    const TextStyle(color: FitGenieTheme.muted, fontSize: 13),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: FitGenieTheme.onPrimary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
  }

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
                          color: isDone
                              ? FitGenieTheme.primary
                              : Colors.transparent,
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
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w500,
                          color: isToday
                              ? FitGenieTheme.text
                              : FitGenieTheme.muted,
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
  }

  // ============================================================
  // 2️⃣ MUSCLE GROUPS GRID
  // ============================================================
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
  }

  // l10n-r3a: display name only; 'name' stays English because it is passed on as the body-part key
  String _muscleLabel(String name) {
    const keys = <String, String>{
      'Chest': 'muscle_chest',
      'Back': 'muscle_back',
      'Legs': 'muscle_legs',
      'Arms': 'muscle_arms',
      'Shoulders': 'muscle_shoulders',
      'Core': 'muscle_core',
    };
    final key = keys[name];
    return key == null ? name : AppStrings.get(key);
  }

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
                      _muscleLabel(name).toUpperCase(),
                      style: t.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${exercises.length} ${AppStrings.get('label_exercises').toLowerCase()}',
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
  }

  // ============================================================
  // 3️⃣ WORKOUT PLANS
  // ============================================================
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
  }

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
                    '~${plan.estimatedMinutes} ${AppStrings.get('label_min').toUpperCase()}',
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
                  '${plan.totalExercises} ${AppStrings.get('label_exercises').toLowerCase()}',
                  style:
                      const TextStyle(color: FitGenieTheme.muted, fontSize: 11),
                ),
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

  // ============================================================
  // 5️⃣ MY LIBRARY
  // ============================================================
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
                                '$exerciseCount ${AppStrings.get('label_exercises').toLowerCase()}',
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
            final type =
                data['type'] ?? AppStrings.get('workout_fallback_type');
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
                              _buildMiniStat(Icons.repeat,
                                  '$sets ${AppStrings.get('workout_detail_sets')}'),
                              if (duration > 0)
                                _buildMiniStat(Icons.timer_outlined,
                                    '$duration ${AppStrings.get('label_min')}'),
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
// 🏃 ACTIVE WORKOUT SCREEN
// ============================================================

class ActiveWorkoutScreen extends StatefulWidget {
  final String userId;
  final String workoutType;
  final String workoutTitle;

  /// Structured plan (exercises, sets, reps, rest). When null, a short list
  /// is built from [workoutType] so older callers keep working.
  final WorkoutPlan? plan;

  const ActiveWorkoutScreen({
    super.key,
    required this.userId,
    required this.workoutType,
    required this.workoutTitle,
    this.plan,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  // active-workout-v2
  final AIService _aiService = AIService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final List<_WorkoutItem> _items;
  final List<Map<String, dynamic>> _loggedSets = [];
  final Map<String, double> _lastWeights = {};
  final ValueNotifier<int> _elapsed = ValueNotifier<int>(0);

  Timer? _ticker;
  String? _sessionId;
  DateTime? _startTime;
  bool _started = false;
  bool _starting = false;
  bool _finishing = false;

  String? _coachTip;
  bool _tipLoading = true;
  bool _tipExpanded = false;

  @override
  void initState() {
    super.initState();
    showWorkoutInjuryWarningIfNeeded(context);
    _items = _buildItems();
    AdsService.instance.loadInterstitialAd();
    _loadLastWeights();
    _loadCoachTip();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _elapsed.dispose();
    super.dispose();
  }

  // ============================================================
  // 📋 ITEMS
  // ============================================================

  double _defaultWeight(Exercise? ex) {
    final eq = (ex?.equipment ?? '').toLowerCase();
    const noLoad = ['bodyweight', 'pull-up', 'dip', 'treadmill', 'bike'];
    if (noLoad.any((k) => eq.contains(k))) return 0;
    return 20;
  }

  double _weightFor(Exercise? ex) {
    if (ex != null && _lastWeights.containsKey(ex.name)) {
      return _lastWeights[ex.name]!;
    }
    return _defaultWeight(ex);
  }

  List<_WorkoutItem> _buildItems() {
    final all = ExerciseData.getAllExercises();

    Exercise? byId(String id) {
      for (final e in all) {
        if (e.id == id) return e;
      }
      return null;
    }

    final plan = widget.plan;
    if (plan != null && plan.exercises.isNotEmpty) {
      return plan.exercises.map((pe) {
        final ex = byId(pe.exerciseId);
        return _WorkoutItem(
          name: ex?.name ?? pe.exerciseId,
          exercise: ex,
          sets: pe.sets,
          reps: pe.reps,
          restSeconds: pe.restSeconds,
          notes: pe.notes,
          weight: _weightFor(ex),
        );
      }).toList();
    }

    // Fallback: no structured plan -> first few exercises of the body part
    return ExerciseData.getByBodyPart(widget.workoutType)
        .take(5)
        .map((ex) => _WorkoutItem(
              name: ex.name,
              exercise: ex,
              sets: 3,
              reps: '12',
              restSeconds: 60,
              weight: _weightFor(ex),
            ))
        .toList();
  }

  int get _currentIndex => _items.indexWhere((e) => !e.isDone);

  String _fmtWeight(double w) =>
      w % 1 == 0 ? '${w.toInt()}' : w.toStringAsFixed(1);

  // ============================================================
  // 📡 DATA
  // ============================================================

  Future<void> _loadLastWeights() async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('workouts')
          .orderBy('startedAt', descending: true)
          .limit(10)
          .get();

      for (final doc in snap.docs) {
        if (doc.id == _sessionId) continue;
        final sets = (doc.data()['sets'] as List?) ?? const [];
        for (final s in sets.reversed) {
          if (s is! Map) continue;
          final name = s['exercise'];
          final w = s['weight'];
          if (name is String && w is num && !_lastWeights.containsKey(name)) {
            _lastWeights[name] = w.toDouble();
          }
        }
      }

      if (!mounted) return;
      setState(() {
        for (final item in _items) {
          final w = _lastWeights[item.name];
          if (w != null && item.doneSets == 0) item.weight = w;
        }
      });
    } catch (e) {
      debugPrint('Last weights error: $e');
    }
  }

  Future<void> _loadCoachTip() async {
    // workout-fixes-v1
    // Din mein sirf ek baar AI: pehle memory, phir Firestore, phir (sirf zaroorat par) AI.
    final today = DateTime.now();
    final dayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final safeTitle = widget.workoutTitle
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final cacheKey = '${widget.userId}|$dayKey|$safeTitle';

    final cached = _coachTipCache[cacheKey];
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _coachTip = cached;
        _tipLoading = false;
      });
      return;
    }

    final ref = _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('coachTips')
        .doc('${dayKey}_$safeTitle');

    // Aaj ka tip Firestore mein pehle se hai? (rules ya net ka masla ho to chhod do)
    try {
      final snap = await ref.get().timeout(const Duration(seconds: 4));
      final saved = snap.data()?['tip'];
      if (saved is String && saved.trim().isNotEmpty) {
        _coachTipCache[cacheKey] = saved;
        if (!mounted) return;
        setState(() {
          _coachTip = saved;
          _tipLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Coach tip read skipped: $e');
    }

    // Nahi mila: AI se sirf ek baar maango
    try {
      final names = _items.map((e) => e.name).join(', ');
      final tip = (await _aiService.chat(
        uid: widget.userId,
        userMessage:
            'Aaj ka workout: ${widget.workoutTitle} ($names). Sirf 2 chhoti lines mein ek practical coach tip do (warm-up ya form ke baare mein). Koi list ya emoji nahi.',
      ))
          .trim();

      if (tip.isNotEmpty) {
        _coachTipCache[cacheKey] = tip;
        unawaited(
          ref.set({
            'tip': tip,
            'createdAt': FieldValue.serverTimestamp(),
          }).catchError((Object e) {
            debugPrint('Coach tip save skipped: $e');
          }),
        );
      }
      if (!mounted) return;
      setState(() {
        _coachTip = tip;
        _tipLoading = false;
      });
    } catch (e) {
      debugPrint('Coach tip error: $e');
      if (!mounted) return;
      setState(() => _tipLoading = false);
    }
  }

  // ============================================================
  // ▶️ WORKOUT FLOW
  // ============================================================

  Future<void> _startWorkout() async {
    if (_started || _starting) return;
    setState(() => _starting = true);

    try {
      // doc() local ID foran deta hai; set() ka ack (net) ka intezaar nahi
      final docRef = _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('workouts')
          .doc();

      unawaited(
        docRef.set({
          'type': widget.workoutTitle,
          'startedAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'sets': [],
          'totalSets': 0,
        }).catchError((Object e) {
          debugPrint('Start workout write error: $e');
        }),
      );

      if (!mounted) return;

      _startTime = DateTime.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        final st = _startTime;
        if (st != null) {
          _elapsed.value = DateTime.now().difference(st).inSeconds;
        }
      });

      setState(() {
        _sessionId = docRef.id;
        _started = true;
        _starting = false;
      });
    } catch (e) {
      debugPrint('Start workout error: $e');
      if (!mounted) return;
      setState(() => _starting = false);
      AppSnackbar.showError(context, '$e');
    }
  }

  Future<void> _openExercise(int index) async {
    final item = _items[index];
    if (item.isDone) return;

    // Sirf current exercise khulti hai, baqi locked
    if (index != _currentIndex) {
      AppSnackbar.showInfo(context, 'Pehle upar wali exercise khatam karo');
      return;
    }

    if (!_started) {
      await _startWorkout();
      if (!_started || !mounted) return;
    }
    _showSetSheet(item);
  }

  void _showSetSheet(_WorkoutItem item) {
    if (!mounted) return;

    // Is set ki shuruaat yaad rakho: sheet band karke dobara kholo to stopwatch resume
    item.setStartedAt ??= DateTime.now();
    final setNo = item.doneSets + 1;

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ActiveSetSheet(
        exercise: item.exercise,
        exerciseNameFallback: item.name,
        initialWeight: item.weight,
        initialReps: item.reps,
        setLabel: AppStrings.get('workout_set_label', params: {
          'current': '$setNo',
          'total': '${item.sets}',
        }),
        restSeconds: item.restSeconds, // REST_PARAM
        initialElapsedSeconds: item.setElapsedSeconds, // ELAPSED_PARAM
        onSetLogged: (weight, reps, durationSeconds, toFailure) async {
          await _logSet(item, weight, reps, durationSeconds);
        },
      ),
    ).then((completed) {
      if (!mounted) return;
      if (completed == true) {
        if (!item.isDone) {
          // Agla set
          _showSetSheet(item);
        } else {
          // Exercise khatam: agli exercise khud khul jaye
          final next = _currentIndex;
          if (next != -1) _showSetSheet(_items[next]);
        }
      }
    });
  }

  Future<void> _logSet(
    _WorkoutItem item,
    double weight,
    String reps,
    int durationSeconds,
  ) async {
    // Timed exercises (e.g. "60 sec") are stored as 1 rep + durationSeconds.
    final repsNum = item.isTimed
        ? 1
        : (int.tryParse(reps.replaceAll(RegExp(r'[^0-9]'), '')) ?? 12);

    final setData = {
      'exercise': item.name,
      'weight': weight,
      'reps': repsNum,
      'durationSeconds': durationSeconds,
      'timestamp': DateTime.now().toIso8601String(),
    };

    item.weight = weight;
    item.doneSets++;
    item.setStartedAt = null; // agla set naye stopwatch se
    if (mounted) setState(() => _loggedSets.add(setData));

    final id = _sessionId;
    if (id != null) {
      // Net kamzor/band ho tab bhi set screen na atke: write queue ho jata hai
      unawaited(
        _firestore
            .collection('users')
            .doc(widget.userId)
            .collection('workouts')
            .doc(id)
            .update({
          'sets': FieldValue.arrayUnion([setData]),
          'totalSets': _loggedSets.length,
        }).catchError((Object e) {
          debugPrint('Log set write error: $e');
        }),
      );
    }
  }

  void _showAddExerciseSheet() {
    var pool = ExerciseData.getByBodyPart(widget.workoutType);
    if (pool.isEmpty) pool = ExerciseData.getAllExercises();
    final used = _items.map((e) => e.exercise?.id).toSet();
    final options = pool.where((e) => !used.contains(e.id)).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  AppStrings.get('workout_choose_exercise'),
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final ex = options[i];
                    return ListTile(
                      title: Text(
                        ex.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        ex.equipment,
                        style: const TextStyle(
                            color: FitGenieTheme.muted, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _addExtra(ex);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addExtra(Exercise ex) {
    final item = _WorkoutItem(
      name: ex.name,
      exercise: ex,
      sets: 3,
      reps: '12',
      restSeconds: 60,
      weight: _weightFor(ex),
    );
    setState(() => _items.add(item));

    if (_currentIndex == _items.length - 1) {
      // Baqi sab ho chuki: seedha khol do
      _openExercise(_items.length - 1);
    } else {
      AppSnackbar.showInfo(context, '${ex.name} list mein jud gayi');
    }
  }

  // ============================================================
  // 🏁 FINISH / EXIT
  // ============================================================

  Future<void> _discardSession() async {
    _ticker?.cancel();
    final id = _sessionId;
    if (id == null) return;
    unawaited(
      _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('workouts')
          .doc(id)
          .delete()
          .catchError((Object e) {
        debugPrint('Discard session error: $e');
      }),
    );
  }

  Future<void> _handleBack() async {
    if (!_started) {
      Navigator.pop(context);
      return;
    }
    if (_loggedSets.isEmpty) {
      await _discardSession();
      if (mounted) Navigator.pop(context);
      return;
    }
    _showExitConfirmation();
  }

  Future<void> _finishWorkout() async {
    final id = _sessionId;
    if (id == null || _finishing) return;

    // Nothing logged -> nothing to save
    if (_loggedSets.isEmpty) {
      await _discardSession();
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _finishing = true);
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inMinutes
        : 0;

    // Server ke ack ka intezaar nahi: offline mein bhi screen aage badhe
    unawaited(
      _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('workouts')
          .doc(id)
          .update({
        'endedAt': FieldValue.serverTimestamp(),
        'status': 'completed',
        'duration': duration,
        'totalSets': _loggedSets.length,
      }).catchError((Object e) {
        debugPrint('Finish workout write error: $e');
      }),
    );

    _ticker?.cancel();
    if (!mounted) return;
    _showCompleteDialog(duration);
  }

  void _showCompleteDialog(int duration) {
    final t = Theme.of(context).textTheme;

    Widget stat(String value, String label) => Column(
          children: [
            Text(value,
                style: t.displaySmall?.copyWith(color: FitGenieTheme.primary)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: t.labelSmall),
          ],
        );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          AppStrings.get('workout_complete'),
          textAlign: TextAlign.center,
          style: t.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.get('workout_great_job'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: FitGenieTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                stat('${_loggedSets.length}',
                    AppStrings.get('workout_stat_sets')),
                stat('$duration', AppStrings.get('workout_stat_minutes')),
              ],
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                // Screen band karne ka raasta ek hi baar chale (ad ka callback ya fallback)
                var exited = false;
                void exitScreen() {
                  if (exited || !mounted) return;
                  exited = true;
                  Navigator.pop(context);
                }

                try {
                  AdsService.instance
                      .showInterstitialAd(onDismissed: exitScreen);
                } catch (e) {
                  debugPrint('Interstitial error: $e');
                  exitScreen();
                }
                // Ad load na hua ho ya callback na aaye to bhi screen na atke
                Future.delayed(const Duration(seconds: 6), exitScreen);
              },
              child: Text(AppStrings.get('done')),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.get('workout_exit_confirm')),
        content: Text(AppStrings.get('workout_exit_sub')),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _discardSession();
              if (mounted) Navigator.pop(context);
            },
            child: Text(
              AppStrings.get('workout_discard'),
              style: const TextStyle(color: FitGenieTheme.error),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _finishWorkout();
            },
            style: FilledButton.styleFrom(minimumSize: const Size(96, 46)),
            child: Text(AppStrings.get('workout_save_exit')),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🧱 BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_started,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: FitGenieTheme.bg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: _handleBack,
          ),
          title: Text(
            widget.workoutTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (_started)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: _buildElapsedChip()),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            FitGenieTheme.screenPadding,
            4,
            FitGenieTheme.screenPadding,
            24,
          ),
          children: [
            _buildSummary(),
            _buildCoachTip(),
            const SizedBox(height: 22),
            _sectionLabel('Exercises'),
            const SizedBox(height: 10),
            ...List.generate(_items.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildExerciseTile(i),
              );
            }),
            const SizedBox(height: 2),
            _buildAddExercise(),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
    );
  }

  Widget _buildElapsedChip() {
    return ValueListenableBuilder<int>(
      valueListenable: _elapsed,
      builder: (_, secs, __) {
        final m = (secs ~/ 60).toString().padLeft(2, '0');
        final s = (secs % 60).toString().padLeft(2, '0');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FitGenieTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined,
                  size: 14, color: FitGenieTheme.primary),
              const SizedBox(width: 6),
              Text(
                '$m:$s',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummary() {
    final t = Theme.of(context).textTheme;
    final totalSets = _items.fold<int>(0, (sum, e) => sum + e.sets);
    final doneSets = _items.fold<int>(
        0, (sum, e) => sum + (e.doneSets > e.sets ? e.sets : e.doneSets));
    final doneEx = _items.where((e) => e.doneSets >= e.sets).length;
    final minutes = widget.plan?.estimatedMinutes;
    final progress = totalSets == 0 ? 0.0 : doneSets / totalSets;

    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$doneEx',
                  style:
                      t.displaySmall?.copyWith(color: FitGenieTheme.primary)),
              Text(' / ${_items.length}',
                  style: t.headlineSmall?.copyWith(color: FitGenieTheme.muted)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('EXERCISES', style: t.labelSmall),
              ),
              const Spacer(),
              if (minutes != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: FitGenieTheme.border),
                  ),
                  child: Text(
                    '~$minutes MIN',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: FitGenieTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: FitGenieTheme.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(FitGenieTheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$doneSets / $totalSets sets',
            style: const TextStyle(color: FitGenieTheme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachTip() {
    // coach-tip-v2
    final tip = _coachTip ?? '';
    if (!_tipLoading && tip.isEmpty) return const SizedBox.shrink();

    final isLong = tip.length > 120;

    Widget bar(double? width) => Container(
          width: width,
          height: 10,
          decoration: BoxDecoration(
            color: FitGenieTheme.border,
            borderRadius: BorderRadius.circular(5),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: FGCard(
        padding: const EdgeInsets.all(16),
        onTap: (!_tipLoading && isLong)
            ? () => setState(() => _tipExpanded = !_tipExpanded)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'COACH TIP',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                if (!_tipLoading && isLong)
                  Text(
                    _tipExpanded ? 'LESS' : 'MORE',
                    style: const TextStyle(
                      color: FitGenieTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_tipLoading) ...[
              bar(double.infinity),
              const SizedBox(height: 8),
              bar(160),
            ] else
              AnimatedSize(
                duration: FitGenieTheme.animNormal,
                alignment: Alignment.topCenter,
                child: Text(
                  tip,
                  maxLines: _tipExpanded ? null : 3,
                  overflow: _tipExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: FitGenieTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTile(int index) {
    final item = _items[index];
    final cur = _currentIndex;
    final isCurrent = index == cur;
    final locked = !item.isDone && !isCurrent;
    final finished = item.doneSets >= item.sets;
    final active = isCurrent && _started;
    final hasNotes = item.notes != null && item.notes!.isNotEmpty;

    final String subtitle = item.skipped
        ? 'Skipped'
        : finished
            ? '${item.sets} × ${item.reps} · ${_fmtWeight(item.weight)} kg'
            : '${item.sets} × ${item.reps} · rest ${item.restSeconds}s';

    Widget trailing;
    if (item.isDone) {
      trailing = const SizedBox.shrink();
    } else if (active) {
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: FitGenieTheme.primary,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          'SET ${item.doneSets + 1}',
          style: const TextStyle(
            color: FitGenieTheme.onPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      );
    } else if (locked) {
      trailing = const Icon(Icons.lock_outline_rounded,
          size: 18, color: FitGenieTheme.muted);
    } else {
      trailing = const Icon(Icons.chevron_right_rounded,
          size: 22, color: FitGenieTheme.muted);
    }

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: FGCard(
        onTap: item.isDone ? null : () => _openExercise(index),
        color: active ? FitGenieTheme.primary.withValues(alpha: 0.08) : null,
        border: Border.all(
          color: active
              ? FitGenieTheme.primary.withValues(alpha: 0.6)
              : FitGenieTheme.border,
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _buildNumberBadge(index, finished && !item.skipped, active),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: item.isDone
                          ? FitGenieTheme.muted
                          : FitGenieTheme.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: FitGenieTheme.muted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (active && hasNotes) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.notes!,
                      style: const TextStyle(
                        color: FitGenieTheme.textSecondary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(item.sets, (s) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(
                              right: s == item.sets - 1 ? 0 : 4),
                          decoration: BoxDecoration(
                            color: s < item.doneSets
                                ? FitGenieTheme.primary
                                : FitGenieTheme.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (active) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () => _skipExercise(index),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                          child: Text(
                            'SKIP',
                            style: TextStyle(
                              color: FitGenieTheme.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }

  void _skipExercise(int index) {
    setState(() {
      _items[index].skipped = true;
      _items[index].setStartedAt = null;
    });
  }

  Widget _buildNumberBadge(int index, bool done, bool isCurrent) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? FitGenieTheme.primary : Colors.transparent,
        border: Border.all(
          color: done
              ? FitGenieTheme.primary
              : (isCurrent ? FitGenieTheme.primary : FitGenieTheme.border),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check_rounded,
                size: 18, color: FitGenieTheme.onPrimary)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color:
                      isCurrent ? FitGenieTheme.primary : FitGenieTheme.muted,
                ),
              ),
      ),
    );
  }

  Widget _buildAddExercise() {
    return InkWell(
      onTap: _showAddExerciseSheet,
      borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
          border: Border.all(color: FitGenieTheme.border),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 18, color: FitGenieTheme.primary),
              SizedBox(width: 6),
              Text(
                'Add exercise',
                style: TextStyle(
                  color: FitGenieTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final allDone = _started && _currentIndex == -1;

    final Widget button;
    if (!_started) {
      button = FilledButton(
        onPressed: _starting ? null : _startWorkout,
        child: _starting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(AppStrings.get('workout_start').toUpperCase()),
      );
    } else if (allDone) {
      button = FilledButton(
        onPressed: _finishing ? null : _finishWorkout,
        child: Text(AppStrings.get('workout_finish').toUpperCase()),
      );
    } else {
      button = OutlinedButton(
        onPressed: _finishing ? null : _finishWorkout,
        child: Text(AppStrings.get('workout_finish').toUpperCase()),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: FitGenieTheme.bg,
          border: Border(top: BorderSide(color: FitGenieTheme.border)),
        ),
        child: button,
      ),
    );
  }
}

// ============================================================
// 📋 One exercise in the live workout list
// ============================================================

class _WorkoutItem {
  final String name;
  final Exercise? exercise;
  final int sets;
  final String reps;
  final int restSeconds;
  final String? notes;
  double weight;
  int doneSets = 0;

  /// User ne "SKIP" dabaya
  bool skipped = false;

  /// Current set kab shuru hua (sheet band/khol karne par stopwatch resume ke liye)
  DateTime? setStartedAt;

  _WorkoutItem({
    required this.name,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.weight,
    this.notes,
  });

  bool get isDone => skipped || doneSets >= sets;

  int get setElapsedSeconds {
    final s = setStartedAt;
    return s == null ? 0 : DateTime.now().difference(s).inSeconds;
  }

  bool get isTimed {
    final r = reps.toLowerCase();
    return r.contains('sec') || r.contains('min');
  }
}

// Coach tip: isi app session mein dobara AI ko request na jaye
final Map<String, String> _coachTipCache = {};
