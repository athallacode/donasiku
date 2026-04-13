import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/donation_model.dart';

class DonationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'donations';

  // Upload Image from Bytes with Base64 Fallback
  Future<String> uploadImageFromBytes(Uint8List imageBytes) async {
    try {
      String fileName = const Uuid().v4();
      Reference ref = _storage.ref().child('donations').child('$fileName.jpg');
      
      // Attempt putData
      UploadTask uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage failed, using Base64 fallback: $e');
      // FALLBACK: Convert to Base64 and return as data URI
      String base64String = base64Encode(imageBytes);
      return 'data:image/jpeg;base64,$base64String';
    }
  }

  // Upload Image to Firebase Storage (Legacy File method)
  Future<String> uploadImage(File imageFile) async {
    try {
      String fileName = const Uuid().v4();
      Reference ref = _storage.ref().child('donations').child('$fileName.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  // Create Donation Document
  Future<void> createDonation(Donation donation) async {
    try {
      await _firestore.collection(_collection).doc(donation.id).set(donation.toMap());
    } catch (e) {
      debugPrint('Error creating donation: $e');
      rethrow;
    }
  }

  // Request a donation (receiver sends a request to donor)
  Future<void> requestDonation({
    required String donationId,
    required String requesterId,
    required String requesterName,
    required String message,
  }) async {
    try {
      final request = DonationRequest(
        requesterId: requesterId,
        requesterName: requesterName,
        message: message,
        requestedAt: DateTime.now(),
        status: 'pending',
      );

      await _firestore.collection(_collection).doc(donationId).update({
        'requests': FieldValue.arrayUnion([request.toMap()]),
      });
    } catch (e) {
      debugPrint('Error requesting donation: $e');
      rethrow;
    }
  }

  // Approve a donation request (donor approves a specific requester)
  Future<void> approveRequest({
    required String donationId,
    required String requesterId,
    required String requesterName,
  }) async {
    try {
      // Get donation to modify requests
      final doc = await _firestore.collection(_collection).doc(donationId).get();
      final data = doc.data();
      if (data == null) return;

      final donation = Donation.fromMap(data);
      final updatedRequests = donation.requests.map((r) {
        if (r.requesterId == requesterId) {
          return DonationRequest(
            requesterId: r.requesterId,
            requesterName: r.requesterName,
            message: r.message,
            requestedAt: r.requestedAt,
            status: 'approved',
          );
        } else {
          return DonationRequest(
            requesterId: r.requesterId,
            requesterName: r.requesterName,
            message: r.message,
            requestedAt: r.requestedAt,
            status: r.status == 'pending' ? 'rejected' : r.status,
          );
        }
      }).toList();

      await _firestore.collection(_collection).doc(donationId).update({
        'status': 'Diproses',
        'receiverId': requesterId,
        'receiverName': requesterName,
        'requests': updatedRequests.map((r) => r.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Error approving request: $e');
      rethrow;
    }
  }

  // Reject a donation request
  Future<void> rejectRequest({
    required String donationId,
    required String requesterId,
  }) async {
    try {
      final doc = await _firestore.collection(_collection).doc(donationId).get();
      final data = doc.data();
      if (data == null) return;

      final donation = Donation.fromMap(data);
      final updatedRequests = donation.requests.map((r) {
        if (r.requesterId == requesterId) {
          return DonationRequest(
            requesterId: r.requesterId,
            requesterName: r.requesterName,
            message: r.message,
            requestedAt: r.requestedAt,
            status: 'rejected',
          );
        }
        return r;
      }).toList();

      await _firestore.collection(_collection).doc(donationId).update({
        'requests': updatedRequests.map((r) => r.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      rethrow;
    }
  }

  // Mark donation as shipped
  Future<void> markAsShipped(String donationId) async {
    try {
      await _firestore.collection(_collection).doc(donationId).update({
        'status': 'Dikirim',
      });
    } catch (e) {
      debugPrint('Error marking as shipped: $e');
      rethrow;
    }
  }

  // Mark donation as received/completed
  Future<void> markAsReceived(String donationId) async {
    try {
      await _firestore.collection(_collection).doc(donationId).update({
        'status': 'Diterima',
      });
    } catch (e) {
      debugPrint('Error marking as received: $e');
      rethrow;
    }
  }

  // Mark donation as cancelled
  Future<void> cancelDonation(String donationId) async {
    try {
      await _firestore.collection(_collection).doc(donationId).update({
        'status': 'Dibatalkan',
      });
    } catch (e) {
      debugPrint('Error cancelling donation: $e');
      rethrow;
    }
  }

  // Legacy claim (for direct claiming without request flow)
  Future<void> claimDonation(String donationId, String receiverId) async {
    try {
      await _firestore.collection(_collection).doc(donationId).update({
        'status': 'Diproses',
        'receiverId': receiverId,
      });
    } catch (e) {
      debugPrint('Error claiming donation: $e');
      rethrow;
    }
  }

  // Stream of User's own donations
  Stream<List<Donation>> getDonationsByDonor(String donorId) {
    return _firestore
        .collection(_collection)
        .where('donorId', isEqualTo: donorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Donation.fromMap(doc.data())).toList();
    });
  }

  // Stream of all available donations (for receivers)
  Stream<List<Donation>> getAvailableDonations() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'Tersedia')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Donation.fromMap(doc.data())).toList();
    });
  }

  // Stream of donations claimed by a receiver
  Stream<List<Donation>> getDonationsByReceiver(String receiverId) {
    return _firestore
        .collection(_collection)
        .where('receiverId', isEqualTo: receiverId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Donation.fromMap(doc.data())).toList();
    });
  }

  // Stream of all donations (for older support or general view)
  Stream<List<Donation>> getAllDonations() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Donation.fromMap(doc.data())).toList();
    });
  }

  // Delete donation
  Future<void> deleteDonation(String donationId) async {
    try {
      await _firestore.collection(_collection).doc(donationId).delete();
    } catch (e) {
      debugPrint('Error deleting donation: $e');
      rethrow;
    }
  }
}
