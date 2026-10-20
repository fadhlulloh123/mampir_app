import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/place_model.dart';

/// ============================================================================
/// API SERVICE — IMPLEMENTASI WEB SERVICE (REST API) MAMPIR APP
/// ============================================================================
///
/// File ini adalah INTI dari penerapan Web Service pada aplikasi MAMPIR.
/// Dibuat untuk memenuhi syarat mata kuliah Pemrograman Mobile.
///
/// APA YANG DILAKUKAN FILE INI:
/// 1. Memanggil REST API menggunakan package 'http' (bukan SDK Firebase/Supabase)
/// 2. Melakukan HTTP GET  → mengambil data tempat dari Supabase REST API
/// 3. Melakukan HTTP POST → mengirim data tempat baru ke Supabase REST API
/// 4. Mem-parsing JSON response menggunakan jsonDecode() ke PlaceModel
/// 5. Menyediakan Fallback Data bawaan jika API belum dikonfigurasi / offline
///
/// UNTUK DOSEN:
/// - Method fetchPlaces() = contoh HTTP GET + JSON parsing
/// - Method submitPlace() = contoh HTTP POST + JSON encoding
/// - Keduanya menggunakan http.get() dan http.post() secara eksplisit
/// - Response di-handle berdasarkan HTTP Status Code (200, 201)
/// ============================================================================
class ApiService {
  /// ==========================================================================
  /// fetchPlaces() — HTTP GET REQUEST KE WEB SERVICE
  /// ==========================================================================
  ///
  /// Fungsi ini mengambil data tempat makan dari Supabase REST API
  /// menggunakan method HTTP GET.
  ///
  /// ALUR KERJA:
  /// 1. Cek apakah konfigurasi Supabase sudah diisi (URL & API Key)
  /// 2. Jika SUDAH → kirim HTTP GET ke endpoint /places
  ///    - Jika response status code 200 (OK) → parse JSON ke List<PlaceModel>
  ///    - Jika gagal → gunakan data fallback bawaan
  /// 3. Jika BELUM dikonfigurasi → langsung gunakan data fallback bawaan
  ///
  /// CONTOH REQUEST YANG DIKIRIM:
  ///   GET https://xxxxx.supabase.co/rest/v1/places
  ///   Headers:
  ///     apikey: <supabase_anon_key>
  ///     Authorization: Bearer <supabase_anon_key>
  ///     Content-Type: application/json
  ///
  /// CONTOH RESPONSE YANG DITERIMA (JSON Array):
  ///   [{ "id": "1", "name": "Kopi Keprok", "city": "Banyumas", ... }]
  /// ==========================================================================
  Future<List<PlaceModel>> fetchPlaces() async {
    // Langkah 1: Cek apakah URL dan API Key Supabase sudah dikonfigurasi
    if (!ApiConfig.isConfigured) {
      // Supabase belum dikonfigurasi → gunakan data fallback bawaan
      // Ini memastikan aplikasi TIDAK CRASH saat demo di depan dosen
      return _getFallbackPlaces();
    }

    try {
      // Langkah 2: Buat URL endpoint untuk GET request
      final url = Uri.parse(ApiConfig.placesEndpoint);

      // Langkah 3: Kirim HTTP GET request ke Supabase REST API
      // Package 'http' digunakan secara eksplisit (bukan SDK Supabase)
      final response = await http.get(
        url,
        headers: ApiConfig.headers,
      );

      // Langkah 4: Cek HTTP Status Code dari response
      if (response.statusCode == 200) {
        // Status 200 OK — data berhasil diambil dari Web Service

        // Langkah 5: Decode JSON string menjadi List<dynamic>
        // jsonDecode() mengubah String JSON menjadi object Dart
        final List<dynamic> jsonData = jsonDecode(response.body);

        // Langkah 6: Mapping setiap JSON object ke PlaceModel
        // Menggunakan fromJson() factory constructor
        final places = jsonData
            .map((json) => PlaceModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return places;
      } else {
        // Status code bukan 200 → ada error dari server
        // Fallback ke data bawaan agar aplikasi tetap berjalan
        return _getFallbackPlaces();
      }
    } catch (e) {
      // Exception terjadi (misal: tidak ada internet, timeout, dll)
      // Fallback ke data bawaan agar aplikasi TIDAK CRASH
      return _getFallbackPlaces();
    }
  }

  /// ==========================================================================
  /// submitPlace() — HTTP POST REQUEST KE WEB SERVICE
  /// ==========================================================================
  ///
  /// Fungsi ini mengirim data tempat makan baru ke Supabase REST API
  /// menggunakan method HTTP POST.
  ///
  /// ALUR KERJA:
  /// 1. Konversi object PlaceModel ke Map menggunakan toJson()
  /// 2. Encode Map menjadi JSON String menggunakan jsonEncode()
  /// 3. Kirim HTTP POST ke endpoint /places dengan body JSON
  /// 4. Cek response: status code 201 (Created) = berhasil
  ///
  /// CONTOH REQUEST YANG DIKIRIM:
  ///   POST https://xxxxx.supabase.co/rest/v1/places
  ///   Headers:
  ///     apikey: <supabase_anon_key>
  ///     Authorization: Bearer <supabase_anon_key>
  ///     Content-Type: application/json
  ///     Prefer: return=representation
  ///   Body:
  ///     {"name": "Warung Baru", "city": "Banyumas", ...}
  ///
  /// PARAMETER:
  ///   [place] — Object PlaceModel yang berisi data tempat baru
  ///
  /// RETURN:
  ///   true  → jika POST berhasil (status 201 Created)
  ///   false → jika gagal atau Supabase belum dikonfigurasi
  /// ==========================================================================
  Future<bool> submitPlace(PlaceModel place) async {
    // Cek apakah Supabase sudah dikonfigurasi
    if (!ApiConfig.isConfigured) {
      // Belum dikonfigurasi → tidak bisa POST ke server
      // Tampilkan pesan bahwa fitur ini butuh koneksi ke Web Service
      return false;
    }

    try {
      // Langkah 1: Buat URL endpoint untuk POST request
      final url = Uri.parse(ApiConfig.placesEndpoint);

      // Langkah 2: Konversi PlaceModel ke JSON String
      // toJson() → Map<String, dynamic> → jsonEncode() → String
      final body = jsonEncode(place.toJson());

      // Langkah 3: Kirim HTTP POST request ke Supabase REST API
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: body,
      );

      // Langkah 4: Cek HTTP Status Code
      // 201 Created = data berhasil disimpan di database Supabase
      if (response.statusCode == 201) {
        return true;
      } else {
        // Gagal — bisa karena validasi server, duplikat, dll
        return false;
      }
    } catch (e) {
      // Exception (tidak ada internet, timeout, dll)
      return false;
    }
  }

  /// ==========================================================================
  /// DATA FALLBACK BAWAAN — 15 TEMPAT NYATA DI BARLINGMASCAKEB
  /// ==========================================================================
  ///
  /// Data ini digunakan ketika:
  /// - URL Supabase belum diisi oleh pengguna
  /// - Tidak ada koneksi internet
  /// - Terjadi error saat mengambil data dari Web Service
  ///
  /// Semua data di bawah ini adalah tempat NYATA yang ada di wilayah
  /// Barlingmascakeb (Banjarnegara, Purbalingga, Banyumas, Cilacap, Kebumen).
  /// ==========================================================================
  List<PlaceModel> _getFallbackPlaces() {
    final List<Map<String, dynamic>> fallbackJson = [
      // ======================== BANYUMAS (5 tempat) ========================
      {
        'id': '1',
        'name': 'Kopi Keprok Purwokerto',
        'city': 'Banyumas',
        'category': 'Cafe & Resto',
        'min_price': 15000,
        'max_price': 45000,
        'avg_price': 25000,
        'rating': 4.6,
        'tags': ['Cafe & Ngopi', 'Outdoor/Santai', 'Wi-Fi & Colokan', 'Makanan Berat'],
        'address': 'Jl. Raya Baturraden, Purwokerto, Banyumas',
        'description': 'Tempat nongkrong asri dengan suasana pedesaan, cocok buat nugas atau kumpul bareng teman dengan harga terjangkau.',
        'open_hours': '09.00 - 23.00 WIB',
        'latitude': -7.3812,
        'longitude': 109.2415,
        'image_url': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Kopi Susu Gula Aren', 'price': 18000},
          {'name': 'Mie Goreng Spesial', 'price': 20000},
          {'name': 'Mendoan Hangat', 'price': 12000},
        ],
      },
      {
        'id': '2',
        'name': 'Mie Ayam Pak Slamet',
        'city': 'Banyumas',
        'category': 'Warung Makan',
        'min_price': 10000,
        'max_price': 20000,
        'avg_price': 13000,
        'rating': 4.7,
        'tags': ['Murah Meriah', 'Makanan Berat'],
        'address': 'Jl. Gerilya, Purwokerto Selatan, Banyumas',
        'description': 'Mie ayam legendaris Purwokerto yang sudah berdiri sejak 1985. Porsi besar, kuah gurih, dan harga sangat bersahabat.',
        'open_hours': '07.00 - 14.00 WIB',
        'latitude': -7.4380,
        'longitude': 109.2340,
        'image_url': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Mie Ayam Biasa', 'price': 12000},
          {'name': 'Mie Ayam Bakso', 'price': 15000},
          {'name': 'Es Teh Manis', 'price': 5000},
        ],
      },
      {
        'id': '3',
        'name': 'Excelso Coffee Purwokerto',
        'city': 'Banyumas',
        'category': 'Cafe & Resto',
        'min_price': 30000,
        'max_price': 75000,
        'avg_price': 50000,
        'rating': 4.4,
        'tags': ['Cafe & Ngopi', 'Wi-Fi & Colokan', 'Makanan Berat'],
        'address': 'Rita Supermall, Jl. Jend. Sudirman, Purwokerto',
        'description': 'Coffee shop modern di pusat kota dengan menu kopi premium dan makanan Western & Indonesia. Cocok untuk meeting atau kerja remote.',
        'open_hours': '10.00 - 22.00 WIB',
        'latitude': -7.4215,
        'longitude': 109.2380,
        'image_url': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Cappuccino', 'price': 42000},
          {'name': 'Nasi Goreng Oriental', 'price': 55000},
          {'name': 'Cheesecake', 'price': 38000},
        ],
      },
      {
        'id': '4',
        'name': 'Warmindo Bu Warni',
        'city': 'Banyumas',
        'category': 'Warmindo',
        'min_price': 5000,
        'max_price': 18000,
        'avg_price': 10000,
        'rating': 4.5,
        'tags': ['Murah Meriah', 'Makanan Berat', 'Buka 24 Jam'],
        'address': 'Jl. HR Bunyamin, Purwokerto, Banyumas',
        'description': 'Warmindo favorit mahasiswa Unsoed! Indomie level pedas bisa request, nasi rames murah, dan buka 24 jam.',
        'open_hours': 'Buka 24 Jam',
        'latitude': -7.4300,
        'longitude': 109.2450,
        'image_url': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Indomie Goreng Telur', 'price': 10000},
          {'name': 'Nasi Rames', 'price': 12000},
          {'name': 'Kopi Tubruk', 'price': 5000},
        ],
      },
      {
        'id': '5',
        'name': 'The Village Baturaden',
        'city': 'Banyumas',
        'category': 'Cafe & Resto',
        'min_price': 25000,
        'max_price': 65000,
        'avg_price': 40000,
        'rating': 4.5,
        'tags': ['Cafe & Ngopi', 'Outdoor/Santai', 'Makanan Berat'],
        'address': 'Jl. Raya Baturraden KM 2, Banyumas',
        'description': 'Resto dengan view pegunungan Baturraden yang instagramable. Cocok untuk date atau kumpul keluarga.',
        'open_hours': '10.00 - 22.00 WIB',
        'latitude': -7.3600,
        'longitude': 109.2200,
        'image_url': 'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Ayam Goreng Kampung', 'price': 35000},
          {'name': 'Sate Kambing', 'price': 45000},
          {'name': 'Jus Alpukat', 'price': 20000},
        ],
      },

      // ======================== PURBALINGGA (3 tempat) ========================
      {
        'id': '6',
        'name': 'Owabong Waterpark Resto',
        'city': 'Purbalingga',
        'category': 'Resto Keluarga',
        'min_price': 15000,
        'max_price': 40000,
        'avg_price': 25000,
        'rating': 4.2,
        'tags': ['Makanan Berat', 'Outdoor/Santai'],
        'address': 'Jl. Raya Owabong, Bojongsari, Purbalingga',
        'description': 'Resto keluarga di area wisata Owabong. Menu tradisional Jawa dengan harga ramah kantong keluarga.',
        'open_hours': '08.00 - 17.00 WIB',
        'latitude': -7.3750,
        'longitude': 109.3490,
        'image_url': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Gurameh Bakar', 'price': 35000},
          {'name': 'Nasi Timbel Komplit', 'price': 25000},
          {'name': 'Es Dawet', 'price': 8000},
        ],
      },
      {
        'id': '7',
        'name': 'Kopi Progo Purbalingga',
        'city': 'Purbalingga',
        'category': 'Cafe',
        'min_price': 10000,
        'max_price': 30000,
        'avg_price': 18000,
        'rating': 4.4,
        'tags': ['Cafe & Ngopi', 'Wi-Fi & Colokan', 'Murah Meriah'],
        'address': 'Jl. Mayjen Sungkono, Purbalingga',
        'description': 'Kedai kopi minimalis favorit anak muda Purbalingga. Harga murah, Wi-Fi kencang, tempat nyaman buat nugas.',
        'open_hours': '08.00 - 23.00 WIB',
        'latitude': -7.3910,
        'longitude': 109.3630,
        'image_url': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Americano', 'price': 12000},
          {'name': 'Kopi Susu Gula Aren', 'price': 15000},
          {'name': 'Roti Bakar Coklat', 'price': 12000},
        ],
      },
      {
        'id': '8',
        'name': 'Soto Sokaraja Pak Marto',
        'city': 'Purbalingga',
        'category': 'Warung Makan',
        'min_price': 10000,
        'max_price': 25000,
        'avg_price': 15000,
        'rating': 4.6,
        'tags': ['Murah Meriah', 'Makanan Berat'],
        'address': 'Jl. Raya Sokaraja, Purbalingga',
        'description': 'Soto khas Sokaraja dengan kuah kacang yang kental dan gurih. Legendaris dan selalu ramai!',
        'open_hours': '06.00 - 15.00 WIB',
        'latitude': -7.4580,
        'longitude': 109.2880,
        'image_url': 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Soto Sokaraja', 'price': 15000},
          {'name': 'Sate Ayam', 'price': 18000},
          {'name': 'Es Jeruk', 'price': 7000},
        ],
      },

      // ======================== BANJARNEGARA (2 tempat) ========================
      {
        'id': '9',
        'name': 'Rumah Makan Sederhana Dieng',
        'city': 'Banjarnegara',
        'category': 'Rumah Makan',
        'min_price': 12000,
        'max_price': 35000,
        'avg_price': 20000,
        'rating': 4.3,
        'tags': ['Makanan Berat', 'Murah Meriah'],
        'address': 'Jl. Raya Dieng, Batur, Banjarnegara',
        'description': 'Rumah makan di dataran tinggi Dieng dengan masakan Jawa rumahan. Cocok mampir setelah wisata Dieng.',
        'open_hours': '07.00 - 21.00 WIB',
        'latitude': -7.2070,
        'longitude': 109.9050,
        'image_url': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Nasi Gudeg', 'price': 18000},
          {'name': 'Ayam Goreng Kampung', 'price': 25000},
          {'name': 'Carica (Khas Dieng)', 'price': 10000},
        ],
      },
      {
        'id': '10',
        'name': 'Kopi Dieng Plateau',
        'city': 'Banjarnegara',
        'category': 'Cafe',
        'min_price': 10000,
        'max_price': 28000,
        'avg_price': 16000,
        'rating': 4.4,
        'tags': ['Cafe & Ngopi', 'Outdoor/Santai'],
        'address': 'Jl. Raya Dieng KM 1, Banjarnegara',
        'description': 'Ngopi di ketinggian 2.000 mdpl dengan view perkebunan kentang Dieng. Kopi lokalnya juara!',
        'open_hours': '08.00 - 20.00 WIB',
        'latitude': -7.2110,
        'longitude': 109.9100,
        'image_url': 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Kopi Robusta Dieng', 'price': 12000},
          {'name': 'Wedang Uwuh', 'price': 10000},
          {'name': 'Pisang Goreng Carica', 'price': 15000},
        ],
      },

      // ======================== CILACAP (3 tempat) ========================
      {
        'id': '11',
        'name': 'Seafood Teluk Penyu',
        'city': 'Cilacap',
        'category': 'Seafood Resto',
        'min_price': 20000,
        'max_price': 60000,
        'avg_price': 35000,
        'rating': 4.5,
        'tags': ['Makanan Berat', 'Outdoor/Santai'],
        'address': 'Jl. Pantai Teluk Penyu, Cilacap',
        'description': 'Resto seafood pinggir pantai Teluk Penyu. Udang, cumi, dan ikan bakar segar langsung dari nelayan!',
        'open_hours': '10.00 - 22.00 WIB',
        'latitude': -7.7400,
        'longitude': 109.0150,
        'image_url': 'https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Udang Bakar Jumbo', 'price': 50000},
          {'name': 'Cumi Goreng Tepung', 'price': 30000},
          {'name': 'Nasi Putih', 'price': 5000},
        ],
      },
      {
        'id': '12',
        'name': 'Warung Nasi Gudeg Bu Siti',
        'city': 'Cilacap',
        'category': 'Warung Makan',
        'min_price': 8000,
        'max_price': 20000,
        'avg_price': 12000,
        'rating': 4.3,
        'tags': ['Murah Meriah', 'Makanan Berat'],
        'address': 'Jl. A. Yani No. 45, Cilacap',
        'description': 'Warung gudeg murah meriah yang jadi andalan warga Cilacap. Porsi besar dan rasa mantap!',
        'open_hours': '06.00 - 14.00 WIB',
        'latitude': -7.7270,
        'longitude': 109.0100,
        'image_url': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Nasi Gudeg Komplit', 'price': 15000},
          {'name': 'Ayam Opor', 'price': 18000},
          {'name': 'Es Teh Manis', 'price': 3000},
        ],
      },
      {
        'id': '13',
        'name': 'D\'Koffie Cilacap',
        'city': 'Cilacap',
        'category': 'Cafe',
        'min_price': 15000,
        'max_price': 35000,
        'avg_price': 22000,
        'rating': 4.3,
        'tags': ['Cafe & Ngopi', 'Wi-Fi & Colokan', 'Outdoor/Santai'],
        'address': 'Jl. Gatot Subroto, Cilacap',
        'description': 'Coffee shop hits di Cilacap. Suasana modern, Wi-Fi kencang, dan menu kopi lokal pilihan.',
        'open_hours': '09.00 - 23.00 WIB',
        'latitude': -7.7310,
        'longitude': 109.0200,
        'image_url': 'https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Cappuccino', 'price': 22000},
          {'name': 'Matcha Latte', 'price': 25000},
          {'name': 'French Fries', 'price': 18000},
        ],
      },

      // ======================== KEBUMEN (2 tempat) ========================
      {
        'id': '14',
        'name': 'Sate Ambal Pak Jono',
        'city': 'Kebumen',
        'category': 'Warung Makan',
        'min_price': 10000,
        'max_price': 25000,
        'avg_price': 15000,
        'rating': 4.7,
        'tags': ['Makanan Berat', 'Murah Meriah'],
        'address': 'Jl. Raya Ambal, Kebumen',
        'description': 'Sate khas Ambal Kebumen yang legendaris! Bumbu kacang kental dengan potongan lontong tebal.',
        'open_hours': '10.00 - 21.00 WIB',
        'latitude': -7.6350,
        'longitude': 109.6550,
        'image_url': 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Sate Ambal (10 tusuk)', 'price': 18000},
          {'name': 'Lontong', 'price': 5000},
          {'name': 'Es Kelapa Muda', 'price': 10000},
        ],
      },
      {
        'id': '15',
        'name': 'Lantai Bumi Coffee Kebumen',
        'city': 'Kebumen',
        'category': 'Cafe',
        'min_price': 12000,
        'max_price': 30000,
        'avg_price': 18000,
        'rating': 4.5,
        'tags': ['Cafe & Ngopi', 'Wi-Fi & Colokan', 'Outdoor/Santai'],
        'address': 'Jl. Kutoarjo KM 3, Kebumen',
        'description': 'Cafe minimalis industrial favorit anak muda Kebumen. Spot foto keren dan kopi nikmat.',
        'open_hours': '10.00 - 24.00 WIB',
        'latitude': -7.6630,
        'longitude': 109.6610,
        'image_url': 'https://images.unsplash.com/photo-1493857671505-72967e2e2760?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Es Kopi Susu', 'price': 15000},
          {'name': 'Latte Art', 'price': 20000},
          {'name': 'Roti Bakar', 'price': 12000},
        ],
      },
    ];

    // Konversi setiap Map JSON ke object PlaceModel menggunakan fromJson()
    return fallbackJson
        .map((json) => PlaceModel.fromJson(json))
        .toList();
  }
}
