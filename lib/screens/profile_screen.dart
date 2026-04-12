import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;
    if (user != null) {
      final profile = await _authService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
          _nameController.text = profile?['name'] ?? '';
          _phoneController.text = profile?['phone'] ?? '';
          _addressController.text = profile?['address'] ?? '';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _authService.updateUserProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      await _loadProfile();
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil berhasil diperbarui!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    final email = _profile?['email'] ?? 'user@email.com';
    final role = _profile?['role'] ?? 'User';
    final name = _profile?['name'] ?? 'Pengguna';

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: CustomScrollView(
        slivers: [
          // ── Clean Header ──
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.white,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    children: [
                      // Title Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Profil Saya', style: AppTheme.headingLarge.copyWith(fontSize: 24)),
                          IconButton(
                            icon: Icon(
                              _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                              color: AppTheme.textDark,
                            ),
                            onPressed: () {
                              setState(() => _isEditing = !_isEditing);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.borderGrey,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: AppTheme.paleBlue,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: AppTheme.headingLarge.copyWith(
                              color: AppTheme.primaryBlue,
                              fontSize: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(name, style: AppTheme.headingMedium),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          role,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(child: Container(height: 1, color: AppTheme.borderGrey)),

          // ── Profile Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Info Cards
                  if (!_isEditing) ...[
                    _buildInfoCard(
                      Icons.email_outlined,
                      'Email',
                      email,
                      AppTheme.primaryBlue,
                    ),
                    _buildInfoCard(
                      Icons.person_outline_rounded,
                      'Nama Lengkap',
                      name,
                      AppTheme.primaryBlue,
                    ),
                    _buildInfoCard(
                      Icons.phone_outlined,
                      'Telepon',
                      _profile?['phone']?.toString().isNotEmpty == true
                          ? _profile!['phone']
                          : 'Belum diisi',
                      AppTheme.primaryBlue,
                    ),
                    _buildInfoCard(
                      Icons.location_on_outlined,
                      'Alamat',
                      _profile?['address']?.toString().isNotEmpty == true
                          ? _profile!['address']
                          : 'Belum diisi',
                      AppTheme.primaryBlue,
                    ),
                  ],

                  // Edit Form
                  if (_isEditing) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.softCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit Profil', style: AppTheme.headingSmall),
                          const SizedBox(height: 24),
                          Text('Nama Lengkap', style: AppTheme.labelBold),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Masukkan nama lengkap',
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Nomor Telepon', style: AppTheme.labelBold),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'Masukkan nomor telepon',
                              prefixIcon: Icon(Icons.phone_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Alamat', style: AppTheme.labelBold),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _addressController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Masukkan alamat',
                              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Simpan Perubahan'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Menu Option
                  _buildMenuOption(
                    icon: Icons.history_rounded,
                    label: 'Riwayat Donasi',
                    color: AppTheme.textDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Logout Option
                  _buildMenuOption(
                    icon: Icons.logout_rounded,
                    label: 'Keluar Akun',
                    color: AppTheme.errorRed,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text('Keluar', style: AppTheme.headingSmall),
                          content: Text(
                            'Yakin ingin keluar dari akun?',
                            style: AppTheme.bodyMedium,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Batal', style: TextStyle(color: AppTheme.textGrey)),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorRed,
                                minimumSize: const Size(0, 40),
                              ),
                              child: const Text('Keluar'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _authService.signOut();
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        }
                      }
                    },
                  ),
                  
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.textDark, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppTheme.softCard,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: AppTheme.headingSmall.copyWith(
                    color: color,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textLight,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
