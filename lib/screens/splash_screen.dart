// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';
import '../core/app_strings.dart';
import '../widgets/medical_disclaimer.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // auth-v2
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _loadingFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    Animation<double> fade(double a, double b) =>
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(a, b, curve: Curves.easeOut),
          ),
        );

    _logoFade = fade(0.0, 0.25);
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack),
      ),
    );
    _textFade = fade(0.2, 0.45);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.45, curve: Curves.easeOut),
      ),
    );
    _taglineFade = fade(0.4, 0.6);
    _loadingFade = fade(0.5, 0.7);

    _controller.forward();

    // Navigate after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () async {
      if (!mounted) return;
      await MedicalDisclaimerDialog.showIfNeeded(context);
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: FitGenieTheme.bg,
      body: SizedBox.expand(
        child: Column(
          children: [
            const Spacer(flex: 3),
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Image.asset(
                  'assets/images/fitgenie_logo.png',
                  width: 130,
                  height: 130,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.fitness_center,
                    size: 72,
                    color: FitGenieTheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _textFade,
              child: SlideTransition(
                position: _textSlide,
                child: Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(
                        text: 'FIT',
                        style: TextStyle(color: FitGenieTheme.primary),
                      ),
                      TextSpan(text: 'GENIE'),
                    ],
                  ),
                  style: t.displayLarge?.copyWith(
                    fontSize: 56,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FadeTransition(
              opacity: _taglineFade,
              child: Text(
                AppStrings.get('splash_tagline').toUpperCase(),
                style: t.labelSmall?.copyWith(letterSpacing: 2),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(flex: 3),
            FadeTransition(
              opacity: _loadingFade,
              child: Column(
                children: [
                  SizedBox(
                    width: 120,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _controller.value,
                          minHeight: 3,
                          backgroundColor: FitGenieTheme.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              FitGenieTheme.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppStrings.get('splash_initializing').toUpperCase(),
                    style: t.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🎨 ARC PAINTER FOR LOADING
// ==========================================

// ==========================================
// ⏳ ANIMATED LOADING TEXT
// ==========================================
