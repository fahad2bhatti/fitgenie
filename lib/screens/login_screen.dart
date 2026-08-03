// lib/screens/login_screen.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/fitgenie_theme.dart';
import '../core/app_strings.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

const String _kPrivacyPolicyUrl =
    'https://fahad2bhatti.github.io/fitgenie-privacy-policy/';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();

  bool loading = false;
  bool googleLoading = false;
  bool rememberMe = true;
  bool _showPassword = false;
  bool _agreedToTerms = false;

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ============================================
  // ? OPEN PRIVACY POLICY / TERMS
  // ============================================
  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(_kPrivacyPolicyUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showSnackBar(AppStrings.get('login_link_error'), isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(AppStrings.get('login_link_error'), isError: true);
      }
    }
  }

  // ============================================
  // ? LOGIN FUNCTION - SECURED
  // ============================================
  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();

    if (!_agreedToTerms) {
      _showSnackBar(AppStrings.get('login_terms_required'), isError: true);
      return;
    }

    // ? Basic validation in UI
    if (email.text.trim().isEmpty) {
      _showSnackBar(AppStrings.get('login_email_required'), isError: true);
      return;
    }
    if (password.text.isEmpty) {
      _showSnackBar(AppStrings.get('login_password_required'), isError: true);
      return;
    }

    setState(() => loading = true);

    try {
      debugPrint("? Login attempt: ${email.text.trim()}");

      final result = await auth.login(
        email.text.trim(),
        password.text,
      );

      if (!mounted) return;

      if (result.success) {
        debugPrint("? Login success: ${result.user?.uid}");
        // Navigation handled by AuthGate automatically
      } else {
        _showSnackBar(result.message, isError: true);
      }
    } catch (e) {
      debugPrint("? Unknown Error: $e");
      if (!mounted) return;
      _showSnackBar(AppStrings.get('login_generic_error'), isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ============================================
  // ? GOOGLE SIGN IN - SECURED
  // ============================================
  Future<void> _signInWithGoogle() async {
    if (!_agreedToTerms) {
      _showSnackBar(AppStrings.get('login_terms_required'), isError: true);
      return;
    }

    setState(() => googleLoading = true);

    try {
      debugPrint('? Starting Google Sign-in...');

      final result = await auth.signInWithGoogle();

      if (!mounted) return;

      if (result.success) {
        debugPrint('? Google Sign-in success: ${result.user?.uid}');
        _showSnackBar(result.message, isError: false);
        // Navigation handled by AuthGate automatically
      } else {
        _showSnackBar(result.message, isError: true);
      }
    } catch (e) {
      debugPrint('? Google Sign-in error: $e');
      if (!mounted) return;
      _showSnackBar(AppStrings.get('login_google_error'), isError: true);
    } finally {
      if (mounted) setState(() => googleLoading = false);
    }
  }

  // ============================================
  // ? SNACKBAR
  // ============================================
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? FitGenieTheme.error : FitGenieTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ============================================
  // ? GO TO SIGNUP
  // ============================================
  void _goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  // ============================================
  // ? FORGOT PASSWORD - SECURED
  // ============================================
  void _forgotPassword() {
    final emailText = email.text.trim();

    showDialog(
      context: context,
      builder: (context) {
        final resetEmailController = TextEditingController(text: emailText);

        return AlertDialog(
          backgroundColor: FitGenieTheme.card,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(AppStrings.get('login_reset_password')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.get('login_reset_instructions'),
                style: const TextStyle(color: FitGenieTheme.muted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: AppStrings.get('login_email_hint'),
                  hintStyle: const TextStyle(color: FitGenieTheme.muted),
                  filled: true,
                  fillColor: FitGenieTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.get('cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final emailInput = resetEmailController.text.trim();
                if (emailInput.isEmpty) {
                  return;
                }

                try {
                  final result = await auth.sendPasswordResetEmail(emailInput);

                  if (context.mounted) {
                    Navigator.pop(context);
                    _showSnackBar(result.message, isError: !result.success);
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showSnackBar(AppStrings.get('login_reset_failed'), isError: true);
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: FitGenieTheme.primary,
              ),
              child: Text(AppStrings.get('login_send')),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // ? BUILD UI
  // ============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0xFF0D1530), FitGenieTheme.bg],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: ConstrainedBox(
                      constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const SizedBox(height: 30),

                            // Logo
                            _buildLogo(),

                            const SizedBox(height: 20),
                            const Text(
                              // Brand name — not localized
                              'FitGenie',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.get('login_tagline'),
                              style: const TextStyle(
                                color: FitGenieTheme.muted,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Email Field
                            _buildTextField(
                              controller: email,
                              icon: Icons.mail_outline,
                              hint: AppStrings.get('login_email_hint'),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),

                            // Password Field
                            _buildTextField(
                              controller: password,
                              icon: Icons.lock_outline,
                              hint: AppStrings.get('login_password_hint'),
                              obscure: !_showPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: FitGenieTheme.muted,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                        () => _showPassword = !_showPassword),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Remember & Forgot
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: rememberMe,
                                    activeColor: FitGenieTheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (v) =>
                                        setState(() => rememberMe = v ?? true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.get('login_remember'),
                                  style: const TextStyle(
                                      color: FitGenieTheme.muted, fontSize: 12),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _forgotPassword,
                                  child: Text(
                                    AppStrings.get('login_forgot'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                )
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Terms & Privacy Policy agreement
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _agreedToTerms,
                                    activeColor: FitGenieTheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (v) =>
                                        setState(() => _agreedToTerms = v ?? false),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                            () => _agreedToTerms = !_agreedToTerms),
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: FitGenieTheme.muted,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                        children: [
                                          TextSpan(text: AppStrings.get('login_terms_prefix')),
                                          TextSpan(
                                            text: AppStrings.get('login_terms_link'),
                                            style: const TextStyle(
                                              color: FitGenieTheme.primary,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = _openPrivacyPolicy,
                                          ),
                                          TextSpan(text: AppStrings.get('login_terms_suffix')),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Sign In Button
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: (loading || !_agreedToTerms) ? null : _signIn,
                                style: FilledButton.styleFrom(
                                  backgroundColor: FitGenieTheme.primary,
                                  disabledBackgroundColor:
                                  FitGenieTheme.primary.withValues(alpha: 0.35),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: loading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : Text(
                                  AppStrings.get('login_button'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: Colors.white.withValues(alpha: 0.1))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    AppStrings.get('login_or'),
                                    style: const TextStyle(
                                        color: FitGenieTheme.muted,
                                        fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: Colors.white.withValues(alpha: 0.1))),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Google Sign-in Button
                            _GoogleSignInButton(
                              onTap: _signInWithGoogle,
                              loading: googleLoading,
                              enabled: _agreedToTerms,
                            ),

                            const SizedBox(height: 24),

                            // Sign Up Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.get('login_signup'),
                                  style: const TextStyle(
                                      color: FitGenieTheme.muted, fontSize: 13),
                                ),
                                TextButton(
                                  onPressed: _goToSignup,
                                  child: Text(
                                    AppStrings.get('login_signup_free'),
                                    style:
                                    const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // ?? LOGO WIDGET
  // ============================================
  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: FitGenieTheme.primary.withValues(alpha: 0.5),
            blurRadius: 100,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/fitgenie_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FitGenieTheme.primary,
                    FitGenieTheme.primary.withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 50,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================
  // ? TEXT FIELD WIDGET
  // ============================================
  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: FitGenieTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: FitGenieTheme.text),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: FitGenieTheme.muted),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: const TextStyle(color: FitGenieTheme.muted),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// ============================================
// ? GOOGLE SIGN-IN BUTTON
// ============================================
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;
  final bool enabled;

  const _GoogleSignInButton({
    required this.onTap,
    this.loading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: (loading || !enabled) ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black54,
                  ),
                )
              else ...[
                Image.network(
                  'https://www.google.com/favicon.ico',
                  height: 20,
                  width: 20,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.g_mobiledata,
                        color: FitGenieTheme.error, size: 24);
                  },
                ),
                const SizedBox(width: 10),
                Text(
                  AppStrings.get('login_google'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}