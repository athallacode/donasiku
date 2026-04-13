import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Kalkulator jarak menggunakan formula Haversine
/// Diimplementasi manual tanpa package eksternal
class DiscoveryDistance {
  /// Radius bumi dalam kilometer
  static const double _earthRadiusKm = 6371.0;

  /// Hitung jarak antara dua titik koordinat menggunakan Haversine Formula
  /// Return: jarak dalam kilometer
  static double calculateDistance(LatLng from, LatLng to) {
    final double lat1 = _degreesToRadians(from.latitude);
    final double lat2 = _degreesToRadians(to.latitude);
    final double deltaLat = _degreesToRadians(to.latitude - from.latitude);
    final double deltaLng = _degreesToRadians(to.longitude - from.longitude);

    final double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  /// Konversi derajat ke radian
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Format jarak ke string yang mudah dibaca
  /// < 1 km → meter (contoh: "750 m")
  /// < 10 km → 1 desimal (contoh: "3.4 km")
  /// >= 10 km → bulat (contoh: "25 km")
  static String formatDistance(double km) {
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '$meters m';
    } else if (km < 10.0) {
      return '${km.toStringAsFixed(1)} km';
    } else {
      return '${km.round()} km';
    }
  }

  /// Validasi apakah koordinat berada dalam wilayah Indonesia
  /// Latitude: -11 hingga 6
  /// Longitude: 95 hingga 141
  /// Koordinat (0, 0) ditolak sebagai invalid
  static bool isValidIndonesianCoordinate(LatLng coord) {
    // Tolak koordinat (0, 0)
    if (coord.latitude == 0.0 && coord.longitude == 0.0) {
      return false;
    }

    // Rentang wilayah Indonesia
    return coord.latitude >= -11.0 &&
        coord.latitude <= 6.0 &&
        coord.longitude >= 95.0 &&
        coord.longitude <= 141.0;
  }
}
