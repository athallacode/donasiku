import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../utils/app_error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _handleLogin() async {
    await AppErrorHandler.performSafeAction(
      context,
      featureName: 'LoginScreen.handleLogin',
      loadingStateSetter: (v) => setState(() => _isLoading = v),
      action: () async {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        
        try {
          await _authService.signIn(email: email, password: password);
        } on FirebaseAuthException catch (authError) {
          // Auto-provision Admin account for testing if it doesn't exist
          if (email == 'admin@donasiku.com' && password == 'admin123' && 
              (authError.code == 'user-not-found' || authError.code == 'invalid-credential' || authError.code == 'invalid-email')) {
            await _authService.signUp(
              email: email,
              password: password,
              role: 'Admin',
              name: 'Administrator',
            );
          } else {
            rethrow;
          }
        }

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        }
      },
    );
  }

  void _handleGoogleLogin() async {
    await AppErrorHandler.performSafeAction(
      context,
      featureName: 'LoginScreen.handleGoogleLogin',
      loadingStateSetter: (v) => setState(() => _isLoading = v),
      action: () async {
        final user = await _authService.signInWithGoogle();
        if (user != null && mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        }
      },
    );
  }

  void _handleForgotPassword() {
    final TextEditingController resetEmailController = TextEditingController(text: _emailController.text);
    bool isDialogLoading = false;
    String? emailError;

    showDialog(
      context: context,
      barrierDismissible: !isDialogLoading,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Reset Password', style: AppTheme.headingSmall),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kami akan mengirimkan tautan reset password ke email Anda.',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  enabled: !isDialogLoading,
                  decoration: InputDecoration(
                    hintText: 'nama@email.com',
                    labelText: 'Email',
                    errorText: emailError,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    if (emailError != null) {
                      setDialogState(() => emailError = null);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDialogLoading ? null : () => Navigator.pop(context),
                child: Text('Batal', style: TextStyle(color: AppTheme.textGrey)),
              ),
              ElevatedButton(
                onPressed: isDialogLoading
                    ? null
                    : () async {
                        final email = resetEmailController.text.trim();
                        
                        // Basic validation
                        if (email.isEmpty) {
                          setDialogState(() => emailError = 'Email tidak boleh kosong');
                          return;
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                          setDialogState(() => emailError = 'Format email salah');
                          return;
                        }

                        setDialogState(() => isDialogLoading = true);

                        try {
                          await _authService.resetPassword(email);
                          if (context.mounted) {
                            Navigator.pop(context);
                            AppErrorHandler.showSuccess(
                              context,
                              'Tautan reset password telah dikirim ke email Anda. Periksa kotak masuk atau folder spam.',
                            );
                          }
                        } catch (e) {
                          setDialogState(() {
                            isDialogLoading = false;
                            emailError = AppErrorHandler.mapErrorToMessage(e);
                          });
                        }
                      },
                child: isDialogLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirim'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/policy'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: AppTheme.textDark, size: 20),
                  ),
                ),

                const SizedBox(height: 40),

                // Logo
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.paleBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset('assets/images/logo.png', height: 40),
                  ),
                ),

                const SizedBox(height: 40),

                // Header
                Text('Selamat Datang', style: AppTheme.headingLarge),
                const SizedBox(height: 8),
                Text(
                  'Masuk ke akun Donasiku Anda',
                  style: AppTheme.bodyMedium.copyWith(fontSize: 15),
                ),

                const SizedBox(height: 36),

                // Email field
                Text('Email', style: AppTheme.labelBold),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'nama@email.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded,
                        color: AppTheme.textLight, size: 20),
                  ),
                ),

                const SizedBox(height: 20),

                // Password field
                Text('Password', style: AppTheme.labelBold),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_outline_rounded,
                        color: AppTheme.textLight, size: 20),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textLight,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleForgotPassword,
                    child: Text(
                      'Lupa Password?',
                      style: AppTheme.labelBold.copyWith(
                        color: AppTheme.primaryBlue,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Masuk', style: AppTheme.buttonText),
                  ),
                ),

                const SizedBox(height: 24),

                // Separator
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: AppTheme.borderGrey)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Atau masuk dengan', style: AppTheme.bodySmall),
                    ),
                    Expanded(child: Container(height: 1, color: AppTheme.borderGrey)),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleLogin,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderGrey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/google_logo.png',
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Google',
                          style: AppTheme.labelBold.copyWith(color: AppTheme.textDark),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Register link
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    child: RichText(
                      text: TextSpan(
                        text: 'Belum punya akun? ',
                        style: AppTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Daftar',
                            style: AppTheme.labelBold.copyWith(
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
