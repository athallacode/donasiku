import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../services/donation_service.dart';
import '../../models/donation_model.dart';
import '../donation_detail_screen.dart';
import '../donation_management_screen.dart';
import '../../widgets/donation_image.dart';
import 'package:intl/intl.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  final AuthService _authService = AuthService();
  final DonationService _donationService = DonationService();
  String _userName = 'Donatur';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = _authService.currentUser;
    if (user != null) {
      final name = await _authService.getUserName(user.uid);
      if (mounted) setState(() => _userName = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: StreamBuilder<List<Donation>>(
        stream: _donationService.getDonationsByDonor(user?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppTheme.textLight),
                  const SizedBox(height: 12),
                  Text('Gagal memuat data', style: AppTheme.bodyMedium),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            );
          }

          final donations = snapshot.data ?? [];
          final int totalItems = donations.length;
          final int pendingRequests = donations.fold<int>(
            0, (sum, d) => sum + d.pendingRequestsCount,
          );
          final int activeItems =
              donations.where((d) => d.status != 'Diterima').length;
          final int receivedItems = 
              donations.where((d) => d.status == 'Diterima').length;

          // Impact calculation
          Map<String, int> impact = {};
          for (var d in donations) {
            impact[d.category] = (impact[d.category] ?? 0) + 1;
          }
          final sortedImpact = impact.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Simple level logic
          int level = 1;
          String levelName = 'Pemula';
          double progress = 0.0;
          int nextTarget = 5;

          if (totalItems >= 5 && totalItems < 15) {
            level = 2;
            levelName = 'Peduli';
            progress = (totalItems - 5) / 10;
            nextTarget = 15;
          } else if (totalItems >= 15) {
            level = 3;
            levelName = 'Pahlawan';
            progress = 1.0;
            nextTarget = totalItems;
          } else {
            progress = totalItems / 5;
          }

          return CustomScrollView(
            slivers: [
              // ── Clean Header ──
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting & Profile
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, $_userName 👋',
                                  style: AppTheme.headingLarge.copyWith(fontSize: 24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Terus berbagi kebaikan',
                                  style: AppTheme.bodyMedium,
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primaryBlue.withAlpha(80), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.paleBlue,
                                child: Text(
                                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'D',
                                  style: AppTheme.headingMedium.copyWith(color: AppTheme.primaryBlue, fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // ── Gamification/Level Card ──
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withAlpha(60),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(40),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.stars_rounded, color: AppTheme.amber, size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Level $level: $levelName',
                                          style: AppTheme.labelBold.copyWith(color: Colors.white, fontSize: 15),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.amber.withAlpha(80),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '$totalItems Donasi',
                                            style: AppTheme.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.white.withAlpha(30),
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.amber),
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      level == 3 
                                        ? 'Anda mencapai level tertinggi! Terima kasih 💙' 
                                        : '${nextTarget - totalItems} donasi lagi menuju Level ${level + 1}',
                                      style: AppTheme.bodySmall.copyWith(color: Colors.white.withAlpha(200), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        
                        // Stats Row
                        Row(
                          children: [
                            _buildStatChip(
                              '$receivedItems\nSelesai',
                              'Telah Diterima',
                              AppTheme.emeraldGreen,
                              Icons.verified_rounded,
                            ),
                            const SizedBox(width: 12),
                            _buildStatChip(
                              '$pendingRequests\nRequest',
                              'Butuh Tinjauan',
                              pendingRequests > 0
                                  ? AppTheme.coral
                                  : AppTheme.amber,
                              Icons.notifications_active_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Dampak Donasi (Informative Metric) ──
              if (sortedImpact.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text('Dampak Donasimu 🌟', style: AppTheme.headingSmall),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: sortedImpact.length,
                          itemBuilder: (context, index) {
                            final cat = sortedImpact[index];
                            return Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderGrey),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withAlpha(15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(cat.key),
                                      color: AppTheme.primaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${cat.value}x',
                                          style: AppTheme.headingMedium.copyWith(color: AppTheme.textDark, fontSize: 18),
                                        ),
                                        Text(
                                          cat.key,
                                          style: AppTheme.bodySmall.copyWith(fontSize: 10, color: AppTheme.textLight),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Section Title ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('List Donasiku', style: AppTheme.headingSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGrey,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderGrey),
                        ),
                        child: Text(
                          '$totalItems Total',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Empty State ──
              if (donations.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60, bottom: 60),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.paleBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(Icons.inventory_2_outlined,
                                size: 48, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(height: 20),
                          Text('Belum ada donasi', style: AppTheme.headingSmall),
                          const SizedBox(height: 8),
                          Text('Mulai donasi pertama Anda sekarang!',
                              style: AppTheme.bodyMedium),
                          const SizedBox(height: 28),
                          ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/add-donation'),
                            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                            label: const Text('Tambah Donasi'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(200, 52),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Donation Cards ──
              if (donations.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildDonationCard(context, donations[index]);
                      },
                      childCount: donations.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'donor_fab',
        onPressed: () => Navigator.pushNamed(context, '/add-donation'),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        label: Text('Tambah', style: AppTheme.labelBold.copyWith(color: Colors.white)),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category.toLowerCase() == 'pakaian') return Icons.checkroom_rounded;
    if (category.toLowerCase() == 'makanan') return Icons.restaurant_rounded;
    if (category.toLowerCase() == 'buku') return Icons.menu_book_rounded;
    if (category.toLowerCase() == 'elektronik') return Icons.devices_rounded;
    return Icons.card_giftcard_rounded;
  }

  Widget _buildStatChip(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  value.split('\n')[0],
                  style: AppTheme.headingLarge.copyWith(
                    color: color,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard(BuildContext context, Donation donation) {
    final bool hasRequests = donation.pendingRequestsCount > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => hasRequests
                ? DonationManagementScreen(donation: donation)
                : DonationDetailScreen(donation: donation),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: AppTheme.softCard,
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: DonationImage(
                imageUrl: donation.imageUrl,
                height: 130,
                width: 120,
                fit: BoxFit.cover,
                errorWidget: Container(
                  height: 130,
                  width: 120,
                  color: AppTheme.paleBlue,
                  child: Icon(Icons.image_outlined,
                      size: 32, color: AppTheme.textLight),
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Status
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(donation.status).withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            donation.status,
                            style: AppTheme.bodySmall.copyWith(
                              color: _getStatusColor(donation.status),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGrey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        donation.category,
                        style: AppTheme.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Location + Date
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            donation.location,
                            style: AppTheme.bodySmall.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (hasRequests) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.coral.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.coral.withAlpha(50)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications_active_rounded, color: AppTheme.coral, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '${donation.pendingRequestsCount} Permintaan',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.coral,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
