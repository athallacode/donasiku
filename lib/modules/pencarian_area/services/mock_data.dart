import 'package:latlong2/latlong.dart';
import '../models/donation_item.dart';
import '../models/category.dart';

/// Data mock untuk testing Discovery Engine
/// 12 item tersebar di Bandung, Cimahi, dan Lembang
class MockData {
  /// Lokasi default user (pusat Bandung)
  static final LatLng defaultUserLocation = LatLng(-6.9175, 107.6191);

  /// Data donasi dummy
  static List<DonationItem> getDonations() {
    return [
      DonationItem(
        id: 'mock_001',
        name: 'Jaket Hoodie Abu-Abu',
        description: 'Jaket hoodie ukuran L, masih bagus dan tebal. Cocok untuk musim hujan.',
        category: DonationCategory.pakaian,
        donorId: 'donor_001',
        donorName: 'Ahmad Rizky',
        donorCity: 'Bandung',
        pickupLocation: LatLng(-6.9145, 107.6090), // Dago, ~1.1 km
        postedAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: ItemStatus.available,
      ),
      DonationItem(
        id: 'mock_002',
        name: 'Buku Pemrograman Dart',
        description: 'Buku belajar Dart dan Flutter lengkap, kondisi 90%. Bonus sticker Flutter.',
        category: DonationCategory.buku,
        donorId: 'donor_002',
        donorName: 'Siti Nurhaliza',
        donorCity: 'Bandung',
        pickupLocation: LatLng(-6.9025, 107.6187), // ITB, ~1.7 km
        postedAt: DateTime.now().subtract(const Duration(hours: 5)),
        status: ItemStatus.available,
      ),
      DonationItem(
        id: 'mock_003',
        name: 'Keyboard Mechanical Bekas',
        description: 'Keyboard mechanical switch blue, tuts lengkap, kabel USB masih baik.',
        category: DonationCategory.elektronik,
        donorId: 'donor_003',
        donorName: 'Budi Santoso',
        donorCity: 'Bandung',
        pickupLocation: LatLng(-6.9210, 107.6070), // Pasteur, ~1.3 km
        postedAt: DateTime.now().subtract(const Duration(days: 1)),
        status: ItemStatus.available,
      ),
      DonationItem(
        id: 'mock_004',
        name: 'Boneka Teddy Bear Besar',
        description: 'Boneka teddy bear ukuran jumbo, warna coklat, bersih dan lembut.',
        category: DonationCategory.mainan,
        donorId: 'donor_004',
        donorName: 'Diana Putri',
        donorCity: 'Cimahi',
        pickupLocation: LatLng(-6.8838, 107.5413), // Cimahi, ~9 km
        postedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        status: ItemStatus.available,
      ),
      DonationItem(
        id: 'mock_005',
        name: 'Panci Set Stainless Steel',
        description: 'Set panci 3 ukuran dengan tutup, masih mengkilap tanpa goresan.',
        category: DonationCategory.perlengkapanRumah,
        donorId: 'donor_005',
        donorName: 'Ibu Yanti',
        donorCity: 'Bandung',
        pickupLocation: LatLng(-6.9340, 107.6268), // Buah Batu, ~2.0 km
        postedAt: DateTime.now().subtract(const Duration(days: 2)),
        status: ItemStatus.available,
      ),
      DonationItem(
        id: 'mock_006',
        name: 'Baju Kaos Anak Set 5pcs',
        description: 'Kaos anak usia 5-7 tahun, aneka warna, kondisi mulus tanpa noda.',
        category: DonationCategory.pakaian,
        donorId: 'donor_006',
        donorName: 'Rini Suryani',
        donorCity: 'Lembang',
        pickupLocation: LatLng(-6.8117, 107.6178), // Lembang, ~11.7 km
        postedAt: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
        status: ItemStatus.available,
      ),
      DonationItem(
        id: 'mock_007',
        name: 'Novel Bumi Karya Tere Liye',
        description: 'Novel Bumi series lengkap 5 buku, sampul masih bagus, halaman bersih.',
        category: DonationCategory.buku,
        donorId: 'donor_007',
        donorName: 'Andi Pratama',
        donorCity: 'Bandung',
        pickupLocation: LatLng(-6.9280, 107.6345), // Antapani, ~2.2 km
        postedAt: DateTime.now().subtract(const Duration(days: 3)),
        status: ItemStatus.available,
      ),
      DonationItem(
        id: 'mock_008',
        name: 'Charger Laptop Universal',
        description: 'Charger laptop multi-pin, output 19V, kompatibel Asus dan Acer.',
        category: DonationCategory.elektronik,
        donorId: 'donor_008',
        donorName: 'Fajar Hidayat',
        donorCity: 'Bandung',
        pickupLocation: LatLng(-6.9050, 107.6350), // Cibeunying, ~2.5 km
        postedAt: DateTime.now().subtract(const Duration(days: 3, hours: 12)),
        status: ItemStatus.requested,
      ),
      DonationItem(
        id: 'mock_009',
        name: 'Sepatu Lari Nike Bekas',
        description: 'Sepatu lari Nike ukuran 42, sol masih tebal, warna hitam-merah.',
        category: DonationCategory.pakaian,
        donorId: 'donor_009',
        donorName: 'Deni Kurniawan',
        donorCity: 'Cimahi',
        pickupLocation: LatLng(-6.8720, 107.5505), // Cimahi Utara, ~7.8 km
        postedAt: DateTime.now().subtract(const Duration(days: 4)),
        status: ItemStatus.available,
      ),
      DonationItem(
        id: 'mock_010',
        name: 'Puzzle Edukasi Anak 300pcs',
        description: 'Puzzle gambar peta Indonesia 300 pieces, lengkap dalam kotak.',
        category: DonationCategory.mainan,
        donorId: 'donor_010',
        donorName: 'Maya Anggraeni',
        donorCity: 'Bandung',
        pickupLocation: LatLng(-6.9400, 107.6500), // Arcamanik, ~4.0 km
        postedAt: DateTime.now().subtract(const Duration(days: 5)),
        status: ItemStatus.available,
      ),
      DonationItem(
        id: 'mock_011',
        name: 'Blender Maspion Bekas',
        description: 'Blender Maspion 2 speed, gelas kaca masih utuh, mesin lancar.',
        category: DonationCategory.perlengkapanRumah,
        donorId: 'donor_001',
        donorName: 'Ahmad Rizky',
        donorCity: 'Bandung',
        pickupLocation: LatLng(-6.9145, 107.6090), // Dago, ~1.1 km
        postedAt: DateTime.now().subtract(const Duration(days: 5, hours: 8)),
        status: ItemStatus.inTransit,
      ),
      DonationItem(
        id: 'mock_012',
        name: 'Tas Ransel Sekolah',
        description: 'Tas ransel warna biru navy, kompartemen laptop 14 inch, tali bahu empuk.',
        category: DonationCategory.lainnya,
        donorId: 'donor_003',
        donorName: 'Budi Santoso',
        donorCity: 'Bandung',
        pickupLocation: LatLng(-6.9185, 107.6095), // Pasteur, ~1.0 km
        postedAt: DateTime.now().subtract(const Duration(days: 6)),
        status: ItemStatus.delivered,
      ),
    ];
  }
}
