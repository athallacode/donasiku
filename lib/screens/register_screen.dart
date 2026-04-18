import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';
import '../utils/app_error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _selectedRole;
  final List<String> _roles = ['Donatur', 'Penerima'];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final DonationService _donationService = DonationService();
  
  File? _ktpFile;
  File? _sktmFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isKtp) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        if (isKtp) {
          _ktpFile = File(pickedFile.path);
        } else {
          _sktmFile = File(pickedFile.path);
        }
      });
    }
  }

  void _handleRegister() async {
    if (_selectedRole == null) {
      AppErrorHandler.showWarning(context, 'Pilih role terlebih dahulu');
      return;
    }

    if (_selectedRole == 'Penerima' && (_ktpFile == null || _sktmFile == null)) {
      AppErrorHandler.showWarning(context, 'Harap unggah Foto KTP dan Bukti SKTM/Rumah');
      return;
    }

    await AppErrorHandler.performSafeAction(
      context,
      featureName: 'RegisterScreen.handleRegister',
      loadingStateSetter: (v) => setState(() => _isLoading = v),
      action: () async {
        String ktpUrl = '';
        String sktmUrl = '';

        if (_selectedRole == 'Penerima') {
          final ktpBytes = await _ktpFile!.readAsBytes();
          ktpUrl = await _donationService.uploadImageFromBytes(ktpBytes);

          final sktmBytes = await _sktmFile!.readAsBytes();
          sktmUrl = await _donationService.uploadImageFromBytes(sktmBytes);
        }

        await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole!,
          name: _nameController.text.trim(),
          ktpUrl: ktpUrl,
          sktmUrl: sktmUrl,
        );
        
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        }
      },
    );
  }

  void _handleGoogleLogin() async {
    await AppErrorHandler.performSafeAction(
      context,
      featureName: 'RegisterScreen.handleGoogleLogin',
      loadingStateSetter: (v) => setState(() => _isLoading = v),
      action: () async {
        final user = await _authService.signInWithGoogle();
        if (user != null && mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        }
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
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
                  onTap: () => Navigator.pop(context),
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

                const SizedBox(height: 24),

                // Header
                Text('Daftar Akun', style: AppTheme.headingLarge),
                const SizedBox(height: 8),
                Text(
                  'Mulai perjalanan berbagi Anda hari ini',
                  style: AppTheme.bodyMedium.copyWith(fontSize: 15),
                ),

                const SizedBox(height: 32),

                // Name field
                Text('Nama Lengkap', style: AppTheme.labelBold),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Nama Anda',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: AppTheme.textLight, size: 20),
                  ),
                ),

                const SizedBox(height: 20),

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
                    hintText: 'Minimal 6 karakter',
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

                const SizedBox(height: 20),

                // Role Dropdown
                Text('Daftar Sebagai', style: AppTheme.labelBold),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGrey,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      hint: Text('Pilih Peran', style: AppTheme.bodyMedium),
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(14),
                      items: _roles.map((String role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role, style: AppTheme.bodyMedium),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedRole = value);
                      },
                    ),
                  ),
                ),

                if (_selectedRole == 'Penerima') ...[
                  const SizedBox(height: 24),
                  Text('Dokumen Verifikasi', style: AppTheme.labelBold),
                  const SizedBox(height: 12),
                  _buildImageUploader('Foto KTP', _ktpFile, () => _pickImage(true)),
                  const SizedBox(height: 12),
                  _buildImageUploader('SKTM / Bukti Rumah', _sktmFile, () => _pickImage(false)),
                  const SizedBox(height: 8),
                  Text(
                    '*Penerima wajib diverifikasi oleh Admin',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed, fontSize: 11),
                  ),
                ],

                const SizedBox(height: 32),

                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Daftar', style: AppTheme.buttonText),
                  ),
                ),

                const SizedBox(height: 24),

                // Separator
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: AppTheme.borderGrey)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Atau daftar dengan', style: AppTheme.bodySmall),
                    ),
                    Expanded(child: Container(height: 1, color: AppTheme.borderGrey)),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Register button
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

                const SizedBox(height: 24),

                // Login link
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    child: RichText(
                      text: TextSpan(
                        text: 'Sudah punya akun? ',
                        style: AppTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Masuk',
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

  Widget _buildImageUploader(String title, File? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: file != null ? AppTheme.emeraldGreen : AppTheme.borderGrey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                file != null ? '✅ $title Diunggah' : 'Unggah $title',
                style: AppTheme.labelBold.copyWith(
                  color: file != null ? AppTheme.emeraldGreen : AppTheme.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              file != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
              color: file != null ? AppTheme.emeraldGreen : AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
