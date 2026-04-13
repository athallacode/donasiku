import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category.dart';

/// Status item donasi
enum ItemStatus {
  available,
  requested,
  inTransit,
  delivered;

  String get label {
    switch (this) {
      case ItemStatus.available:
        return 'Tersedia';
      case ItemStatus.requested:
        return 'Diminta';
      case ItemStatus.inTransit:
        return 'Dikirim';
      case ItemStatus.delivered:
        return 'Diterima';
    }
  }

  /// Warna badge untuk setiap status
  int get colorValue {
    switch (this) {
      case ItemStatus.available:
        return 0xFF10B981; // hijau
      case ItemStatus.requested:
        return 0xFFF59E0B; // kuning
      case ItemStatus.inTransit:
        return 0xFF3B82F6; // biru
      case ItemStatus.delivered:
        return 0xFF94A3B8; // abu
    }
  }

  /// Konversi dari string status Firestore existing
  static ItemStatus fromString(String value) {
    switch (value) {
      case 'Tersedia':
        return ItemStatus.available;
      case 'Diproses':
      case 'Diminta':
        return ItemStatus.requested;
      case 'Dikirim':
        return ItemStatus.inTransit;
      case 'Diterima':
        return ItemStatus.delivered;
      default:
        return ItemStatus.available;
    }
  }
}

/// Role pengguna untuk perilaku Discovery yang berbeda
enum UserRole {
  donatur,
  penerima,
  admin;

  static UserRole fromString(String value) {
    switch (value) {
      case 'Donatur':
        return UserRole.donatur;
      case 'Penerima':
        return UserRole.penerima;
      case 'Admin':
        return UserRole.admin;
      default:
        return UserRole.penerima;
    }
  }
}

/// Model item donasi untuk modul Discovery
class DonationItem {
  final String id;
  final String name;
  final String description;
  final DonationCategory category;
  final String donorId;
  final String donorName;
  final String donorCity;
  final LatLng pickupLocation;
  final String imageUrl;
  final DateTime postedAt;
  final ItemStatus status;
  double? distanceKm; // Diisi saat runtime oleh filter jarak

  DonationItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.donorId,
    required this.donorName,
    required this.donorCity,
    required this.pickupLocation,
    this.imageUrl = '',
    required this.postedAt,
    this.status = ItemStatus.available,
    this.distanceKm,
  });

  /// Konversi dari Firestore document (kompatibel dengan Donation model existing)
  factory DonationItem.fromFirestore(Map<String, dynamic> map) {
    // Ambil koordinat dari field location/pickupLocation
    double lat = 0;
    double lng = 0;

    if (map['latitude'] != null && map['longitude'] != null) {
      lat = (map['latitude'] as num).toDouble();
      lng = (map['longitude'] as num).toDouble();
    } else if (map['pickupLat'] != null && map['pickupLng'] != null) {
      lat = (map['pickupLat'] as num).toDouble();
      lng = (map['pickupLng'] as num).toDouble();
    } else if (map['geopoint'] != null && map['geopoint'] is GeoPoint) {
      final gp = map['geopoint'] as GeoPoint;
      lat = gp.latitude;
      lng = gp.longitude;
    }

    return DonationItem(
      id: map['id'] ?? '',
      name: map['productName'] ?? map['name'] ?? '',
      description: map['description'] ?? '',
      category: DonationCategory.fromString(map['category'] ?? 'Lainnya'),
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      donorCity: map['location'] ?? map['donorCity'] ?? '',
      pickupLocation: LatLng(lat, lng),
      imageUrl: map['imageUrl'] ?? '',
      postedAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: ItemStatus.fromString(map['status'] ?? 'Tersedia'),
    );
  }

  /// Konversi dari JSON (untuk mock data)
  factory DonationItem.fromJson(Map<String, dynamic> json) {
    return DonationItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: DonationCategory.fromString(json['category'] ?? 'Lainnya'),
      donorId: json['donorId'] ?? '',
      donorName: json['donorName'] ?? '',
      donorCity: json['donorCity'] ?? '',
      pickupLocation: LatLng(
        (json['pickupLat'] as num?)?.toDouble() ?? 0,
        (json['pickupLng'] as num?)?.toDouble() ?? 0,
      ),
      imageUrl: json['imageUrl'] ?? '',
      postedAt: json['postedAt'] != null
          ? DateTime.parse(json['postedAt'])
          : DateTime.now(),
      status: ItemStatus.fromString(json['status'] ?? 'Tersedia'),
    );
  }

  /// Konversi ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.label,
      'donorId': donorId,
      'donorName': donorName,
      'donorCity': donorCity,
      'pickupLat': pickupLocation.latitude,
      'pickupLng': pickupLocation.longitude,
      'imageUrl': imageUrl,
      'postedAt': postedAt.toIso8601String(),
      'status': status.label,
    };
  }

  /// Copy dengan modifikasi
  DonationItem copyWith({
    String? id,
    String? name,
    String? description,
    DonationCategory? category,
    String? donorId,
    String? donorName,
    String? donorCity,
    LatLng? pickupLocation,
    String? imageUrl,
    DateTime? postedAt,
    ItemStatus? status,
    double? distanceKm,
  }) {
    return DonationItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      donorCity: donorCity ?? this.donorCity,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      imageUrl: imageUrl ?? this.imageUrl,
      postedAt: postedAt ?? this.postedAt,
      status: status ?? this.status,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
