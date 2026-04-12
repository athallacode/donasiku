import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih role terlebih dahulu'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    if (_selectedRole == 'Penerima' && (_ktpFile == null || _sktmFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap unggah Foto KTP dan Bukti SKTM/Rumah'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
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
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Terjadi kesalahan'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload gagal: $e'),
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

                const SizedBox(height: 32),

                // Header
                Text('Buat Akun', style: AppTheme.headingLarge),
                const SizedBox(height: 8),
                Text(
                  'Bergabung untuk mulai berdonasi atau menerima',
                  style: AppTheme.bodyMedium.copyWith(fontSize: 15),
                ),

                const SizedBox(height: 32),

                // Role selection
                Text('Pilih Peran', style: AppTheme.labelBold),
                const SizedBox(height: 12),
                Row(
                  children: _roles.map((role) {
                    final isSelected = _selectedRole == role;
                    final icon = role == 'Donatur'
                        ? Icons.volunteer_activism_rounded
                        : Icons.favorite_rounded;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedRole = role;
                          _ktpFile = null;
                          _sktmFile = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(
                            right: role == 'Donatur' ? 6 : 0,
                            left: role == 'Penerima' ? 6 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : AppTheme.backgroundGrey,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : AppTheme.borderGrey,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(icon,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textLight,
                                  size: 28),
                              const SizedBox(height: 8),
                              Text(
                                role,
                                style: AppTheme.labelBold.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textGrey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Name
                Text('Nama Lengkap', style: AppTheme.labelBold),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Masukan nama lengkap',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: AppTheme.textLight, size: 20),
                  ),
                ),

                const SizedBox(height: 20),

                // Email
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

                // Password
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

                // Validation Files for Penerima
                if (_selectedRole == 'Penerima') ...[
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.amber.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppTheme.warningOrange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Verifikasi Identitas', style: AppTheme.labelBold.copyWith(color: AppTheme.warningOrange))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mendaftar sebagai Penerima mewajibkan Anda melampirkan foto KTP dan Surat Keterangan Tidak Mampu (SKTM) / Bukti Rumah untuk diverifikasi oleh Admin.',
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 16),
                        // KTP Uploader
                        _buildImageUploader('Foto KTP', _ktpFile, () => _pickImage(true)),
                        const SizedBox(height: 12),
                        // SKTM Uploader
                        _buildImageUploader('SKTM / Foto Rumah', _sktmFile, () => _pickImage(false)),
                      ],
                    ),
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
