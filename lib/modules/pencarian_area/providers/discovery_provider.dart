import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/donation_item.dart';
import '../models/category.dart';
import '../services/discovery_service.dart';
import '../services/mock_data.dart';
import '../../../utils/app_error_handler.dart';

/// Mode tampilan hasil pencarian
enum ViewMode { list, map }

/// Provider untuk state management Discovery Engine
class DiscoveryProvider extends ChangeNotifier {
  final DiscoveryService _service = DiscoveryService();

  // === STATE ===
  String _keyword = '';
  Set<DonationCategory> _selectedCategories = {};
  double _radiusKm = 10.0;
  LatLng _userLocation = MockData.defaultUserLocation;
  UserRole _userRole = UserRole.penerima;
  List<DonationItem> _results = [];
  int _totalItems = 0;
  bool _isLoading = false;
  String? _errorMessage;
  ViewMode _viewMode = ViewMode.list;
  ItemStatus? _adminStatusFilter;
  bool _isLocationVerified = true;
  Timer? _debounceTimer;

  // === GETTERS ===
  String get keyword => _keyword;
  Set<DonationCategory> get selectedCategories => _selectedCategories;
  double get radiusKm => _radiusKm;
  LatLng get userLocation => _userLocation;
  UserRole get userRole => _userRole;
  List<DonationItem> get results => _results;
  int get totalItems => _totalItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ViewMode get viewMode => _viewMode;
  ItemStatus? get adminStatusFilter => _adminStatusFilter;
  bool get isLocationVerified => _isLocationVerified;

  /// Inisialisasi provider dengan role dan lokasi
  Future<void> initialize({
    required UserRole role,
    bool isVerified = true,
  }) async {
    _userRole = role;
    _isLocationVerified = isVerified;

    if (!_isLocationVerified && role == UserRole.penerima) {
      notifyListeners();
      return;
    }

    // Coba ambil lokasi GPS user
    await _tryGetUserLocation();
    await search();
  }

  /// Coba ambil lokasi GPS, fallback ke default Bandung
  Future<void> _tryGetUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // Fallback ke lokasi default
        debugPrint('GPS permission denied, menggunakan lokasi default Bandung');
        _userLocation = MockData.defaultUserLocation;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      // Validasi dalam wilayah Indonesia
      if (newLocation.latitude >= -11.0 &&
          newLocation.latitude <= 6.0 &&
          newLocation.longitude >= 95.0 &&
          newLocation.longitude <= 141.0) {
        _userLocation = newLocation;
      } else {
        _userLocation = MockData.defaultUserLocation;
      }
    } catch (e) {
      debugPrint('Error mendapatkan lokasi GPS: $e');
      _userLocation = MockData.defaultUserLocation;
    }
  }

  /// Set keyword pencarian dengan debounce 300ms
  void setKeyword(String value) {
    _keyword = value;

    // Cancel timer lama
    _debounceTimer?.cancel();

    // Debounce 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      search();
    });
  }

  /// Toggle kategori (multi-select)
  void toggleCategory(DonationCategory category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories = Set.from(_selectedCategories)..remove(category);
    } else {
      _selectedCategories = Set.from(_selectedCategories)..add(category);
    }
    search();
  }

  /// Reset semua kategori (pilih "Semua")
  void clearCategories() {
    _selectedCategories = {};
    search();
  }

  /// Set radius pencarian
  void setRadius(double value) {
    _radiusKm = value;
    search();
  }

  /// Set mode tampilan (list/map)
  void setViewMode(ViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  /// Set filter status admin
  void setAdminStatusFilter(ItemStatus? status) {
    _adminStatusFilter = status;
    search();
  }

  /// Set lokasi user manual (untuk Admin)
  void setUserLocation(LatLng location) {
    _userLocation = location;
    search();
  }

  /// Perlebar radius ke 25 km (CTA empty state)
  void expandRadius() {
    _radiusKm = 25.0;
    search();
  }

  /// Reset semua filter
  void resetFilters() {
    _keyword = '';
    _selectedCategories = {};
    _radiusKm = 10.0;
    _adminStatusFilter = null;
    search();
  }

  /// Eksekusi pencarian utama
  Future<void> search() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _results = await _service.searchAndFilter(
        userLocation: _userLocation,
        userRole: _userRole,
        selectedCategories:
            _selectedCategories.isEmpty ? null : _selectedCategories,
        keyword: _keyword,
        maxRadiusKm: _radiusKm,
        adminStatusFilter: _adminStatusFilter,
      );

      _totalItems = await _service.getTotalItemCount();
    } on InvalidCoordinateException catch (e) {
      _errorMessage = e.message;
      _results = [];
    } catch (e) {
      _errorMessage = AppErrorHandler.mapErrorToMessage(e);
      _results = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
