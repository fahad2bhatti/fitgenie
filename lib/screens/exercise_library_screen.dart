// lib/screens/exercise_library_screen.dart

import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';
import '../services/wger_service.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final WgerService _service = WgerService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<WgerCategory> _categories = [];
  List<WgerExercise> _exercises = [];
  List<WgerExercise> _filteredExercises = [];

  int? _selectedCategoryId; // null = "All"
  bool _loadingCategories = true;
  bool _loadingExercises = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final categories = await _service.getCategories();

    if (!mounted) return;
    setState(() {
      _categories = categories;
      _loadingCategories = false;
    });

    // Load "All" exercises by default (first page, general pool)
    _loadExercises(null);
  }

  Future<void> _loadExercises(int? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _loadingExercises = true;
      _error = null;
    });

    final exercises = await _service.getExercises(categoryId: categoryId, limit: 60);

    if (!mounted) return;

    setState(() {
      _exercises = exercises;
      _filteredExercises = exercises;
      _loadingExercises = false;
      if (exercises.isEmpty) {
        _error = 'Is category mein exercises nahi mile. Koi aur category try karo.';
      }
    });
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filteredExercises = q.isEmpty
          ? _exercises
          : _exercises.where((e) => e.name.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitGenieTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('🏋️ Exercise Library'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Exercise search karo...',
                hintStyle: TextStyle(color: FitGenieTheme.muted),
                prefixIcon: Icon(Icons.search, color: FitGenieTheme.muted),
                filled: true,
                fillColor: FitGenieTheme.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category chips
          if (_loadingCategories)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: _selectedCategoryId == null,
                    onTap: () => _loadExercises(null),
                  ),
                  const SizedBox(width: 8),
                  ..._categories.map(
                        (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        label: cat.name,
                        selected: _selectedCategoryId == cat.id,
                        onTap: () => _loadExercises(cat.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Exercise list
          Expanded(
            child: _loadingExercises
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: FitGenieTheme.muted),
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                return _ExerciseTile(
                  exercise: exercise,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExerciseDetailScreen(exercise: exercise),
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
}

// ==========================================
// 🏷️ CATEGORY CHIP
// ==========================================
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? FitGenieTheme.primary
              : FitGenieTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? FitGenieTheme.primary : FitGenieTheme.muted.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : FitGenieTheme.muted,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 🃏 EXERCISE TILE
// ==========================================
class _ExerciseTile extends StatelessWidget {
  final WgerExercise exercise;
  final VoidCallback onTap;

  const _ExerciseTile({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FitGenieTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FitGenieTheme.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FitGenieTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: exercise.imageUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  exercise.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.fitness_center,
                    color: FitGenieTheme.primary,
                  ),
                ),
              )
                  : const Icon(Icons.fitness_center, color: FitGenieTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.muscles.isNotEmpty
                        ? '${exercise.categoryName} • ${exercise.muscles.first}'
                        : exercise.categoryName,
                    style: TextStyle(color: FitGenieTheme.muted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: FitGenieTheme.muted),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 📄 EXERCISE DETAIL SCREEN
// ==========================================
class ExerciseDetailScreen extends StatelessWidget {
  final WgerExercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitGenieTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(exercise.name, style: const TextStyle(fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (exercise.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  exercise.imageUrl!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderImage(),
                ),
              )
            else
              _placeholderImage(),

            const SizedBox(height: 20),

            Text(
              exercise.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: FitGenieTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                exercise.categoryName,
                style: const TextStyle(color: FitGenieTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            if (exercise.muscles.isNotEmpty) ...[
              _sectionTitle('🎯 Primary Muscles'),
              _chipsRow(exercise.muscles, FitGenieTheme.primary),
              const SizedBox(height: 16),
            ],

            if (exercise.secondaryMuscles.isNotEmpty) ...[
              _sectionTitle('💪 Secondary Muscles'),
              _chipsRow(exercise.secondaryMuscles, FitGenieTheme.teal),
              const SizedBox(height: 16),
            ],

            if (exercise.equipment.isNotEmpty) ...[
              _sectionTitle('🛠️ Equipment'),
              _chipsRow(exercise.equipment, FitGenieTheme.warning),
              const SizedBox(height: 16),
            ],

            if (exercise.description.isNotEmpty) ...[
              _sectionTitle('📋 How to do it'),
              const SizedBox(height: 8),
              Text(
                exercise.description,
                style: TextStyle(color: FitGenieTheme.muted, fontSize: 14, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: FitGenieTheme.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(Icons.fitness_center, size: 64, color: FitGenieTheme.muted.withValues(alpha: 0.4)),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15));
  }

  Widget _chipsRow(List<String> items, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map(
              (item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(item, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        )
            .toList(),
      ),
    );
  }
}