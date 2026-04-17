import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../theme.dart';

class AppErrorHandler {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

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
        case 'not-found':
          return 'Data yang Anda cari tidak ditemukan.';
        case 'already-exists':
          return 'Data ini sudah ada dalam sistem.';
        case 'deadline-exceeded':
          return 'Waktu koneksi habis. Silakan coba lagi.';
        case 'quota-exceeded':
          return 'Kapasitas server penuh. Silakan coba beberapa saat lagi.';
        default:
          return 'Terjadi masalah komunikasi dengan server (${error.code}).';
      }
    } else if (error is Exception) {
      final message = error.toString().replaceFirst('Exception: ', '');
      if (message.contains('SocketException')) {
        return 'Gagal terhubung ke internet. Periksa koneksi Anda.';
      }
      return message;
    }

    return 'Terjadi kesalahan yang tidak terduga: ${error.toString()}';
  }

  /// Wraps an async action with automatic loading, logging, and error notification.
  /// Used to make code more "voluminous" and robust.
  static Future<T?> performSafeAction<T>(
    BuildContext context, {
    required Future<T> Function() action,
    required String featureName,
    String? successMessage,
    Function(bool)? loadingStateSetter,
  }) async {
    try {
      loadingStateSetter?.call(true);
      final result = await action();
      
      if (successMessage != null && context.mounted) {
        showSuccess(context, successMessage);
      }
      
      return result;
    } catch (e, stack) {
      logError(featureName, e, stack);
      if (context.mounted) {
        showError(context, e);
      }
      return null;
    } finally {
      loadingStateSetter?.call(false);
    }
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

  /// Standardized logging with device info and Firestore sync.
  static void logError(String feature, dynamic error, [StackTrace? stackTrace]) async {
    final timestamp = DateTime.now();
    debugPrint('----------------------------------------');
    debugPrint('ERROR in Feature: $feature');
    debugPrint('Timestamp: $timestamp');
    debugPrint('Message: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
    debugPrint('----------------------------------------');
    
    // Log to Firestore with enhanced metadata
    _logToFirestore(feature, error, stackTrace, timestamp);
  }

  /// Private helper to log errors to Firestore collection with device details.
  static void _logToFirestore(String feature, dynamic error, StackTrace? stack, DateTime time) async {
    try {
      Map<String, dynamic> deviceData = {};
      
      try {
        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
          deviceData = {
            'model': androidInfo.model,
            'brand': androidInfo.brand,
            'version': androidInfo.version.release,
            'sdk': androidInfo.version.sdkInt,
          };
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
          deviceData = {
            'model': iosInfo.utsname.machine,
            'version': iosInfo.systemVersion,
            'name': iosInfo.name,
          };
        }
      } catch (e) {
        deviceData = {'error': 'Failed to get device info: $e'};
      }

      await FirebaseFirestore.instance.collection('error_logs').add({
        'feature': feature,
        'message': error.toString(),
        'stackTrace': stack?.toString(),
        'timestamp': time,
        'device': deviceData,
        'platform': Platform.operatingSystem,
      });
    } catch (e) {
      debugPrint('CRITICAL: Failed to log error to Firestore: $e');
    }
  }
}
