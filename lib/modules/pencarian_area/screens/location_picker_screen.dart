import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../theme.dart';

class LocationPickerResult {
  final LatLng location;
  final String address;

  LocationPickerResult({required this.location, required this.address});
}

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late MapController _mapController;
  LatLng _selectedLocation = const LatLng(-6.9175, 107.6191); // Default Bandung
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _currentAddress = 'Mengambil lokasi...';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _reverseGeocode(_selectedLocation);
    } else {
      _determinePosition();
    }
  }

  /// Ambil posisi GPS HP saat ini sebagai titik awal
  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition();
        final newLoc = LatLng(position.latitude, position.longitude);
        setState(() {
          _selectedLocation = newLoc;
        });
        _mapController.move(newLoc, 15.0);
        _reverseGeocode(newLoc);
      } else {
         _reverseGeocode(_selectedLocation);
      }
    } catch (e) {
      debugPrint('Error getting position: $e');
      _reverseGeocode(_selectedLocation);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Cari alamat berdasarkan teks (Geocoding) via Nominatim
  Future<void> _searchAddress() async {
    if (_searchController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final query = Uri.encodeComponent(_searchController.text);
      final url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1&countrycodes=id';
      
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Donasiku_App_v1',
      });

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lon = double.parse(results[0]['lon']);
          final newLoc = LatLng(lat, lon);
          
          setState(() {
            _selectedLocation = newLoc;
            _currentAddress = results[0]['display_name'];
          });
          _mapController.move(newLoc, 15.0);
        } else {
          _showToast('Alamat tidak ditemukan');
        }
      }
    } catch (e) {
      _showToast('Terjadi kesalahan pencarian');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Cari nama alamat berdasarkan koordinat (Reverse Geocoding)
  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1';
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Donasiku_App_v1',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentAddress = data['display_name'] ?? 'Alamat tidak diketahui';
        });
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi Penjemputan'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // ── Map ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
                _reverseGeocode(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.donasiku',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppTheme.errorRed,
                      size: 45,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Search Bar Overlay ──
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _searchAddress(),
                decoration: InputDecoration(
                  hintText: 'Cari Alamat/Jalan...',
                  hintStyle: AppTheme.bodySmall,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
                  suffixIcon: _isLoading 
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppTheme.primaryBlue),
                        onPressed: _searchAddress,
                      ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
            ),
          ),

          // ── Bottom Panel ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppTheme.emeraldGreen, size: 20),
                      const SizedBox(width: 8),
                      Text('Alamat Terpilih', style: AppTheme.labelBold),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentAddress,
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textGrey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          LocationPickerResult(
                            location: _selectedLocation,
                            address: _currentAddress,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Konfirmasi Lokasi', style: AppTheme.buttonText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
