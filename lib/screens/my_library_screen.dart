// lib/screens/my_library_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app/fitgenie_theme.dart';
import '../widgets/fg_card.dart';
import '../data/exercise_data.dart';

// ============================================================
// 📚 MY LIBRARY SCREEN
// Custom workout builder + saved custom workouts + custom session
// ============================================================

class MyLibraryScreen extends StatefulWidget {
  final String userId;
  final bool openCreate;

  const MyLibraryScreen({
    super.key,
    required this.userId,
    this.openCreate = false,
  });

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> {
  @override
  void initState() {
    super.initState();

    if (widget.openCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openCreateWorkout();
      });
    }
  }

  void _openCreateWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomWorkoutBuilderScreen(
          userId: widget.userId,
        ),
      ),
    );
  }

  void _openEditWorkout(String workoutId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomWorkoutBuilderScreen(
          userId: widget.userId,
          workoutId: workoutId,
          existingData: data,
        ),
      ),
    );
  }

  Future<void> _deleteWorkout(String workoutId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitGenieTheme.cardDark,
        title: const Text('Delete Workout?'),
        content: const Text('Yeh custom workout permanently delete ho jayega.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('customWorkouts')
          .doc(workoutId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout deleted')),
        );
      }
    }
  }

  String _bodyPartEmoji(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'chest':
        return '🏋️';
      case 'back':
        return '🔙';
      case 'legs':
        return '🦵';
      case 'arms':
        return '💪';
      case 'shoulders':
        return '🎯';
      case 'core':
        return '🔥';
      case 'cardio':
        return '🏃';
      case 'mixed':
        return '📚';
      default:
        return '💪';
    }
  }

  Color _bodyPartColor(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'chest':
        return Colors.red;
      case 'back':
        return Colors.blue;
      case 'legs':
        return Colors.green;
      case 'arms':
        return Colors.orange;
      case 'shoulders':
        return Colors.purple;
      case 'core':
        return Colors.teal;
      case 'cardio':
        return Colors.pink;
      default:
        return FitGenieTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitGenieTheme.background,
      appBar: AppBar(
        backgroundColor: FitGenieTheme.cardDark,
        title: const Text('My Library 📚'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateWorkout,
        backgroundColor: FitGenieTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Workout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Header card
          Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FitGenieTheme.primary.withOpacity(0.28),
                    FitGenieTheme.primary.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: FitGenieTheme.primary.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('📚', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Custom Workout Library',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Apni marzi se exercises select karo, save karo aur kabhi bhi start karo.',
                          style: TextStyle(
                            color: FitGenieTheme.muted,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('customWorkouts')
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'My Workout';
                    final bodyPart = data['bodyPart'] ?? 'Mixed';
                    final exercises =
                    (data['exercises'] as List<dynamic>? ?? []);
                    final color = _bodyPartColor(bodyPart);
                    final emoji = _bodyPartEmoji(bodyPart);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: FGCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          _miniTag(bodyPart, color),
                                          const SizedBox(width: 6),
                                          _miniTag(
                                            '${exercises.length} exercises',
                                            FitGenieTheme.teal,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (exercises.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: exercises.take(4).map((e) {
                                  final map =
                                  e as Map<String, dynamic>;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: FitGenieTheme.background,
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      map['name'] ?? 'Exercise',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: FitGenieTheme.muted,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                            if (exercises.length > 4) ...[
                              const SizedBox(height: 6),
                              Text(
                                '+${exercises.length - 4} more exercises',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: FitGenieTheme.muted,
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CustomWorkoutSessionScreen(
                                                userId: widget.userId,
                                                workoutName: name,
                                                workoutId: doc.id,
                                                exercises: exercises
                                                    .map((e) => Map<String, dynamic>.from(
                                                    e as Map))
                                                    .toList(),
                                              ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.play_arrow,
                                        color: Colors.white, size: 18),
                                    label: const Text(
                                      'Start',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: color,
                                      minimumSize:
                                      const Size(double.infinity, 44),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _circleActionButton(
                                  icon: Icons.edit_outlined,
                                  color: FitGenieTheme.primary,
                                  onTap: () =>
                                      _openEditWorkout(doc.id, data),
                                ),
                                const SizedBox(width: 8),
                                _circleActionButton(
                                  icon: Icons.delete_outline,
                                  color: Colors.red,
                                  onTap: () => _deleteWorkout(doc.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: FitGenieTheme.card,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.library_books_outlined,
                size: 52,
                color: FitGenieTheme.muted,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No custom workouts yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Apna khud ka workout banao.\nChest routine, arm blaster, fat loss circuit — jo marzi.',
              style: TextStyle(
                color: FitGenieTheme.muted,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _openCreateWorkout,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create First Workout',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: FitGenieTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _circleActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ============================================================
// 🛠 CUSTOM WORKOUT BUILDER SCREEN
// Create / Edit custom workout
// ============================================================

class CustomWorkoutBuilderScreen extends StatefulWidget {
  final String userId;
  final String? workoutId;
  final Map<String, dynamic>? existingData;

  const CustomWorkoutBuilderScreen({
    super.key,
    required this.userId,
    this.workoutId,
    this.existingData,
  });

  @override
  State<CustomWorkoutBuilderScreen> createState() =>
      _CustomWorkoutBuilderScreenState();
}

class _CustomWorkoutBuilderScreenState
    extends State<CustomWorkoutBuilderScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedBodyPart = 'All';
  String _searchQuery = '';
  bool _saving = false;

  final Map<String, Map<String, dynamic>> _selectedExercises = {};

  bool get _isEditing => widget.workoutId != null;

  @override
  void initState() {
    super.initState();

    if (widget.existingData != null) {
      _nameController.text = widget.existingData!['name'] ?? '';
      final exercises =
      (widget.existingData!['exercises'] as List<dynamic>? ?? []);
      for (final item in exercises) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = map['exerciseId'];
        if (id != null) {
          _selectedExercises[id] = map;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _bodyParts => [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Core',
    'Cardio',
  ];

  List<Exercise> get _filteredExercises {
    List<Exercise> list = _selectedBodyPart == 'All'
        ? ExerciseData.getAllExercises()
        : ExerciseData.getByBodyPart(_selectedBodyPart);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) {
        return e.name.toLowerCase().contains(q) ||
            e.equipment.toLowerCase().contains(q) ||
            e.bodyPart.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  String _deriveWorkoutBodyPart() {
    if (_selectedExercises.isEmpty) return 'Mixed';

    final bodyParts = _selectedExercises.values
        .map((e) => (e['bodyPart'] ?? 'Mixed').toString())
        .toSet()
        .toList();

    if (bodyParts.length == 1) return bodyParts.first;
    return 'Mixed';
  }

  Future<void> _saveWorkout() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout name likho')),
      );
      return;
    }

    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 1 exercise select karo')),
      );
      return;
    }

    setState(() => _saving = true);

    final payload = {
      'name': name,
      'bodyPart': _deriveWorkoutBodyPart(),
      'exercises': _selectedExercises.values.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (!_isEditing) 'createdAt': FieldValue.serverTimestamp(),
    };

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('customWorkouts');

    if (_isEditing) {
      await ref.doc(widget.workoutId).update(payload);
    } else {
      await ref.add(payload);
    }

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Workout updated successfully ✅'
                : 'Workout saved successfully ✅',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _toggleExercise(Exercise exercise) {
    final exists = _selectedExercises.containsKey(exercise.id);

    setState(() {
      if (exists) {
        _selectedExercises.remove(exercise.id);
      } else {
        _selectedExercises[exercise.id] = {
          'exerciseId': exercise.id,
          'name': exercise.name,
          'bodyPart': exercise.bodyPart,
          'sets': 3,
          'reps': '12',
          'equipment': exercise.equipment,
        };
      }
    });
  }

  void _editExerciseConfig(Exercise exercise) {
    final data = _selectedExercises[exercise.id];
    if (data == null) return;

    int selectedSets = (data['sets'] ?? 3) as int;
    final repsController =
    TextEditingController(text: (data['reps'] ?? '12').toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: FitGenieTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 18),

                const Text('Sets',
                    style: TextStyle(fontWeight: FontWeight.w600)),
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
                            color: sel
                                ? FitGenieTheme.primary
                                : FitGenieTheme.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '$s',
                              style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : FitGenieTheme.muted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                const Text('Reps / Time',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: repsController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Example: 12 or 45 sec',
                    hintStyle: TextStyle(color: FitGenieTheme.muted),
                    filled: true,
                    fillColor: FitGenieTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedExercises[exercise.id] = {
                          ..._selectedExercises[exercise.id]!,
                          'sets': selectedSets,
                          'reps': repsController.text.trim().isEmpty
                              ? '12'
                              : repsController.text.trim(),
                        };
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FitGenieTheme.primary,
                    ),
                    child: const Text(
                      'Save Config',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _bodyPartEmoji(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'chest':
        return '🏋️';
      case 'back':
        return '🔙';
      case 'legs':
        return '🦵';
      case 'shoulders':
        return '🎯';
      case 'biceps':
      case 'triceps':
        return '💪';
      case 'core':
        return '🔥';
      case 'cardio':
        return '🏃';
      default:
        return '💪';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedList = _selectedExercises.values.toList();

    return Scaffold(
      backgroundColor: FitGenieTheme.background,
      appBar: AppBar(
        backgroundColor: FitGenieTheme.cardDark,
        title: Text(_isEditing ? 'Edit Workout ✏️' : 'Create Workout ➕'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveWorkout,
            child: _saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text(
              'SAVE',
              style: TextStyle(
                color: FitGenieTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Name
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Workout name e.g. My Chest Routine',
                    hintStyle: TextStyle(color: FitGenieTheme.muted),
                    prefixIcon: Icon(Icons.drive_file_rename_outline,
                        color: FitGenieTheme.muted),
                    filled: true,
                    fillColor: FitGenieTheme.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    hintStyle: TextStyle(color: FitGenieTheme.muted),
                    prefixIcon:
                    Icon(Icons.search, color: FitGenieTheme.muted),
                    filled: true,
                    fillColor: FitGenieTheme.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body part filter
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: _bodyParts.map((part) {
                final selected = _selectedBodyPart == part;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedBodyPart = part),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? FitGenieTheme.primary.withOpacity(0.2)
                            : FitGenieTheme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? FitGenieTheme.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        part == 'All'
                            ? 'All'
                            : '${_bodyPartEmoji(part)} $part',
                        style: TextStyle(
                          color: selected
                              ? FitGenieTheme.primary
                              : FitGenieTheme.muted,
                          fontSize: 12,
                          fontWeight: selected
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

          const SizedBox(height: 14),

          // Selected exercises
          if (selectedList.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FitGenieTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: FitGenieTheme.primary.withOpacity(0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Selected Exercises',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const Spacer(),
                      Text(
                        '${selectedList.length}',
                        style: const TextStyle(
                          color: FitGenieTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...selectedList.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['name'] ?? 'Exercise',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                              FitGenieTheme.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item['sets']} × ${item['reps']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: FitGenieTheme.muted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              final exercise =
                              ExerciseData.getAllExercises().firstWhere(
                                    (e) => e.id == item['exerciseId'],
                              );
                              _editExerciseConfig(exercise);
                            },
                            child: const Icon(Icons.edit_outlined,
                                size: 18,
                                color: FitGenieTheme.primary),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedExercises.remove(
                                    item['exerciseId']);
                              });
                            },
                            child: const Icon(Icons.close,
                                size: 18, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

          if (selectedList.isNotEmpty) const SizedBox(height: 12),

          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                final selected =
                _selectedExercises.containsKey(exercise.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      if (selected) {
                        _editExerciseConfig(exercise);
                      } else {
                        _toggleExercise(exercise);
                      }
                    },
                    child: FGCard(
                      child: Row(
                        children: [
                          if (exercise.hasGif)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: exercise.gifUrl,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                placeholder: (c, u) => Container(
                                  width: 72,
                                  height: 72,
                                  color: FitGenieTheme.background,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: (c, u, e) => Container(
                                  width: 72,
                                  height: 72,
                                  color: FitGenieTheme.background,
                                  child: const Icon(Icons.fitness_center,
                                      color: Colors.white24),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 72,
                              height: 72,
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
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${exercise.bodyPart} • ${exercise.equipment}',
                                  style: TextStyle(
                                    color: FitGenieTheme.muted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (selected)
                                  Text(
                                    '${_selectedExercises[exercise.id]!['sets']} × ${_selectedExercises[exercise.id]!['reps']}',
                                    style: const TextStyle(
                                      color: FitGenieTheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: selected,
                            onChanged: (v) {
                              if (selected) {
                                setState(() {
                                  _selectedExercises.remove(exercise.id);
                                });
                              } else {
                                _toggleExercise(exercise);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ▶️ CUSTOM WORKOUT SESSION SCREEN
// Starts a saved custom workout
// ============================================================

class CustomWorkoutSessionScreen extends StatefulWidget {
  final String userId;
  final String workoutName;
  final String workoutId;
  final List<Map<String, dynamic>> exercises;

  const CustomWorkoutSessionScreen({
    super.key,
    required this.userId,
    required this.workoutName,
    required this.workoutId,
    required this.exercises,
  });

  @override
  State<CustomWorkoutSessionScreen> createState() =>
      _CustomWorkoutSessionScreenState();
}

class _CustomWorkoutSessionScreenState
    extends State<CustomWorkoutSessionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _started = false;
  String? _sessionId;
  DateTime? _startTime;
  final List<Map<String, dynamic>> _loggedSets = [];

  Exercise? _findExercise(String exerciseId) {
    try {
      return ExerciseData.getAllExercises()
          .firstWhere((e) => e.id == exerciseId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _startWorkout() async {
    final docRef = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('workouts')
        .add({
      'type': widget.workoutName,
      'source': 'custom_library',
      'customWorkoutId': widget.workoutId,
      'startedAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'sets': [],
      'totalSets': 0,
      'plannedExercises': widget.exercises,
    });

    setState(() {
      _started = true;
      _sessionId = docRef.id;
      _startTime = DateTime.now();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom workout started! 🔥')),
      );
    }
  }

  Future<void> _logSet(
      String exercise, double weight, String reps) async {
    final setData = {
      'exercise': exercise,
      'weight': weight,
      'reps': reps,
      'timestamp': DateTime.now().toIso8601String(),
    };

    setState(() => _loggedSets.add(setData));

    if (_sessionId != null) {
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('workouts')
          .doc(_sessionId)
          .update({
        'sets': FieldValue.arrayUnion([setData]),
        'totalSets': _loggedSets.length,
      });
    }
  }

  void _showLogSetDialog() {
    if (widget.exercises.isEmpty) return;

    Map<String, dynamic> selected = widget.exercises.first;
    final weightController = TextEditingController(text: '20');
    final repsController =
    TextEditingController(text: (selected['reps'] ?? '12').toString());
    int selectedSets = (selected['sets'] ?? 1) as int;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FitGenieTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final exerciseObj =
          _findExercise((selected['exerciseId'] ?? '').toString());

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🏋️ Log Set',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('Select Exercise',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: FitGenieTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        isExpanded: true,
                        value: selected,
                        dropdownColor: FitGenieTheme.cardDark,
                        items: widget.exercises.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item['name'] ?? 'Exercise'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() {
                            selected = value;
                            selectedSets = (value['sets'] ?? 1) as int;
                            repsController.text =
                                (value['reps'] ?? '12').toString();
                          });
                        },
                      ),
                    ),
                  ),

                  if (exerciseObj != null && exerciseObj.hasGif) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: exerciseObj.gifUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Container(
                          height: 120,
                          color: FitGenieTheme.background,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (c, u, e) => Container(
                          height: 120,
                          color: FitGenieTheme.background,
                          child: const Center(
                            child: Icon(Icons.fitness_center,
                                color: Colors.white24),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  const Text('Sets',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: ExerciseData.setsOptions.map((s) {
                      final sel = selectedSets == s;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedSets = s),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding:
                            const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: sel
                                  ? FitGenieTheme.primary
                                  : FitGenieTheme.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '$s',
                                style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : FitGenieTheme.muted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  const Text('Reps / Time',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: repsController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '12 or 45 sec',
                      filled: true,
                      fillColor: FitGenieTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Weight (kg)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '20',
                      suffixText: 'kg',
                      filled: true,
                      fillColor: FitGenieTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        for (int i = 0; i < selectedSets; i++) {
                          await _logSet(
                            (selected['name'] ?? 'Exercise').toString(),
                            double.tryParse(weightController.text) ?? 0,
                            repsController.text.trim().isEmpty
                                ? '12'
                                : repsController.text.trim(),
                          );
                        }
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FitGenieTheme.primary,
                      ),
                      child: const Text(
                        'Save Sets',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _finishWorkout() async {
    if (_sessionId == null) return;

    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inMinutes
        : 0;

    await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('workouts')
        .doc(_sessionId)
        .update({
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
          title: const Text('🎉 Workout Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Custom workout done! 💪'),
              const SizedBox(height: 16),
              Text('Sets logged: ${_loggedSets.length}'),
              Text('Duration: $duration min'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: FitGenieTheme.primary),
              child: const Text('Done',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FitGenieTheme.cardDark,
        title: const Text('Exit Workout?'),
        content: const Text('Save or discard your workout progress?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child:
            const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finishWorkout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Save & Exit',
                style: TextStyle(color: Colors.white)),
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
        title: Text('${widget.workoutName} 📚'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (_started && _loggedSets.isNotEmpty) {
              _confirmExit();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_started)
            TextButton(
              onPressed: _finishWorkout,
              child: const Text(
                'FINISH',
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FGCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.workoutName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.exercises.length} selected exercises',
                    style: TextStyle(color: FitGenieTheme.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (!_started)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startWorkout,
                  icon:
                  const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(
                    'Start Custom Workout',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FitGenieTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

            if (_started) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Workout Progress',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        StreamBuilder(
                          stream: Stream.periodic(
                              const Duration(seconds: 1)),
                          builder: (context, snapshot) {
                            final minutes = _startTime != null
                                ? DateTime.now()
                                .difference(_startTime!)
                                .inMinutes
                                : 0;
                            return Text(
                              '$minutes min',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            const Text(
              'Planned Exercises',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            ...widget.exercises.map((item) {
              final exercise =
              _findExercise((item['exerciseId'] ?? '').toString());

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: FGCard(
                  child: Row(
                    children: [
                      if (exercise != null && exercise.hasGif)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: exercise.gifUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            placeholder: (c, u) => Container(
                              width: 72,
                              height: 72,
                              color: FitGenieTheme.background,
                              child: const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (c, u, e) => Container(
                              width: 72,
                              height: 72,
                              color: FitGenieTheme.background,
                              child: const Icon(Icons.fitness_center,
                                  color: Colors.white24),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 72,
                          height: 72,
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
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? 'Exercise',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item['sets']} × ${item['reps']}',
                              style: TextStyle(
                                  color: FitGenieTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['bodyPart'] ?? '',
                              style: TextStyle(
                                  color: FitGenieTheme.muted,
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            if (_started) ...[
              const SizedBox(height: 18),
              const Text(
                'Logged Sets',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              if (_loggedSets.isEmpty)
                FGCard(
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 38, color: FitGenieTheme.muted),
                        const SizedBox(height: 8),
                        Text('No sets logged yet',
                            style:
                            TextStyle(color: FitGenieTheme.muted)),
                      ],
                    ),
                  ),
                )
              else
                ...List.generate(_loggedSets.length, (index) {
                  final set = _loggedSets[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: FGCard(
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color:
                              FitGenieTheme.primary.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: FitGenieTheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  set['exercise'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${set['weight']} kg × ${set['reps']}',
                                  style: TextStyle(
                                      color: FitGenieTheme.muted,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle,
                              color: Colors.green),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showLogSetDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Log Set',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FitGenieTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _finishWorkout,
                  icon: const Icon(Icons.check, color: Colors.green),
                  label: const Text(
                    'Finish Workout',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 16),
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