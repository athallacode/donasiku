import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../services/donation_service.dart';
import '../../utils/app_error_handler.dart';
import '../../modules/pencarian_area/providers/discovery_provider.dart';
import '../../modules/pencarian_area/models/donation_item.dart';
import '../../modules/pencarian_area/widgets/donation_card.dart';
import '../../modules/pencarian_area/widgets/category_filter_chips.dart';
import '../../modules/pencarian_area/widgets/radius_slider.dart';
import '../../modules/pencarian_area/widgets/empty_state.dart';
import '../../modules/pencarian_area/utils/distance_calculator.dart';
import '../donation_detail_screen.dart';
import '../../models/donation_model.dart';

class ReceiverDashboard extends StatefulWidget {
  final bool isPreviewMode;

  const ReceiverDashboard({
    super.key,
    this.isPreviewMode = false,
  });

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
      'desc': 'Gunakan slider radius & kategori untuk mencari.',
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryProvider>().initialize(
            role: UserRole.penerima,
            isVerified: !widget.isPreviewMode,
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

  @override
  Widget build(BuildContext context) {
    return Consumer<DiscoveryProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,
          body: CustomScrollView(
            slivers: [
              // ── Header ──
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Halo, $_userName 👋',
                                    style: AppTheme.headingLarge.copyWith(fontSize: 24),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Temukan donasi di sekitar Anda',
                                    style: AppTheme.bodyMedium,
                                  ),
                                ],
                              ),
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
                        if (widget.isPreviewMode) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.amber.withAlpha(15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.amber.withAlpha(50)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.remove_red_eye_rounded, color: AppTheme.amber),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Akun Anda sedang diverifikasi. Anda bisa melihat donasi, tetapi belum bisa memintanya.',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── Informative Guide ──
              if (provider.keyword.isEmpty) ...[
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
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],

              // ── Discovery Tools (Search, Categories, Radius) ──
              SliverToBoxAdapter(
                child: Container(
                  color: AppTheme.white,
                  child: Column(
                    children: [
                      // Search & View Toggle
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundGrey,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) => provider.setKeyword(value),
                                  decoration: InputDecoration(
                                    hintText: 'Cari baju, buku...',
                                    hintStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textLight),
                                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue, size: 22),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear_rounded, color: AppTheme.textLight, size: 18),
                                            onPressed: () {
                                              _searchController.clear();
                                              provider.setKeyword('');
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundGrey,
                                borderRadius: BorderRadius.circular(10),
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
                      ),

                      // Category filter chips
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CategoryFilterChips(
                          selectedCategories: provider.selectedCategories,
                          onToggle: (cat) => provider.toggleCategory(cat),
                          onClearAll: () => provider.clearCategories(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Radius slider
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: RadiusSlider(
                    value: provider.radiusKm,
                    onChanged: (v) => provider.setRadius(v),
                  ),
                ),
              ),

              // Result counter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    children: [
                      Text(
                        'Menampilkan ${provider.results.length} dari ${provider.totalItems} barang',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ' dalam radius ${provider.radiusKm.round()} km',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Main Content Area ──
              if (provider.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
                )
              else if (provider.errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.errorRed),
                          const SizedBox(height: 20),
                          Text(
                            provider.errorMessage!,
                            style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorRed),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => provider.search(),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (provider.results.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateWidget(
                    onExpandRadius: () => provider.expandRadius(),
                    onResetFilter: () {
                      _searchController.clear();
                      provider.resetFilters();
                    },
                  ),
                )
              else if (provider.viewMode == ViewMode.list)
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
                        return DonationCard(
                          item: provider.results[index],
                          userRole: UserRole.penerima,
                          isGridMode: true,
                          onRequestTap: !widget.isPreviewMode
                              ? () => _showRequestDialog(context, provider.results[index])
                              : null,
                          onDetailTap: () => _navigateToDetail(context, provider.results[index]),
                        );
                      },
                      childCount: provider.results.length,
                    ),
                  ),
                )
              else
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: _buildMapView(provider),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Navigate to Donation Detail Screen
  void _navigateToDetail(BuildContext context, DonationItem item) {
    // Convert DiscoveryItem back to standard Donation model if needed, 
    // but the best way is to fetch the full object or adapt it.
    // For simplicity, we create a partial Donation object.
    final donation = Donation(
      id: item.id,
      donorId: item.donorId,
      productName: item.name,
      category: item.category.label,
      description: item.description,
      location: item.donorCity,
      imageUrl: item.imageUrl,
      status: item.status.label,
      createdAt: item.createdAt,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DonationDetailScreen(
          donation: donation,
          isReadOnly: widget.isPreviewMode,
        ),
      ),
    );
  }

  /// Map view dengan FlutterMap (OpenStreetMap)
  Widget _buildMapView(DiscoveryProvider provider) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: provider.userLocation,
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.donasiku',
        ),
        MarkerLayer(
          markers: [
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
                    BoxShadow(
                      color: AppTheme.primaryBlue.withAlpha(80),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 22),
              ),
            ),
            ...provider.results.map((item) {
              return Marker(
                point: item.pickupLocation,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _showMapPopup(context, item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.emeraldGreen.withAlpha(60),
                          blurRadius: 6,
                        ),
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

  /// Popup saat tap marker di map
  void _showMapPopup(BuildContext context, DonationItem item) {
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
                          Icon(Icons.location_on_rounded, size: 14, color: AppTheme.emeraldGreen),
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToDetail(context, item);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      elevation: 0,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Lihat Detail', style: TextStyle(color: Colors.white)),
                  ),
                ),
                if (!widget.isPreviewMode) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showRequestDialog(context, item);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        elevation: 0,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Minta Barang', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog permintaan donasi
  void _showRequestDialog(BuildContext context, DonationItem item) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Minta Donasi', style: AppTheme.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(item.category.icon, color: item.category.color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item.name, style: AppTheme.labelBold.copyWith(fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Tulis pesan untuk donatur:', style: AppTheme.bodyMedium),
            const SizedBox(height: 10),
            TextField(
              controller: messageController,
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
          (() {
            bool isSending = false;
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final message = messageController.text.trim();
                          if (message.isEmpty) {
                            AppErrorHandler.showWarning(context, 'Pesan tidak boleh kosong');
                            return;
                          }

                          setDialogState(() => isSending = true);

                          try {
                            final user = _authService.currentUser;
                            if (user == null) throw Exception('Silakan login terlebih dahulu');
                            final userName = await _authService.getUserName(user.uid);

                            await DonationService().requestDonation(
                              donationId: item.id,
                              requesterId: user.uid,
                              requesterName: userName,
                              message: message,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              AppErrorHandler.showSuccess(context, 'Permintaan berhasil dikirim! 🎉');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setDialogState(() => isSending = false);
                              AppErrorHandler.showError(context, e);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreen,
                    elevation: 0,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Kirim Permintaan'),
                );
              },
            );
          }()),
        ],
      ),
    );
  }

  /// Tombol toggle view (list/map)
  Widget _buildViewToggle({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : AppTheme.textLight,
        ),
      ),
    );
  }
}
