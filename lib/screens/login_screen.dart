import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
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
    setState(() => _isLoading = true);
    try {
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
          // Signed up and logged in successfully
        } else {
          rethrow;
        }
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Terjadi kesalahan'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

                const SizedBox(height: 32),

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
