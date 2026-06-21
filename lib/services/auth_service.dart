import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/app_error_handler.dart';
import 'app_notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign Up
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String role,
    String name = '',
    String? ktpUrl,
    String? sktmUrl,
  }) async {
    User? createdUser;
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      createdUser = userCredential.user;

      // Save role and profile to Firestore
      if (createdUser != null) {
        bool isVerified = false;

        await _firestore.collection('users').doc(createdUser.uid).set({
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
      }

      return userCredential;
    } catch (e) {
      // If Firestore write fails, clean up the created Firebase Auth user to avoid orphan accounts
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (cleanupError) {
          debugPrint(
            'Failed to clean up created user after Firestore failure: $cleanupError',
          );
        }
      }
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


      return userCredential;
    } catch (e) {
      AppErrorHandler.logError('AuthService.signIn', e);
      rethrow;
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.setLanguageCode('id');
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      AppErrorHandler.logError('AuthService.resetPassword', e);
      rethrow;
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // If new user, create a default Firestore profile
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final user = userCredential.user!;
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email ?? '',
          'name':
              user.displayName ?? (user.email?.split('@').first ?? 'Pengguna'),
          'role': 'Donatur', // Default role for Google login
          'isVerified': false,
          'ktpUrl': '',
          'sktmUrl': '',
          'phone': '',
          'address': '',
          'photoUrl': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });      }

      return userCredential;
    } catch (e) {
      AppErrorHandler.logError('AuthService.signInWithGoogle', e);
      rethrow;
    }
  }

  // Sign In Anonymously (Guest)
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      AppErrorHandler.logError('AuthService.signInAnonymously', e);
      rethrow;
    }
  }

  bool get isGuest => _auth.currentUser?.isAnonymous ?? false;

  // Sign Out
  Future<void> signOut() async {
    final user = _auth.currentUser;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    // Anonymous accounts must be deleted, not just signed out, to avoid
    // accumulating orphaned guest accounts in Firebase Auth indefinitely.
    if (user?.isAnonymous == true) {
      try {
        await user!.delete();
        return; // Firebase auto-signs out on delete
      } catch (_) {}
    }
    await _auth.signOut();
  }

  // Delete current authenticated user (useful for cleaning up orphaned accounts)
  Future<void> deleteCurrentUser() async {
    try {
      await _auth.currentUser?.delete();
      // Firebase Auth automatically signs out the user on delete.
      // Still clear Google Sign-In session in case it was a Google account.
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    } catch (e) {
      AppErrorHandler.logError('AuthService.deleteCurrentUser', e);
      rethrow;
    }
  }

  // Get Current User
  User? get currentUser => _auth.currentUser;

  // Stream of Auth Changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get User Role from Firestore
  Future<String?> getUserRole(String uid) async {
    if (isGuest) return 'Guest';
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
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
    if (isGuest) return false;
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['isVerified'] ?? false;
      }
      return false;
    } catch (e) {
      AppErrorHandler.logError('AuthService.getUserVerificationStatus', e);
      return false;
    }
  }

  // Get full user profile stream
  Stream<Map<String, dynamic>?> getUserProfileStream(String uid) {
    if (isGuest) {
      return Stream.value({
        'name': 'Tamu',
        'email': 'tamu@donasiku.com',
        'role': 'Guest',
        'isVerified': false,
        'phone': '',
        'address': '',
        'photoUrl': '',
      });
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  // Get full user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    if (isGuest) {
      return {
        'name': 'Tamu',
        'email': 'tamu@donasiku.com',
        'role': 'Guest',
        'isVerified': false,
        'phone': '',
        'address': '',
        'photoUrl': '',
      };
    }
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
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
    if (isGuest) return 'Tamu';
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
    if (isGuest) throw Exception('Tamu tidak dapat memperbarui profil');
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

  // Update verification documents (KTP & SKTM) — called after auth is established
  Future<void> updateVerificationDocuments({
    required String uid,
    required String ktpUrl,
    required String sktmUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'ktpUrl': ktpUrl,
        'sktmUrl': sktmUrl,
      });
    } catch (e) {
      AppErrorHandler.logError('AuthService.updateVerificationDocuments', e);
      rethrow;
    }
  }

  // Upload Profile Picture
  Future<String> uploadProfilePicture(String uid, Uint8List imageBytes) async {
    try {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('profile.jpg');
      UploadTask uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update the user's profile with the new photo URL
      await updateUserProfile(uid: uid, photoUrl: downloadUrl);

      return downloadUrl;
    } catch (e) {
      AppErrorHandler.logError('AuthService.uploadProfilePicture', e);
      rethrow;
    }
  }

  // Delete Profile Picture
  Future<void> deleteProfilePicture(String uid) async {
    try {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('profile.jpg');
      try {
        await ref.delete();
      } catch (e) {
        // If file doesn't exist, ignore the error
        debugPrint('Profile picture file not found or already deleted: $e');
      }

      // Update the user's profile to clear the photo URL
      await updateUserProfile(uid: uid, photoUrl: '');
    } catch (e) {
      AppErrorHandler.logError('AuthService.deleteProfilePicture', e);
      rethrow;
    }
  }

  // Update FCM token
  Future<void> updateFCMToken(String uid, String token) async {
    if (isGuest) return;
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    } catch (e) {
      AppErrorHandler.logError('AuthService.updateFCMToken', e);
    }
  }
}
