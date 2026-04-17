import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';

class AppErrorHandler {
  /// Maps technical exceptions to user-friendly Indonesian messages.
  static String mapErrorToMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
        case 'wrong-password':
          return 'Kata sandi salah. Silakan coba lagi.';
        case 'network-request-failed':
          return 'Koneksi internet bermasalah. Pastikan Anda terhubung.';
        case 'email-already-in-use':
          return 'Email ini sudah terdaftar. Silakan masuk.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'weak-password':
          return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';
        case 'user-disabled':
          return 'Akun ini telah dinonaktifkan.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Silakan tunggu sebentar.';
        case 'operation-not-allowed':
          return 'Metode login ini tidak diaktifkan.';
        case 'invalid-credential':
          return 'Kredensial tidak valid atau sudah kedaluwarsa.';
        default:
          return error.message ?? 'Terjadi kesalahan pada sistem otentikasi.';
      }
    } else if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Anda tidak memiliki izin untuk melakukan aksi ini.';
        case 'unavailable':
          return 'Layanan sedang tidak tersedia. Coba lagi nanti.';
        default:
          return 'Gagal memproses data ke server.';
      }
    } else if (error is Exception) {
      final message = error.toString().replaceFirst('Exception: ', '');
      if (message.contains('SocketException')) {
        return 'Gagal terhubung ke internet.';
      }
      return message;
    }

    return 'Terjadi kesalahan yang tidak terduga.';
  }

  /// Shows a standardized error snackbar.
  static void showError(BuildContext context, dynamic error) {
    final message = mapErrorToMessage(error);
    _showSnackBar(context, message, AppTheme.errorRed, Icons.error_outline_rounded);
  }

  /// Shows a standardized success snackbar.
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, AppTheme.successGreen, Icons.check_circle_outline_rounded);
  }

  /// Shows a standardized warning snackbar.
  static void showWarning(BuildContext context, String message) {
    _showSnackBar(context, message, AppTheme.warningOrange, Icons.warning_amber_rounded);
  }

  static void _showSnackBar(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTheme.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Standardized logging (can be extended to Firestore later)
  static void logError(String feature, dynamic error, [StackTrace? stackTrace]) {
    debugPrint('----------------------------------------');
    debugPrint('ERROR in Feature: $feature');
    debugPrint('Timestamp: ${DateTime.now()}');
    debugPrint('Message: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
    debugPrint('----------------------------------------');
    
    // Log to Firestore for critical tracking
    _logToFirestore(feature, error);
  }

  /// Private helper to log errors to Firestore collection
  static void _logToFirestore(String feature, dynamic error) {
    try {
      FirebaseFirestore.instance.collection('error_logs').add({
        'feature': feature,
        'message': error.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'Android/iOS', // Simplified for now
      });
    } catch (e) {
      debugPrint('Failed to log error to Firestore: $e');
    }
  }
}
