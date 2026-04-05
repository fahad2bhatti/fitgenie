// lib/screens/meal_scanner_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app/fitgenie_theme.dart';
import '../services/ai_service.dart';
import 'dart:math' show min;

class MealScannerScreen extends StatefulWidget {
  const MealScannerScreen({super.key});

  @override
  State<MealScannerScreen> createState() => _MealScannerScreenState();
}

class _MealScannerScreenState extends State<MealScannerScreen> {
  final AIService _aiService = AIService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  MealAnalysis? _analysis;
  bool _loading = false;
  String? _error;

  // ==========================================
  // 📷 PICK IMAGE
  // ==========================================
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysis = null;
          _error = null;
        });

        // Auto analyze
        _analyzeImage();
      }
    } catch (e) {
      _showSnackBar('Image pick nahi ho payi: $e', isError: true);
    }
  }

  // ==========================================
// 🤖 ANALYZE IMAGE - UPDATED
// ==========================================
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _analysis = null;
    });

    try {
      debugPrint('🔄 Starting image analysis...');
      final analysis = await _aiService.analyzeMealPhoto(_selectedImage!);
      debugPrint('✅ Analysis complete: ${analysis.foodName}');

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Analysis error: $e');
      if (mounted) {
        setState(() {
          _error = 'Analysis fail ho gayi: ${e.toString().substring(0, min(50, e.toString().length))}';
          _loading = false;
        });
      }
    }
  }
  // ==========================================
  // 💾 SAVE TO CALORIES
  // ==========================================
  void _saveToCalories() {
    if (_analysis == null) return;

    // TODO: Save to Firestore/local storage
    Navigator.pop(context, _analysis);

    _showSnackBar(
      '${_analysis!.foodName} added! (+${_analysis!.calories} cal)',
      isError: false,
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitGenieTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('🍽️ Meal Scanner'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ==========================================
            // 📷 IMAGE PREVIEW
            // ==========================================
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: FitGenieTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: FitGenieTheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: FitGenieTheme.muted.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Khana ki photo lo ya select karo',
                    style: TextStyle(
                      color: FitGenieTheme.muted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 📷 CAMERA & GALLERY BUTTONS
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: FitGenieTheme.primary,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.orange,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==========================================
            // ⏳ LOADING STATE
            // ==========================================
            if (_loading)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: FitGenieTheme.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      color: FitGenieTheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI analyze kar raha hai... 🤖',
                      style: TextStyle(color: FitGenieTheme.muted),
                    ),
                  ],
                ),
              ),

            // ==========================================
            // ❌ ERROR STATE
            // ==========================================
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.red),
                      onPressed: _analyzeImage,
                    ),
                  ],
                ),
              ),

            // ==========================================
            // ✅ ANALYSIS RESULT
            // ==========================================
            if (_analysis != null) ...[
              _buildAnalysisCard(),
              const SizedBox(height: 16),
              _buildNutritionGrid(),
              const SizedBox(height: 16),
              _buildHealthTip(),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveToCalories,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add to Today\'s Calories',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: FitGenieTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🍽️ ANALYSIS CARD
  // ==========================================
  Widget _buildAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FitGenieTheme.primary.withOpacity(0.2),
            FitGenieTheme.card,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FitGenieTheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🍽️', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _analysis!.foodName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _analysis!.foodNameHindi,
                  style: TextStyle(
                    color: FitGenieTheme.muted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _analysis!.quantity,
                  style: TextStyle(
                    color: FitGenieTheme.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${_analysis!.calories}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: FitGenieTheme.primary,
                ),
              ),
              Text(
                'kcal',
                style: TextStyle(color: FitGenieTheme.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📊 NUTRITION GRID
  // ==========================================
  Widget _buildNutritionGrid() {
    return Row(
      children: [
        _NutritionTile(
          label: 'Protein',
          value: '${_analysis!.protein}g',
          color: Colors.red,
          icon: '🥩',
        ),
        _NutritionTile(
          label: 'Carbs',
          value: '${_analysis!.carbs}g',
          color: Colors.orange,
          icon: '🍚',
        ),
        _NutritionTile(
          label: 'Fat',
          value: '${_analysis!.fat}g',
          color: Colors.yellow,
          icon: '🧈',
        ),
        _NutritionTile(
          label: 'Fiber',
          value: '${_analysis!.fiber}g',
          color: Colors.green,
          icon: '🥬',
        ),
      ],
    );
  }

  // ==========================================
  // 💡 HEALTH TIP
  // ==========================================
  Widget _buildHealthTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _analysis!.isHealthy
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _analysis!.isHealthy
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            _analysis!.isHealthy ? '✅' : '⚠️',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _analysis!.healthTip,
              style: TextStyle(
                color: _analysis!.isHealthy ? Colors.green : Colors.orange,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 🔘 ACTION BUTTON
// ==========================================
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 📊 NUTRITION TILE
// ==========================================
class _NutritionTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String icon;

  const _NutritionTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: FitGenieTheme.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
        ),
      ),
    );
  }
}