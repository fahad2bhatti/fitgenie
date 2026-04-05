// lib/screens/muscle_group_exercises_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app/fitgenie_theme.dart';
import '../widgets/fg_card.dart';
import '../data/exercise_data.dart';

// ============================================================
// 💪 MUSCLE GROUP EXERCISES SCREEN
// Shows all exercises for a specific body part with GIFs
// ============================================================

class MuscleGroupExercisesScreen extends StatefulWidget {
  final String bodyPart;
  final String emoji;
  final Color color;

  const MuscleGroupExercisesScreen({
    super.key,
    required this.bodyPart,
    required this.emoji,
    required this.color,
  });

  @override
  State<MuscleGroupExercisesScreen> createState() =>
      _MuscleGroupExercisesScreenState();
}

class _MuscleGroupExercisesScreenState
    extends State<MuscleGroupExercisesScreen> {
  String _filterEquipment = 'All';
  String _filterDifficulty = 'All';
  bool _showGifs = true;

  late List<Exercise> _allExercises;

  @override
  void initState() {
    super.initState();
    _allExercises = ExerciseData.getByBodyPart(widget.bodyPart);
  }

  List<Exercise> get _filteredExercises {
    return _allExercises.where((e) {
      if (_filterEquipment != 'All' && e.equipment != _filterEquipment) {
        return false;
      }
      if (_filterDifficulty != 'All' && e.difficulty != _filterDifficulty) {
        return false;
      }
      return true;
    }).toList();
  }

  List<String> get _equipmentOptions {
    final Set<String> equipment = {'All'};
    for (var e in _allExercises) {
      equipment.add(e.equipment);
    }
    return equipment.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitGenieTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──
          _buildSliverHeader(),

          // ── Filters ──
          SliverToBoxAdapter(child: _buildFilters()),

          // ── Exercise Count ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${_filteredExercises.length} exercises',
                    style: TextStyle(color: FitGenieTheme.muted, fontSize: 14),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showGifs = !_showGifs),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _showGifs
                            ? FitGenieTheme.primary.withOpacity(0.15)
                            : FitGenieTheme.card,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showGifs
                                ? Icons.gif_box
                                : Icons.gif_box_outlined,
                            size: 16,
                            color: _showGifs
                                ? FitGenieTheme.primary
                                : FitGenieTheme.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showGifs ? 'GIFs ON' : 'GIFs OFF',
                            style: TextStyle(
                              fontSize: 11,
                              color: _showGifs
                                  ? FitGenieTheme.primary
                                  : FitGenieTheme.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Exercise List ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final exercise = _filteredExercises[index];
                  return _buildExerciseCard(exercise, index);
                },
                childCount: _filteredExercises.length,
              ),
            ),
          ),

          // ── Bottom Spacing ──
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ============================================================
  // 🎨 SLIVER HEADER
  // ============================================================
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 180,
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
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          '${widget.emoji} ${widget.bodyPart}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.4),
                widget.color.withOpacity(0.1),
                FitGenieTheme.background,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 50)),
                const SizedBox(height: 8),
                Text(
                  '${_allExercises.length} Exercises',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                Text(
                  'with animated demos 🎬',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🎛️ FILTERS
  // ============================================================
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      child: Column(
        children: [
          // Equipment Filter
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _equipmentOptions.map((eq) {
                final isSelected = _filterEquipment == eq;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filterEquipment = eq),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.color.withOpacity(0.2)
                            : FitGenieTheme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? widget.color
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        eq,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? widget.color
                              : FitGenieTheme.muted,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Difficulty Filter
          Row(
            children: ['All', 'Beginner', 'Intermediate', 'Advanced']
                .map((diff) {
              final isSelected = _filterDifficulty == diff;
              Color diffColor;
              switch (diff) {
                case 'Beginner':
                  diffColor = Colors.green;
                  break;
                case 'Intermediate':
                  diffColor = Colors.orange;
                  break;
                case 'Advanced':
                  diffColor = Colors.red;
                  break;
                default:
                  diffColor = FitGenieTheme.muted;
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _filterDifficulty = diff),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? diffColor.withOpacity(0.2)
                          : FitGenieTheme.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? diffColor
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        diff,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? diffColor
                              : FitGenieTheme.muted,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🎬 EXERCISE CARD WITH GIF
  // ============================================================
  Widget _buildExerciseCard(Exercise exercise, int index) {
    return GestureDetector(
      onTap: () => _showExerciseDetail(exercise),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FGCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── GIF Section ──
              if (_showGifs && exercise.hasGif)
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: exercise.gifUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: FitGenieTheme.background,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: widget.color.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Loading...',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: FitGenieTheme.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 150,
                          color: FitGenieTheme.background,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fitness_center,
                                    size: 40,
                                    color: widget.color.withOpacity(0.3)),
                                const SizedBox(height: 8),
                                Text(exercise.name,
                                    style: TextStyle(
                                        color: FitGenieTheme.muted,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Calories Badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department,
                                  size: 14, color: FitGenieTheme.hot),
                              const SizedBox(width: 2),
                              Text(
                                '${exercise.caloriesPerMin} cal/min',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Difficulty Badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child:
                        _buildDifficultyBadge(exercise.difficulty),
                      ),

                      // Number Badge
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      // Tap Hint
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.info_outline,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Info Section ──
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row
                    Row(
                      children: [
                        if (!_showGifs || !exercise.hasGif)
                          Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: widget.color,
                                    fontSize: 16),
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
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildTag(
                                      exercise.equipment, FitGenieTheme.teal),
                                  const SizedBox(width: 6),
                                  if (exercise.tempo.isNotEmpty)
                                    _buildTag(
                                        'Tempo: ${exercise.tempo}',
                                        FitGenieTheme.primary),
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

                    // Muscles
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: exercise.musclesWorked
                          .map((muscle) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('💪 $muscle',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green)),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),

                    // Quick Instruction
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: FitGenieTheme.muted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            exercise.instructions,
                            style: TextStyle(
                                color: FitGenieTheme.muted, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Full Guide →',
                            style: TextStyle(
                                color: widget.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
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
  // 📋 EXERCISE DETAIL BOTTOM SHEET
  // ============================================================
  void _showExerciseDetail(Exercise exercise) {
    final String name = exercise.name;
    final String bodyPart = exercise.bodyPart;
    final String equipment = exercise.equipment;
    final String difficulty = exercise.difficulty;
    final String instructions = exercise.instructions;
    final String gifUrl = exercise.gifUrl;
    final int calories = exercise.caloriesPerMin;
    final String tempo = exercise.tempo;
    final List<String> muscles = exercise.musclesWorked;
    final List<String> steps = exercise.detailedSteps;
    final List<String> tips = exercise.tips;
    final List<String> mistakes = exercise.commonMistakes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
              // ── Handle ──
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

              // ── Close ──
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

              // ── GIF ──
              if (gifUrl.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: widget.color.withOpacity(0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: gifUrl,
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(
                        height: 280,
                        color: FitGenieTheme.background,
                        child: const Center(
                            child: CircularProgressIndicator()),
                      ),
                      errorWidget: (c, u, e) => Container(
                        height: 200,
                        color: FitGenieTheme.background,
                        child: const Center(
                          child: Icon(Icons.fitness_center,
                              size: 48, color: Colors.white24),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 150,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: FitGenieTheme.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.fitness_center,
                        size: 60, color: Colors.white24),
                  ),
                ),

              const SizedBox(height: 16),

              // ── Content ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(name,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Info Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(Icons.fitness_center,
                            bodyPart, widget.color),
                        _buildInfoChip(
                            Icons.build, equipment, FitGenieTheme.teal),
                        _buildInfoChip(Icons.local_fire_department,
                            '$calories cal/min', FitGenieTheme.hot),
                        if (tempo.isNotEmpty)
                          _buildInfoChip(Icons.speed,
                              'Tempo: $tempo', FitGenieTheme.primary),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Difficulty
                    _buildDifficultyBadge(difficulty),
                    const SizedBox(height: 16),

                    // Muscles
                    if (muscles.isNotEmpty) ...[
                      const Text('Target Muscles',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.white70)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: muscles
                            .map((m) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                            Colors.green.withOpacity(0.15),
                            borderRadius:
                            BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.green
                                    .withOpacity(0.3)),
                          ),
                          child: Text('💪 $m',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.green)),
                        ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Description
                    if (instructions.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: FitGenieTheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.description,
                                size: 18, color: widget.color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(instructions,
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.5)),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ── Steps ──
                    if (steps.isNotEmpty) ...[
                      _buildSectionTitle(
                          '📝 How to Perform', widget.color),
                      const SizedBox(height: 14),
                      for (int i = 0; i < steps.length; i++)
                        _buildStepItem(i + 1, steps[i]),
                      const SizedBox(height: 24),
                    ],

                    // ── Tips ──
                    if (tips.isNotEmpty) ...[
                      _buildSectionTitle(
                          '💡 Pro Tips', Colors.amber),
                      const SizedBox(height: 14),
                      for (int i = 0; i < tips.length; i++)
                        _buildBulletItem(tips[i], Colors.amber,
                            Icons.lightbulb_outline),
                      const SizedBox(height: 24),
                    ],

                    // ── Mistakes ──
                    if (mistakes.isNotEmpty) ...[
                      _buildSectionTitle(
                          '⚠️ Common Mistakes', FitGenieTheme.hot),
                      const SizedBox(height: 14),
                      for (int i = 0; i < mistakes.length; i++)
                        _buildBulletItem(mistakes[i],
                            FitGenieTheme.hot,
                            Icons.warning_amber_outlined),
                      const SizedBox(height: 24),
                    ],

                    // No Details
                    if (steps.isEmpty &&
                        tips.isEmpty &&
                        mistakes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: FitGenieTheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 40,
                                  color: FitGenieTheme.muted),
                              const SizedBox(height: 8),
                              Text('Detailed guide coming soon!',
                                  style: TextStyle(
                                      color: FitGenieTheme.muted)),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 50),
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
  // 🛠️ HELPER WIDGETS
  // ============================================================

  Widget _buildSectionTitle(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(title,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color)),
    );
  }

  Widget _buildStepItem(int number, String text) {
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
                colors: [
                  widget.color,
                  widget.color.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('$number',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(text,
                  style:
                  const TextStyle(fontSize: 14, height: 1.5)),
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
              child: Text(text,
                  style:
                  const TextStyle(fontSize: 13, height: 1.5)),
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
          Text(text,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
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
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(difficulty,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}