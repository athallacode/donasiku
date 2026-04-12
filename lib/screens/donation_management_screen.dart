import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/donation_model.dart';
import '../services/donation_service.dart';
import '../widgets/donation_image.dart';
import 'package:intl/intl.dart';

class DonationManagementScreen extends StatelessWidget {
  final Donation donation;

  const DonationManagementScreen({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    final DonationService donationService = DonationService();
    final pendingRequests =
        donation.requests.where((r) => r.status == 'pending').toList();
    final otherRequests =
        donation.requests.where((r) => r.status != 'pending').toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Kelola Permintaan', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderGrey, height: 1),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Donation Info Header ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: AppTheme.softCard,
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  DonationImage(
                    imageUrl: donation.imageUrl,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      height: 100,
                      width: 100,
                      color: AppTheme.paleBlue,
                      child: const Icon(Icons.image_outlined,
                          color: AppTheme.accentBlue),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donation.productName,
                            style: AppTheme.labelBold.copyWith(fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              donation.category,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: AppTheme.coral),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  donation.location,
                                  style: AppTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Pending Requests Section ──
          if (pendingRequests.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.coral.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_outlined,
                          color: AppTheme.coral, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Permintaan Masuk (${pendingRequests.length})',
                      style: AppTheme.headingSmall,
                    ),
                  ],
                ),
              ),
            ),

          if (pendingRequests.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final request = pendingRequests[index];
                    return _buildRequestCard(
                      context,
                      request,
                      donationService,
                      isPending: true,
                    );
                  },
                  childCount: pendingRequests.length,
                ),
              ),
            ),

          // ── No Pending Requests ──
          if (pendingRequests.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldGreen.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 48,
                          color: AppTheme.emeraldGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada permintaan baru',
                        style: AppTheme.headingSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Semua permintaan sudah ditangani',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Past Requests History ──
          if (otherRequests.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Text(
                  'Riwayat Permintaan',
                  style: AppTheme.headingSmall.copyWith(
                    fontSize: 16,
                    color: AppTheme.textGrey,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final request = otherRequests[index];
                    return _buildRequestCard(
                      context,
                      request,
                      donationService,
                      isPending: false,
                    );
                  },
                  childCount: otherRequests.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    DonationRequest request,
    DonationService donationService, {
    required bool isPending,
  }) {
    final statusColor = request.status == 'approved'
        ? AppTheme.emeraldGreen
        : request.status == 'rejected'
            ? AppTheme.errorRed
            : AppTheme.amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.softCard,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Requester Info
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryBlue.withAlpha(25),
                  child: Text(
                    request.requesterName.isNotEmpty
                        ? request.requesterName[0].toUpperCase()
                        : 'U',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.primaryBlue,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requesterName,
                        style: AppTheme.labelBold.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm')
                            .format(request.requestedAt),
                        style: AppTheme.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (!isPending)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.status == 'approved' ? 'Disetujui' : 'Ditolak',
                      style: AppTheme.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            // Message
            if (request.message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Text(
                  '"${request.message}"',
                  style: AppTheme.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
            // Action Buttons
            if (isPending) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await donationService.rejectRequest(
                          donationId: donation.id,
                          requesterId: request.requesterId,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Permintaan ditolak'),
                              backgroundColor: AppTheme.errorRed,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                        side: const BorderSide(color: AppTheme.errorRed),
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await donationService.approveRequest(
                          donationId: donation.id,
                          requesterId: request.requesterId,
                          requesterName: request.requesterName,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Permintaan disetujui! 🎉'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Setujui'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
