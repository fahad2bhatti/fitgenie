// lib/screens/welcome_intro_screen.dart
//
// Shown ONCE — right after a brand-new user's first signup, before the
// onboarding data-collection wizard starts. Existing users never see this
// (gated by Firestore's `profileComplete` flag in main.dart's AuthGate, not
// a local SharedPreferences flag — so it also survives reinstalls tied to
// the same account).
//
// Two phases, matching the splash screen's animation language:
//   Phase 0 — FitGenie logo intro (scale + fade + slight rotation)
//   Phase 1 — tilted screenshot collage + headline + "Get Started"

import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';
import '../core/app_strings.dart';

// Real in-app screenshots used for the Phase 1 collage. Registered under
// assets/images/preview/ in pubspec.yaml.
const List<String> _kPreviewImages = [
  'assets/images/preview/preview_1.jpg',
  'assets/images/preview/preview_2.jpg',
  'assets/images/preview/preview_3.jpg',
  'assets/images/preview/preview_4.jpg',
  'assets/images/preview/preview_5.jpg',
  'assets/images/preview/preview_6.jpg',
  'assets/images/preview/preview_7.jpg',
];

class WelcomeIntroScreen extends StatefulWidget {
  final String userName;
  final VoidCallback onGetStarted;

  const WelcomeIntroScreen({
    super.key,
    required this.userName,
    required this.onGetStarted,
  });

  @override
  State<WelcomeIntroScreen> createState() => _WelcomeIntroScreenState();
}

class _WelcomeIntroScreenState extends State<WelcomeIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _shineController;
  late final AnimationController _introController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoRotation;
  late final Animation<double> _logoReveal; // circular "draw-in" mask 0→1

  late final Animation<double> _introOpacity;
  late final Animation<Offset> _introSlide;

  int _phase = 0;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Runs once, right after the logo has finished revealing — a soft
    // diagonal light sweep passing over the icon (the "polish" moment).
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Logo grows from a small dot into full size via a circular clip —
    // the closest honest Flutter equivalent of the video's "assembling"
    // logo, since that clip is a raster PNG rather than an SVG path.
    _logoReveal = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _logoRotation = Tween<double>(begin: -0.15, end: 0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _introOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeIn),
    );

    _introSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await _logoController.forward();
    if (!mounted) return;
    await _shineController.forward(); // shine sweep once logo has formed
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _phase = 1);
    await _introController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _shineController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitGenieTheme.bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _phase == 0 ? _buildLogoPhase() : _buildIntroPhase(),
        ),
      ),
    );
  }

  // ==========================================
  // PHASE 0 — Logo intro
  // Circular "draw-in" reveal (mimics the video's assembling logo,
  // adapted for a raster PNG instead of a traced SVG path) + a soft
  // diagonal shine sweep once it has fully formed.
  // ==========================================
  Widget _buildLogoPhase() {
    return Center(
      key: const ValueKey('logo'),
      child: AnimatedBuilder(
        animation: Listenable.merge([_logoController, _shineController]),
        builder: (context, child) {
          return Opacity(
            opacity: _logoOpacity.value,
            child: Transform.scale(
              scale: _logoScale.value,
              child: Transform.rotate(
                angle: _logoRotation.value,
                child: child,
              ),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_logoReveal, _shineController]),
              builder: (context, _) {
                return ClipPath(
                  clipper: _CircleRevealClipper(_logoReveal.value),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(FitGenieTheme.radiusXL),
                      boxShadow: [
                        BoxShadow(
                          color: FitGenieTheme.primary
                              .withValues(alpha: 0.35 * _logoReveal.value),
                          blurRadius: 35,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius:
                          BorderRadius.circular(FitGenieTheme.radiusXL),
                          child: Image.asset(
                            'assets/images/fitgenie_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        // Diagonal shine sweep, once, after the logo forms
                        if (_shineController.value > 0)
                          Positioned.fill(
                            child: ShaderMask(
                              blendMode: BlendMode.srcATop,
                              shaderCallback: (rect) {
                                final t = _shineController.value;
                                final dx = -1.4 + t * 2.8;
                                return LinearGradient(
                                  begin: Alignment(dx - 0.35, -1),
                                  end: Alignment(dx + 0.35, 1),
                                  colors: [
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.55),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.35, 0.5, 0.65],
                                ).createShader(rect);
                              },
                              child: const SizedBox.expand(),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            const Text(
              'FitGenie',
              style: TextStyle(
                color: FitGenieTheme.text,
                fontSize: 25,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.get('welcome_intro_tagline'),
              style: TextStyle(
                color: FitGenieTheme.muted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PHASE 1 — Tilted screenshot collage + Get Started
  // (Layout modeled on the reference video: a rotated grid of
  // screenshots up top, fading into a dark gradient, with the
  // headline + button anchored near the bottom.)
  // ==========================================
  Widget _buildIntroPhase() {
    return Stack(
      key: const ValueKey('intro'),
      children: [
        // Collage fills the whole screen behind everything else
        Positioned.fill(
          child: FadeTransition(
            opacity: _introOpacity,
            child: _ImageCollage(images: _kPreviewImages),
          ),
        ),

        // Dark gradient so the collage fades into the background
        // toward the bottom, keeping the text readable
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.45, 0.72, 1.0],
                  colors: [
                    FitGenieTheme.bg.withValues(alpha: 0.0),
                    FitGenieTheme.bg.withValues(alpha: 0.35),
                    FitGenieTheme.bg.withValues(alpha: 0.92),
                    FitGenieTheme.bg,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Headline + subtitle + button, pinned toward the bottom
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _introOpacity,
                  child: SlideTransition(
                    position: _introSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('welcome_intro_greeting',
                              params: {'name': widget.userName}),
                          style: const TextStyle(
                            color: FitGenieTheme.text,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppStrings.get('welcome_intro_subtitle'),
                          style: TextStyle(
                            color: FitGenieTheme.muted,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: widget.onGetStarted,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FitGenieTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    FitGenieTheme.radiusLG),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.get('welcome_get_started'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 20),
                              ],
                            ),
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
      ],
    );
  }
}

// ==========================================
// ✨ Circular reveal clip — logo "draws itself in" from the center
// outward as `fraction` goes 0 → 1.
// ==========================================
class _CircleRevealClipper extends CustomClipper<Path> {
  final double fraction;
  _CircleRevealClipper(this.fraction);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide * 0.75; // slightly over-scan corners
    final radius = maxRadius * fraction;
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant _CircleRevealClipper oldClipper) =>
      oldClipper.fraction != fraction;
}

// ==========================================
// ✨ Tilted screenshot collage — 3 columns, each rotated at a
// slightly different angle and vertically offset, like a photo
// wall. Pure Flutter, no external image/animation package.
// ==========================================
class _ImageCollage extends StatelessWidget {
  final List<String> images;
  const _ImageCollage({required this.images});

  @override
  Widget build(BuildContext context) {
    // Split the 7 screenshots across 3 columns.
    final col1 = [images[0], images[3]];
    final col2 = [images[1], images[4], images[6]];
    final col3 = [images[2], images[5]];

    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.rotate(
                angle: -0.10,
                child: Transform.translate(
                  offset: const Offset(10, 10),
                  child: _collageColumn(col1),
                ),
              ),
              Transform.rotate(
                angle: 0.07,
                child: Transform.translate(
                  offset: const Offset(0, -30),
                  child: _collageColumn(col2),
                ),
              ),
              Transform.rotate(
                angle: -0.08,
                child: Transform.translate(
                  offset: const Offset(-10, 15),
                  child: _collageColumn(col3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _collageColumn(List<String> paths) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: paths
          .map((p) => Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          width: 118,
          height: 235,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(p, fit: BoxFit.cover),
        ),
      ))
          .toList(),
    );
  }
}