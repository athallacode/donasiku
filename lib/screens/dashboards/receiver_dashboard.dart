import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../models/donation_model.dart';
import '../donation_detail_screen.dart';
import '../../widgets/donation_image.dart';

// Modul Discovery (Pencarian Area)
import '../../modules/pencarian_area/providers/discovery_provider.dart';
import '../../modules/pencarian_area/models/donation_item.dart';
import '../../modules/pencarian_area/widgets/category_filter_chips.dart';
import '../../modules/pencarian_area/widgets/radius_slider.dart';
import '../../modules/pencarian_area/utils/distance_calculator.dart';

class ReceiverDashboard extends StatefulWidget {
  const ReceiverDashboard({super.key});

  @override
  State<ReceiverDashboard> createState() => _ReceiverDashboardState();
}

class _ReceiverDashboardState extends State<ReceiverDashboard> {
  final AuthService _authService = AuthService();
  String _userName = 'Penerima';
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

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

  @override
  void initState() {
    super.initState();
    _loadUserName();
    // Inisialisasi Discovery Engine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryProvider>().initialize(
            role: UserRole.penerima,
            isVerified: true, // Asumsikan true, atau cek verifikasi aktual jika ada
          );
    });
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
    _mapController.dispose();
    super.dispose();
  }

  /// Helper untuk konversi DonationItem -> Donation
  /// Digunakan agar kita bisa memanggil DonationDetailScreen tanpa error
  Donation _toDonation(DonationItem item) {
    return Donation(
      id: item.id,
      donorId: item.donorId,
      donorName: item.donorName,
      productName: item.name,
      description: item.description,
      category: item.category.label,
      imageUrl: item.imageUrl,
      location: item.donorCity,
      createdAt: item.postedAt,
      status: item.status.label,
      latitude: item.pickupLocation.latitude,
      longitude: item.pickupLocation.longitude,
      // requests dikosongkan karena penerima tidak memanage requests
      requests: const [], 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      // Menggunakan Consumer untuk memantau state Discovery
      body: Consumer<DiscoveryProvider>(
        builder: (context, provider, _) {
          // Ambil hasil filter
          final filteredDonations = provider.results;
          
          // Ambil donasi terbaru (sorting by date dari provider.results)
          var recentDonations = List<DonationItem>.from(filteredDonations)
            ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
          recentDonations = recentDonations.take(4).toList();

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
                        // Search Bar & View Toggle
                        Row(
                          children: [
                            Expanded(
                              child: Container(
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
                                  onChanged: (value) => provider.setKeyword(value),
                                  decoration: InputDecoration(
                                    hintText: 'Cari baju, buku, atau lainnya...',
                                    prefixIcon: const Icon(Icons.search_rounded,
                                        color: AppTheme.primaryBlue, size: 22),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear_rounded,
                                                color: AppTheme.textLight, size: 18),
                                            onPressed: () {
                                              _searchController.clear();
                                              provider.setKeyword('');
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
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Toggle view (list/map)
                            Container(
                              height: 52,
                              padding: const EdgeInsets.all(4),
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
                              child: Row(
                                children: [
                                  _buildViewToggle(
                                    icon: Icons.grid_view_rounded,
                                    isActive: provider.viewMode == ViewMode.list,
                                    onTap: () => provider.setViewMode(ViewMode.list),
                                  ),
                                  _buildViewToggle(
                                    icon: Icons.map_rounded,
                                    isActive: provider.viewMode == ViewMode.map,
                                    onTap: () => provider.setViewMode(ViewMode.map),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Informative Guide (Panduan) ──
              if (_searchController.text.isEmpty && provider.viewMode == ViewMode.list) ...[
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

              // ── Recommended Section (Baru Ditambahkan) ──
              if (_searchController.text.isEmpty && recentDonations.isNotEmpty && provider.viewMode == ViewMode.list) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text('Baru Ditambahkan', style: AppTheme.headingSmall),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 230,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: recentDonations.length,
                          itemBuilder: (context, index) {
                            final donation = recentDonations[index];
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

              // ── Radius & Category Filter ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: provider.viewMode == ViewMode.list && _searchController.text.isEmpty ? 32 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter Radius
                      RadiusSlider(
                        value: provider.radiusKm,
                        onChanged: (v) => provider.setRadius(v),
                      ),
                      const SizedBox(height: 16),
                      // Filter Kategori (Multi-select)
                      CategoryFilterChips(
                        selectedCategories: provider.selectedCategories,
                        onToggle: (cat) => provider.toggleCategory(cat),
                        onClearAll: () => provider.clearCategories(),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Results Info ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Hasil Pencarian', style: AppTheme.headingSmall),
                      Text(
                        '${filteredDonations.length} barang',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content View (Grid / Map) ──
              if (provider.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(60.0),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
                  ),
                )
              else if (filteredDonations.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40, bottom: 60),
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
                            child: const Icon(Icons.search_off_rounded,
                                size: 48, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(height: 16),
                          Text('Tidak ada barang di radius ${provider.radiusKm.round()} km', style: AppTheme.headingSmall),
                          const SizedBox(height: 8),
                          Text(
                            'Coba perbesar radius atau ubah filter',
                            style: AppTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (provider.viewMode == ViewMode.map)
                SliverFillRemaining(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primaryBlue.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildMapView(provider),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

  /// Membangun tombol toggle (List / Map)
  Widget _buildViewToggle({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : AppTheme.textLight,
        ),
      ),
    );
  }

  /// Membangun Map View
  Widget _buildMapView(DiscoveryProvider provider) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: provider.userLocation,
        initialZoom: 13.0,
      ),
      children: [
        // Tile layer OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.donasiku',
        ),
        // Marker layer
        MarkerLayer(
          markers: [
            // Marker lokasi user (biru)
            Marker(
              point: provider.userLocation,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryBlue.withAlpha(80), blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 22),
              ),
            ),
            // Marker untuk setiap item donasi (hijau)
            ...provider.results.map((item) {
              return Marker(
                point: item.pickupLocation,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _showMapPopup(item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(color: AppTheme.emeraldGreen.withAlpha(60), blurRadius: 6),
                      ],
                    ),
                    child: Icon(item.category.icon, color: Colors.white, size: 18),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Popup marker di peta
  void _showMapPopup(DonationItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.category.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.category.icon, color: item.category.color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppTheme.labelBold.copyWith(fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.emeraldGreen),
                          const SizedBox(width: 4),
                          Text(
                            item.distanceKm != null
                                ? '${DiscoveryDistance.formatDistance(item.distanceKm!)} • ${item.donorCity}'
                                : item.donorCity,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.emeraldGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item.description,
              style: AppTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup popup
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DonationDetailScreen(donation: _toDonation(item)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Lihat Detail & Minta', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun kartu donasi untuk Grid / List horizontal
  Widget _buildDonationCard(DonationItem item, {bool isCompact = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DonationDetailScreen(donation: _toDonation(item)),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: DonationImage(
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  cacheWidth: 400, // resize di memory, hemat RAM untuk thumbnail
                  errorWidget: Container(
                    color: AppTheme.paleBlue,
                    child: const Center(
                      child: Icon(Icons.image_outlined, size: 32, color: AppTheme.textLight),
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
                      item.name,
                      style: AppTheme.labelBold.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldGreen.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category.label,
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
                        const Icon(Icons.near_me_rounded, size: 13, color: AppTheme.coral),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.distanceKm != null
                                ? DiscoveryDistance.formatDistance(item.distanceKm!)
                                : item.donorCity,
                            style: AppTheme.bodySmall.copyWith(fontSize: 10, color: AppTheme.coral, fontWeight: FontWeight.w600),
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
