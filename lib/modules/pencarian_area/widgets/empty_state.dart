import 'package:flutter/material.dart';
import '../../../theme.dart';

/// Widget empty state saat hasil pencarian 0
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onExpandRadius;
  final VoidCallback onResetFilter;

  const EmptyStateWidget({
    super.key,
    required this.onExpandRadius,
    required this.onResetFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ilustrasi ikon
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.paleBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 56,
                color: AppTheme.primaryBlue.withAlpha(150),
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'Belum ada barang yang cocok',
              style: AppTheme.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Coba perlebar radius pencarian atau ubah filter kategori Anda',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Tombol Perlebar Radius
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onExpandRadius,
                icon: const Icon(Icons.radar_rounded, color: Colors.white, size: 20),
                label: Text(
                  'Perlebar Radius (25 km)',
                  style: AppTheme.buttonText,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tombol Reset Filter
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onResetFilter,
                icon: Icon(Icons.refresh_rounded,
                    color: AppTheme.textDark, size: 20),
                label: Text(
                  'Reset Filter',
                  style: AppTheme.labelBold.copyWith(color: AppTheme.textDark),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.borderGrey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
