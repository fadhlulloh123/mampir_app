import 'dart:convert';
import 'dart:math' as math;

/// ============================================================
/// MODEL DATA TEMPAT MAKAN & NONGKRONG — MAMPIR APP
/// ============================================================
/// Class ini merepresentasikan satu entitas tempat makan/nongkrong
/// se-BARLINGMASCAKEB dengan dukungan fasilitas, rating, ulasan,
/// harga, koordinat, dan menu andalan.
/// ============================================================

/// Model untuk item menu andalan sebuah tempat.
class MenuHighlight {
  final String name;
  final int price;

  MenuHighlight({required this.name, required this.price});

  /// Factory constructor untuk parsing dari JSON (Web Service response).
  factory MenuHighlight.fromJson(Map<String, dynamic> json) {
    return MenuHighlight(
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
    );
  }

  /// Konversi ke Map untuk dikirim ke Web Service (HTTP POST).
  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
      };
}

/// Model utama yang merepresentasikan satu tempat makan/nongkrong.
class PlaceModel {
  final String id;
  final String name;
  final String city;
  final String category;
  final int minPrice;
  final int maxPrice;
  final int avgPrice;
  final double rating;
  final int reviewCount;
  final List<String> facilities;
  final List<String> tags;
  final String address;
  final String description;
  final String openHours;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final List<MenuHighlight> menuHighlights;

  PlaceModel({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.minPrice,
    required this.maxPrice,
    int? avgPrice,
    required this.rating,
    this.reviewCount = 150,
    List<String>? facilities,
    List<String>? tags,
    required this.address,
    required this.description,
    required this.openHours,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.menuHighlights,
  })  : avgPrice = avgPrice ?? ((minPrice + maxPrice) ~/ 2),
        facilities = facilities ?? tags ?? const [],
        tags = tags ?? facilities ?? const [];

  /// Alias getter averagePrice bertipe double untuk kompatibilitas spesifikasi
  double get averagePrice => avgPrice.toDouble();

  /// List nama menu andalan dalam bentuk string
  List<String> get menuHighlightNames =>
      menuHighlights.map((e) => e.name).toList();

  /// ================================================================
  /// fromJson — Parsing data JSON dari response Web Service
  /// ================================================================
  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    // Parsing menu_highlights: bisa berupa List<Map>, List<String>, atau String JSON
    List<MenuHighlight> parseMenuHighlights(dynamic raw) {
      if (raw == null) return [];
      if (raw is String) {
        try {
          final decoded = jsonDecode(raw) as List;
          return decoded.map((e) {
            if (e is Map<String, dynamic>) return MenuHighlight.fromJson(e);
            return MenuHighlight(name: e.toString(), price: 0);
          }).toList();
        } catch (_) {
          return [MenuHighlight(name: raw, price: 0)];
        }
      }
      if (raw is List) {
        return raw.map((e) {
          if (e is Map<String, dynamic>) return MenuHighlight.fromJson(e);
          return MenuHighlight(name: e.toString(), price: 0);
        }).toList();
      }
      return [];
    }

    // Parsing facilities / tags: bisa berupa List<String> atau String JSON
    List<String> parseStringList(dynamic raw) {
      if (raw == null) return [];
      if (raw is String) {
        try {
          final decoded = jsonDecode(raw) as List;
          return decoded.map((e) => e.toString()).toList();
        } catch (_) {
          return [raw];
        }
      }
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return [];
    }

    final rawFacilities = json['facilities'] ?? json['tags'];
    final parsedFacilities = parseStringList(rawFacilities);

    final min = (json['min_price'] as num?)?.toInt() ?? 0;
    final max = (json['max_price'] as num?)?.toInt() ?? min;
    final avg = (json['avg_price'] as num?)?.toInt() ??
        (json['average_price'] as num?)?.toInt() ??
        ((min + max) ~/ 2);

    return PlaceModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      category: json['category'] as String? ?? 'Makan',
      minPrice: min,
      maxPrice: max,
      avgPrice: avg,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (json['review_count'] as num?)?.toInt() ??
          (json['reviewCount'] as num?)?.toInt() ??
          250,
      facilities: parsedFacilities,
      tags: parsedFacilities,
      address: json['address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      openHours: json['open_hours'] as String? ??
          json['openHours'] as String? ??
          '09:00 - 22:00',
      latitude: (json['latitude'] as num?)?.toDouble() ?? -7.424,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 109.230,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String? ?? '',
      menuHighlights: parseMenuHighlights(
          json['menu_highlights'] ?? json['menuHighlights']),
    );
  }

  /// ================================================================
  /// toJson — Serialisasi data untuk dikirim via HTTP POST
  /// ================================================================
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'category': category,
        'min_price': minPrice,
        'max_price': maxPrice,
        'avg_price': avgPrice,
        'rating': rating,
        'review_count': reviewCount,
        'facilities': facilities,
        'tags': tags,
        'address': address,
        'description': description,
        'open_hours': openHours,
        'latitude': latitude,
        'longitude': longitude,
        'image_url': imageUrl,
        'menu_highlights': menuHighlights.map((m) => m.toJson()).toList(),
      };

  /// Helper: cek apakah harga rata-rata tempat ini di bawah budget user.
  bool isWithinBudget(int userBudget) =>
      userBudget <= 0 || avgPrice <= userBudget || minPrice <= userBudget;

  /// Helper: hitung skor kecocokan berdasarkan preferensi user.
  int matchScore(List<String> userTags) {
    if (userTags.isEmpty) return 0;
    return facilities.where((tag) => userTags.contains(tag)).length;
  }

  /// Format ulasan untuk tampilan kartu UI (contoh: '1,2k' atau '980')
  String get formattedReviewCount {
    if (reviewCount >= 1000) {
      final double inK = reviewCount / 1000.0;
      return '${inK.toStringAsFixed(1).replaceAll('.', ',')}k';
    }
    return reviewCount.toString();
  }

  /// Hitung estimasi jarak dari koordinat referensi dalam kilometer
  double distanceInKmFrom(double refLat, double refLng) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        math.cos((latitude - refLat) * p) / 2 +
        math.cos(refLat * p) *
            math.cos(latitude * p) *
            (1 - math.cos((longitude - refLng) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Format teks jarak (contoh: '1.2 km' atau '800 m')
  String formattedDistance([double refLat = -7.4244, double refLng = 109.2302]) {
    final dist = distanceInKmFrom(refLat, refLng);
    if (dist < 1.0) {
      final m = (dist * 1000).round();
      return '$m m';
    }
    return '${dist.toStringAsFixed(1)} km';
  }

  /// Format rentang harga sesuai UI mockup: 'Rp 15.000 - 50.000'
  String get priceRange {
    if (minPrice == maxPrice) {
      return 'Rp ${_formatRupiah(minPrice)}';
    }
    return 'Rp ${_formatRupiah(minPrice)} - ${_formatRupiah(maxPrice)}';
  }

  /// Format harga rata-rata tunggal
  String get formattedAveragePrice => 'Rp ${_formatRupiah(avgPrice)}';

  static String _formatRupiah(int amount) {
    final str = amount.toString();
    final result = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(str[i]);
    }
    return result.toString();
  }
}
