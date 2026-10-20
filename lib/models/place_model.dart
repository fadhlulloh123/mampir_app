import 'dart:convert';

/// ============================================================
/// MODEL DATA TEMPAT MAKAN & NONGKRONG — MAMPIR APP
/// ============================================================
/// Class ini merepresentasikan satu entitas tempat makan/nongkrong.
/// Digunakan untuk:
/// - Parsing data JSON dari Web Service (Supabase REST API)
/// - Menyimpan data fallback bawaan
/// - Serialisasi data untuk dikirim via HTTP POST
/// ============================================================

/// Model untuk item menu andalan sebuah tempat.
class MenuHighlight {
  final String name;
  final int price;

  MenuHighlight({required this.name, required this.price});

  /// Factory constructor untuk parsing dari JSON (Web Service response).
  factory MenuHighlight.fromJson(Map<String, dynamic> json) {
    return MenuHighlight(
      name: json['name'] as String,
      price: (json['price'] as num).toInt(),
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
    required this.avgPrice,
    required this.rating,
    required this.tags,
    required this.address,
    required this.description,
    required this.openHours,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.menuHighlights,
  });

  /// ================================================================
  /// fromJson — Parsing data JSON dari response Web Service
  /// ================================================================
  /// Method ini dipanggil setelah menerima response HTTP GET dari
  /// Supabase REST API. Data JSON di-decode menggunakan jsonDecode()
  /// lalu di-mapping ke object PlaceModel.
  ///
  /// Contoh penggunaan di ApiService:
  ///   final data = jsonDecode(response.body) as List;
  ///   return data.map((json) => PlaceModel.fromJson(json)).toList();
  /// ================================================================
  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    // Parsing menu_highlights: bisa berupa List<Map> atau String JSON
    List<MenuHighlight> parseMenuHighlights(dynamic raw) {
      if (raw == null) return [];
      if (raw is String) {
        try {
          final decoded = jsonDecode(raw) as List;
          return decoded
              .map((e) => MenuHighlight.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {
          return [];
        }
      }
      if (raw is List) {
        return raw
            .map((e) => MenuHighlight.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    // Parsing tags: bisa berupa List<String> atau String JSON
    List<String> parseTags(dynamic raw) {
      if (raw == null) return [];
      if (raw is String) {
        try {
          final decoded = jsonDecode(raw) as List;
          return decoded.cast<String>();
        } catch (_) {
          return [];
        }
      }
      if (raw is List) {
        return raw.cast<String>();
      }
      return [];
    }

    return PlaceModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      category: json['category'] as String? ?? '',
      minPrice: (json['min_price'] as num?)?.toInt() ?? 0,
      maxPrice: (json['max_price'] as num?)?.toInt() ?? 0,
      avgPrice: (json['avg_price'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      tags: parseTags(json['tags']),
      address: json['address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      openHours: json['open_hours'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String? ?? '',
      menuHighlights: parseMenuHighlights(json['menu_highlights']),
    );
  }

  /// ================================================================
  /// toJson — Serialisasi data untuk dikirim via HTTP POST
  /// ================================================================
  /// Method ini digunakan saat pengguna mengusulkan tempat baru
  /// melalui form "Tambah Tempat". Data di-convert ke Map<String,dynamic>
  /// lalu di-encode dengan jsonEncode() untuk dikirim sebagai body
  /// HTTP POST request ke Supabase REST API.
  ///
  /// Contoh penggunaan di ApiService:
  ///   final body = jsonEncode(newPlace.toJson());
  ///   await http.post(url, headers: headers, body: body);
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
        'tags': tags,
        'address': address,
        'description': description,
        'open_hours': openHours,
        'latitude': latitude,
        'longitude': longitude,
        'image_url': imageUrl,
        'menu_highlights':
            menuHighlights.map((m) => m.toJson()).toList(),
      };

  /// Helper: cek apakah harga rata-rata tempat ini di bawah budget user.
  bool isWithinBudget(int userBudget) => avgPrice <= userBudget;

  /// Helper: hitung skor kecocokan berdasarkan tag preferensi user.
  /// Semakin banyak tag yang cocok, skor semakin tinggi.
  int matchScore(List<String> userTags) {
    if (userTags.isEmpty) return 0;
    return tags.where((tag) => userTags.contains(tag)).length;
  }

  /// Format harga ke Rupiah untuk ditampilkan di UI.
  String get priceRange => 'Rp${_formatRupiah(minPrice)} - Rp${_formatRupiah(maxPrice)}';

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
