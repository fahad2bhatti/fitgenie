// lib/screens/splash_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Main animations
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  // Animations
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _loadingFade;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    // Main controller for sequence
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Pulse controller for logo glow
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Rotate controller for loading
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo fade in (0.0 - 0.4)
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Logo scale with bounce (0.0 - 0.5)
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Text fade in (0.3 - 0.6)
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    // Text slide up (0.3 - 0.6)
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    // Tagline fade in (0.5 - 0.7)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.7, curve: Curves.easeOut),
      ),
    );

    // Loading fade in (0.6 - 0.8)
    _loadingFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    // Pulse animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimations() {
    _mainController.forward();
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();

    // Navigate after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF0D1117),
              Color(0xFF0A0A0F),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background particles/stars effect
            ..._buildBackgroundParticles(),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _mainController,
                  _pulseController,
                ]),
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Logo with glow effect (NO CIRCLE)
                      _buildLogo(),

                      const SizedBox(height: 40),

                      // App Name with slide animation
                      _buildAppName(),

                      const SizedBox(height: 12),

                      // Tagline
                      _buildTagline(),

                      const Spacer(flex: 2),

                      // Custom loading indicator
                      _buildLoadingIndicator(),

                      const SizedBox(height: 16),

                      // Loading text
                      _buildLoadingText(),

                      const SizedBox(height: 50),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🎨 BACKGROUND PARTICLES
  // ==========================================
  List<Widget> _buildBackgroundParticles() {
    return List.generate(20, (index) {
      final random = math.Random(index);
      final size = random.nextDouble() * 3 + 1;
      final left = random.nextDouble() * 400;
      final top = random.nextDouble() * 800;
      final opacity = random.nextDouble() * 0.5 + 0.1;

      return Positioned(
        left: left,
        top: top,
        child: FadeTransition(
          opacity: _logoFade,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: FitGenieTheme.primary.withOpacity(opacity),
              boxShadow: [
                BoxShadow(
                  color: FitGenieTheme.primary.withOpacity(opacity * 0.5),
                  blurRadius: size * 2,
                  spreadRadius: size * 0.5,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ==========================================
  // 🖼️ LOGO (NO CIRCLE, JUST LOGO WITH GLOW)
  // ==========================================
  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  // Glow effect behind logo (no circle border)
                  boxShadow: [
                    BoxShadow(
                      color: FitGenieTheme.primary.withOpacity(0.4),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: FitGenieTheme.primary.withOpacity(0.2),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/fitgenie_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon if logo not found
                    return ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          FitGenieTheme.primary,
                          FitGenieTheme.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 80,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // 📝 APP NAME
  // ==========================================
  Widget _buildAppName() {
    return FadeTransition(
      opacity: _textFade,
      child: SlideTransition(
        position: _textSlide,
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.white,
              FitGenieTheme.primary,
              Colors.white,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: const Text(
            'FitGenie',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 💬 TAGLINE
  // ==========================================
  Widget _buildTagline() {
    return FadeTransition(
      opacity: _taglineFade,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  FitGenieTheme.primary.withOpacity(0.5),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Your AI Fitness Coach',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
              letterSpacing: 2,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 30,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FitGenieTheme.primary.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ⏳ CUSTOM LOADING INDICATOR
  // ==========================================
  Widget _buildLoadingIndicator() {
    return FadeTransition(
      opacity: _loadingFade,
      child: AnimatedBuilder(
        animation: _rotateController,
        builder: (context, child) {
          return SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating ring
                Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: FitGenieTheme.primary.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _ArcPainter(
                        color: FitGenieTheme.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
                // Inner rotating ring (opposite direction)
                Transform.rotate(
                  angle: -_rotateController.value * 2 * math.pi,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: FitGenieTheme.primary.withOpacity(0.1),
                        width: 2,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _ArcPainter(
                        color: FitGenieTheme.primary.withOpacity(0.7),
                        strokeWidth: 2,
                        startAngle: math.pi,
                      ),
                    ),
                  ),
                ),
                // Center dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FitGenieTheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: FitGenieTheme.primary.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 📝 LOADING TEXT
  // ==========================================
  Widget _buildLoadingText() {
    return FadeTransition(
      opacity: _loadingFade,
      child: _AnimatedLoadingText(),
    );
  }
}

// ==========================================
// 🎨 ARC PAINTER FOR LOADING
// ==========================================
class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double startAngle;

  _ArcPainter({
    required this.color,
    required this.strokeWidth,
    this.startAngle = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, startAngle, math.pi * 0.7, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// ⏳ ANIMATED LOADING TEXT
// ==========================================
class _AnimatedLoadingText extends StatefulWidget {
  @override
  State<_AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<_AnimatedLoadingText> {
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _animateDots();
  }

  void _animateDots() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
        _animateDots();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;
    final spaces = ' ' * (3 - _dotCount);

    return Text(
      'Initializing$dots$spaces',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[500],
        letterSpacing: 1,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}