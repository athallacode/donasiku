import 'package:flutter/material.dart';
import '../models/donation_model.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';
import '../services/chat_service.dart';
import '../theme.dart';
import '../widgets/donation_image.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class DonationDetailScreen extends StatefulWidget {
  final Donation donation;

  const DonationDetailScreen({super.key, required this.donation});

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  bool _isLoading = false;
  final DonationService _donationService = DonationService();
  final AuthService _authService = AuthService();
  final _messageController = TextEditingController();

  Future<void> _handleRequest() async {
    final user = _authService.currentUser;
    if (user == null) return;

    // Show request dialog
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Minta Donasi', style: AppTheme.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kirim pesan ke donatur untuk meminta barang ini:',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Saya membutuhkan barang ini untuk...',
                hintStyle: AppTheme.bodySmall,
                filled: true,
                fillColor: AppTheme.backgroundGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _messageController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreen,
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Kirim Permintaan'),
          ),
        ],
      ),
    );

    if (message == null) return;

    setState(() => _isLoading = true);
    try {
      final userName = await _authService.getUserName(user.uid);
      await _donationService.requestDonation(
        donationId: widget.donation.id,
        requesterId: user.uid,
        requesterName: userName,
        message: message,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permintaan berhasil dikirim! 🎉'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim permintaan: $e'),
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
    _messageController.dispose();
    super.dispose();
  }

  void _openChat(BuildContext context) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final chatService = ChatService();
    final chatRoom = await chatService.getOrCreateChatRoom(
      donationId: widget.donation.id,
      donationName: widget.donation.productName,
      donorId: widget.donation.donorId,
      donorName: widget.donation.donorName,
      receiverId: widget.donation.receiverId ?? '',
      receiverName: widget.donation.receiverName ?? '',
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

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final bool isDonor = user?.uid == widget.donation.donorId;
    final bool alreadyRequested = widget.donation.requests
        .any((r) => r.requesterId == user?.uid);
    final bool canRequest =
        !isDonor && widget.donation.status == 'Tersedia' && !alreadyRequested;
    final bool canChat = (widget.donation.status == 'Diproses' ||
        widget.donation.status == 'Dikirim') &&
        (widget.donation.receiverName ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: CustomScrollView(
        slivers: [
          // ── Image Header ──
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: AppTheme.primaryBlue,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'donation-${widget.donation.id}',
                child: DonationImage(
                  imageUrl: widget.donation.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: AppTheme.paleBlue,
                    child: const Center(
                      child: Icon(Icons.image_outlined,
                          size: 80, color: AppTheme.accentBlue),
                    ),
                  ),
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textDark),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0, -24, 0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Category Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.donation.status)
                                .withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      _getStatusColor(widget.donation.status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.donation.status,
                                style: AppTheme.bodySmall.copyWith(
                                  color: _getStatusColor(
                                      widget.donation.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderGrey),
                          ),
                          child: Text(
                            widget.donation.category,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Product Name
                    Text(
                      widget.donation.productName,
                      style: AppTheme.headingLarge.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: 12),

                    // Location
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.coral.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.location_on_outlined,
                              color: AppTheme.coral, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.donation.location,
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Donor name
                    if (widget.donation.donorName.isNotEmpty)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_outline_rounded,
                                color: AppTheme.primaryBlue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Donatur: ${widget.donation.donorName}',
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 28),
                    Container(height: 1, color: AppTheme.borderGrey),
                    const SizedBox(height: 28),

                    // Description
                    Text('Deskripsi', style: AppTheme.headingSmall),
                    const SizedBox(height: 12),
                    Text(
                      widget.donation.description,
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.textDark,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Time Info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.textDark.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.access_time_rounded,
                              color: AppTheme.textDark, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Waktu Posting',
                              style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textLight),
                            ),
                            Text(
                              DateFormat('dd MMMM yyyy, HH:mm')
                                  .format(widget.donation.createdAt),
                              style: AppTheme.labelBold.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Already Requested Notice
                    if (alreadyRequested && !isDonor) ...[
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.amberLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.amber.withAlpha(70)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppTheme.amber, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Anda sudah mengirim permintaan untuk donasi ini. Tunggu konfirmasi dari donatur.',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Action Bar ──
      bottomNavigationBar: (canRequest || canChat)
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.borderGrey)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (canChat)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openChat(context),
                          icon: const Icon(Icons.chat_outlined, size: 20),
                          label: const Text('Chat'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlue,
                            side: const BorderSide(color: AppTheme.primaryBlue),
                            minimumSize: const Size(0, 52),
                          ),
                        ),
                      ),
                    if (canChat && canRequest) const SizedBox(width: 12),
                    if (canRequest)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleRequest,
                          icon: _isLoading 
                            ? const SizedBox.shrink() 
                            : const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 20),
                          label: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Minta Donasi', style: AppTheme.buttonText),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emeraldGreen,
                            minimumSize: const Size(0, 52),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Tersedia':
        return AppTheme.primaryBlue;
      case 'Diproses':
        return AppTheme.amber;
      case 'Dikirim':
        return AppTheme.accentBlue;
      case 'Diterima':
        return AppTheme.emeraldGreen;
      default:
        return AppTheme.textLight;
    }
  }
}
