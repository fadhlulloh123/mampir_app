import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/place_model.dart';

/// ============================================================
/// GOOGLE PLACES SERVICE (PLACES API NEW) — REAL & AUTHENTIC
/// ============================================================
/// Menghubungkan aplikasi MAMPIR langsung ke Google Places API (New)
/// resmi menggunakan API Key Google Cloud.
/// Mendukung pencarian teks warung makan, cafe, resto, dan warkop
/// di wilayah Purwokerto dan sekitarnya lengkap dengan rating nyata,
/// jumlah ulasan nyata, alamat jalan asli, dan koordinat GPS asli.
/// ============================================================
class PlacesApiException implements Exception {
  final String message;
  final int? statusCode;
  PlacesApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class GooglePlacesService {
  static const String _endpoint =
      'https://places.googleapis.com/v1/places:searchText';
  static const String _nearbyEndpoint =
      'https://places.googleapis.com/v1/places:searchNearby';

  /// Tipe yang dipakai saat filter kategori = "Semua", supaya hasil
  /// tetap relevan (tempat makan/minum/nongkrong), bukan tempat acak.
  static const List<String> nearbyAllTypes = [
    'restaurant',
    'cafe',
    'coffee_shop',
    'fast_food_restaurant',
    'meal_takeaway',
    'bar',
  ];

  /// Pemetaan kategori UI MAMPIR -> tipe Google Places API (New).
  static const Map<String, List<String>> nearbyCategoryTypes = {
    'Restoran': ['restaurant'],
    'Warung Makan': ['restaurant', 'meal_takeaway'],
    'Cafe': ['cafe'],
    'Coffee Shop': ['coffee_shop'],
    'Tempat Nongkrong': ['cafe', 'bar'],
    'Fast Food': ['fast_food_restaurant'],
  };

  final http.Client _client;
  final Map<String, List<PlaceModel>> _cache = {};

  GooglePlacesService({http.Client? client})
    : _client = client ?? http.Client();

  String get _apiKey => ApiConfig.googlePlacesApiKey;

  /// Cari tempat makan di Purwokerto berdasarkan kata kunci asli pengguna.
  /// Contoh: "ayam penyet", "soto", "cafe baturraden", "mendoan".
  Future<List<PlaceModel>> searchPlaces(
    String query, {
    double? lat,
    double? lng,
    String? region,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    final cacheKey =
        '${trimmed.toLowerCase()}_${region ?? ''}_${lat ?? ''}_${lng ?? ''}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      // Pastikan query berorientasi ke Purwokerto & Banyumas jika belum tercantum
      String effectiveQuery = trimmed;
      final lower = trimmed.toLowerCase();
      if (!lower.contains('purwokerto') &&
          !lower.contains('banyumas') &&
          !lower.contains('baturraden') &&
          !lower.contains('sokaraja')) {
        if (region != null && region.isNotEmpty && region != 'Semua Wilayah') {
          effectiveQuery = '$trimmed $region Purwokerto';
        } else {
          effectiveQuery = '$trimmed Purwokerto';
        }
      }

      final centerLat = lat ?? -7.4244;
      final centerLng = lng ?? 109.2304;

      final body = jsonEncode({
        'textQuery': effectiveQuery,
        'locationBias': {
          'circle': {
            'center': {'latitude': centerLat, 'longitude': centerLng},
            'radius': 15000.0,
          },
        },
        'languageCode': 'id',
        'maxResultCount': 20,
      });

      final response = await _client.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': ApiConfig.googlePlacesApiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,'
              'places.location,places.rating,places.userRatingCount,'
              'places.priceLevel,places.primaryType,places.types,'
              'places.editorialSummary,places.regularOpeningHours.openNow,'
              'places.regularOpeningHours.weekdayDescriptions,places.photos',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final placesJson = data['places'] as List<dynamic>?;
      if (placesJson == null || placesJson.isEmpty) {
        return [];
      }

      final results = placesJson
          .map((item) => _mapPlaceToModel(item as Map<String, dynamic>))
          .whereType<PlaceModel>()
          .toList();

      _cache[cacheKey] = results;
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Cari tempat di sekitar koordinat menggunakan Places API (New)
  /// `places:searchNearby`. Radius dalam kilometer, tipe mengikuti
  /// [nearbyCategoryTypes] atau daftar tipe Google Places langsung.
  Future<List<PlaceModel>> searchNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
    List<String>? includedTypes,
    String? keyword,
    int maxResultCount = 20,
    String rankPreference = 'DISTANCE',
  }) async {
    if (_apiKey.isEmpty) {
      throw PlacesApiException(
        'Google Places API key belum dikonfigurasi. '
        'Jalankan aplikasi dengan --dart-define=GOOGLE_PLACES_API_KEY=...',
      );
    }

    final radiusMeters = (radiusKm <= 0 ? 50000.0 : radiusKm * 1000.0)
        .clamp(1.0, 50000.0);
    final types = includedTypes
        ?.map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final normalizedKeyword = keyword?.trim() ?? '';
    final cacheKey =
        'nearby_${latitude.toStringAsFixed(5)}_'
        '${longitude.toStringAsFixed(5)}_'
        '${radiusMeters.toStringAsFixed(0)}_'
        '${types?.join(',') ?? ''}_$normalizedKeyword'
        '_${rankPreference.toLowerCase()}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final body = jsonEncode({
        'locationRestriction': {
          'circle': {
            'center': {'latitude': latitude, 'longitude': longitude},
            'radius': radiusMeters,
          },
        },
        'maxResultCount': maxResultCount,
        'languageCode': 'id',
        'rankPreference': rankPreference,
        if (types != null && types.isNotEmpty) 'includedTypes': types,
        if (normalizedKeyword.isNotEmpty) 'keyword': normalizedKeyword,
      });

      final response = await _client.post(
        Uri.parse(_nearbyEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,'
              'places.location,places.rating,places.userRatingCount,'
              'places.priceLevel,places.primaryType,places.types,'
              'places.editorialSummary,places.regularOpeningHours.openNow,'
              'places.regularOpeningHours.weekdayDescriptions,places.photos',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        String detail = '';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorJson['error'] as Map<String, dynamic>?;
          detail = error?['message'] as String? ?? '';
        } catch (_) {}
        throw PlacesApiException(
          detail.isNotEmpty
              ? 'Google Places API gagal (${response.statusCode}): $detail'
              : 'Google Places API gagal (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final placesJson = data['places'] as List<dynamic>?;
      if (placesJson == null || placesJson.isEmpty) {
        _cache[cacheKey] = const [];
        return const [];
      }

      final results = placesJson
          .map((item) => _mapPlaceToModel(item as Map<String, dynamic>))
          .whereType<PlaceModel>()
          .toList();

      _cache[cacheKey] = results;
      return results;
    } on PlacesApiException {
      rethrow;
    } catch (e) {
      throw PlacesApiException('Gagal menghubungi Google Places API: $e');
    }
  }

  /// Konversi data asli dari Google Places API (New) ke PlaceModel
  PlaceModel? _mapPlaceToModel(Map<String, dynamic> item) {
    try {
      final id =
          item['id'] as String? ??
          'gplace_${DateTime.now().microsecondsSinceEpoch}';
      final displayNameObj = item['displayName'] as Map<String, dynamic>?;
      final name =
          displayNameObj?['text'] as String? ?? 'Tempat Makan Purwokerto';

      final locationObj = item['location'] as Map<String, dynamic>?;
      if (locationObj == null) return null;
      final lat = (locationObj['latitude'] as num?)?.toDouble();
      final lng = (locationObj['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      final formattedAddress =
          item['formattedAddress'] as String? ??
          'Purwokerto, Banyumas, Jawa Tengah';
      final rating = (item['rating'] as num?)?.toDouble() ?? 0.0;
      final userRatingCount = (item['userRatingCount'] as num?)?.toInt() ?? 0;
      final priceLevel = item['priceLevel'] as String?;
      final primaryType = item['primaryType'] as String? ?? '';
      final summaryObj = item['editorialSummary'] as Map<String, dynamic>?;
      final description = summaryObj?['text'] as String? ??
          (rating > 0
              ? 'Data tempat dari Google Maps dengan rating $rating '
                  'dan $userRatingCount ulasan.'
              : 'Data tempat dari Google Maps.');
      final openingObj = item['regularOpeningHours'] as Map<String, dynamic>?;
      final openingDays = (openingObj?['weekdayDescriptions'] as List<dynamic>?)
          ?.whereType<String>()
          .toList();
      final openNow = openingObj?['openNow'] as bool?;
      final openStatus = openNow == null
          ? null
          : (openNow ? 'Buka sekarang' : 'Tutup sekarang');
      final openHoursText = <String>[
        ?openStatus,
        if (openingDays != null && openingDays.isNotEmpty)
          openingDays.join('; '),
      ].join(' • ');

      // Deteksi Wilayah Kota/Kecamatan dari Alamat Asli
      String city = 'Purwokerto Kota';
      final addrLower = formattedAddress.toLowerCase();
      if (addrLower.contains('baturraden')) {
        city = 'Baturraden';
      } else if (addrLower.contains('sokaraja')) {
        city = 'Sokaraja';
      } else if (addrLower.contains('purwokerto utara') ||
          addrLower.contains('unsoed')) {
        city = 'Purwokerto Utara';
      } else if (addrLower.contains('purwokerto timur')) {
        city = 'Purwokerto Timur';
      } else if (addrLower.contains('purwokerto barat') ||
          addrLower.contains('bar.')) {
        city = 'Purwokerto Barat';
      } else if (addrLower.contains('purwokerto selatan') ||
          addrLower.contains('sel.')) {
        city = 'Purwokerto Selatan';
      }

      // Deteksi kategori untuk kartu Near Me.
      final rawTypes = (item['types'] as List<dynamic>?)
              ?.whereType<String>()
              .map((t) => t.toLowerCase())
              .toList() ??
          const <String>[];
      final nameLower = name.toLowerCase();
      final typeLower = <String>[
        primaryType.toLowerCase(),
        ...rawTypes,
      ].join(' ');

      String category = 'Restoran';
      if (typeLower.contains('fast_food_restaurant') ||
          nameLower.contains('fast food') ||
          nameLower.contains('kfc') ||
          nameLower.contains('mcdonald')) {
        category = 'Fast Food';
      } else if (typeLower.contains('coffee_shop')) {
        category = 'Coffee Shop';
      } else if (nameLower.contains('warkop') ||
          nameLower.contains('angkringan') ||
          nameLower.contains('wedangan') ||
          nameLower.contains('warung kopi') ||
          nameLower.contains('warung makan') ||
          nameLower.contains('warteg')) {
        category = 'Warung Makan';
      } else if (typeLower.contains('cafe') ||
          nameLower.contains('kopi') ||
          nameLower.contains('coffee') ||
          nameLower.contains('cafe')) {
        category = 'Cafe';
      } else if (typeLower.contains('bar')) {
        category = 'Tempat Nongkrong';
      }

      // Estimasi Budget berdasarkan PriceLevel Google
      int minPrice = 15000;
      int maxPrice = 35000;
      switch (priceLevel) {
        case 'PRICE_LEVEL_FREE':
          minPrice = 0;
          maxPrice = 0;
          break;
        case 'PRICE_LEVEL_INEXPENSIVE':
          minPrice = 10000;
          maxPrice = 25000;
          break;
        case 'PRICE_LEVEL_MODERATE':
          minPrice = 25000;
          maxPrice = 60000;
          break;
        case 'PRICE_LEVEL_EXPENSIVE':
          minPrice = 60000;
          maxPrice = 120000;
          break;
        case 'PRICE_LEVEL_VERY_EXPENSIVE':
          minPrice = 120000;
          maxPrice = 250000;
          break;
      }

      // Foto dari Google Places API (New) jika tersedia
      String imageUrl = '';
      final photos = item['photos'] as List<dynamic>?;
      if (photos != null && photos.isNotEmpty) {
        final firstPhoto = photos.first as Map<String, dynamic>?;
        final photoName = firstPhoto?['name'] as String?;
        if (photoName != null &&
            photoName.isNotEmpty &&
            ApiConfig.googlePlacesApiKey.isNotEmpty) {
          imageUrl =
              'https://places.googleapis.com/v1/$photoName/media?maxHeightPx=800&maxWidthPx=1200&key=${ApiConfig.googlePlacesApiKey}';
        }
      }

      return PlaceModel(
        id: id,
        name: name,
        city: city,
        category: category,
        minPrice: minPrice,
        maxPrice: maxPrice,
        avgPrice: (minPrice + maxPrice) ~/ 2,
        rating: rating,
        reviewCount: userRatingCount,
        address: formattedAddress,
        description: description,
        openHours: openHoursText.isEmpty
            ? 'Jam buka tidak tersedia di Google Maps'
            : openHoursText,
        latitude: lat,
        longitude: lng,
        imageUrl: imageUrl,
        facilities: const [],
        tags: [category, city, 'Google Maps'],
        menuHighlights: const [],
      );
    } catch (_) {
      return null;
    }
  }
}
