import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../utils/app_error_handler.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<void> _approveUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isVerified': true,
      });
      if (mounted) {
        AppErrorHandler.showSuccess(context, 'Akun Penerima berhasil disetujui.');
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _rejectUser(String uid) async {
    try {
      // In a real app we'd also delete the Firebase Auth user.
      // For MVP, we delete the firestore profile so they can't login as Penerima.
      await _firestore.collection('users').doc(uid).delete();
      if (mounted) {
        AppErrorHandler.showError(context, 'Akun Penerima ditolak dan dihapus.');
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showError(context, e);
      }
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppTheme.labelBold),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: AppTheme.paleBlue,
                    child: Center(
                      child: Text('Gagal memuat gambar', style: AppTheme.bodySmall),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text('Admin Verifikasi', style: AppTheme.headingSmall.copyWith(color: AppTheme.textDark)),
        backgroundColor: AppTheme.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          IconButton(
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('role', isEqualTo: 'Penerima')
            .where('isVerified', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi Kesalahan: ${AppErrorHandler.mapErrorToMessage(snapshot.error)}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.emeraldGreen),
                  ),
                  const SizedBox(height: 16),
                  Text('Semua sudah diverifikasi', style: AppTheme.headingSmall),
                  const SizedBox(height: 8),
                  Text('Tidak ada akun menunggu.', style: AppTheme.bodyMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final userData = docs[index].data() as Map<String, dynamic>;
              final String uid = docs[index].id;
              final String name = userData['name'] ?? 'Tanpa Nama';
              final String email = userData['email'] ?? 'Tanpa Email';
              final String ktpUrl = userData['ktpUrl'] ?? '';
              final String sktmUrl = userData['sktmUrl'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: AppTheme.softCard,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.paleBlue,
                            child: const Icon(Icons.person, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: AppTheme.labelBold.copyWith(fontSize: 16)),
                                Text(email, style: AppTheme.bodySmall),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.amber.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Pending', style: AppTheme.bodySmall.copyWith(color: AppTheme.warningOrange)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Dokumen Terlampir:', style: AppTheme.labelBold.copyWith(fontSize: 13)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: ktpUrl.isNotEmpty
                                  ? () => _showImageDialog(context, ktpUrl, 'Foto KTP')
                                  : null,
                              icon: const Icon(Icons.badge_outlined, size: 18),
                              label: const Text('KTP'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryBlue,
                                side: const BorderSide(color: AppTheme.primaryBlue),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: sktmUrl.isNotEmpty
                                  ? () => _showImageDialog(context, sktmUrl, 'Foto SKTM / Rumah')
                                  : null,
                              icon: const Icon(Icons.home_outlined, size: 18),
                              label: const Text('SKTM / Rumah'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.emeraldGreen,
                                side: const BorderSide(color: AppTheme.emeraldGreen),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _rejectUser(uid),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorRed,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Tolak Akun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _approveUser(uid),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Verifikasi (Terima)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
