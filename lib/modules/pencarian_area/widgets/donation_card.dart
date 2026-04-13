import 'package:flutter/material.dart';
import '../models/donation_item.dart';
import '../utils/distance_calculator.dart';
import '../../../theme.dart';

/// Widget card untuk menampilkan item donasi di list view
class DonationCard extends StatelessWidget {
  final DonationItem item;
  final UserRole userRole;
  final VoidCallback? onRequestTap;
  final VoidCallback? onDetailTap;

  const DonationCard({
    super.key,
    required this.item,
    required this.userRole,
    this.onRequestTap,
    this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetailTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ikon kategori
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: item.category.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.category.icon,
                  color: item.category.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),

              // Info item
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris atas: nama + badge status (admin)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: AppTheme.labelBold.copyWith(fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Badge status hanya untuk Admin
                        if (userRole == UserRole.admin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Color(item.status.colorValue).withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.status.label,
                              style: TextStyle(
                                color: Color(item.status.colorValue),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Deskripsi
                    Text(
                      item.description,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textGrey,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Info donatur
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.donorName,
                          style: AppTheme.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Info jarak & lokasi
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppTheme.emeraldGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.distanceKm != null
                              ? '${DiscoveryDistance.formatDistance(item.distanceKm!)} • ${item.donorCity}'
                              : item.donorCity,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.emeraldGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Tombol aksi sesuai role
                    _buildActionButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    switch (userRole) {
      case UserRole.penerima:
        return SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: onRequestTap,
            icon: const Icon(Icons.favorite_border_rounded,
                color: Colors.white, size: 16),
            label: Text(
              'Minta Barang Ini',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        );

      case UserRole.admin:
        return SizedBox(
          height: 36,
          child: OutlinedButton.icon(
            onPressed: onDetailTap,
            icon: Icon(Icons.analytics_outlined,
                color: AppTheme.primaryBlue, size: 16),
            label: Text(
              'Lihat Detail Audit',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryBlue.withAlpha(60)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        );

      case UserRole.donatur:
        // Donatur: tidak ada tombol aksi
        return const SizedBox.shrink();
    }
  }
}
