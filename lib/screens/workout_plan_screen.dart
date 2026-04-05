// lib/screens/workout_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app/fitgenie_theme.dart';
import '../widgets/fg_card.dart';
import '../data/workout_plans_data.dart';
import '../data/exercise_data.dart';
import 'workout_screen.dart' show ActiveWorkoutScreen;

// ============================================================
// 📋 WORKOUT PLAN SCREEN
// Push / Pull / Legs / Upper / Lower / Arms / Full Body details
// ============================================================

class WorkoutPlanScreen extends StatefulWidget {
  final WorkoutPlan plan;
  final String userId;

  const WorkoutPlanScreen({
    super.key,
    required this.plan,
    required this.userId,
  });

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  bool _showGifs = true;

  List<Exercise> get _allExercises => ExerciseData.getAllExercises();

  Exercise? _findExerciseById(String id) {
    try {
      return _allExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  String _resolveWorkoutTypeForTracker() {
    switch (widget.plan.category) {
      case 'legs':
        return 'legs';
      case 'cardio':
        return 'cardio';
      case 'arms':
        return 'arms';
      case 'full_body':
        return 'full_body';
      default:
        return 'full_body';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.plan.color);

    return Scaffold(
      backgroundColor: FitGenieTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(color),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewCard(color),
                  const SizedBox(height: 18),
                  _buildTargetMuscles(color),
                  const SizedBox(height: 18),
                  _buildStatsRow(color),
                  const SizedBox(height: 18),
                  _buildStartButton(color),
                  const SizedBox(height: 24),
                  _buildExerciseHeader(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final planExercise = widget.plan.exercises[index];
                  final exercise =
                  _findExerciseById(planExercise.exerciseId);
                  return _buildPlanExerciseCard(
                    planExercise: planExercise,
                    exercise: exercise,
                    index: index,
                    color: color,
                  );
                },
                childCount: widget.plan.exercises.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ============================================================
  // 🎨 HEADER
  // ============================================================
  Widget _buildSliverHeader(Color color) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: FitGenieTheme.cardDark,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          onPressed: () => setState(() => _showGifs = !_showGifs),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _showGifs ? Icons.gif_box : Icons.gif_box_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          '${widget.plan.emoji} ${widget.plan.name}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.45),
                color.withOpacity(0.15),
                FitGenieTheme.background,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.plan.emoji,
                        style: const TextStyle(fontSize: 52)),
                    const SizedBox(height: 10),
                    Text(
                      widget.plan.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDifficultyBadge(widget.plan.difficulty),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 📝 OVERVIEW
  // ============================================================
  Widget _buildOverviewCard(Color color) {
    return FGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan Overview',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            widget.plan.description,
            style: TextStyle(
              color: FitGenieTheme.muted,
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetMuscles(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Muscles',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.plan.targetMuscles.map((muscle) {
            return Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Text(
                '💪 $muscle',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Color color) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.fitness_center,
            value: '${widget.plan.totalExercises}',
            label: 'Exercises',
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.repeat,
            value: '${widget.plan.totalSets}',
            label: 'Total Sets',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer_outlined,
            value: '${widget.plan.estimatedMinutes}',
            label: 'Minutes',
            color: FitGenieTheme.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return FGCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: FitGenieTheme.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveWorkoutScreen(
                userId: widget.userId,
                workoutType: _resolveWorkoutTypeForTracker(),
                workoutTitle: widget.plan.name,
              ),
            ),
          );
        },
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text(
          'Start This Workout',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseHeader() {
    return Row(
      children: [
        const Text(
          'Exercises in this Plan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        const Spacer(),
        Text(
          _showGifs ? 'GIFs ON' : 'GIFs OFF',
          style: TextStyle(
            color: FitGenieTheme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 🏋️ PLAN EXERCISE CARD
  // ============================================================
  Widget _buildPlanExerciseCard({
    required PlanExercise planExercise,
    required Exercise? exercise,
    required int index,
    required Color color,
  }) {
    if (exercise == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: FGCard(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Text('${index + 1}',
                  style: TextStyle(color: color)),
            ),
            title: Text(planExercise.exerciseId),
            subtitle: Text(
              '${planExercise.sets} sets × ${planExercise.reps}',
              style: TextStyle(color: FitGenieTheme.muted),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showExerciseDetail(exercise, planExercise, color),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FGCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showGifs && exercise.hasGif)
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: exercise.gifUrl,
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 190,
                          color: FitGenieTheme.background,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 150,
                          color: FitGenieTheme.background,
                          child: const Center(
                            child: Icon(Icons.fitness_center,
                                color: Colors.white24, size: 42),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 8,
                        right: 8,
                        child:
                        _buildDifficultyBadge(exercise.difficulty),
                      ),

                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.repeat,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${planExercise.sets} × ${planExercise.reps}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!_showGifs || !exercise.hasGif)
                          Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildTag(exercise.equipment,
                                      FitGenieTheme.teal),
                                  const SizedBox(width: 6),
                                  _buildTag(
                                    '${planExercise.sets} × ${planExercise.reps}',
                                    color,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!_showGifs || !exercise.hasGif)
                          _buildDifficultyBadge(exercise.difficulty),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: exercise.musclesWorked.map((muscle) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '💪 $muscle',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _miniChip(Icons.timer_outlined,
                            '${planExercise.restSeconds}s rest'),
                        const SizedBox(width: 8),
                        _miniChip(Icons.local_fire_department,
                            '${exercise.caloriesPerMin} cal/min'),
                      ],
                    ),

                    if (planExercise.notes != null &&
                        planExercise.notes!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: FitGenieTheme.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.notes,
                                size: 16, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                planExercise.notes!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: FitGenieTheme.muted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    Text(
                      'Tap for full form guide →',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  // ============================================================
  // 📖 DETAIL BOTTOM SHEET
  // ============================================================
  void _showExerciseDetail(
      Exercise exercise,
      PlanExercise planExercise,
      Color color,
      ) {
    final steps = exercise.detailedSteps;
    final tips = exercise.tips;
    final mistakes = exercise.commonMistakes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.93,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: FitGenieTheme.cardDark,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white54, size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              if (exercise.hasGif)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: exercise.gifUrl,
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 280,
                        color: FitGenieTheme.background,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: FitGenieTheme.background,
                        child: const Center(
                          child: Icon(Icons.fitness_center,
                              size: 50, color: Colors.white24),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(Icons.fitness_center,
                            exercise.bodyPart, color),
                        _buildInfoChip(Icons.build,
                            exercise.equipment, FitGenieTheme.teal),
                        _buildInfoChip(
                          Icons.repeat,
                          '${planExercise.sets} × ${planExercise.reps}',
                          Colors.orange,
                        ),
                        _buildInfoChip(
                          Icons.timer_outlined,
                          '${planExercise.restSeconds}s rest',
                          Colors.green,
                        ),
                        _buildInfoChip(
                          Icons.local_fire_department,
                          '${exercise.caloriesPerMin} cal/min',
                          FitGenieTheme.hot,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildDifficultyBadge(exercise.difficulty),
                    const SizedBox(height: 16),

                    if (exercise.musclesWorked.isNotEmpty) ...[
                      const Text(
                        'Target Muscles',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                        exercise.musclesWorked.map((muscle) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '💪 $muscle',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.green,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (planExercise.notes != null &&
                        planExercise.notes!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: color.withOpacity(0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.notes, color: color, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                planExercise.notes!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: color,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FitGenieTheme.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.description,
                              size: 18, color: color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              exercise.instructions,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (steps.isNotEmpty) ...[
                      _buildSectionTitle('📝 How to Perform', color),
                      const SizedBox(height: 14),
                      for (int i = 0; i < steps.length; i++)
                        _buildStepItem(i + 1, steps[i], color),
                      const SizedBox(height: 24),
                    ],

                    if (tips.isNotEmpty) ...[
                      _buildSectionTitle('💡 Pro Tips', Colors.amber),
                      const SizedBox(height: 14),
                      for (final tip in tips)
                        _buildBulletItem(
                          tip,
                          Colors.amber,
                          Icons.lightbulb_outline,
                        ),
                      const SizedBox(height: 24),
                    ],

                    if (mistakes.isNotEmpty) ...[
                      _buildSectionTitle(
                          '⚠️ Common Mistakes', FitGenieTheme.hot),
                      const SizedBox(height: 14),
                      for (final mistake in mistakes)
                        _buildBulletItem(
                          mistake,
                          FitGenieTheme.hot,
                          Icons.warning_amber_outlined,
                        ),
                      const SizedBox(height: 24),
                    ],

                    const SizedBox(height: 40),
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
  // 🛠 HELPERS
  // ============================================================
  Widget _buildSectionTitle(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStepItem(int number, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: FitGenieTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: FitGenieTheme.muted),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: FitGenieTheme.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    IconData icon;

    switch (difficulty.toLowerCase()) {
      case 'beginner':
        color = Colors.green;
        icon = Icons.star_outline;
        break;
      case 'intermediate':
        color = Colors.orange;
        icon = Icons.star_half;
        break;
      case 'advanced':
        color = Colors.red;
        icon = Icons.star;
        break;
      default:
        color = Colors.grey;
        icon = Icons.star_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            difficulty,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}