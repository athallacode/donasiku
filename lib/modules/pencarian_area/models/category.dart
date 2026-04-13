import 'package:flutter/material.dart';

/// Enum kategori donasi dengan label Indonesia dan ikon Material
enum DonationCategory {
  pakaian,
  buku,
  elektronik,
  mainan,
  perlengkapanRumah,
  lainnya;

  /// Label tampilan dalam Bahasa Indonesia
  String get label {
    switch (this) {
      case DonationCategory.pakaian:
        return 'Pakaian';
      case DonationCategory.buku:
        return 'Buku';
      case DonationCategory.elektronik:
        return 'Elektronik';
      case DonationCategory.mainan:
        return 'Mainan';
      case DonationCategory.perlengkapanRumah:
        return 'Perlengkapan Rumah';
      case DonationCategory.lainnya:
        return 'Lainnya';
    }
  }

  /// Ikon Material untuk setiap kategori
  IconData get icon {
    switch (this) {
      case DonationCategory.pakaian:
        return Icons.checkroom_rounded;
      case DonationCategory.buku:
        return Icons.menu_book_rounded;
      case DonationCategory.elektronik:
        return Icons.devices_rounded;
      case DonationCategory.mainan:
        return Icons.toys_rounded;
      case DonationCategory.perlengkapanRumah:
        return Icons.home_rounded;
      case DonationCategory.lainnya:
        return Icons.more_horiz_rounded;
    }
  }

  /// Warna aksen untuk setiap kategori
  Color get color {
    switch (this) {
      case DonationCategory.pakaian:
        return const Color(0xFF10B981);
      case DonationCategory.buku:
        return const Color(0xFF3B82F6);
      case DonationCategory.elektronik:
        return const Color(0xFFF59E0B);
      case DonationCategory.mainan:
        return const Color(0xFFF43F5E);
      case DonationCategory.perlengkapanRumah:
        return const Color(0xFF8B5CF6);
      case DonationCategory.lainnya:
        return const Color(0xFF64748B);
    }
  }

  /// Konversi dari string (Firestore/JSON)
  static DonationCategory fromString(String value) {
    // Cocokkan dengan label Indonesia (dari Firestore existing)
    switch (value.toLowerCase()) {
      case 'pakaian':
        return DonationCategory.pakaian;
      case 'buku':
        return DonationCategory.buku;
      case 'elektronik':
        return DonationCategory.elektronik;
      case 'mainan':
        return DonationCategory.mainan;
      case 'perlengkapan rumah':
      case 'perlengkapanrumah':
        return DonationCategory.perlengkapanRumah;
      default:
        return DonationCategory.lainnya;
    }
  }
}
