import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Illustration
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.amber.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    size: 80,
                    color: AppTheme.amber,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Menunggu Verifikasi',
                  style: AppTheme.headingLarge.copyWith(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(
                  'Akun Anda sedang ditinjau oleh Admin Donasiku. Kami akan memeriksa dokumen KTP dan SKTM Anda secepatnya untuk memastikan bantuan tepat sasaran.',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.textGrey, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Refresh Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to dashboard which re-evaluates role and verified status
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: Text('Muat Ulang Status', style: AppTheme.buttonText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
                    label: Text(
                      'Keluar Akses',
                      style: AppTheme.labelBold.copyWith(color: AppTheme.errorRed),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.errorRed, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
