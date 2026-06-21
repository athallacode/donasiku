import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/donation_model.dart';
import '../services/donation_service.dart';
import '../services/auth_service.dart';
import '../widgets/donation_image.dart';
import 'edit_donation_screen.dart';
import 'donation_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/app_notification_service.dart';

class DonationManagementScreen extends StatefulWidget {
  final Donation donation;

  const DonationManagementScreen({super.key, required this.donation});

  @override
  State<DonationManagementScreen> createState() => _DonationManagementScreenState();
}

class _DonationManagementScreenState extends State<DonationManagementScreen> {
  final DonationService _donationService = DonationService();

  void _showCancelConfirmation(BuildContext context, String donationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Donasi?'),
        content: const Text('Apakah Anda yakin ingin membatalkan donasi ini? Data akan dipindahkan ke Riwayat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () async {
              await _donationService.cancelDonation(donationId);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back from management
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Donasi telah dibatalkan'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
              }
            },
            child: const Text('Ya, Batalkan', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    DonationRequest request,
    String donationId, {
    required bool isPending,
  }) {
    final statusColor = request.status == 'approved'
        ? AppTheme.emeraldGreen
        : request.status == 'rejected'
            ? AppTheme.errorRed
            : AppTheme.amber;

    final AuthService authService = AuthService();

    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getUserProfile(request.requesterId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final photoUrl = profile?['photoUrl'] as String?;

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
                      backgroundImage: photoUrl?.isNotEmpty == true
                          ? CachedNetworkImageProvider(photoUrl!)
                          : null,
                      child: photoUrl?.isNotEmpty == true
                          ? null
                          : Text(
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
                            await _donationService.rejectRequest(
                              donationId: donationId,
                              requesterId: request.requesterId,
                            );
                            
                            // Trigger local notification
                            await AppNotificationService().showInstantNotification(
                              id: donationId.hashCode + 1,
                              title: 'Permintaan Ditolak ❌',
                              body: 'Anda menolak permintaan ${request.requesterName} untuk "${widget.donation.productName}".',
                              payload: '/dashboard',
                            );

                            // Trigger remote FCM push notification to the Requester
                            await AppNotificationService().sendPushNotification(
                              receiverUid: request.requesterId,
                              title: 'Permintaan Belum Disetujui 😔',
                              body: 'Maaf, permintaan Anda untuk "${widget.donation.productName}" belum disetujui.',
                              payload: '/dashboard',
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Permintaan ditolak'),
                                  backgroundColor: AppTheme.errorRed,
                                ),
                              );
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
                            await _donationService.approveRequest(
                              donationId: donationId,
                              requesterId: request.requesterId,
                              requesterName: request.requesterName,
                            );

                            // Trigger local notification
                            await AppNotificationService().showInstantNotification(
                              id: donationId.hashCode + 2,
                              title: 'Permintaan Disetujui! 🎉',
                              body: 'Anda menyetujui permintaan ${request.requesterName} untuk "${widget.donation.productName}". Barang kini dalam proses.',
                              payload: '/dashboard',
                            );

                            // Trigger remote FCM push notification to the Requester
                            await AppNotificationService().sendPushNotification(
                              receiverUid: request.requesterId,
                              title: 'Permintaan Disetujui! 🎉',
                              body: 'Donatur menyetujui permintaan Anda untuk "${widget.donation.productName}".',
                              payload: '/dashboard',
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Permintaan disetujui! 🎉'),
                                  backgroundColor: AppTheme.successGreen,
                                ),
                              );
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Donation?>(
      stream: _donationService.getDonationStream(widget.donation.id),
      initialData: widget.donation,
      builder: (context, snapshot) {
        final donation = snapshot.data;
        if (donation == null) {
          return const Scaffold(
            body: Center(
              child: Text('Donasi tidak ditemukan atau telah dihapus'),
            ),
          );
        }

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
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      donation.productName,
                                      style: AppTheme.labelBold.copyWith(fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      donation.status,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
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

              // ── Description Section ──
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.softCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deskripsi Kondisi', style: AppTheme.headingSmall.copyWith(fontSize: 15)),
                      const SizedBox(height: 8),
                      Text(
                        donation.description,
                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textDark, height: 1.4),
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
                          donation.id,
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
                          donation.id,
                          isPending: false,
                        );
                      },
                      childCount: otherRequests.length,
                    ),
                  ),
                ),
              ],

              // ── Action Buttons ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      // Edit Donasi Button (only if status is Tersedia)
                      if (donation.status == 'Tersedia') ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditDonationScreen(donation: donation),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
                          label: Text('Edit Donasi', style: AppTheme.buttonText),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Lihat Tampilan Publik Button
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DonationDetailScreen(donation: donation),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 20),
                        label: const Text('Lihat Tampilan Publik'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Batalkan Donasi Button (only if status is Tersedia or Diproses)
                      if (donation.status == 'Tersedia' || donation.status == 'Diproses') ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            _showCancelConfirmation(context, donation.id);
                          },
                          icon: const Icon(Icons.cancel_outlined, size: 20),
                          label: const Text('Batalkan Donasi'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorRed,
                            side: const BorderSide(color: AppTheme.errorRed),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}
