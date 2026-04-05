// lib/screens/workout_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app/fitgenie_theme.dart';
import '../widgets/fg_card.dart';
import '../data/exercise_data.dart';
import 'workout_screen.dart' show ActiveWorkoutScreen;

// ============================================================
// 🕐 WORKOUT DETAIL SCREEN
// Shows full details of a completed / active workout
// ============================================================

class WorkoutDetailScreen extends StatelessWidget {
  final String workoutId;
  final String userId;
  final Map<String, dynamic> workoutData;

  const WorkoutDetailScreen({
    super.key,
    required this.workoutId,
    required this.userId,
    required this.workoutData,
  });

  String get workoutType => (workoutData['type'] ?? 'Workout').toString();
  String get status => (workoutData['status'] ?? 'completed').toString();
  int get totalSets => (workoutData['totalSets'] ?? 0) as int;
  int get duration => (workoutData['duration'] ?? 0) as int;
  String get source => (workoutData['source'] ?? 'manual').toString();

  List<Map<String, dynamic>> get loggedSets {
    final raw = workoutData['sets'] as List<dynamic>? ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  List<Map<String, dynamic>> get plannedExercises {
    final raw = workoutData['plannedExercises'] as List<dynamic>? ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Timestamp? get startedAt => workoutData['startedAt'] as Timestamp?;
  Timestamp? get endedAt => workoutData['endedAt'] as Timestamp?;

  Map<String, List<Map<String, dynamic>>> get groupedSets {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final set in loggedSets) {
      final name = (set['exercise'] ?? 'Exercise').toString();
      grouped.putIfAbsent(name, () => []);
      grouped[name]!.add(set);
    }
    return grouped;
  }

  int get uniqueExercises => groupedSets.keys.length;

  double get totalVolume {
    double volume = 0;
    for (final set in loggedSets) {
      final weight = (set['weight'] is num)
          ? (set['weight'] as num).toDouble()
          : double.tryParse(set['weight'].toString()) ?? 0;

      final reps = _extractNumber(set['reps']?.toString() ?? '0');
      volume += weight * reps;
    }
    return volume;
  }

  int get estimatedCalories {
    if (duration <= 0) return totalSets * 4;
    return duration * 6;
  }

  String get formattedDate {
    if (startedAt == null) return 'Unknown date';
    final d = startedAt!.toDate();
    return '${d.day}/${d.month}/${d.year} • ${_formatTime(d)}';
  }

  String get formattedEndDate {
    if (endedAt == null) return '--';
    final d = endedAt!.toDate();
    return '${d.day}/${d.month}/${d.year} • ${_formatTime(d)}';
  }

  String _formatTime(DateTime d) {
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final suffix = d.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  int _extractNumber(String text) {
    final match = RegExp(r'\d+').firstMatch(text);
    if (match == null) return 0;
    return int.tryParse(match.group(0) ?? '0') ?? 0;
  }

  Exercise? _findExerciseByName(String name) {
    try {
      return ExerciseData.getAllExercises().firstWhere(
            (e) => e.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  String _inferWorkoutType() {
    final t = workoutType.toLowerCase();

    if (t.contains('chest')) return 'chest';
    if (t.contains('back') || t.contains('pull')) return 'back';
    if (t.contains('leg') || t.contains('lower')) return 'legs';
    if (t.contains('shoulder')) return 'shoulders';
    if (t.contains('arm')) return 'arms';
    if (t.contains('core')) return 'core';
    if (t.contains('cardio')) return 'cardio';
    if (t.contains('full') || t.contains('push') || t.contains('upper')) {
      return 'full_body';
    }

    return 'full_body';
  }

  String _workoutEmoji() {
    final t = workoutType.toLowerCase();
    if (t.contains('chest')) return '🏋️';
    if (t.contains('back') || t.contains('pull')) return '🔙';
    if (t.contains('leg') || t.contains('lower')) return '🦵';
    if (t.contains('shoulder')) return '🎯';
    if (t.contains('arm')) return '💪';
    if (t.contains('core')) return '🔥';
    if (t.contains('cardio')) return '🏃';
    if (t.contains('push')) return '🔴';
    if (t.contains('full')) return '🏆';
    if (t.contains('upper')) return '🟡';
    return '🏋️';
  }

  Color _workoutColor() {
    final t = workoutType.toLowerCase();
    if (t.contains('chest')) return Colors.red;
    if (t.contains('back') || t.contains('pull')) return Colors.blue;
    if (t.contains('leg') || t.contains('lower')) return Colors.green;
    if (t.contains('shoulder')) return Colors.purple;
    if (t.contains('arm')) return Colors.orange;
    if (t.contains('core')) return Colors.teal;
    if (t.contains('cardio')) return Colors.pink;
    if (t.contains('full')) return Colors.amber;
    return FitGenieTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _workoutColor();

    return Scaffold(
      backgroundColor: FitGenieTheme.background,
      appBar: AppBar(
        backgroundColor: FitGenieTheme.cardDark,
        title: const Text('Workout Details 🕐'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context, color),
            const SizedBox(height: 18),

            _buildStatsRow(color),
            const SizedBox(height: 18),

            if (plannedExercises.isNotEmpty) ...[
              _buildSectionTitle('📋 Planned Exercises', color),
              const SizedBox(height: 10),
              _buildPlannedExercises(color),
              const SizedBox(height: 18),
            ],

            _buildSectionTitle('💪 Performed Exercises', color),
            const SizedBox(height: 10),
            _buildPerformedExercises(color),
            const SizedBox(height: 18),

            _buildSectionTitle('🧾 All Logged Sets', color),
            const SizedBox(height: 10),
            _buildAllLoggedSets(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🎨 HEADER CARD
  // ============================================================

  Widget _buildHeaderCard(BuildContext context, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.35),
            color.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _workoutEmoji(),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutType,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              _infoPill(Icons.schedule, '${duration > 0 ? duration : '--'} min'),
              const SizedBox(width: 8),
              _infoPill(Icons.repeat, '$totalSets sets'),
              const SizedBox(width: 8),
              _infoPill(Icons.fitness_center, '$uniqueExercises exercises'),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActiveWorkoutScreen(
                          userId: userId,
                          workoutType: _inferWorkoutType(),
                          workoutTitle: workoutType,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Repeat Workout',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final completed = status == 'completed';
    final color = completed ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.access_time,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            completed ? 'Completed' : 'Active',
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

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 📊 STATS
  // ============================================================

  Widget _buildStatsRow(Color color) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.repeat,
            value: '$totalSets',
            label: 'Sets',
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.fitness_center,
            value: '$uniqueExercises',
            label: 'Exercises',
            color: FitGenieTheme.teal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.scale,
            value: totalVolume.toStringAsFixed(0),
            label: 'Volume',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.local_fire_department,
            value: '$estimatedCalories',
            label: 'Calories',
            color: FitGenieTheme.hot,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return FGCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: FitGenieTheme.muted,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 📋 PLANNED EXERCISES
  // ============================================================

  Widget _buildPlannedExercises(Color color) {
    return Column(
      children: plannedExercises.map((item) {
        final exercise = _findExerciseByName((item['name'] ?? '').toString());

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: FGCard(
            child: Row(
              children: [
                if (exercise != null && exercise.hasGif)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: exercise.gifUrl,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(
                        width: 68,
                        height: 68,
                        color: FitGenieTheme.background,
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (c, u, e) => Container(
                        width: 68,
                        height: 68,
                        color: FitGenieTheme.background,
                        child: const Icon(Icons.fitness_center,
                            color: Colors.white24),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: FitGenieTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fitness_center,
                        color: Colors.white24),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (item['name'] ?? 'Exercise').toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item['sets'] ?? '--'} × ${item['reps'] ?? '--'}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.checklist, color: color, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // 💪 PERFORMED EXERCISES GROUPED
  // ============================================================

  Widget _buildPerformedExercises(Color color) {
    if (loggedSets.isEmpty) {
      return FGCard(
        child: Center(
          child: Column(
            children: [
              Icon(Icons.info_outline,
                  size: 36, color: FitGenieTheme.muted),
              const SizedBox(height: 8),
              Text(
                'No set logs found',
                style: TextStyle(color: FitGenieTheme.muted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: groupedSets.entries.map((entry) {
        final exerciseName = entry.key;
        final sets = entry.value;
        final exercise = _findExerciseByName(exerciseName);

        final totalExerciseVolume = sets.fold<double>(0, (sum, set) {
          final weight = (set['weight'] is num)
              ? (set['weight'] as num).toDouble()
              : double.tryParse(set['weight'].toString()) ?? 0;
          final reps = _extractNumber(set['reps']?.toString() ?? '0');
          return sum + (weight * reps);
        });

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: FGCard(
            child: Column(
              children: [
                Row(
                  children: [
                    if (exercise != null && exercise.hasGif)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: exercise.gifUrl,
                          width: 78,
                          height: 78,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(
                            width: 78,
                            height: 78,
                            color: FitGenieTheme.background,
                            child: const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (c, u, e) => Container(
                            width: 78,
                            height: 78,
                            color: FitGenieTheme.background,
                            child: const Icon(Icons.fitness_center,
                                color: Colors.white24),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: FitGenieTheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.fitness_center,
                            color: Colors.white24),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exerciseName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${sets.length} sets completed',
                            style: TextStyle(
                              color: FitGenieTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _tinyInfo('Vol ${totalExerciseVolume.toStringAsFixed(0)}'),
                              if (exercise != null)
                                _tinyInfo(exercise.bodyPart),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(sets.length, (index) {
                  final set = sets[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FitGenieTheme.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: FitGenieTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: FitGenieTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${set['weight']} kg × ${set['reps']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(Icons.check_circle,
                            size: 18, color: Colors.green),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // 🧾 ALL LOGGED SETS
  // ============================================================

  Widget _buildAllLoggedSets() {
    if (loggedSets.isEmpty) {
      return FGCard(
        child: Center(
          child: Text(
            'No set data available',
            style: TextStyle(color: FitGenieTheme.muted),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(loggedSets.length, (index) {
        final set = loggedSets[index];
        final timestampString = (set['timestamp'] ?? '').toString();

        String time = '--';
        if (timestampString.isNotEmpty) {
          try {
            final parsed = DateTime.parse(timestampString);
            time = _formatTime(parsed);
          } catch (_) {}
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: FGCard(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: FitGenieTheme.primary.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: FitGenieTheme.primary,
                        fontWeight: FontWeight.bold,
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
                        (set['exercise'] ?? 'Exercise').toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${set['weight']} kg × ${set['reps']}',
                        style: TextStyle(
                          color: FitGenieTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: FitGenieTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ============================================================
  // 🏷 HELPERS
  // ============================================================

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const Spacer(),
        Container(
          width: 34,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _tinyInfo(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FitGenieTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: FitGenieTheme.muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}