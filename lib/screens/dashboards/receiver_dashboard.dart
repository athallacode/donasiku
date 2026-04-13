import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../services/donation_service.dart';
import '../../models/donation_model.dart';
import '../donation_detail_screen.dart';
import '../../widgets/donation_image.dart';

class ReceiverDashboard extends StatefulWidget {
  const ReceiverDashboard({super.key});

  @override
  State<ReceiverDashboard> createState() => _ReceiverDashboardState();
}

class _ReceiverDashboardState extends State<ReceiverDashboard> {
  final AuthService _authService = AuthService();
  final DonationService _donationService = DonationService();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  String _userName = 'Penerima';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _stepsData = [
    {
      'title': 'Cari Barang',
      'desc': 'Temukan barang yang paling sesuai dengan kebutuhan Anda.',
      'icon': Icons.search_rounded,
      'color': AppTheme.primaryBlue,
    },
    {
      'title': 'Kirim Permintaan',
      'desc': 'Tekan tombol "Minta" dan tulis alasan dengan sopan.',
      'icon': Icons.send_rounded,
      'color': AppTheme.amber,
    },
    {
      'title': 'Tunggu Balasan',
      'desc': 'Donatur akan segera meninjau permintaan Anda.',
      'icon': Icons.hourglass_top_rounded,
      'color': AppTheme.accentBlue,
    },
    {
      'title': 'Ambil Barang',
      'desc': 'Gunakan fitur chat untuk janjian lokasi temu.',
      'icon': Icons.handshake_rounded,
      'color': AppTheme.emeraldGreen,
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Semua', 'icon': Icons.apps_rounded},
    {'name': 'Pakaian', 'icon': Icons.checkroom_rounded},
    {'name': 'Makanan', 'icon': Icons.restaurant_rounded},
    {'name': 'Buku', 'icon': Icons.menu_book_rounded},
    {'name': 'Elektronik', 'icon': Icons.devices_rounded},
    {'name': 'Lainnya', 'icon': Icons.more_horiz_rounded},
  ];

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: StreamBuilder<List<Donation>>(
        stream: _donationService.getAvailableDonations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }

          var allDonations = snapshot.data ?? [];
          var recentDonations = [];
          
          // Using sorting to guarantee 'Baru Ditambahkan' is actually recent.
          // Note: In real production, this would be a separate query limit sorted by date.
          var sortedByDate = List<Donation>.from(allDonations)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            
          if (sortedByDate.isNotEmpty) {
            recentDonations = sortedByDate.take(4).toList();
          }

          var filteredDonations = List<Donation>.from(sortedByDate);

          if (_selectedCategory != 'Semua') {
            filteredDonations = filteredDonations
                .where((d) => d.category == _selectedCategory)
                .toList();
          }

          if (_searchQuery.isNotEmpty) {
            filteredDonations = filteredDonations
                .where((d) =>
                    d.productName.toLowerCase().contains(_searchQuery) ||
                    d.description.toLowerCase().contains(_searchQuery) ||
                    d.location.toLowerCase().contains(_searchQuery))
                .toList();
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
                                  'Temukan barang yang Anda butuhkan',
                                  style: AppTheme.bodyMedium,
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.emeraldGreen.withAlpha(80), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.mintGreen,
                                child: Text(
                                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'P',
                                  style: AppTheme.headingMedium.copyWith(color: AppTheme.emeraldGreen, fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withAlpha(10),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() => _searchQuery = value.toLowerCase());
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari baju, buku, atau lainnya...',
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: AppTheme.primaryBlue, size: 22),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded,
                                          color: AppTheme.textLight, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : Container(
                                      margin: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                                    ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Informative Guide (Panduan Menggunakan Aplikasi) ──
              if (_searchQuery.isEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text('Cara Meminta Donasi', style: AppTheme.headingSmall),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 154,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _stepsData.length,
                          itemBuilder: (context, index) {
                            final step = _stepsData[index];
                            final color = step['color'] as Color;
                            return Container(
                              width: 240,
                              margin: const EdgeInsets.only(right: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.borderGrey),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withAlpha(20),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: color.withAlpha(15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(step['icon'] as IconData, color: color, size: 22),
                                      ),
                                      Text(
                                        'Langkah ${index + 1}',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.textLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    step['title'] as String,
                                    style: AppTheme.labelBold.copyWith(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    step['desc'] as String,
                                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textDark, fontSize: 11),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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

              // ── Recommended Section ( Baru Saja Ditambahkan ) ──
              if (_searchQuery.isEmpty && recentDonations.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Baru Ditambahkan ', style: AppTheme.headingSmall),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 230,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: recentDonations.length,
                          itemBuilder: (context, index) {
                            final donation = recentDonations[index] as Donation;
                            return Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 14),
                              child: _buildDonationCard(donation, isCompact: true),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Categories ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: _searchQuery.isEmpty ? 32 : 20),
                  child: SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat['name'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat['name']),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryBlue
                                    : AppTheme.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : AppTheme.borderGrey,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryBlue.withAlpha(40),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    cat['icon'] as IconData,
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.primaryBlue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    cat['name'] as String,
                                    style: AppTheme.labelBold.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textDark,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Section Title ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  child: Text(
                    _selectedCategory == 'Semua'
                        ? 'Semua Kategori'
                        : 'Kategori: $_selectedCategory',
                    style: AppTheme.headingSmall,
                  ),
                ),
              ),

              // ── Donation Grid ──
              if (filteredDonations.isEmpty)
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
                            child: Icon(Icons.search_off_rounded,
                                size: 48, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(height: 16),
                          Text('Tidak ada donasi', style: AppTheme.headingSmall),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Coba kata kunci lain'
                                : 'Belum ada di kategori $_selectedCategory',
                            style: AppTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildDonationCard(filteredDonations[index]);
                      },
                      childCount: filteredDonations.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDonationCard(Donation donation, {bool isCompact = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DonationDetailScreen(donation: donation),
          ),
        );
      },
      child: Container(
        decoration: AppTheme.softCard,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: DonationImage(
                  imageUrl: donation.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: AppTheme.paleBlue,
                    child: Center(
                      child: Icon(Icons.image_outlined,
                          size: 32, color: AppTheme.textLight),
                    ),
                  ),
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 10 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.productName,
                      style: AppTheme.labelBold.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldGreen.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        donation.category,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.emeraldGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Divider(color: AppTheme.borderGrey, height: 12),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: AppTheme.coral),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            donation.location,
                            style: AppTheme.bodySmall.copyWith(fontSize: 10),
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
    );
  }
}
