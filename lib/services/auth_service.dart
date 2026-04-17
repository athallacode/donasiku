import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_error_handler.dart';
import 'app_notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String role,
    String name = '',
    String? ktpUrl,
    String? sktmUrl,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save role and profile to Firestore
      if (userCredential.user != null) {
        bool isVerified = role == 'Donatur' || role == 'Admin';

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'name': name.isNotEmpty ? name : email.split('@').first,
          'role': role,
          'isVerified': isVerified, // New Field
          'ktpUrl': ktpUrl ?? '',
          'sktmUrl': sktmUrl ?? '',
          'phone': '',
          'address': '',
          'photoUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        AppNotificationService().showInstantNotification(
          id: 1,
          title: 'Akun Berhasil Dibuat! 🎉',
          body: 'Selamat bergabung di Donasiku, ${name.isNotEmpty ? name : email.split('@').first}.',
        );
      }

      return userCredential;
    } catch (e) {
      AppErrorHandler.logError('AuthService.signUp', e);
      rethrow;
    }
  }

  // Sign In
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppNotificationService().showInstantNotification(
        id: 2,
        title: 'Selamat Datang Kembali! 👋',
        body: 'Berbagi kebaikan dimulai dari sini.',
      );

      return userCredential;
    } catch (e) {
      AppErrorHandler.logError('AuthService.signIn', e);
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get Current User
  User? get currentUser => _auth.currentUser;

  // Stream of Auth Changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get User Role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['role'];
      }
      return null;
    } catch (e) {
      AppErrorHandler.logError('AuthService.getUserRole', e);
      return null;
    }
  }

  // Get User Verification Status
  Future<bool> getUserVerificationStatus(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['isVerified'] ?? false;
      }
      return false;
    } catch (e) {
      AppErrorHandler.logError('AuthService.getUserVerificationStatus', e);
      return false;
    }
  }

  // Get full user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      AppErrorHandler.logError('AuthService.getUserProfile', e);
      return null;
    }
  }

  // Get user name
  Future<String> getUserName(String uid) async {
    try {
      final profile = await getUserProfile(uid);
      return profile?['name'] ?? 'Pengguna';
    } catch (e) {
      return 'Pengguna';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? address,
    String? photoUrl,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (address != null) data['address'] = address;
      if (photoUrl != null) data['photoUrl'] = photoUrl;

      if (data.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(data);
      }
    } catch (e) {
      AppErrorHandler.logError('AuthService.updateUserProfile', e);
      rethrow;
    }
  }

  // Stream user profile
  Stream<Map<String, dynamic>?> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    });
  }
}
