import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// ============================================================
/// LOCATION SERVICE — KELOLA GPS BERAKURASI TINGGI
/// ============================================================
/// Mengatasi masalah GPS tidak akurat dengan:
/// 1. AndroidSettings dengan FusedLocationProvider (Google Play Services)
///    dan fallback otomatis ke LocationManager.GPS_PROVIDER murni.
/// 2. Mode akurasi tinggi (LocationAccuracy.bestForNavigation).
/// 3. Filter akurasi (akurasi di bawah toleransi meter).
/// 4. Cache posisi terkini yang tersinkronisasi di seluruh aplikasi.
/// 5. Stream lokasi dinamis untuk peta dan layar rute waktu nyata.
/// 6. Penghitungan jarak berbasis geodesik WGS-84 (Geolocator.distanceBetween).
/// ============================================================
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  static LocationService get instance => _instance;

  LocationService._internal();

  Position? _currentPosition;
  DateTime? _lastFetchTime;
  StreamSubscription<Position>? _trackingSubscription;

  final StreamController<Position> _locationStreamController =
      StreamController<Position>.broadcast();

  /// Stream posisi pengguna yang selalu terbarui
  Stream<Position> get onLocationChanged => _locationStreamController.stream;

  /// Posisi Position terkini dari geolocator
  Position? get currentPosition => _currentPosition;

  /// Koordinat LatLng untuk FlutterMap / GoogleMaps
  LatLng? get currentLatLng => _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : null;

  /// Tingkat akurasi posisi terkini dalam meter (semakin kecil semakin akurat)
  double? get currentAccuracy => _currentPosition?.accuracy;

  /// Mendapatkan konfigurasi LocationSettings terbaik per platform
  LocationSettings _buildLocationSettings({
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    int distanceFilter = 2,
    int intervalSeconds = 2,
    bool forceLocationManager = false,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        forceLocationManager: forceLocationManager,
        intervalDuration: Duration(seconds: intervalSeconds),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: accuracy,
        activityType: ActivityType.fitness,
        distanceFilter: distanceFilter,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: false,
      );
    }
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
  }

  /// Memeriksa dan meminta izin lokasi pengguna
  Future<bool> checkAndRequestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// Mendapatkan lokasi GPS pengguna dengan prioritas akurasi terbaik
  Future<Position?> getCurrentLocation({bool forceRefresh = false}) async {
    try {
      // 1. Cek izin dan status layanan
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        return _currentPosition;
      }

      // 2. Jika ada posisi segar (< 15 detik) dan forceRefresh == false, gunakan langsung
      if (!forceRefresh &&
          _currentPosition != null &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!).inSeconds < 15) {
        return _currentPosition;
      }

      // 3. Cek posisi terakhir diketahui sebagai baseline awal jika belum ada cache
      if (_currentPosition == null) {
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null && lastKnown.accuracy <= 100) {
            _updatePosition(lastKnown);
          }
        } catch (_) {}
      }

      // 4. Request GPS dengan akurasi terbaik (Fused Location Provider)
      Position? resolved;
      try {
        resolved = await Geolocator.getCurrentPosition(
          locationSettings: _buildLocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            forceLocationManager: false,
          ),
        ).timeout(const Duration(seconds: 14));
      } catch (_) {
        // 5. Fallback ke native LocationManager.GPS_PROVIDER murni jika Fused Provider gagal
        try {
          resolved = await Geolocator.getCurrentPosition(
            locationSettings: _buildLocationSettings(
              accuracy: LocationAccuracy.high,
              forceLocationManager: true,
            ),
          ).timeout(const Duration(seconds: 10));
        } catch (_) {
          // Fallback terakhir: last known position dari sistem OS
          try {
            resolved = await Geolocator.getLastKnownPosition();
          } catch (_) {}
        }
      }

      if (resolved != null) {
        _updatePosition(resolved);
        return resolved;
      }

      return _currentPosition;
    } catch (_) {
      return _currentPosition;
    }
  }

  /// Memulai pemantauan lokasi berkelanjutan (live tracking)
  StreamSubscription<Position>? startTracking({
    void Function(Position position)? onPositionChanged,
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    int distanceFilter = 2,
  }) {
    _trackingSubscription?.cancel();

    try {
      final settings = _buildLocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        intervalSeconds: 2,
      );

      _trackingSubscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen((position) {
        _updatePosition(position);
        if (onPositionChanged != null) {
          onPositionChanged(position);
        }
      }, onError: (_) {});
    } catch (_) {}

    return _trackingSubscription;
  }

  /// Menghentikan pelacakan langsung
  void stopTracking() {
    _trackingSubscription?.cancel();
    _trackingSubscription = null;
  }

  void _updatePosition(Position pos) {
    _currentPosition = pos;
    _lastFetchTime = DateTime.now();
    _locationStreamController.add(pos);
  }

  /// Hitung jarak akurat berbasis Geodesik WGS-84 (dalam kilometer)
  double calculateDistanceInKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    if (startLatitude == 0 && startLongitude == 0) return double.infinity;
    if (endLatitude == 0 && endLongitude == 0) return double.infinity;

    final meters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return meters / 1000.0;
  }

  /// Format teks jarak (contoh: '850 m' atau '2.4 km')
  String formatDistanceInKm(double distanceKm) {
    if (!distanceKm.isFinite || distanceKm < 0) return 'Jarak tidak tersedia';
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
