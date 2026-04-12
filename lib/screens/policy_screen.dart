import 'package:flutter/material.dart';
import '../theme.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.06),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textBlack, size: 20),
          ),
          onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Logo
              Image.asset('assets/images/logo.png', height: 36),
              const SizedBox(height: 28),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.softCard,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.paleBlue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: AppTheme.primaryBlue,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Kebijakan Privasi &\nSyarat Penggunaan',
                            style: AppTheme.headingMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Aplikasi Donasiku',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Dengan menggunakan aplikasi Donasiku, Anda setuju dengan hal berikut:',
                          style: AppTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        _buildPolicyItem(
                          '1. Data Pengguna',
                          'Kami menyimpan data akun, data donasi, serta data penerima hanya untuk keperluan verifikasi dan proses donasi.',
                          Icons.storage_rounded,
                          AppTheme.infoBlue,
                        ),
                        _buildPolicyItem(
                          '2. Kerahasiaan',
                          'Data tidak akan dijual/disewakan, hanya digunakan untuk menghubungkan donatur dan penerima.',
                          Icons.lock_rounded,
                          AppTheme.emeraldGreen,
                        ),
                        _buildPolicySection(
                          '3. Hak & Kewajiban',
                          Icons.gavel_rounded,
                          AppTheme.amber,
                          [
                            'Donatur wajib mendonasikan barang layak pakai.',
                            'Penerima wajib menggunakan barang sesuai kebutuhan sosial, bukan untuk komersial.',
                            'Pengguna bertanggung jawab menjaga akun masing-masing.',
                          ],
                        ),
                        _buildPolicyItem(
                          '4. Konten & Barang',
                          'Donasiku tidak bertanggung jawab atas kualitas/kondisi barang, namun kami melakukan verifikasi dasar.',
                          Icons.inventory_rounded,
                          AppTheme.coral,
                        ),
                        _buildPolicyItem(
                          '5. Pembatasan',
                          'Donasiku adalah platform penghubung, bukan pihak pengirim.',
                          Icons.info_rounded,
                          AppTheme.accentBlue,
                        ),
                        _buildPolicyItem(
                          '6. Perubahan',
                          'Syarat & privasi dapat diperbarui sewaktu-waktu.',
                          Icons.update_rounded,
                          AppTheme.textGrey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Saya Setuju & Lanjutkan', style: AppTheme.buttonText),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyItem(String title, String content, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.labelBold),
                const SizedBox(height: 4),
                Text(content, style: AppTheme.bodySmall.copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(
      String title, IconData icon, Color color, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Text(title, style: AppTheme.labelBold),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTheme.bodySmall.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
