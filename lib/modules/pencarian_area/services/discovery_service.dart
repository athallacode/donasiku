import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donation_item.dart';
import '../models/category.dart';
import '../utils/distance_calculator.dart';
import '../../../utils/app_error_handler.dart';
import 'mock_data.dart';

/// Service layer untuk Discovery Engine
/// Mengelola pengambilan data dan filter chain
class DiscoveryService {
  /// Flag untuk switch antara mock data dan Firestore
  /// Set ke false untuk menggunakan Firestore langsung
  static const bool useMockData = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ambil semua item donasi dari data source
  Future<List<DonationItem>> _fetchAllItems() async {
    if (useMockData) {
      // Simulasi delay network
      await Future.delayed(const Duration(milliseconds: 400));
      return MockData.getDonations();
    }

    // Firestore: ambil dari collection donations
    try {
      final snapshot = await _firestore.collection('donations').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return DonationItem.fromFirestore(data);
      }).toList();
    } catch (e) {
      AppErrorHandler.logError('DiscoveryService._fetchAllItems', e);
      rethrow;
    }
  }

  /// Filter chain utama: status → category → keyword → distance
  /// Mengembalikan list item yang sudah difilter dan diurutkan
  Future<List<DonationItem>> searchAndFilter({
    required LatLng userLocation,
    required UserRole userRole,
    Set<DonationCategory>? selectedCategories,
    String keyword = '',
    double maxRadiusKm = 10.0,
    ItemStatus? adminStatusFilter,
  }) async {
    try {
      // Validasi koordinat user
      if (!DiscoveryDistance.isValidIndonesianCoordinate(userLocation)) {
        throw InvalidCoordinateException(
          'Koordinat lokasi tidak valid. Pastikan lokasi berada di wilayah Indonesia.',
        );
      }

      // Ambil semua data
      List<DonationItem> items = await _fetchAllItems();

      // === FILTER CHAIN (urutan wajib) ===

      // 1. Filter status berdasarkan role
      items = _filterByStatus(items, userRole, adminStatusFilter);

      // 2. Filter kategori
      items = _filterByCategory(items, selectedCategories);

      // 3. Filter keyword (case-insensitive di name & description)
      items = _filterByKeyword(items, keyword);

      // 4. Filter jarak + hitung distance
      items = _filterByDistance(items, userLocation, maxRadiusKm);

      // === SORTING ===
      // Primary: distance ASC (terdekat dulu)
      // Secondary (tiebreaker): postedAt DESC (terbaru dulu)
      items.sort((a, b) {
        final distCompare = (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0);
        if (distCompare != 0) return distCompare;
        return b.postedAt.compareTo(a.postedAt);
      });

      return items;
    } catch (e) {
      AppErrorHandler.logError('DiscoveryService.searchAndFilter', e);
      rethrow;
    }
  }

  /// Step 1: Filter berdasarkan status & role
  List<DonationItem> _filterByStatus(
    List<DonationItem> items,
    UserRole role,
    ItemStatus? adminFilter,
  ) {
    if (role == UserRole.admin) {
      // Admin: filter berdasarkan dropdown, null = semua
      if (adminFilter != null) {
        return items.where((item) => item.status == adminFilter).toList();
      }
      return items;
    }

    // Donatur & Penerima: hanya item available
    return items.where((item) => item.status == ItemStatus.available).toList();
  }

  /// Step 2: Filter berdasarkan kategori terpilih
  List<DonationItem> _filterByCategory(
    List<DonationItem> items,
    Set<DonationCategory>? selectedCategories,
  ) {
    if (selectedCategories == null || selectedCategories.isEmpty) {
      return items; // Tidak ada filter = semua lolos
    }
    return items
        .where((item) => selectedCategories.contains(item.category))
        .toList();
  }

  /// Step 3: Filter berdasarkan keyword (case-insensitive)
  List<DonationItem> _filterByKeyword(
    List<DonationItem> items,
    String keyword,
  ) {
    if (keyword.trim().isEmpty) return items;

    final query = keyword.toLowerCase().trim();
    return items.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  }

  /// Step 4: Filter berdasarkan jarak & hitung distance
  List<DonationItem> _filterByDistance(
    List<DonationItem> items,
    LatLng userLocation,
    double maxRadiusKm,
  ) {
    final List<DonationItem> result = [];

    for (final item in items) {
      // Skip item dengan koordinat invalid
      if (!DiscoveryDistance.isValidIndonesianCoordinate(item.pickupLocation)) {
        continue;
      }

      final distance = DiscoveryDistance.calculateDistance(
        userLocation,
        item.pickupLocation,
      );

      if (distance <= maxRadiusKm) {
        result.add(item.copyWith(distanceKm: distance));
      }
    }

    return result;
  }

  /// Hitung total item tanpa filter (untuk counter)
  Future<int> getTotalItemCount() async {
    try {
      final items = await _fetchAllItems();
      return items.length;
    } catch (e) {
      AppErrorHandler.logError('DiscoveryService.getTotalItemCount', e);
      return 0;
    }
  }
}

/// Exception untuk koordinat tidak valid
class InvalidCoordinateException implements Exception {
  final String message;
  InvalidCoordinateException(this.message);

  @override
  String toString() => message;
}
