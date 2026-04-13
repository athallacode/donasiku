import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/donation_item.dart';
import '../providers/discovery_provider.dart';
import '../utils/distance_calculator.dart';
import '../widgets/donation_card.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/radius_slider.dart';
import '../widgets/empty_state.dart';
import '../../../services/donation_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme.dart';

/// Layar utama Discovery Engine & Filtering
class DiscoveryScreen extends StatefulWidget {
  final UserRole userRole;
  final bool isLocationVerified;

  const DiscoveryScreen({
    super.key,
    required this.userRole,
    this.isLocationVerified = true,
  });

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Inisialisasi provider setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryProvider>().initialize(
            role: widget.userRole,
            isVerified: widget.isLocationVerified,
          );
    });
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
        // Cek verifikasi lokasi (Penerima)
        if (!provider.isLocationVerified &&
            widget.userRole == UserRole.penerima) {
          return _buildVerificationBlockedScreen();
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,
          appBar: AppBar(
            backgroundColor: AppTheme.white,
            elevation: 0,
            title: Text(
              'Cari Barang Donasi',
              style: AppTheme.headingSmall.copyWith(color: AppTheme.textDark),
            ),
            centerTitle: false,
            actions: [
              // Toggle view (list/map)
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildViewToggle(
                      icon: Icons.list_rounded,
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
          body: Column(
            children: [
              // Container filter (scroll-proof)
              Container(
                color: AppTheme.white,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGrey,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => provider.setKeyword(value),
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau deskripsi barang...',
                            hintStyle: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textLight,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppTheme.primaryBlue,
                              size: 22,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        color: AppTheme.textLight, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      provider.setKeyword('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),

                    // Banner info role (Donatur)
                    if (widget.userRole == UserRole.donatur)
                      _buildRoleBanner(
                        'Mode Lihat — daftar barang dari donatur lain di area Anda',
                        Icons.visibility_rounded,
                        AppTheme.primaryBlue,
                      ),

                    // Banner info role (Admin)
                    if (widget.userRole == UserRole.admin)
                      _buildRoleBanner(
                        'Mode Admin — monitor semua barang donasi',
                        Icons.admin_panel_settings_rounded,
                        AppTheme.amber,
                      ),

                    // Admin status filter
                    if (widget.userRole == UserRole.admin)
                      _buildAdminStatusFilter(provider),

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
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: RadiusSlider(
                  value: provider.radiusKm,
                  onChanged: (v) => provider.setRadius(v),
                ),
              ),

              // Result counter
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
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

              // Content area
              Expanded(
                child: _buildContent(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Konten utama (loading / error / empty / list / map)
  Widget _buildContent(DiscoveryProvider provider) {
    // Loading
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      );
    }

    // Error
    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded,
                    size: 48, color: AppTheme.errorRed),
              ),
              const SizedBox(height: 20),
              Text(
                provider.errorMessage!,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorRed),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => provider.search(),
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (provider.results.isEmpty) {
      return EmptyStateWidget(
        onExpandRadius: () => provider.expandRadius(),
        onResetFilter: () {
          _searchController.clear();
          provider.resetFilters();
        },
      );
    }

    // List view atau Map view
    if (provider.viewMode == ViewMode.list) {
      return _buildListView(provider);
    } else {
      return _buildMapView(provider);
    }
  }

  /// List view builder
  Widget _buildListView(DiscoveryProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      itemCount: provider.results.length,
      itemBuilder: (context, index) {
        final item = provider.results[index];
        return DonationCard(
          item: item,
          userRole: widget.userRole,
          onRequestTap: widget.userRole == UserRole.penerima
              ? () => _showRequestDialog(context, item)
              : null,
          onDetailTap: () => _showDetailDialog(context, item),
        );
      },
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

            // Marker untuk setiap item (hijau)
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
                    child: Icon(item.category.icon,
                        color: Colors.white, size: 18),
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
                  child: Icon(item.category.icon,
                      color: item.category.color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: AppTheme.labelBold.copyWith(fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 14, color: AppTheme.emeraldGreen),
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
                      _showDetailDialog(context, item);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      elevation: 0,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Lihat Detail',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                if (widget.userRole == UserRole.penerima) ...[
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
                      child: const Text('Minta Barang',
                          style: TextStyle(color: Colors.white)),
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

  /// Dialog detail item
  void _showDetailDialog(BuildContext context, DonationItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: item.category.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.category.icon,
                          color: item.category.color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: AppTheme.headingSmall),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: item.category.color.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.category.label,
                              style: TextStyle(
                                color: item.category.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: AppTheme.borderGrey),
                const SizedBox(height: 16),

                // Deskripsi
                Text('Deskripsi', style: AppTheme.labelBold),
                const SizedBox(height: 8),
                Text(item.description, style: AppTheme.bodyMedium),
                const SizedBox(height: 20),

                // Info grid
                _buildDetailRow(Icons.person_outline_rounded,
                    'Donatur', item.donorName),
                _buildDetailRow(Icons.location_on_outlined,
                    'Lokasi', item.donorCity),
                if (item.distanceKm != null)
                  _buildDetailRow(Icons.near_me_rounded,
                      'Jarak',
                      DiscoveryDistance.formatDistance(item.distanceKm!)),
                _buildDetailRow(Icons.schedule_rounded,
                    'Status', item.status.label),

                const SizedBox(height: 24),

                // Tombol aksi
                if (widget.userRole == UserRole.penerima)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showRequestDialog(context, item);
                      },
                      icon: const Icon(Icons.favorite_border_rounded,
                          color: Colors.white, size: 18),
                      label: Text('Minta Barang Ini',
                          style: AppTheme.buttonText),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        elevation: 0,
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
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textLight),
          const SizedBox(width: 10),
          Text('$label: ', style: AppTheme.bodySmall),
          Expanded(
            child: Text(
              value,
              style: AppTheme.labelBold.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog permintaan donasi (untuk Penerima)
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
            // Info item
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(item.category.icon,
                      color: item.category.color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item.name,
                        style: AppTheme.labelBold.copyWith(fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tulis pesan untuk donatur:',
              style: AppTheme.bodyMedium,
            ),
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
            child: Text('Batal',
                style: TextStyle(color: AppTheme.textGrey)),
          ),
          (() {
            bool isSending = false;
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return ElevatedButton(
                  onPressed: isSending ? null : () async {
                  final message = messageController.text.trim();
                  if (message.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pesan tidak boleh kosong')),
                    );
                    return;
                  }

                  setDialogState(() => isSending = true);

                  try {
                    final authService = AuthService();
                    final donationService = DonationService();
                    final user = authService.currentUser;

                    if (user == null) throw Exception('Silakan login terlebih dahulu');
                    
                    final userName = await authService.getUserName(user.uid);

                    await donationService.requestDonation(
                      donationId: item.id,
                      requesterId: user.uid,
                      requesterName: userName,
                      message: message,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Permintaan berhasil dikirim! 🎉'),
                          backgroundColor: AppTheme.successGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      setDialogState(() => isSending = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal mengirim: $e'),
                          backgroundColor: AppTheme.errorRed,
                        ),
                      );
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
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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

  /// Banner info role
  Widget _buildRoleBanner(String message, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Filter status dropdown untuk Admin
  Widget _buildAdminStatusFilter(DiscoveryProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Text('Status:', style: AppTheme.labelBold.copyWith(fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ItemStatus?>(
                  value: provider.adminStatusFilter,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.textDark),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua Status'),
                    ),
                    ...ItemStatus.values.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(s.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(s.label),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) => provider.setAdminStatusFilter(value),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Layar blokir untuk Penerima yang belum terverifikasi
  Widget _buildVerificationBlockedScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: Text('Cari Barang Donasi',
            style: AppTheme.headingSmall.copyWith(color: AppTheme.textDark)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hourglass_top_rounded,
                    size: 56, color: AppTheme.amber),
              ),
              const SizedBox(height: 24),
              Text(
                'Menunggu Verifikasi',
                style: AppTheme.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Lokasi Anda sedang menunggu verifikasi Admin. Discovery akan aktif setelah lokasi diverifikasi.',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
