// lib/screens/signup_screen.dart

import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';
import '../core/app_strings.dart';
import '../widgets/app_snackbar.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _agreeToTerms = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String? _validateInputsQuick() {
    if (_nameController.text.trim().isEmpty) {
      return AppStrings.get('error_empty');
    }
    if (_emailController.text.trim().isEmpty) {
      return AppStrings.get('error_invalid_email');
    }
    if (_passwordController.text.isEmpty) {
      return AppStrings.get('error_invalid_password');
    }
    if (_confirmPasswordController.text.isEmpty) {
      return 'Please confirm your password.';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Passwords do not match.';
    }
    if (!_agreeToTerms) {
      return 'Please accept the Terms & Conditions.';
    }
    return null;
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    final quickError = _validateInputsQuick();
    if (quickError != null) {
      AppSnackbar.showError(context, quickError);
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await _auth.signUpWithName(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        AppSnackbar.showSuccess(context, result.message);
        // AuthGate handles navigation automatically
      } else {
        AppSnackbar.showError(context, result.message);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          AppStrings.get('error_unknown'),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ NAYA:
  void _goToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // auth-v2
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: FitGenieTheme.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight - 32),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back
                          IconButton(
                            onPressed: _goToLogin,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 20),
                          ),
                          const SizedBox(height: 8),
                          _buildLogo(),
                          const SizedBox(height: 18),
                          Text(
                            AppStrings.get('signup_title').toUpperCase(),
                            style: t.displayMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.get('signup_subtitle'),
                            style: const TextStyle(
                              color: FitGenieTheme.muted,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 28),

                          _buildTextField(
                            controller: _nameController,
                            hint: AppStrings.get('field_full_name'),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _emailController,
                            hint: AppStrings.get('login_email_hint'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _passwordController,
                            hint: AppStrings.get('signup_password_hint'),
                            obscure: !_showPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: FitGenieTheme.muted,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _showPassword = !_showPassword),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hint:
                                AppStrings.get('signup_confirm_password_hint'),
                            obscure: !_showConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: FitGenieTheme.muted,
                                size: 20,
                              ),
                              onPressed: () => setState(() =>
                                  _showConfirmPassword = !_showConfirmPassword),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Terms & Conditions
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _agreeToTerms,
                                  onChanged: (v) => setState(
                                      () => _agreeToTerms = v ?? false),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _agreeToTerms = !_agreeToTerms),
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: FitGenieTheme.muted,
                                        fontSize: 12,
                                      ),
                                      children: [
                                        TextSpan(
                                            text: AppStrings.get(
                                                'login_terms_prefix')),
                                        TextSpan(
                                          text: AppStrings.get(
                                              'signup_terms_of_service'),
                                          style: const TextStyle(
                                            color: FitGenieTheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                            text: AppStrings.get('signup_and')),
                                        TextSpan(
                                          text: AppStrings.get(
                                              'signup_privacy_policy'),
                                          style: const TextStyle(
                                            color: FitGenieTheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                            text: AppStrings.get(
                                                'signup_terms_suffix')),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _loading ? null : _signUp,
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: FitGenieTheme.onPrimary,
                                      ),
                                    )
                                  : Text(
                                      AppStrings.get('signup_button')
                                          .toUpperCase(),
                                    ),
                            ),
                          ),

                          const Spacer(),
                          const SizedBox(height: 20),

                          // Already have account + Google hint
                          Center(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppStrings.get('signup_have_account'),
                                      style: const TextStyle(
                                          color: FitGenieTheme.muted,
                                          fontSize: 13),
                                    ),
                                    TextButton(
                                      onPressed: _goToLogin,
                                      child: Text(
                                        AppStrings.get('signup_sign_in'),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  AppStrings.get('signup_google_hint'),
                                  style: TextStyle(
                                    color: FitGenieTheme.muted
                                        .withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/fitgenie_logo.png',
      width: 64,
      height: 64,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.fitness_center,
          size: 38.4,
          color: FitGenieTheme.primary,
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: FitGenieTheme.text),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
