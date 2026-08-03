// lib/screens/onboarding_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app/fitgenie_theme.dart';
import '../core/app_strings.dart';
import '../core/language_provider.dart';
import '../widgets/app_snackbar.dart';
import 'shell_screen.dart';


class OnboardingScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const OnboardingScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  final _firestore = FirebaseFirestore.instance;
  final _languageProvider = LanguageProvider();

  int _pageIndex = 0;
  bool _isSaving = false;

  // Collected data
  bool _selectedEnglish = true; // Page 0 — language
  String? _gender;
  int? _age;
  double? _height; // cm
  double? _weight; // kg
  String? _fitnessLevel;
  String? _goal;

  static const _totalPages = 6;

  @override
  void initState() {
    super.initState();
    _selectedEnglish = _languageProvider.isEnglish;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_pageIndex) {
      case 0:
        return true;
      case 1:
        return _gender != null;
      case 2:
        return _age != null;
      case 3:
        return _height != null && _weight != null;
      case 4:
        return _fitnessLevel != null;
      case 5:
        return _goal != null;
      default:
        return false;
    }
  }

  void _next() {
    if (!_canContinue) return;

    if (_pageIndex == 0) {
      _languageProvider.setLanguage(_selectedEnglish);
    }

    if (_pageIndex == _totalPages - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  void _back() {
    if (_pageIndex == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  Map<String, int> _calculateGoals() {
    final w = _weight!;
    final h = _height!;
    final a = _age!;

    double bmr;
    if (_gender == 'Male') {
      bmr = 10 * w + 6.25 * h - 5 * a + 5;
    } else if (_gender == 'Female') {
      bmr = 10 * w + 6.25 * h - 5 * a - 161;
    } else {
      bmr = 10 * w + 6.25 * h - 5 * a - 78;
    }

    double tdee = bmr * 1.55;

    int calories;
    double proteinPerKg;
    switch (_goal) {
      case 'Lose Weight':
        calories = (tdee - 500).round();
        proteinPerKg = 1.8;
        break;
      case 'Build Muscle':
      case 'Gain Strength':
        calories = (tdee + 300).round();
        proteinPerKg = 2.0;
        break;
      default:
        calories = tdee.round();
        proteinPerKg = 1.6;
    }

    final protein = (w * proteinPerKg).round();
    final fats = ((calories * 0.25) / 9).round();
    final carbs = ((calories - (protein * 4) - (fats * 9)) / 4).round();

    return {
      'caloriesGoal': calories.clamp(1200, 4500),
      'proteinGoal': protein,
      'carbsGoal': carbs.clamp(50, 600),
      'fatsGoal': fats.clamp(20, 200),
      'waterGoal': 8,
    };
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);

    try {
      final goals = _calculateGoals();

      await _firestore.collection('users').doc(widget.userId).set({
        'gender': _gender,
        'age': _age,
        'height': _height,
        'weight': _weight,
        'fitnessLevel': _fitnessLevel,
        'goal': _goal,
        'profileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('goals')
          .doc('main')
          .set({
        ...goals,
        'stepsGoal': 10000,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ShellScreen(
            userId: widget.userId,
            userName: widget.userName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackbar.showError(
        context,
        'Kuch masla ho gaya: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitGenieTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _pageIndex = i),
                children: [
                  _AnimatedPage(child: _languagePage()),
                  _AnimatedPage(child: _genderPage()),
                  _AnimatedPage(child: _agePage()),
                  _AnimatedPage(child: _bodyStatsPage()),
                  _AnimatedPage(child: _fitnessLevelPage()),
                  _AnimatedPage(child: _goalPage()),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HEADER — greeting + progress
  // ==========================================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get('onboarding_welcome',
                    params: {'name': widget.userName}),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: FitGenieTheme.text,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  '${_pageIndex + 1}/$_totalPages',
                  key: ValueKey(_pageIndex),
                  style: const TextStyle(color: FitGenieTheme.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.onboardingSubtitle,
            style: const TextStyle(color: FitGenieTheme.muted, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(_totalPages, (i) {
              final active = i <= _pageIndex;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.only(right: i == _totalPages - 1 ? 0 : 6),
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? FitGenieTheme.primary
                        : FitGenieTheme.card2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PAGE 0 — Language Selection
  // ==========================================
  Widget _languagePage() {
    return _pageWrapper(
      title: AppStrings.get('language_select_title'),
      subtitle: 'You can change this later in Settings',
      child: Column(
        children: [
          _selectableCard(
            label: AppStrings.get('language_english'),
            description: 'Everything in English',
            icon: Icons.language,
            selected: _selectedEnglish,
            onTap: () => setState(() => _selectedEnglish = true),
          ),
          const SizedBox(height: 12),
          _selectableCard(
            label: AppStrings.get('language_urdu'),
            description: 'Roman Urdu mein',
            icon: Icons.language,
            selected: !_selectedEnglish,
            onTap: () => setState(() => _selectedEnglish = false),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PAGE 1 — Gender
  // ==========================================
  Widget _genderPage() {
    final options = [
      {'label': 'Male', 'icon': Icons.male},
      {'label': 'Female', 'icon': Icons.female},
      {'label': 'Other', 'icon': Icons.person},
    ];

    return _pageWrapper(
      title: AppStrings.onboardingGender,
      subtitle: AppStrings.onboardingGenderSub,
      child: Column(
        children: options.map((o) {
          final selected = _gender == o['label'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _selectableCard(
              label: o['label'] as String,
              icon: o['icon'] as IconData,
              selected: selected,
              onTap: () => setState(() => _gender = o['label'] as String),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // PAGE 2 — Age
  // ==========================================
  Widget _agePage() {
    final age = _age ?? 25;
    return _pageWrapper(
      title: AppStrings.onboardingAge,
      subtitle: AppStrings.onboardingAgeSub,
      child: Column(
        children: [
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: child,
            ),
            child: Text(
              '$age',
              key: ValueKey(age),
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: FitGenieTheme.primary,
              ),
            ),
          ),
          const Text('saal', style: TextStyle(color: FitGenieTheme.muted)),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: FitGenieTheme.primary,
              inactiveTrackColor: FitGenieTheme.card2,
              thumbColor: FitGenieTheme.primary,
              overlayColor: FitGenieTheme.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: age.toDouble(),
              min: 13,
              max: 80,
              divisions: 67,
              onChanged: (v) => setState(() => _age = v.round()),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PAGE 3 — Height + Weight
  // ==========================================
  Widget _bodyStatsPage() {
    final height = _height ?? 170.0;
    final weight = _weight ?? 65.0;

    return _pageWrapper(
      title: AppStrings.onboardingHeight,
      subtitle: AppStrings.onboardingHeightSub,
      child: Column(
        children: [
          _statSliderCard(
            label: 'Height',
            value: height,
            unit: 'cm',
            min: 120,
            max: 220,
            onChanged: (v) => setState(() => _height = v),
          ),
          const SizedBox(height: 20),
          _statSliderCard(
            label: 'Weight',
            value: weight,
            unit: 'kg',
            min: 30,
            max: 180,
            onChanged: (v) => setState(() => _weight = v),
          ),
        ],
      ),
    );
  }

  Widget _statSliderCard({
    required String label,
    required double value,
    required String unit,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FitGenieTheme.card,
        borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: FitGenieTheme.muted)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '${value.toStringAsFixed(0)} $unit',
                  key: ValueKey(value),
                  style: const TextStyle(
                    color: FitGenieTheme.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: FitGenieTheme.teal,
              inactiveTrackColor: FitGenieTheme.card2,
              thumbColor: FitGenieTheme.teal,
              overlayColor: FitGenieTheme.teal.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PAGE 4 — Fitness Level
  // ==========================================
  Widget _fitnessLevelPage() {
    final levels = [
      {'label': 'Beginner', 'desc': 'Abhi shuru kar raha/rahi hoon'},
      {'label': 'Intermediate', 'desc': 'Kuch mahino se active hoon'},
      {'label': 'Advanced', 'desc': 'Regular training kar raha/rahi hoon'},
    ];

    return _pageWrapper(
      title: AppStrings.onboardingLevel,
      subtitle: AppStrings.onboardingLevelSub,
      child: Column(
        children: levels.map((l) {
          final selected = _fitnessLevel == l['label'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _selectableCard(
              label: l['label'] as String,
              description: l['desc'] as String,
              icon: Icons.fitness_center,
              selected: selected,
              onTap: () =>
                  setState(() => _fitnessLevel = l['label'] as String),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // PAGE 5 — Goal
  // ==========================================
  Widget _goalPage() {
    final goals = [
      {'label': 'Lose Weight', 'icon': Icons.trending_down},
      {'label': 'Build Muscle', 'icon': Icons.fitness_center},
      {'label': 'Stay Fit', 'icon': Icons.favorite},
      {'label': 'Gain Strength', 'icon': Icons.bolt},
    ];

    return _pageWrapper(
      title: AppStrings.onboardingGoal,
      subtitle: AppStrings.onboardingGoalSub,
      child: Column(
        children: goals.map((g) {
          final selected = _goal == g['label'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _selectableCard(
              label: g['label'] as String,
              icon: g['icon'] as IconData,
              selected: selected,
              onTap: () => setState(() => _goal = g['label'] as String),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // Shared widgets
  // ==========================================
  Widget _pageWrapper({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: FitGenieTheme.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: FitGenieTheme.muted, fontSize: 14),
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }

  // ✨ Selectable card with smooth scale-on-tap feedback
  Widget _selectableCard({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    String? description,
  }) {
    return _TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? FitGenieTheme.primary.withValues(alpha: 0.15)
              : FitGenieTheme.card,
          borderRadius: BorderRadius.circular(FitGenieTheme.radiusLG),
          border: Border.all(
            color: selected ? FitGenieTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedRotation(
              duration: const Duration(milliseconds: 220),
              turns: selected ? 0.02 : 0,
              child: Icon(
                icon,
                color: selected ? FitGenieTheme.primary : FitGenieTheme.muted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? FitGenieTheme.text
                          : FitGenieTheme.text.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        description,
                        style: const TextStyle(
                          color: FitGenieTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: child,
              ),
              child: selected
                  ? const Icon(
                Icons.check_circle,
                key: ValueKey('checked'),
                color: FitGenieTheme.primary,
              )
                  : const SizedBox.shrink(key: ValueKey('unchecked')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          if (_pageIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _back,
                child: Text(AppStrings.onboardingBack),
              ),
            ),
          if (_pageIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (!_canContinue || _isSaving) ? null : _next,
              child: _isSaving
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
                  : Text(
                _pageIndex == _totalPages - 1
                    ? AppStrings.onboardingStart
                    : AppStrings.onboardingNext,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ✨ NEW — Entrance animation wrapper for each page
// Fade + slight upward slide when a page appears
// ==========================================
class _AnimatedPage extends StatefulWidget {
  final Widget child;
  const _AnimatedPage({required this.child});

  @override
  State<_AnimatedPage> createState() => _AnimatedPageState();
}

class _AnimatedPageState extends State<_AnimatedPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// ==========================================
// ✨ NEW — Tap scale-down feedback for selectable cards
// ==========================================
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScale({required this.child, required this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  double _scale = 1.0;

  void _setScale(double value) => setState(() => _scale = value);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setScale(0.97),
      onTapUp: (_) => _setScale(1.0),
      onTapCancel: () => _setScale(1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}