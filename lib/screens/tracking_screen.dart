import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';
import '../services/chat_service.dart';
import '../models/donation_model.dart';
import '../widgets/donation_image.dart';
import 'chat_screen.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final DonationService donationService = DonationService();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tracking',
                      style: AppTheme.headingLarge.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lacak status donasi aktif Anda',
                      style: AppTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Active Donations
          FutureBuilder<String?>(
            future: authService.getUserRole(user?.uid ?? ''),
            builder: (context, roleSnapshot) {
              final role = roleSnapshot.data;

              return StreamBuilder<List<Donation>>(
                stream: role == 'Donatur'
                    ? donationService.getDonationsByDonor(user?.uid ?? '')
                    : donationService.getDonationsByReceiver(user?.uid ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryBlue),
                      ),
                    );
                  }

                  var donations = snapshot.data ?? [];
                  donations = donations
                      .where((d) =>
                          d.status == 'Diproses' ||
                          d.status == 'Dikirim' ||
                          (d.status == 'Tersedia' &&
                              (d.receiverName ?? '').isNotEmpty))
                      .toList();

                  if (donations.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_shipping_outlined,
                                size: 48, color: AppTheme.textLight),
                            const SizedBox(height: 16),
                            Text('Tidak ada donasi aktif',
                                style: AppTheme.headingSmall),
                            const SizedBox(height: 8),
                            Text(
                              'Donasi yang sedang diproses muncul di sini',
                              style: AppTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _TrackingCard(
                            donation: donations[index],
                            role: role ?? 'Donatur',
                            donationService: donationService,
                            authService: authService,
                          );
                        },
                        childCount: donations.length,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final Donation donation;
  final String role;
  final DonationService donationService;
  final AuthService authService;

  const _TrackingCard({
    required this.donation,
    required this.role,
    required this.donationService,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.softCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donation Info
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DonationImage(
                  imageUrl: donation.imageUrl,
                  height: 56,
                  width: 56,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    height: 56,
                    width: 56,
                    color: AppTheme.backgroundGrey,
                    child: Icon(Icons.image_outlined,
                        color: AppTheme.textLight, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.productName,
                      style: AppTheme.labelBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role == 'Donatur'
                          ? '→ ${(donation.receiverName ?? '').isNotEmpty ? donation.receiverName : "Belum ada"}'
                          : '← ${donation.donorName}',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor(donation.status).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  donation.status,
                  style: AppTheme.bodySmall.copyWith(
                    color: _getStatusColor(donation.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Timeline
          _buildTimeline(donation.status),

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              if ((donation.receiverName ?? '').isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openChat(context),
                    icon: const Icon(Icons.chat_outlined, size: 16),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textDark,
                      side: const BorderSide(color: AppTheme.borderGrey),
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              if ((donation.receiverName ?? '').isNotEmpty && _canUpdateStatus())
                const SizedBox(width: 10),
              if (_canUpdateStatus())
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canUpdateStatus()
                          ? AppTheme.primaryBlue
                          : AppTheme.textLight,
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _getActionLabel(),
                      style: AppTheme.buttonText.copyWith(fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final steps = ['Diproses', 'Dikirim', 'Diterima'];
    int currentIndex = steps.indexOf(currentStatus);

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector
          final stepIndex = i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: stepIndex < currentIndex
                  ? AppTheme.emeraldGreen
                  : AppTheme.borderGrey,
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isCompleted = stepIndex <= currentIndex;
        final isCurrent = stepIndex == currentIndex;

        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.emeraldGreen
                    : AppTheme.backgroundGrey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? AppTheme.emeraldGreen
                      : AppTheme.borderGrey,
                  width: 1.5,
                ),
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : Icons.circle,
                size: isCompleted ? 16 : 8,
                color: isCompleted ? Colors.white : AppTheme.borderGrey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              steps[stepIndex],
              style: AppTheme.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                color: isCompleted ? AppTheme.emeraldGreen : AppTheme.textLight,
              ),
            ),
          ],
        );
      }),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Diproses':
        return AppTheme.amber;
      case 'Dikirim':
        return AppTheme.primaryBlue;
      case 'Diterima':
        return AppTheme.emeraldGreen;
      default:
        return AppTheme.textLight;
    }
  }

  bool _canUpdateStatus() {
    if (role == 'Donatur' && donation.status == 'Diproses') return true;
    if (role == 'Penerima' && donation.status == 'Dikirim') return true;
    return false;
  }

  String _getActionLabel() {
    if (role == 'Donatur') return 'Kirim Barang';
    return 'Konfirmasi Diterima';
  }

  void _updateStatus(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          role == 'Donatur' ? 'Kirim Barang?' : 'Konfirmasi Diterima?',
          style: AppTheme.headingSmall,
        ),
        content: Text(
          role == 'Donatur'
              ? 'Barang akan ditandai sebagai sedang dikirim.'
              : 'Konfirmasi bahwa Anda telah menerima barang.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal',
                style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 40),
            ),
            child: Text(role == 'Donatur' ? 'Kirim' : 'Terima'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (role == 'Donatur') {
          await donationService.markAsShipped(donation.id);
        } else {
          await donationService.markAsReceived(donation.id);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                role == 'Donatur'
                    ? 'Status diperbarui: Dikirim'
                    : 'Barang telah diterima!',
              ),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  void _openChat(BuildContext context) async {
    final user = authService.currentUser;
    if (user == null) return;

    final chatService = ChatService();
    final chatRoom = await chatService.getOrCreateChatRoom(
      donationId: donation.id,
      donationName: donation.productName,
      donorId: donation.donorId,
      donorName: donation.donorName,
      receiverId: donation.receiverId ?? '',
      receiverName: donation.receiverName ?? '',
    );

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatRoom: chatRoom),
        ),
      );
    }
  }
}
