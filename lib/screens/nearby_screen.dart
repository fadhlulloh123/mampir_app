import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../models/place_model.dart';
import '../services/google_places_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'place_detail_screen.dart';
import 'route_screen.dart';

/// ============================================================
/// NEAR ME / TEMPAT TERDEKAT — MAMPIR
/// ============================================================
/// Menampilkan tempat makan & nongkrong di sekitar pengguna dengan:
/// - Deteksi lokasi GPS real-time + tombol perbarui lokasi
/// - Filter radius 0-1, 1-3, 3-5, 5-10, dan >10 km
/// - Filter kategori (restoran, warung, cafe, coffee shop, nongkrong, fast food)
/// - Pencarian memakai Google Places API (New) places:searchNearby
/// - Peta Google Maps dengan marker user + marker tempat
/// - Daftar kartu ala Gojek dengan detail & petunjuk arah
/// ============================================================
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  static const List<String> _radiusOptions = [
    '0–1 km',
    '1–3 km',
    '3–5 km',
    '5–10 km',
    '>10 km',
  ];

  static const List<String> _categoryOptions = [
    'Semua',
    'Restoran',
    'Warung Makan',
    'Cafe',
    'Coffee Shop',
    'Tempat Nongkrong',
    'Fast Food',
  ];

  final GooglePlacesService _placesService = GooglePlacesService();
  final LocationService _locationService = LocationService.instance;

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _locationSubscription;

  latlng.LatLng? _userLocation;
  List<PlaceModel> _places = <PlaceModel>[];
  String _radiusFilter = '3–5 km';
  String? _selectedCategory;
  String _sortBy = 'nearest';
  bool _loadingLocation = true;
  bool _loadingPlaces = false;
  String? _errorMessage;
  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    _initializeNearby();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationService.stopTracking();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeNearby() async {
    await _loadCurrentLocation(forceRefresh: false);
    _listenToLocationChanges();
  }

  Future<void> _loadCurrentLocation({required bool forceRefresh}) async {
    setState(() {
      _loadingLocation = true;
      _errorMessage = null;
    });

    final position = await _locationService.getCurrentLocation(
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;

    if (position != null) {
      setState(() {
        _userLocation = latlng.LatLng(position.latitude, position.longitude);
        _loadingLocation = false;
        _errorMessage = null;
      });
      await _fetchNearbyPlaces();
    } else {
      setState(() {
        _loadingLocation = false;
        _errorMessage =
            'Izin lokasi belum diberikan atau GPS tidak aktif. '
            'Aktifkan GPS dan izinkan MAMPIR mengakses lokasi, lalu coba lagi.';
      });
    }
  }

  void _listenToLocationChanges() {
    _locationSubscription?.cancel();
    _locationService.startTracking(distanceFilter: 10);
    _locationSubscription = _locationService.onLocationChanged.listen((
      position,
    ) {
      if (!mounted) return;
      setState(() {
        _userLocation = latlng.LatLng(position.latitude, position.longitude);
      });
    });
  }

  Future<void> _fetchNearbyPlaces() async {
    final userLocation = _userLocation;
    if (userLocation == null) return;

    setState(() {
      _loadingPlaces = true;
      _errorMessage = null;
    });
    final requestId = ++_requestSerial;

    try {
      final types = _selectedCategory == null
          ? GooglePlacesService.nearbyAllTypes
          : GooglePlacesService.nearbyCategoryTypes[_selectedCategory!];
      final queryRadiusKm = _radiusToQueryKm(_radiusFilter);
      final places = await _placesService.searchNearby(
        latitude: userLocation.latitude,
        longitude: userLocation.longitude,
        radiusKm: queryRadiusKm,
        includedTypes: types,
        maxResultCount: 20,
        // Untuk bucket >10 km, pakai popularitas agar hasil tidak
        // didominasi tempat-tempat yang jaraknya <10 km.
        rankPreference: _radiusFilter == '>10 km' ? 'POPULARITY' : 'DISTANCE',
      );

      final filtered = places.where((place) {
        final distance = _distanceKm(place);
        return distance.isFinite && _distanceInSelectedRange(distance);
      }).toList();

      _sortPlaces(filtered);

      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _places = filtered;
        _loadingPlaces = false;
        _errorMessage = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _adjustCamera());
    } on PlacesApiException catch (error) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _loadingPlaces = false;
        _places = <PlaceModel>[];
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _loadingPlaces = false;
        _places = <PlaceModel>[];
        _errorMessage = 'Gagal memuat tempat terdekat: $error';
      });
    }
  }

  void _sortPlaces(List<PlaceModel> places) {
    if (_sortBy == 'rating') {
      places.sort((a, b) {
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        return _distanceKm(a).compareTo(_distanceKm(b));
      });
    } else {
      places.sort((a, b) => _distanceKm(a).compareTo(_distanceKm(b)));
    }
  }

  double _distanceKm(PlaceModel place) {
    final userLocation = _userLocation;
    if (userLocation == null) return double.infinity;
    return place.distanceInKmFrom(
      userLocation.latitude,
      userLocation.longitude,
    );
  }

  double _radiusToQueryKm(String label) {
    switch (label) {
      case '0–1 km':
        return 1;
      case '1–3 km':
        return 3;
      case '3–5 km':
        return 5;
      case '5–10 km':
        return 10;
      case '>10 km':
        return 50;
      default:
        return 5;
    }
  }

  bool _distanceInSelectedRange(double distance) {
    switch (_radiusFilter) {
      case '0–1 km':
        return distance <= 1;
      case '1–3 km':
        return distance > 1 && distance <= 3;
      case '3–5 km':
        return distance > 3 && distance <= 5;
      case '5–10 km':
        return distance > 5 && distance <= 10;
      case '>10 km':
        return distance > 10;
      default:
        return true;
    }
  }

  void _adjustCamera() {
    final points = <latlng.LatLng>[
      ?_userLocation,
      ..._places.map(
        (place) => latlng.LatLng(place.latitude, place.longitude),
      ),
    ];
    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }

    var south = points.first.latitude;
    var north = points.first.latitude;
    var west = points.first.longitude;
    var east = points.first.longitude;

    for (final point in points.skip(1)) {
      south = math.min(south, point.latitude);
      north = math.max(north, point.latitude);
      west = math.min(west, point.longitude);
      east = math.max(east, point.longitude);
    }

    final latPadding = math.max((north - south) * 0.12, 0.002);
    final lngPadding = math.max((east - west) * 0.12, 0.002);
    final bounds = LatLngBounds(
      latlng.LatLng(south - latPadding, west - lngPadding),
      latlng.LatLng(north + latPadding, east + lngPadding),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  List<Marker> _buildFlutterMapMarkers() {
    final markers = <Marker>[];

    // Marker pengguna (biru)
    final userLocation = _userLocation;
    if (userLocation != null) {
      markers.add(
        Marker(
          point: userLocation,
          width: 26,
          height: 26,
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.my_location,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    // Marker tempat (oranye)
    for (final place in _places) {
      final point = latlng.LatLng(place.latitude, place.longitude);
      markers.add(
        Marker(
          point: point,
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _showPlaceInfo(place),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.warmGradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Future<void> _refreshLocation() async {
    await _loadCurrentLocation(forceRefresh: true);
  }

  void _onCategoryChanged(String? category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
    if (_userLocation != null) {
      _fetchNearbyPlaces();
    }
  }

  void _onRadiusChanged(String radius) {
    if (_radiusFilter == radius) return;
    setState(() => _radiusFilter = radius);
    if (_userLocation != null) {
      _fetchNearbyPlaces();
    }
  }

  void _onSortChanged(String sort) {
    if (_sortBy == sort) return;
    setState(() {
      _sortBy = sort;
      final list = List<PlaceModel>.from(_places);
      _sortPlaces(list);
      _places = list;
    });
  }

  latlng.LatLng? _widgetUserLocation() {
    final userLocation = _userLocation;
    if (userLocation == null) return null;
    return latlng.LatLng(userLocation.latitude, userLocation.longitude);
  }

  void _openDetail(PlaceModel place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailScreen(
          place: place,
          userLocation: _widgetUserLocation(),
        ),
      ),
    );
  }

  void _openRoute(PlaceModel place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RouteScreen(place: place, userLocation: _widgetUserLocation()),
      ),
    );
  }

  Future<void> _showPlaceInfo(PlaceModel place) async {
    final colors = AppTheme.colors(context);
    final distance = _distanceKm(place);

    _mapController.move(
      latlng.LatLng(place.latitude, place.longitude),
      16,
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surfaceNavy,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.borderNavy,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: _placeImageWidget(place, colors),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${place.category} • ${place.priceRange}',
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppTheme.gold,
                                  size: 16,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  place.rating > 0
                                      ? place.rating.toStringAsFixed(1)
                                      : 'Belum ada rating',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.near_me_rounded,
                                  color: colors.textSecondary,
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _formatDistanceKm(distance),
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: Icon(Icons.close, color: colors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppTheme.orange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          place.address,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (place.openHours.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: AppTheme.orange,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            place.openHours,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _openDetail(place);
                          },
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('Lihat Detail'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textPrimary,
                            side: BorderSide(color: colors.borderNavy),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _openRoute(place);
                          },
                          icon: const Icon(Icons.directions_rounded, size: 18),
                          label: const Text('Petunjuk Arah'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _placeImageWidget(PlaceModel place, AppColors colors) {
    final imageUrl = place.imageUrl.trim();
    if (imageUrl.isEmpty) {
      return Container(
        color: colors.searchNavy,
        child: const Icon(
          Icons.restaurant_rounded,
          color: AppTheme.orange,
          size: 30,
        ),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: colors.searchNavy,
        child: const Icon(
          Icons.restaurant_rounded,
          color: AppTheme.orange,
          size: 30,
        ),
      ),
    );
  }

  String _formatDistanceKm(double distance) {
    if (!distance.isFinite) return 'Jarak tidak tersedia';
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  String _shortOpenStatus(String openHours) {
    final lower = openHours.toLowerCase();
    if (lower.contains('buka sekarang')) return 'Buka sekarang';
    if (lower.contains('tutup sekarang')) return 'Tutup sekarang';
    return openHours.split(' • ').first;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Stack(
        children: [
          _buildMap(),
          _buildBottomPanel(colors),
          _buildTopOverlay(colors),
          if (_loadingLocation || _loadingPlaces)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: AppTheme.gold,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const latlng.LatLng(-7.4244, 109.2304),
        initialZoom: 13.5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
          subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
          userAgentPackageName: 'com.mampir.mampir_app',
        ),
        if (_userLocation != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: _userLocation!,
                radius: 20,
                useRadiusInMeter: false,
                color: Colors.blueAccent.withValues(alpha: 0.15),
                borderColor: Colors.blueAccent.withValues(alpha: 0.4),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),
        MarkerLayer(
          markers: _buildFlutterMapMarkers(),
        ),
      ],
    );
  }

  Widget _buildTopOverlay(AppColors colors) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  _circleButton(
                    icon: Icons.arrow_back_rounded,
                    colors: colors,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceNavy.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.borderNavy),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: colors.isDark ? 0.30 : 0.08,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            color: AppTheme.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tempat Terdekat',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  _loadingLocation
                                      ? 'Mendeteksi lokasi kamu...'
                                      : _userLocation == null
                                      ? 'Lokasi belum tersedia'
                                      : '${_places.length} tempat • $_radiusFilter',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _circleButton(
                            icon: Icons.my_location_rounded,
                            colors: colors,
                            loading: _loadingLocation || _loadingPlaces,
                            onTap: _refreshLocation,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildCategoryFilters(colors),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildRadiusAndSortFilters(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required AppColors colors,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return Material(
      color: colors.surfaceNavy,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: loading ? null : onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.gold,
                  ),
                )
              : Icon(icon, color: AppTheme.gold, size: 20),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(AppColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categoryOptions.map((label) {
          final value = label == 'Semua' ? null : label;
          return _buildFilterChip(
            label: label,
            selected: _selectedCategory == value,
            colors: colors,
            onSelected: () => _onCategoryChanged(value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRadiusAndSortFilters(AppColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._radiusOptions.map(
            (label) => _buildFilterChip(
              label: label,
              selected: _radiusFilter == label,
              colors: colors,
              onSelected: () => _onRadiusChanged(label),
            ),
          ),
          Container(
            width: 1,
            height: 22,
            margin: const EdgeInsets.only(right: 8, left: 2),
            color: colors.borderNavy,
          ),
          _buildFilterChip(
            label: 'Terdekat',
            selected: _sortBy == 'nearest',
            colors: colors,
            onSelected: () => _onSortChanged('nearest'),
          ),
          _buildFilterChip(
            label: 'Rating Tertinggi',
            selected: _sortBy == 'rating',
            colors: colors,
            onSelected: () => _onSortChanged('rating'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required AppColors colors,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        labelStyle: TextStyle(
          color: selected ? Colors.black : colors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        selectedColor: AppTheme.gold,
        backgroundColor: colors.surfaceNavy.withValues(alpha: 0.96),
        side: BorderSide(color: selected ? AppTheme.gold : colors.borderNavy),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildBottomPanel(AppColors colors) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = math.max(screenHeight * 0.46, 300.0);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: sheetHeight,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceNavy,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: colors.isDark ? 0.45 : 0.12,
              ),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderNavy,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _loadingPlaces
                          ? 'Mencari tempat terdekat...'
                          : 'Daftar Tempat (${_places.length})',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (_loadingPlaces)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.gold,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _buildListContent(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent(AppColors colors) {
    if (_loadingPlaces) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.gold),
      );
    }
    if (_errorMessage != null) {
      return _buildErrorState(colors);
    }
    if (_places.isEmpty) {
      return _buildEmptyState(colors);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: _places.length,
      itemBuilder: (context, index) => _buildPlaceCard(_places[index], colors),
    );
  }

  Widget _buildPlaceCard(PlaceModel place, AppColors colors) {
    final distance = _distanceKm(place);
    final status = _shortOpenStatus(place.openHours);
    final statusLower = status.toLowerCase();
    final statusColor = statusLower.contains('buka')
        ? Colors.greenAccent
        : statusLower.contains('tutup')
        ? Colors.redAccent
        : colors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.cardNavy,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderNavy),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 86,
                  height: 86,
                  child: _placeImageWidget(place, colors),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${place.category} • ${_formatDistanceKm(distance)}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppTheme.gold,
                          size: 15,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          place.rating > 0
                              ? '${place.rating.toStringAsFixed(1)} '
                                    '(${place.formattedReviewCount})'
                              : 'Belum ada rating',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                    if (place.openHours.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openDetail(place),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.borderNavy),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Lihat Detail',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _openRoute(place),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Petunjuk Arah',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_searching_rounded,
              size: 44,
              color: colors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada tempat ditemukan',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Coba ubah filter jarak/kategori atau perbarui lokasi kamu.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AppColors colors) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppTheme.orange,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadingLocation || _loadingPlaces
                  ? null
                  : () {
                      if (_userLocation == null) {
                        _loadCurrentLocation(forceRefresh: true);
                      } else {
                        _fetchNearbyPlaces();
                      }
                    },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
            ),
            if (_userLocation == null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Geolocator.openAppSettings(),
                icon: const Icon(Icons.settings_rounded, size: 18),
                label: const Text('Buka Pengaturan Izin'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.gold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
