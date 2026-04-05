// lib/screens/signup_screen.dart

import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

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
  bool _googleLoading = false;
  bool _agreeToTerms = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ============================================
  // ✅ UI VALIDATION (Quick checks)
  // ============================================
  String? _validateInputsQuick() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) return 'Naam daal bhai';
    if (email.isEmpty) return 'Email daal bhai';
    if (password.isEmpty) return 'Password daal bhai';
    if (confirmPassword.isEmpty) return 'Confirm password daal bhai';
    if (password != confirmPassword) return 'Dono passwords match nahi kar rahe';
    if (!_agreeToTerms) return 'Terms & Conditions accept kar';

    return null;
  }

  // ============================================
  // 🔐 SIGN UP - SECURED
  // ============================================
  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    // ✅ Quick UI validation
    final quickError = _validateInputsQuick();
    if (quickError != null) {
      _showSnackBar(quickError, isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      // ✅ Use AuthResult for complete validation
      final result = await _auth.signUpWithName(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        _showSnackBar(result.message, isError: false);
        // Navigation will be handled by AuthGate automatically
      } else {
        _showSnackBar(result.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Kuch gadbad ho gayi. Dobara try kar.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ============================================
  // 🔐 GOOGLE SIGN IN
  // ============================================
  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);

    try {
      final result = await _auth.signInWithGoogle();

      if (!mounted) return;

      if (result.success) {
        _showSnackBar(result.message, isError: false);
      } else {
        _showSnackBar(result.message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Google Sign-in mein error aaya.', isError: true);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  // ============================================
  // 📢 SNACKBAR
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
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

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
                            const SizedBox(height: 10),

                            // Back Button
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: _goToLogin,
                                icon: const Icon(Icons.arrow_back_ios,
                                    color: Colors.white),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Logo
                            _buildLogo(),

                            const SizedBox(height: 20),

                            // Title
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Start your fitness journey today',
                              style: TextStyle(
                                color: FitGenieTheme.muted,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Name Field
                            _buildTextField(
                              controller: _nameController,
                              icon: Icons.person_outline,
                              hint: 'Full Name',
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 12),

                            // Email Field
                            _buildTextField(
                              controller: _emailController,
                              icon: Icons.mail_outline,
                              hint: 'Email Address',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),

                            // Password Field with strength hint
                            _buildTextField(
                              controller: _passwordController,
                              icon: Icons.lock_outline,
                              hint: 'Password (8+ chars, A-Z, 0-9, @#\$)',
                              obscure: !_showPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: FitGenieTheme.muted,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _showPassword = !_showPassword),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Confirm Password Field
                            _buildTextField(
                              controller: _confirmPasswordController,
                              icon: Icons.lock_outline,
                              hint: 'Confirm Password',
                              obscure: !_showConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: FitGenieTheme.muted,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                        () => _showConfirmPassword = !_showConfirmPassword),
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
                                    activeColor: FitGenieTheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (v) =>
                                        setState(() => _agreeToTerms = v ?? false),
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
                                          const TextSpan(text: 'I agree to the '),
                                          TextSpan(
                                            text: 'Terms of Service',
                                            style: TextStyle(
                                              color: FitGenieTheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                              color: FitGenieTheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
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
                                style: FilledButton.styleFrom(
                                  backgroundColor: FitGenieTheme.primary,
                                  disabledBackgroundColor:
                                  FitGenieTheme.primary.withOpacity(0.5),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Text(
                                  'Create Account',
                                  style: TextStyle(
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
                                        color: Colors.white.withOpacity(0.1))),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                        color: FitGenieTheme.muted, fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.1))),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Google Button
                            _GoogleSignInButton(
                              onTap: _signInWithGoogle,
                              loading: _googleLoading,
                            ),

                            const SizedBox(height: 24),

                            // Already have account
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account?',
                                  style: TextStyle(
                                      color: FitGenieTheme.muted, fontSize: 13),
                                ),
                                TextButton(
                                  onPressed: _goToLogin,
                                  child: const Text(
                                    'Sign In',
                                    style:
                                    TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: FitGenieTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                    FitGenieTheme.primary.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 45,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: FitGenieTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
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
// 🔘 GOOGLE SIGN-IN BUTTON
// ============================================
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;

  const _GoogleSignInButton({
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
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
                      color: Colors.red, size: 24);
                },
              ),
              const SizedBox(width: 10),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}