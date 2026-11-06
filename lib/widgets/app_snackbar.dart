// lib/widgets/app_snackbar.dart
//
// Beech screen mein dark card, halki glow, smooth animation, aur neeche patli
// bar jo time ke saath khatam hoti hai. Error ka rang laal nahi, warm flame hai,
// aur lafz dhamkane wale nahi, dostana hain.
//
// Purane static methods ki tarah use hota hai:
//   AppSnackbar.showSuccess(context, 'Meal add ho gaya');
//   AppSnackbar.showError(context, 'Internet check karo');
//   AppSnackbar.showWarning(context, 'Pehle goal set karo');
//   AppSnackbar.showInfo(context, 'Sync ho raha hai');

import 'dart:async';

import 'package:flutter/material.dart';

import '../app/fitgenie_theme.dart';

enum _ToastKind { success, error, warning, info }

class AppSnackbar {
  AppSnackbar._();

  static OverlayEntry? _current;

  static void showSuccess(BuildContext context, String message,
          {String? title}) =>
      _show(context, _ToastKind.success, message, title);

  static void showError(BuildContext context, String message,
          {String? title}) =>
      _show(context, _ToastKind.error, _friendly(message), title);

  static void showWarning(BuildContext context, String message,
          {String? title}) =>
      _show(context, _ToastKind.warning, message, title);

  static void showInfo(BuildContext context, String message, {String? title}) =>
      _show(context, _ToastKind.info, message, title);

  /// Technical/lamba error (Exception, Firebase code wagera) user ko nahi dikhana.
  static String _friendly(String m) {
    final lower = m.toLowerCase();
    final looksTechnical = m.length > 90 ||
        lower.contains('exception') ||
        lower.contains('firebase') ||
        lower.contains('socketexception') ||
        lower.contains('[') ||
        lower.contains('null');
    return looksTechnical
        ? 'Kuch theek se nahi hua. Dobara try karo, sab safe hai.'
        : m;
  }

  static void _show(
    BuildContext context,
    _ToastKind kind,
    String message,
    String? title,
  ) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    dismiss();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        kind: kind,
        title: title,
        message: message,
        duration: const Duration(milliseconds: 3200),
        onClosed: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    _current?.remove();
    _current = null;
  }
}

class _ToastView extends StatefulWidget {
  final _ToastKind kind;
  final String? title;
  final String message;
  final Duration duration;
  final VoidCallback onClosed;

  const _ToastView({
    required this.kind,
    required this.title,
    required this.message,
    required this.duration,
    required this.onClosed,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 220),
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    await _c.reverse();
    widget.onClosed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  Color get _accent => switch (widget.kind) {
        _ToastKind.success => FitGenieTheme.primary,
        _ToastKind.error => FitGenieTheme.hot,
        _ToastKind.warning => FitGenieTheme.warning,
        _ToastKind.info => FitGenieTheme.teal,
      };

  IconData get _icon => switch (widget.kind) {
        _ToastKind.success => Icons.check_rounded,
        _ToastKind.error => Icons.refresh_rounded,
        _ToastKind.warning => Icons.priority_high_rounded,
        _ToastKind.info => Icons.info_outline_rounded,
      };

  String get _defaultTitle => switch (widget.kind) {
        _ToastKind.success => 'Ho gaya!',
        _ToastKind.error => 'Thora sa masla ho gaya',
        _ToastKind.warning => 'Zara dhyan se',
        _ToastKind.info => 'Note',
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final accent = _accent;

    final scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _c,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    final iconPop = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    );

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: FadeTransition(
          opacity: fade,
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.45),
            child: Center(
              child: ScaleTransition(
                scale: scale,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: FitGenieTheme.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.18),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ScaleTransition(
                                  scale: iconPop,
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.14),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(_icon, color: accent, size: 28),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.title ?? _defaultTitle,
                                  textAlign: TextAlign.center,
                                  style: t.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.message,
                                  textAlign: TextAlign.center,
                                  style: t.bodyMedium?.copyWith(
                                    color: FitGenieTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Flow: bar jo dheere dheere khatam hoti hai
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1, end: 0),
                            duration: widget.duration,
                            builder: (_, v, __) => LinearProgressIndicator(
                              value: v,
                              minHeight: 3,
                              backgroundColor: FitGenieTheme.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                accent.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
