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
  late final AnimationController _introController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

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

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _phase = 1);
    await _introController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
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
    // auth-v2
    final t = Theme.of(context).textTheme;
    return Center(
      key: const ValueKey('logo'),
      child: AnimatedBuilder(
        animation: _logoController,
        builder: (context, child) {
          return Opacity(
            opacity: _logoOpacity.value,
            child: Transform.scale(scale: _logoScale.value, child: child),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/fitgenie_logo.png',
              width: 110,
              height: 110,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 22),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: 'FIT',
                    style: TextStyle(color: FitGenieTheme.primary),
                  ),
                  TextSpan(text: 'GENIE'),
                ],
              ),
              style: t.displaySmall?.copyWith(letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.get('welcome_intro_tagline').toUpperCase(),
              style: t.labelSmall,
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
    final t = Theme.of(context).textTheme;

    return Stack(
      key: const ValueKey('intro'),
      children: [
        // Collage poori screen ke peeche
        Positioned.fill(
          child: FadeTransition(
            opacity: _introOpacity,
            child: _ImageCollage(images: _kPreviewImages),
          ),
        ),

        // Neeche ki taraf andhera gradient, taake text saaf parha jaye
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

        // Headline + subtitle + button
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
                          (widget.userName.trim().isEmpty
                                  ? AppStrings.get('welcome_back_generic')
                                  : AppStrings.get('welcome_intro_greeting',
                                      params: {'name': widget.userName}))
                              .toUpperCase(),
                          style: t.displaySmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppStrings.get('welcome_intro_subtitle'),
                          style: const TextStyle(
                            color: FitGenieTheme.muted,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: widget.onGetStarted,
                            child: Text(
                              AppStrings.get('welcome_get_started')
                                  .toUpperCase(),
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
// ✨ Tilted screenshot collage — 3 columns, each rotated at a
// slightly different angle and vertically offset, like a photo
// wall. Pure Flutter, no external image/animation package.
// ==========================================
// ==========================================
// Screenshot collage: 3 upright columns, gently staggered.
// No rotation, no overlap, flat tiles (border token, no shadow).
// Replace the old `_ImageCollage` class with this one.
// ==========================================
// ==========================================
// Screenshot collage: 3 upright columns that scroll upward in a
// seamless loop (new screens keep coming up from the bottom).
// Replace the current `_ImageCollage` class with this one.
// ==========================================
class _ImageCollage extends StatefulWidget {
  final List<String> images;
  const _ImageCollage({required this.images});

  @override
  State<_ImageCollage> createState() => _ImageCollageState();
}

class _ImageCollageState extends State<_ImageCollage>
    with SingleTickerProviderStateMixin {
  static const double _gap = 10;
  static const double _sidePadding = 18;

  // Har column alag screenshot se shuru hota hai aur halka vertical shift
  // (tile ke hisse mein), taake teeno columns ki rows barabar na dikhen.
  static const List<int> _startIndex = [0, 3, 5];
  static const List<double> _startShift = [0, 0.5, 0.25];

  // Ek poora loop kitni der mein. Zyada = dheema scroll.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 50),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final still = MediaQuery.disableAnimationsOf(context);

    final tileWidth = (width - _sidePadding * 2 - _gap * 2) / 3;
    final tileHeight = tileWidth * 2.05;
    final stride = tileHeight + _gap;
    final loopHeight = stride * widget.images.length;

    return Stack(
      children: [
        Positioned.fill(
          child: ClipRect(
            child: OverflowBox(
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: _gap,
                  children: [
                    for (var i = 0; i < 3; i++)
                      _scrollingColumn(
                        index: i,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                        stride: stride,
                        loopHeight: loopHeight,
                        dpr: dpr,
                        still: still,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Upar ka hard cut chhupane ke liye halka fade
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 70,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    FitGenieTheme.bg,
                    FitGenieTheme.bg.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _scrollingColumn({
    required int index,
    required double tileWidth,
    required double tileHeight,
    required double stride,
    required double loopHeight,
    required double dpr,
    required bool still,
  }) {
    final n = widget.images.length;

    // Saari screenshots do baar: jab pehla set poora upar chala jata hai
    // to doosra set bilkul usi jagah hota hai, is liye loop mein jhatka nahi.
    final strip = Column(
      mainAxisSize: MainAxisSize.min,
      spacing: _gap,
      children: [
        for (var k = 0; k < n * 2; k++)
          _tile(
            widget.images[(_startIndex[index] + k) % n],
            tileWidth,
            tileHeight,
            dpr,
          ),
      ],
    );

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: strip,
        builder: (context, child) {
          final t = still ? 0.0 : _controller.value;
          final dy =
              (t * loopHeight + _startShift[index] * stride) % loopHeight;
          return Transform.translate(offset: Offset(0, -dy), child: child);
        },
      ),
    );
  }

  Widget _tile(String path, double width, double height, double dpr) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
        border: Border.all(color: FitGenieTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        cacheWidth: (width * dpr).round(),
      ),
    );
  }
}
