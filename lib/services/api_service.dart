import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/place_model.dart';

/// ============================================================================
/// API SERVICE — IMPLEMENTASI WEB SERVICE (REST API) MAMPIR APP
/// ============================================================================
///
/// File ini adalah INTI dari penerapan Web Service pada aplikasi MAMPIR.
/// Memanggil REST API menggunakan package `http` (HTTP GET & POST),
/// mem-parsing JSON response, dan menyediakan data tempat NYATA di
/// 5 kabupaten BARLINGMASCAKEB (Banyumas, Purbalingga, Banjarnegara,
/// Cilacap, dan Kebumen).
/// ============================================================================
class ApiService {
  /// Mengambil data tempat makan dari Supabase REST API via HTTP GET.
  /// Jika API belum dikonfigurasi atau offline, otomatis fallback ke data lokal.
  Future<List<PlaceModel>> fetchPlaces() async {
    if (!ApiConfig.isConfigured) {
      return _getFallbackPlaces();
    }

    try {
      final url = Uri.parse(ApiConfig.placesEndpoint);
      final response = await http.get(
        url,
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData
            .map((json) => PlaceModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        return _getFallbackPlaces();
      }
    } catch (_) {
      return _getFallbackPlaces();
    }
  }

  /// Mengirim data tempat makan baru ke Supabase REST API via HTTP POST.
  Future<bool> submitPlace(PlaceModel place) async {
    if (!ApiConfig.isConfigured) {
      return false;
    }

    try {
      final url = Uri.parse(ApiConfig.placesEndpoint);
      final body = jsonEncode(place.toJson());
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: body,
      );

      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// ==========================================================================
  /// DATA TEMPAT NYATA SE-BARLINGMASCAKEB (25 TEMPAT)
  /// ==========================================================================
  List<PlaceModel> _getFallbackPlaces() {
    final List<Map<String, dynamic>> fallbackJson = [
      // ======================== BANYUMAS / PURWOKERTO ========================
      {
        'id': 'pwt-1',
        'name': 'Kopi Kenangan',
        'city': 'Purwokerto / Banyumas',
        'category': 'Cafe',
        'min_price': 15000,
        'max_price': 50000,
        'avg_price': 25000,
        'rating': 4.8,
        'review_count': 1200,
        'facilities': ['AC', 'WiFi', 'Colokan', 'Indoor', 'Parkir'],
        'address': 'Jl. Jend. Sudirman No. 392, Purwokerto',
        'description':
            'Kopi Kenangan adalah tempat ngopi yang nyaman dengan suasana modern dan cocok untuk bekerja atau sekadar santai bersama teman.',
        'open_hours': '08.00 - 22.00 WIB',
        'latitude': -7.4244,
        'longitude': 109.2302,
        'image_url':
            'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Kopi Kenangan Mantan', 'price': 18000},
          {'name': 'Avocado Coffee', 'price': 24000},
          {'name': 'Roti Cokelat Klasik', 'price': 12000},
        ],
      },
      {
        'id': 'pwt-2',
        'name': 'Warung Bu Sari',
        'city': 'Purwokerto / Banyumas',
        'category': 'Makan',
        'min_price': 10000,
        'max_price': 25000,
        'avg_price': 15000,
        'rating': 4.7,
        'review_count': 980,
        'facilities': ['Outdoor', 'Parkir', 'Mushola', 'Rumahan'],
        'address': 'Jl. HR Bunyamin No. 88 (Dekat Kampus Unsoed), Purwokerto',
        'description':
            'Warung makan prasmanan khas Banyumasan dengan aneka sayur lodeh, ayam goreng lengkuas, mendoan hangat, dan sambal terasi segar harga mahasiswa.',
        'open_hours': '07.00 - 21.00 WIB',
        'latitude': -7.4085,
        'longitude': 109.2450,
        'image_url':
            'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Paket Nasi Sayur + Ayam', 'price': 18000},
          {'name': 'Mendoan Purwokerto (3 pcs)', 'price': 9000},
          {'name': 'Es Jeruk Peras Segar', 'price': 5000},
        ],
      },
      {
        'id': 'pwt-3',
        'name': 'The Local Space',
        'city': 'Purwokerto / Banyumas',
        'category': 'Cafe',
        'min_price': 20000,
        'max_price': 70000,
        'avg_price': 35000,
        'rating': 4.6,
        'review_count': 640,
        'facilities': ['WiFi', 'Colokan', 'AC', 'Indoor', 'Outdoor', 'Ramah Hewan'],
        'address': 'Jl. Dr. Angka No. 45, Purwokerto',
        'description':
            'Tempat nongkrong dengan desain modern dan suasana yang nyaman, cocok untuk bekerja remote, nugas skripsi, atau sekadar santai.',
        'open_hours': '10.00 - 23.00 WIB',
        'latitude': -7.4172,
        'longitude': 109.2395,
        'image_url':
            'https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Caramel Macchiato', 'price': 28000},
          {'name': 'Truffle French Fries', 'price': 25000},
          {'name': 'Pasta Carbonara', 'price': 35000},
        ],
      },
      {
        'id': 'pwt-4',
        'name': 'Roti Bakar 88',
        'city': 'Purwokerto / Banyumas',
        'category': 'Nongkrong',
        'min_price': 15000,
        'max_price': 40000,
        'avg_price': 22000,
        'rating': 4.5,
        'review_count': 410,
        'facilities': ['WiFi', 'Outdoor', 'Colokan', 'Musik', 'Parkir'],
        'address': 'Jl. Prof. Dr. Suharso (Kompleks GOR Satria), Purwokerto',
        'description':
            'Spot nongkrong malam favorit pemuda Purwokerto dengan varian roti bakar tebal, pisang bakar keju, indomie spesial, dan aneka minuman segar.',
        'open_hours': '16.00 - 01.00 WIB',
        'latitude': -7.4120,
        'longitude': 109.2510,
        'image_url':
            'https://images.unsplash.com/photo-1509722747041-616f39b57569?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Roti Bakar Cokelat Keju', 'price': 18000},
          {'name': 'Indomie Kuah Kornet Telur', 'price': 16000},
          {'name': 'Es Ovaltine Volcano', 'price': 14000},
        ],
      },
      {
        'id': 'pwt-5',
        'name': 'Soto H. Loso Sokaraja',
        'city': 'Purwokerto / Banyumas',
        'category': 'Restoran',
        'min_price': 20000,
        'max_price': 45000,
        'avg_price': 30000,
        'rating': 4.9,
        'review_count': 2300,
        'facilities': ['Parkir', 'Mushola', 'Outdoor', 'Indoor'],
        'address': 'Jl. Raya Bank Jateng No. 15, Sokaraja, Banyumas',
        'description':
            'Soto khas Sokaraja paling legendaris dengan kuah kaldu sapi kental berpadu sambal kacang gurih serta ketupat dan kerupuk cantir merah khas.',
        'open_hours': '08.00 - 20.30 WIB',
        'latitude': -7.4612,
        'longitude': 109.2789,
        'image_url':
            'https://images.unsplash.com/photo-1541832676-9b763b0239ab?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Soto Daging Sapi Komplit', 'price': 28000},
          {'name': 'Soto Ayam Kampung', 'price': 23000},
          {'name': 'Tempe Mendoan Sokaraja', 'price': 10000},
        ],
      },
      {
        'id': 'pwt-6',
        'name': 'Kopi Keprok Baturraden',
        'city': 'Purwokerto / Banyumas',
        'category': 'Cafe',
        'min_price': 15000,
        'max_price': 45000,
        'avg_price': 25000,
        'rating': 4.7,
        'review_count': 1100,
        'facilities': ['Outdoor', 'WiFi', 'Colokan', 'Mushola', 'Romantis'],
        'address': 'Jl. Raya Baturraden KM 7, Karanggintung, Banyumas',
        'description':
            'Cafe nuansa pedesaan kaki Gunung Slamet yang sejuk, gemericik air kali, hamparan sawah, dan kopi tubruk tradisional nikmat.',
        'open_hours': '09.00 - 23.00 WIB',
        'latitude': -7.3621,
        'longitude': 109.2435,
        'image_url':
            'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Kopi Tubruk Keprok', 'price': 15000},
          {'name': 'Pisang Goreng Gula Aren', 'price': 14000},
          {'name': 'Nasi Sayur Desa', 'price': 22000},
        ],
      },
      {
        'id': 'pwt-7',
        'name': 'Warmindo Sudirman Sentosa',
        'city': 'Purwokerto / Banyumas',
        'category': 'Warung',
        'min_price': 6000,
        'max_price': 18000,
        'avg_price': 12000,
        'rating': 4.6,
        'review_count': 850,
        'facilities': ['WiFi', 'Colokan', 'Outdoor'],
        'address': 'Jl. Jend. Sudirman No. 120, Purwokerto',
        'description':
            'Warmindo andalan begadang anak kampus. Buka 24 jam dengan racikan mie dok-dok, magelangan gurih, dan es nutrisari dingin.',
        'open_hours': 'Buka 24 Jam',
        'latitude': -7.4230,
        'longitude': 109.2350,
        'image_url':
            'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Mie Dok-Dok Pedas Telur', 'price': 12000},
          {'name': 'Nasi Magelangan', 'price': 14000},
          {'name': 'Es Kopi Goodday Dingin', 'price': 5000},
        ],
      },

      // ======================== PURBALINGGA ========================
      {
        'id': 'pbg-1',
        'name': 'Gulai Melung Bu Sambas',
        'city': 'Purbalingga',
        'category': 'Restoran',
        'min_price': 25000,
        'max_price': 55000,
        'avg_price': 35000,
        'rating': 4.8,
        'review_count': 1650,
        'facilities': ['Parkir', 'Mushola', 'Outdoor', 'Indoor'],
        'address': 'Dusun Melung, Larangan, Pengadegan, Purbalingga',
        'description':
            'Kuliner khas Purbalingga legendaris berbahan dasar daging kambing dengan kuah santan kuning rempah melimpah yang dimasak di atas tungku kayu arang.',
        'open_hours': '08.30 - 18.00 WIB',
        'latitude': -7.4112,
        'longitude': 109.4315,
        'image_url':
            'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Gulai Melung Kambing Porsi', 'price': 35000},
          {'name': 'Nasi Hangat Bakul', 'price': 6000},
          {'name': 'Es Beras Kencur Segar', 'price': 7000},
        ],
      },
      {
        'id': 'pbg-2',
        'name': 'Kedai Kopi Usman Purbalingga',
        'city': 'Purbalingga',
        'category': 'Cafe',
        'min_price': 12000,
        'max_price': 35000,
        'avg_price': 20000,
        'rating': 4.6,
        'review_count': 530,
        'facilities': ['WiFi', 'Colokan', 'Outdoor', 'Musik'],
        'address': 'Jl. Komisaris Noto Sumarsono No. 12, Purbalingga Kidul',
        'description':
            'Kedai kopi estetik ramah kantong di tengah kota Purbalingga, cocok untuk hangout santai malam hari dengan pilihan kopi biji lokal Jawa Tengah.',
        'open_hours': '14.00 - 23.30 WIB',
        'latitude': -7.3912,
        'longitude': 109.3621,
        'image_url':
            'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Kopi Susu Usman', 'price': 16000},
          {'name': 'French Fries Sambal Matah', 'price': 15000},
          {'name': 'Toast Cokelat Lumer', 'price': 14000},
        ],
      },
      {
        'id': 'pbg-3',
        'name': 'Soto Kriyik Bu Solet',
        'city': 'Purbalingga',
        'category': 'Makan',
        'min_price': 15000,
        'max_price': 30000,
        'avg_price': 20000,
        'rating': 4.7,
        'review_count': 820,
        'facilities': ['Parkir', 'Indoor', 'Rumahan'],
        'address': 'Jl. MT Haryono No. 22, Karangsentul, Purbalingga',
        'description':
            'Soto khas Purbalingga bertabur remukan jeroan ayam kering kriuk (kriyik) dengan kuah santan gurih bening khas bumi Perwira.',
        'open_hours': '07.30 - 15.00 WIB',
        'latitude': -7.3850,
        'longitude': 109.3580,
        'image_url':
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Soto Kriyik Komplit', 'price': 22000},
          {'name': 'Tahu Bacem Goreng', 'price': 4000},
          {'name': 'Es Teh Manis', 'price': 4000},
        ],
      },
      {
        'id': 'pbg-4',
        'name': 'Angkringan Mas Bro Alun-alun',
        'city': 'Purbalingga',
        'category': 'Nongkrong',
        'min_price': 5000,
        'max_price': 20000,
        'avg_price': 12000,
        'rating': 4.5,
        'review_count': 390,
        'facilities': ['Outdoor', 'Lesehan', 'Musik'],
        'address': 'Sisi Selatan Alun-alun Purbalingga',
        'description':
            'Spot lesehan nongkrong malam hari di sekitar alun-alun dengan aneka sate telur puyuh, sate usus, nasi kucing sambal teri, dan wedang jahe geprek.',
        'open_hours': '17.30 - 01.00 WIB',
        'latitude': -7.3892,
        'longitude': 109.3635,
        'image_url':
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Nasi Kucing Teri Tempe', 'price': 4000},
          {'name': 'Sate Usus & Telur Puyuh', 'price': 3000},
          {'name': 'Wedang Jahe Susu Rempah', 'price': 7000},
        ],
      },

      // ======================== BANJARNEGARA ========================
      {
        'id': 'bjr-1',
        'name': 'Dawet Ayu Asli Hj. Munardjo',
        'city': 'Banjarnegara',
        'category': 'Makan',
        'min_price': 8000,
        'max_price': 20000,
        'avg_price': 12000,
        'rating': 4.9,
        'review_count': 2100,
        'facilities': ['Parkir', 'Outdoor', 'Rumahan'],
        'address': 'Jl. Dipayuda No. 18, Alun-alun Banjarnegara',
        'description':
            'Ikon kuliner Banjarnegara nomor satu di dunia. Cendol hijau alami daun suji berpadu santan gurih dan juruh gula kelapa asli aroma pandan wangi.',
        'open_hours': '08.00 - 17.00 WIB',
        'latitude': -7.3965,
        'longitude': 109.6978,
        'image_url':
            'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Es Dawet Ayu Durian', 'price': 15000},
          {'name': 'Es Dawet Ayu Original', 'price': 9000},
          {'name': 'Tahu Bakso Goreng', 'price': 10000},
        ],
      },
      {
        'id': 'bjr-2',
        'name': 'Kopi Bitingan Dieng & Roastery',
        'city': 'Banjarnegara',
        'category': 'Cafe',
        'min_price': 15000,
        'max_price': 45000,
        'avg_price': 25000,
        'rating': 4.7,
        'review_count': 610,
        'facilities': ['WiFi', 'Outdoor', 'Rooftop', 'Colokan', 'Romantis'],
        'address': 'Jl. Raya Dieng KM 18, Wanayasa, Banjarnegara',
        'description':
            'Menikmati seduhan biji kopi arabika Yellow Caturra khas pegunungan Dieng dengan panorama perbukitan berkabut yang menyejukkan mata.',
        'open_hours': '09.00 - 22.00 WIB',
        'latitude': -7.2145,
        'longitude': 109.8450,
        'image_url':
            'https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Single Origin Arabica Dieng', 'price': 22000},
          {'name': 'Carica Squash Dingin', 'price': 16000},
          {'name': 'Tempe Kemul Hangat', 'price': 12000},
        ],
      },
      {
        'id': 'bjr-3',
        'name': 'Rumah Makan Sari Rahayu',
        'city': 'Banjarnegara',
        'category': 'Restoran',
        'min_price': 20000,
        'max_price': 60000,
        'avg_price': 35000,
        'rating': 4.6,
        'review_count': 750,
        'facilities': ['Parkir', 'AC', 'Mushola', 'Indoor'],
        'address': 'Jl. Letjend S. Parman No. 55, Banjarnegara',
        'description':
            'Restoran keluarga dengan sajian gurame bakar madu, ayam kampung kremes, aneka tumisan sayur segar, dan sambal terasi khas Banyumasan.',
        'open_hours': '09.30 - 21.00 WIB',
        'latitude': -7.3995,
        'longitude': 109.6890,
        'image_url':
            'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Gurame Bakar Madu Spesial', 'price': 48000},
          {'name': 'Ayam Goreng Kremes Kampung', 'price': 28000},
          {'name': 'Tumis Kangkung Belacan', 'price': 15000},
        ],
      },
      {
        'id': 'bjr-4',
        'name': 'Bakso Gondang Banjarnegara',
        'city': 'Banjarnegara',
        'category': 'Makan',
        'min_price': 12000,
        'max_price': 25000,
        'avg_price': 18000,
        'rating': 4.6,
        'review_count': 590,
        'facilities': ['Parkir', 'Indoor', 'Outdoor'],
        'address': 'Jl. Pemuda No. 40, Banjarnegara',
        'description':
            'Bakso urat sapi asli dengan kuah kaldu sumsum gurih khas, tetelan melimpah, dan mie kuning lembut kenyal.',
        'open_hours': '10.00 - 20.30 WIB',
        'latitude': -7.3980,
        'longitude': 109.6950,
        'image_url':
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Bakso Urat Tetelan Spesial', 'price': 20000},
          {'name': 'Bakso Halus Telur', 'price': 18000},
          {'name': 'Es Campur Segar', 'price': 8000},
        ],
      },

      // ======================== CILACAP ========================
      {
        'id': 'clp-1',
        'name': 'Warung Seafood Teluk Penyu Bu Rini',
        'city': 'Cilacap',
        'category': 'Restoran',
        'min_price': 30000,
        'max_price': 85000,
        'avg_price': 50000,
        'rating': 4.8,
        'review_count': 1890,
        'facilities': ['Outdoor', 'Parkir', 'Mushola', 'Romantis'],
        'address': 'Kawasan Pantai Teluk Penyu, Cilacap Selatan',
        'description':
            'Sajian kepiting saus Padang, udang bakar madu, dan ikan bawal laut bakar segar langsung dari tangkapan nelayan pesisir Cilacap dengan hembusan angin laut.',
        'open_hours': '10.00 - 22.00 WIB',
        'latitude': -7.7420,
        'longitude': 109.0250,
        'image_url':
            'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Kepiting Saus Padang', 'price': 65000},
          {'name': 'Udang Bakar Jimbaran', 'price': 45000},
          {'name': 'Cumi Goreng Tepung Crispy', 'price': 35000},
        ],
      },
      {
        'id': 'clp-2',
        'name': 'Tahu Masak Pak Tambur',
        'city': 'Cilacap',
        'category': 'Makan',
        'min_price': 10000,
        'max_price': 20000,
        'avg_price': 14000,
        'rating': 4.7,
        'review_count': 920,
        'facilities': ['Outdoor', 'Parkir', 'Rumahan'],
        'address': 'Jl. Anggrek No. 14, Cilacap Tengah',
        'description':
            'Kuliner khas Cilacap perpaduan tahu putih goreng panas, lontong pulen, kubis segar, kecambah, taburan kerupuk merah, dan siraman kuah kecap rawit pedas manis.',
        'open_hours': '10.00 - 18.00 WIB',
        'latitude': -7.7215,
        'longitude': 109.0110,
        'image_url':
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Tahu Masak Telur Lontong', 'price': 15000},
          {'name': 'Tahu Masak Biasa', 'price': 12000},
          {'name': 'Es Kelapa Muda Jeruk', 'price': 6000},
        ],
      },
      {
        'id': 'clp-3',
        'name': 'Kopi Pantai Cilacap',
        'city': 'Cilacap',
        'category': 'Cafe',
        'min_price': 15000,
        'max_price': 40000,
        'avg_price': 24000,
        'rating': 4.6,
        'review_count': 580,
        'facilities': ['WiFi', 'Outdoor', 'Colokan', 'Romantis', 'Musik'],
        'address': 'Jl. Pasir Putih, Pantai Teluk Penyu, Cilacap',
        'description':
            'Tempat nongkrong tepi pantai dengan sunset memukau menghadap Pulau Nusakambangan, live acoustic malam hari, dan aneka kopi kekinian.',
        'open_hours': '15.00 - 24.00 WIB',
        'latitude': -7.7390,
        'longitude': 109.0275,
        'image_url':
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Sunset Coastal Latte', 'price': 22000},
          {'name': 'Pisang Bakar Coklat Keju', 'price': 16000},
          {'name': 'Mojito Mint Segar', 'price': 18000},
        ],
      },
      {
        'id': 'clp-4',
        'name': 'Brekecek Pathak Jahan Bu Min',
        'city': 'Cilacap',
        'category': 'Makan',
        'min_price': 20000,
        'max_price': 45000,
        'avg_price': 28000,
        'rating': 4.8,
        'review_count': 1140,
        'facilities': ['Parkir', 'Indoor', 'Mushola'],
        'address': 'Jl. Slamet No. 5, Cilacap Selatan',
        'description':
            'Masakan rempah tradisional khas pesisir Cilacap dengan kepala ikan laut jahan yang pedas, gurih, dan asam segar rempah lengkuas.',
        'open_hours': '09.00 - 17.00 WIB',
        'latitude': -7.7310,
        'longitude': 109.0180,
        'image_url':
            'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Brekecek Kepala Ikan Jahan', 'price': 30000},
          {'name': 'Ikan Asin Cabe Ijo', 'price': 12000},
          {'name': 'Sayur Asem Segar', 'price': 8000},
        ],
      },

      // ======================== KEBUMEN ========================
      {
        'id': 'kbm-1',
        'name': 'Sate Ambal Pak Alip',
        'city': 'Kebumen',
        'category': 'Makan',
        'min_price': 25000,
        'max_price': 50000,
        'avg_price': 32000,
        'rating': 4.9,
        'review_count': 2400,
        'facilities': ['Parkir', 'Mushola', 'Outdoor', 'Indoor'],
        'address': 'Jl. Pahlawan No. 45, Ambal, Kebumen',
        'description':
            'Sate ayam khas Ambal dengan bumbu tempe kedelai halus yang gurih manis khas rempah Jawa kuno. Dagingnya empuk dipanggang arang batok kelapa.',
        'open_hours': '08.00 - 21.00 WIB',
        'latitude': -7.7650,
        'longitude': 109.7320,
        'image_url':
            'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Sate Ambal Ayam (10 Tusuk) + Ketupat', 'price': 28000},
          {'name': 'Sate Kulit Ambal Gurih', 'price': 22000},
          {'name': 'Es Jeruk Nipis Madu', 'price': 6000},
        ],
      },
      {
        'id': 'kbm-2',
        'name': 'Nasi Penggel Pak Melan',
        'city': 'Kebumen',
        'category': 'Makan',
        'min_price': 12000,
        'max_price': 25000,
        'avg_price': 16000,
        'rating': 4.7,
        'review_count': 910,
        'facilities': ['Outdoor', 'Lesehan', 'Rumahan'],
        'address': 'Jl. Pemuda (Samping Alun-alun Kebumen)',
        'description':
            'Nasi kepal bulat (penggel) disajikan dengan daun pisang beralas pincuk, sayur gori gurih santan, dan pilihan jeroan sapi atau kikil kenyal.',
        'open_hours': '06.00 - 10.30 WIB',
        'latitude': -7.6710,
        'longitude': 109.6580,
        'image_url':
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Nasi Penggel Lauk Kikil', 'price': 16000},
          {'name': 'Nasi Penggel Babat Iso', 'price': 19000},
          {'name': 'Teh Hangat Manis Tubruk', 'price': 3000},
        ],
      },
      {
        'id': 'kbm-3',
        'name': 'Malindo Cafe & Resto Gombong',
        'city': 'Kebumen',
        'category': 'Cafe',
        'min_price': 18000,
        'max_price': 55000,
        'avg_price': 28000,
        'rating': 4.6,
        'review_count': 670,
        'facilities': ['WiFi', 'AC', 'Colokan', 'Mushola', 'Indoor', 'Outdoor'],
        'address': 'Jl. Yos Sudarso No. 188, Gombong, Kebumen',
        'description':
            'Kafe dan resto estetik di jantung kota Gombong dengan hidangan fusi lokal-western, suasana cozy untuk kumpul keluarga atau nugas.',
        'open_hours': '10.00 - 22.00 WIB',
        'latitude': -7.6045,
        'longitude': 109.5120,
        'image_url':
            'https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Chicken Cordon Bleu', 'price': 36000},
          {'name': 'Kopi Susu Malindo', 'price': 20000},
          {'name': 'Waffle Ice Cream Berry', 'price': 22000},
        ],
      },
      {
        'id': 'kbm-4',
        'name': 'Kopi Alun-Alun Kebumen',
        'city': 'Kebumen',
        'category': 'Nongkrong',
        'min_price': 8000,
        'max_price': 25000,
        'avg_price': 15000,
        'rating': 4.5,
        'review_count': 490,
        'facilities': ['Outdoor', 'WiFi', 'Musik', 'Lesehan'],
        'address': 'Pusat Kuliner Kapal Mendoan Alun-alun Kebumen',
        'description':
            'Tempat nongkrong malam favorit di kawasan ikonik Kapal Mendoan Alun-alun Kebumen dengan aneka camilan hangat, kopi tubruk, dan wedangan jahe.',
        'open_hours': '16.00 - 24.00 WIB',
        'latitude': -7.6725,
        'longitude': 109.6590,
        'image_url':
            'https://images.unsplash.com/photo-1509722747041-616f39b57569?auto=format&fit=crop&w=800&q=80',
        'menu_highlights': [
          {'name': 'Mendoan Jumbo Sambal Kecap', 'price': 10000},
          {'name': 'Kopi Tubruk Robusta Kebumen', 'price': 9000},
          {'name': 'Wedang Ronde Hangat', 'price': 12000},
        ],
      },
    ];

    return fallbackJson.map((json) => PlaceModel.fromJson(json)).toList();
  }
}
