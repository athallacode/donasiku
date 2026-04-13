import 'package:cloud_firestore/cloud_firestore.dart';

class DonationRequest {
  final String requesterId;
  final String requesterName;
  final String message;
  final DateTime requestedAt;
  final String status; // 'pending', 'approved', 'rejected'

  DonationRequest({
    required this.requesterId,
    required this.requesterName,
    required this.message,
    required this.requestedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'message': message,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status,
    };
  }

  factory DonationRequest.fromMap(Map<String, dynamic> map) {
    return DonationRequest(
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      message: map['message'] ?? '',
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
    );
  }
}

class Donation {
  final String id;
  final String donorId;
  final String donorName;
  final String productName;
  final String description;
  final String category;
  final String imageUrl;
  final String location;
  final DateTime createdAt;
  final String status; // 'Tersedia', 'Diproses', 'Dikirim', 'Diterima'
  final String? receiverId;
  final String? receiverName;
  final double? latitude;
  final double? longitude;
  final List<DonationRequest> requests;

  Donation({
    required this.id,
    required this.donorId,
    this.donorName = '',
    required this.productName,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.location,
    required this.createdAt,
    this.status = 'Tersedia',
    this.receiverId,
    this.receiverName,
    this.latitude,
    this.longitude,
    this.requests = const [],
  });

  int get pendingRequestsCount =>
      requests.where((r) => r.status == 'pending').length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donorId': donorId,
      'donorName': donorName,
      'productName': productName,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'latitude': latitude,
      'longitude': longitude,
      'requests': requests.map((r) => r.toMap()).toList(),
    };
  }

  factory Donation.fromMap(Map<String, dynamic> map) {
    return Donation(
      id: map['id'] ?? '',
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      productName: map['productName'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      location: map['location'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] ?? 'Tersedia',
      receiverId: map['receiverId'],
      receiverName: map['receiverName'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      requests: map['requests'] != null
          ? (map['requests'] as List)
              .map((r) => DonationRequest.fromMap(r as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Donation copyWith({
    String? id,
    String? donorId,
    String? donorName,
    String? productName,
    String? description,
    String? category,
    String? imageUrl,
    String? location,
    DateTime? createdAt,
    String? status,
    String? receiverId,
    String? receiverName,
    double? latitude,
    double? longitude,
    List<DonationRequest>? requests,
  }) {
    return Donation(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      requests: requests ?? this.requests,
    );
  }
}
