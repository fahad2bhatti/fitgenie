// lib/screens/meal_scanner_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app/fitgenie_theme.dart';
import '../core/app_strings.dart';
import '../services/ai_service.dart';
import '../services/open_food_facts_service.dart';
import '../widgets/medical_disclaimer.dart';
import 'dart:math' show min;

class MealScannerScreen extends StatefulWidget {
  const MealScannerScreen({super.key});

  @override
  State<MealScannerScreen> createState() => _MealScannerScreenState();
}

class _MealScannerScreenState extends State<MealScannerScreen>
    with SingleTickerProviderStateMixin {
  final AIService _aiService = AIService();
  final OpenFoodFactsService _foodFactsService = OpenFoodFactsService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  MealAnalysis? _analysis;
  bool _loading = false;
  String? _error;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ==========================================
  // 📸 PICK IMAGE
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
  // 🔍 SCAN BARCODE (Open Food Facts)
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: FitGenieTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.document_scanner,
                  color: FitGenieTheme.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text(AppStrings.get('scanner_title')),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          children: [
            // ==========================================
            // 🎯 SCAN FRAME / IMAGE PREVIEW
            // ==========================================
            _buildScanFrame(),

            const SizedBox(height: 22),

            // ==========================================
            // 🎛️ CAMERA / GALLERY / BARCODE BUTTONS
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: AppStrings.get('scanner_camera'),
                    color: FitGenieTheme.primary,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library_rounded,
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
                icon: Icons.qr_code_scanner_rounded,
                label: AppStrings.get('scanner_scan_barcode'),
                color: FitGenieTheme.success,
                onTap: _scanBarcode,
              ),
            ),

            const SizedBox(height: 20),
            const MedicalDisclaimerBanner(compact: true),
            const SizedBox(height: 8),

            // ==========================================
            // ⏳ LOADING STATE
            // ==========================================
            if (_loading) ...[
              const SizedBox(height: 12),
              _buildLoadingCard(),
            ],

            // ==========================================
            // ⚠️ ERROR STATE
            // ==========================================
            if (_error != null) ...[
              const SizedBox(height: 12),
              _buildErrorCard(),
            ],

            // ==========================================
            // 📊 ANALYSIS RESULT
            // ==========================================
            if (_analysis != null) ...[
              const SizedBox(height: 16),
              _buildAnalysisCard(),
              const SizedBox(height: 16),
              _buildNutritionGrid(),
              const SizedBox(height: 16),
              _buildHealthTip(),
              const SizedBox(height: 24),
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
  // 🎯 SCAN FRAME (signature visual)
  // Camera-viewfinder style corners around the preview, with a
  // pulsing glow badge when idle — reinforces "AI is scanning" feel.
  // ==========================================
  Widget _buildScanFrame() {
    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [FitGenieTheme.card, FitGenieTheme.card2],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                : _buildEmptyPreview(),
          ),
        ),

        // Corner brackets — always visible, camera-viewfinder style
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ScanCornersPainter(
                color: _analysis != null
                    ? FitGenieTheme.success
                    : FitGenieTheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnim.value,
              child: child,
            ),
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    FitGenieTheme.primary.withValues(alpha: 0.28),
                    FitGenieTheme.teal.withValues(alpha: 0.16),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: FitGenieTheme.primary.withValues(alpha: 0.28),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 40,
                color: FitGenieTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            AppStrings.get('scanner_placeholder'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Camera se click karo ya gallery se pick karo',
            style: TextStyle(color: FitGenieTheme.muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FitGenieTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FitGenieTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: FitGenieTheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppStrings.get('scanner_loading'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
            FitGenieTheme.primary.withValues(alpha: 0.18),
            FitGenieTheme.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FitGenieTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FitGenieTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('🍛', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _analysis!.foodName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _analysis!.foodNameHindi,
                  style: TextStyle(color: FitGenieTheme.muted, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: FitGenieTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _analysis!.quantity,
                    style: const TextStyle(color: FitGenieTheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                '${_analysis!.calories}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: FitGenieTheme.primary,
                ),
              ),
              Text(
                AppStrings.get('scanner_kcal'),
                style: TextStyle(color: FitGenieTheme.muted, fontSize: 11),
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
          label: AppStrings.get('scanner_protein'),
          value: '${_analysis!.protein}g',
          color: FitGenieTheme.error,
          icon: Icons.egg_alt_rounded,
        ),
        _NutritionTile(
          label: AppStrings.get('scanner_carbs'),
          value: '${_analysis!.carbs}g',
          color: FitGenieTheme.warning,
          icon: Icons.grain_rounded,
        ),
        _NutritionTile(
          label: AppStrings.get('scanner_fat'),
          value: '${_analysis!.fat}g',
          color: Colors.amber,
          icon: Icons.opacity_rounded,
        ),
        _NutritionTile(
          label: AppStrings.get('scanner_fiber'),
          value: '${_analysis!.fiber}g',
          color: FitGenieTheme.success,
          icon: Icons.eco_rounded,
        ),
      ],
    );
  }

  // ==========================================
  // 💡 HEALTH TIP
  // ==========================================
  Widget _buildHealthTip() {
    final healthy = _analysis!.isHealthy;
    final tone = healthy ? FitGenieTheme.success : FitGenieTheme.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              healthy ? Icons.check_circle_rounded : Icons.info_rounded,
              color: tone,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _analysis!.healthTip,
              style: TextStyle(color: tone, fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 🖼️ SCAN CORNERS PAINTER (signature element)
// ==========================================
class _ScanCornersPainter extends CustomPainter {
  final Color color;

  _ScanCornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const len = 26.0;
    const inset = 16.0;

    // Top-left
    canvas.drawLine(const Offset(inset, inset + len), const Offset(inset, inset), paint);
    canvas.drawLine(const Offset(inset, inset), const Offset(inset + len, inset), paint);

    // Top-right
    canvas.drawLine(Offset(size.width - inset, inset + len), Offset(size.width - inset, inset), paint);
    canvas.drawLine(Offset(size.width - inset, inset), Offset(size.width - inset - len, inset), paint);

    // Bottom-left
    canvas.drawLine(Offset(inset, size.height - inset - len), Offset(inset, size.height - inset), paint);
    canvas.drawLine(Offset(inset, size.height - inset), Offset(inset + len, size.height - inset), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - inset, size.height - inset - len), Offset(size.width - inset, size.height - inset), paint);
    canvas.drawLine(Offset(size.width - inset, size.height - inset), Offset(size.width - inset - len, size.height - inset), paint);
  }

  @override
  bool shouldRepaint(covariant _ScanCornersPainter oldDelegate) => oldDelegate.color != color;
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
// 🥗 NUTRITION TILE
// ==========================================
class _NutritionTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: FitGenieTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: FitGenieTheme.muted,
                fontSize: 10.5,
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