import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';
import '../models/donation_model.dart';
import '../widgets/donation_image.dart';
import 'donation_detail_screen.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AuthService _authService = AuthService();
  final DonationService _donationService = DonationService();
  String _selectedCategory = 'Semua';
  String? _selectedMonth;

  final List<String> _categories = [
    'Semua',
    'Pakaian',
    'Makanan',
    'Buku',
    'Elektronik',
    'Lainnya'
  ];

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Riwayat Donasi', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.textBlack,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderGrey, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            color: AppTheme.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                // Category filter
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final selected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.primaryBlue : AppTheme.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? AppTheme.primaryBlue : AppTheme.borderGrey,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: AppTheme.bodySmall.copyWith(
                                color: selected ? Colors.white : AppTheme.textDark,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                // Month filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.textLight),
                      const SizedBox(width: 8),
                      Text('Bulan', style: AppTheme.labelBold.copyWith(fontSize: 13, color: AppTheme.textDark)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _monthChip(null, 'Semua'),
                              ..._getLast6Months().map((m) =>
                                  _monthChip(m, DateFormat('MMM yyy').format(m))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Container(height: 1, color: AppTheme.borderGrey),

          // History List
          Expanded(
            child: FutureBuilder<String?>(
              future: _authService.getUserRole(user?.uid ?? ''),
              builder: (context, roleSnapshot) {
                final role = roleSnapshot.data;

                return StreamBuilder<List<Donation>>(
                  stream: role == 'Donatur'
                      ? _donationService.getDonationsByDonor(user?.uid ?? '')
                      : _donationService.getDonationsByReceiver(user?.uid ?? ''),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                      );
                    }

                    var donations = snapshot.data ?? [];
                    donations = donations.where((d) => d.status == 'Diterima').toList();

                    if (_selectedCategory != 'Semua') {
                      donations = donations.where((d) => d.category == _selectedCategory).toList();
                    }

                    if (_selectedMonth != null) {
                      final month = DateTime.parse(_selectedMonth!);
                      donations = donations.where((d) =>
                          d.createdAt.year == month.year &&
                          d.createdAt.month == month.month).toList();
                    }

                    donations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    if (donations.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 48, color: AppTheme.textLight),
                            const SizedBox(height: 16),
                            Text('Belum ada riwayat', style: AppTheme.headingSmall),
                            const SizedBox(height: 8),
                            Text('Transaksi yang selesai akan muncul di sini',
                                style: AppTheme.bodyMedium),
                          ],
                        ),
                      );
                    }

                    return CustomScrollView(
                      slivers: [
                        // Stats bar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: Row(
                              children: [
                                _buildStatChip(
                                  '${donations.length}',
                                  'Barang',
                                  AppTheme.primaryBlue,
                                ),
                                const SizedBox(width: 12),
                                _buildStatChip(
                                  '${donations.map((d) => d.category).toSet().length}',
                                  'Kategori',
                                  AppTheme.emeraldGreen,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // List
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildHistoryCard(context, donations[index], role);
                              },
                              childCount: donations.length,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthChip(DateTime? month, String label) {
    final isSelected = (month == null && _selectedMonth == null) ||
        (month != null && _selectedMonth == month.toIso8601String());
        
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMonth = month?.toIso8601String();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.textDark : AppTheme.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.textDark : AppTheme.borderGrey,
            ),
          ),
          child: Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: isSelected ? Colors.white : AppTheme.textGrey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  List<DateTime> _getLast6Months() {
    final now = DateTime.now();
    return List.generate(6, (i) => DateTime(now.year, now.month - i, 1));
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTheme.headingMedium.copyWith(color: color, fontSize: 20),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Donation donation, String? role) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DonationDetailScreen(donation: donation)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                height: 90,
                width: 90,
                fit: BoxFit.cover,
                errorWidget: Container(
                  height: 90,
                  width: 90,
                  color: AppTheme.paleBlue,
                  child: Icon(Icons.image_outlined, color: AppTheme.textLight),
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            donation.productName,
                            style: AppTheme.labelBold.copyWith(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldGreen.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Selesai',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.emeraldGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role == 'Donatur'
                          ? 'Penerima: ${donation.receiverName}'
                          : 'Donatur: ${donation.donorName}',
                      style: AppTheme.bodySmall.copyWith(fontSize: 12),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          donation.category,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textLight,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd MMM yyyy').format(donation.createdAt),
                          style: AppTheme.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppTheme.textLight,
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
