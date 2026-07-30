// lib/screens/meal_scanner_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app/fitgenie_theme.dart';
import '../core/app_strings.dart';
import '../services/ai_service.dart';
import '../services/open_food_facts_service.dart';
import 'dart:math' show min;

class MealScannerScreen extends StatefulWidget {
  const MealScannerScreen({super.key});

  @override
  State<MealScannerScreen> createState() => _MealScannerScreenState();
}

class _MealScannerScreenState extends State<MealScannerScreen> {
  final AIService _aiService = AIService();
  final OpenFoodFactsService _foodFactsService = OpenFoodFactsService();
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
      _showSnackBar(
        AppStrings.get('scanner_pick_error', params: {'error': e.toString()}),
        isError: true,
      );
    }
  }

  // ==========================================
  // 🤖 ANALYZE IMAGE (AI / Gemini)
  // ==========================================
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _analysis = null;
    });

    try {
      debugPrint('Starting image analysis...');
      final analysis = await _aiService.analyzeMealPhoto(_selectedImage!);
      debugPrint('Analysis complete: ${analysis.foodName}');

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Analysis error: $e');
      if (mounted) {
        setState(() {
          _error = AppStrings.get('scanner_error', params: {
            'error': e.toString().substring(0, min(50, e.toString().length))
          });
          _loading = false;
        });
      }
    }
  }

  // ==========================================
  // 📦 SCAN BARCODE (Open Food Facts)
  // ==========================================
  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _BarcodeScannerPage()),
    );

    if (barcode == null || barcode.isEmpty) return;

    setState(() {
      _selectedImage = null; // barcode result replaces any photo preview
      _loading = true;
      _error = null;
      _analysis = null;
    });

    try {
      debugPrint('Looking up barcode: $barcode');
      final result = await _foodFactsService.getProductByBarcode(barcode);

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _loading = false;
          _error = AppStrings.get('scanner_barcode_not_found');
        });
        return;
      }

      setState(() {
        _analysis = result;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Barcode lookup error: $e');
      if (mounted) {
        setState(() {
          _error = AppStrings.get('scanner_barcode_error');
          _loading = false;
        });
      }
    }
  }

  // ==========================================
  // ✅ SAVE TO CALORIES
  // ==========================================
  void _saveToCalories() {
    if (_analysis == null) return;

    // TODO: Save to Firestore/local storage
    Navigator.pop(context, _analysis);

    _showSnackBar(
      AppStrings.get('scanner_added', params: {
        'food': _analysis!.foodName,
        'calories': '${_analysis!.calories}',
      }),
      isError: false,
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? FitGenieTheme.error : FitGenieTheme.success,
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
        title: Text(AppStrings.get('scanner_title')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ==========================================
            // 🖼 IMAGE PREVIEW
            // ==========================================
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: FitGenieTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: FitGenieTheme.primary.withValues(alpha: 0.3),
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
                    _analysis != null ? Icons.qr_code_2 : Icons.restaurant_menu,
                    size: 80,
                    color: FitGenieTheme.muted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _analysis != null
                        ? AppStrings.get('scanner_barcode_found')
                        : AppStrings.get('scanner_placeholder'),
                    style: TextStyle(
                      color: FitGenieTheme.muted,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 🎛 CAMERA / GALLERY / BARCODE BUTTONS
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.camera_alt,
                    label: AppStrings.get('scanner_camera'),
                    color: FitGenieTheme.primary,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library,
                    label: AppStrings.get('scanner_gallery'),
                    color: FitGenieTheme.warning,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _ActionButton(
                icon: Icons.qr_code_scanner,
                label: AppStrings.get('scanner_scan_barcode'),
                color: FitGenieTheme.success,
                onTap: _scanBarcode,
              ),
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
                      AppStrings.get('scanner_loading'),
                      style: TextStyle(color: FitGenieTheme.muted),
                    ),
                  ],
                ),
              ),

            // ==========================================
            // ⚠️ ERROR STATE
            // ==========================================
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: FitGenieTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FitGenieTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: FitGenieTheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: FitGenieTheme.error),
                      ),
                    ),
                    if (_selectedImage != null)
                      IconButton(
                        icon: const Icon(Icons.refresh, color: FitGenieTheme.error),
                        onPressed: _analyzeImage,
                      ),
                  ],
                ),
              ),

            // ==========================================
            // 📊 ANALYSIS RESULT (shared by AI photo scan + barcode scan)
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
                  label: Text(
                    AppStrings.get('scanner_add'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
  // 🍽 ANALYSIS CARD
  // ==========================================
  Widget _buildAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FitGenieTheme.primary.withValues(alpha: 0.2),
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
              color: FitGenieTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🍲', style: TextStyle(fontSize: 32)),
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
                AppStrings.get('scanner_kcal'),
                style: TextStyle(color: FitGenieTheme.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📈 NUTRITION GRID
  // ==========================================
  Widget _buildNutritionGrid() {
    return Row(
      children: [
        _NutritionTile(
          label: AppStrings.get('scanner_protein'),
          value: '${_analysis!.protein}g',
          color: FitGenieTheme.error,
          icon: '💪',
        ),
        _NutritionTile(
          label: AppStrings.get('scanner_carbs'),
          value: '${_analysis!.carbs}g',
          color: FitGenieTheme.warning,
          icon: '🍞',
        ),
        _NutritionTile(
          label: AppStrings.get('scanner_fat'),
          value: '${_analysis!.fat}g',
          color: Colors.yellow,
          icon: '🧈',
        ),
        _NutritionTile(
          label: AppStrings.get('scanner_fiber'),
          value: '${_analysis!.fiber}g',
          color: FitGenieTheme.success,
          icon: '🌾',
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
            ? FitGenieTheme.success.withValues(alpha: 0.1)
            : FitGenieTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _analysis!.isHealthy
              ? FitGenieTheme.success.withValues(alpha: 0.3)
              : FitGenieTheme.warning.withValues(alpha: 0.3),
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
                color: _analysis!.isHealthy ? FitGenieTheme.success : FitGenieTheme.warning,
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
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
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

// ==========================================
// 📷 BARCODE SCANNER PAGE
// Full-screen camera view using mobile_scanner. Pops the first detected
// barcode value back to the caller.
// ==========================================
class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
  );
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    _handled = true;
    Navigator.pop(context, value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(AppStrings.get('scanner_barcode_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: FitGenieTheme.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              AppStrings.get('scanner_barcode_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}