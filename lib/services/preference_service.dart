import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================
/// PREFERENCE SERVICE — PENYIMPANAN LOKAL MAMPIR APP
/// ============================================================
/// Menangani penyimpanan data pengguna secara lokal via SharedPreferences:
/// a. is_first_launch (boolean)
/// b. user_budget (int/double)
/// c. selected_region (String, default: "Purwokerto / Banyumas")
/// d. user_preferences (`List<String>`)
/// e. search_history (`List<String>`, max 10 tanpa duplikat)
/// f. favorite_places (`List<String>` ID tempat)
/// ============================================================
class PreferenceService {
  static const String keyFirstLaunch = 'is_first_launch';
  static const String keyBudget = 'user_budget';
  static const String keyRegion = 'selected_region';
  static const String keyPreferences = 'user_preferences';
  static const String keySearchHistory = 'search_history';
  static const String keyFavorites = 'favorite_places';

  // Legacy key compatibility
  static const String _legacyKeyOnboarded = 'is_onboarded';
  static const String _legacyKeyCity = 'user_city';
  static const String _legacyKeyTags = 'user_tags';
  static const String _legacyKeyTagHistory = 'tag_history';
  static const String _legacyKeyFavorites = 'favorite_ids';

  // ======================== FIRST LAUNCH / ONBOARDING ========================

  /// Mengecek apakah user baru pertama kali membuka aplikasi.
  /// Default: true (belum pernah buka onboarding).
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(keyFirstLaunch)) {
      return prefs.getBool(keyFirstLaunch) ?? true;
    }
    // Cek fallback legacy
    final legacyOnboarded = prefs.getBool(_legacyKeyOnboarded);
    if (legacyOnboarded != null) {
      return !legacyOnboarded;
    }
    return true;
  }

  /// Mengubah status first launch setelah user selesai onboarding.
  Future<void> setFirstLaunch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyFirstLaunch, value);
    await prefs.setBool(_legacyKeyOnboarded, !value);
  }

  /// Alias kompatibilitas
  Future<bool> isOnboarded() async => !(await isFirstLaunch());
  Future<void> setOnboarded() async => setFirstLaunch(false);

  // ======================== USER BUDGET ========================

  /// Simpan budget maksimal per orang (dalam Rupiah).
  Future<void> saveBudget(int budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyBudget, budget);
  }

  /// Ambil budget terakhir. Default: 25.000 (sesuai filter cepat awal di mockup).
  Future<int> getBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyBudget) ?? 25000;
  }

  // ======================== SELECTED REGION ========================

  /// Simpan wilayah terpilih se-BARLINGMASCAKEB.
  Future<void> saveSelectedRegion(String region) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyRegion, region);
    await prefs.setString(_legacyKeyCity, region);
  }

  /// Ambil wilayah terpilih. Default: "Purwokerto / Banyumas".
  Future<String> getSelectedRegion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyRegion) ??
        prefs.getString(_legacyKeyCity) ??
        'Purwokerto / Banyumas';
  }

  /// Alias kompatibilitas kota
  Future<void> saveCity(String city) async => saveSelectedRegion(city);
  Future<String> getCity() async => getSelectedRegion();

  // ======================== USER PREFERENCES / TAGS ========================

  /// Simpan daftar preferensi kategori/tempat/fasilitas acuan pengguna.
  Future<void> saveUserPreferences(List<String> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyPreferences, jsonEncode(preferences));
    await prefs.setString(_legacyKeyTags, jsonEncode(preferences));
    await _updateTagHistory(preferences);
  }

  /// Ambil daftar preferensi pengguna.
  Future<List<String>> getUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyPreferences) ?? prefs.getString(_legacyKeyTags);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// Alias kompatibilitas tags
  Future<void> saveTags(List<String> tags) async => saveUserPreferences(tags);
  Future<List<String>> getTags() async => getUserPreferences();

  Future<void> _updateTagHistory(List<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyKeyTagHistory);
    Map<String, int> history = {};
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        history = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {
        // ignore
      }
    }
    for (final tag in tags) {
      history[tag] = (history[tag] ?? 0) + 1;
    }
    await prefs.setString(_legacyKeyTagHistory, jsonEncode(history));
  }

  Future<Map<String, int>> getTagHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyKeyTagHistory);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  // ======================== SEARCH HISTORY ========================

  /// Ambil seluruh riwayat pencarian pengguna (maksimal 10 item).
  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keySearchHistory);
    if (raw == null) {
      // Default riwayat awal seperti di mockup jika kosong
      return [
        'cafe di purwokerto',
        'makan malam budget 50rb',
        'tempat nongkrong + wifi',
        'restoran seafood',
      ];
    }
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// Simpan atau perbarui riwayat pencarian:
  /// - Diletakkan paling depan
  /// - Tidak ada duplikasi
  /// - Maksimal 10 item
  Future<void> addSearchKeyword(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final list = await getSearchHistory();

    // Hapus jika sudah pernah ada agar pindah ke urutan paling atas
    list.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
    list.insert(0, trimmed);

    if (list.length > 10) {
      list.removeRange(10, list.length);
    }

    await prefs.setString(keySearchHistory, jsonEncode(list));
  }

  /// Hapus satu kata kunci dari riwayat pencarian.
  Future<void> removeSearchKeyword(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSearchHistory();
    list.removeWhere((item) => item.toLowerCase() == keyword.trim().toLowerCase());
    await prefs.setString(keySearchHistory, jsonEncode(list));
  }

  /// Hapus seluruh riwayat pencarian.
  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySearchHistory, jsonEncode([]));
  }

  // ======================== FAVORITE PLACES ========================

  /// Simpan daftar ID tempat favorit.
  Future<void> saveFavorites(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyFavorites, jsonEncode(ids));
    await prefs.setString(_legacyKeyFavorites, jsonEncode(ids));
  }

  /// Ambil daftar ID tempat favorit.
  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyFavorites) ?? prefs.getString(_legacyKeyFavorites);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// Toggle favorit: tambah jika belum ada, hapus jika sudah ada.
  Future<bool> toggleFavorite(String placeId) async {
    final favorites = await getFavorites();
    final isFav = favorites.contains(placeId);
    if (isFav) {
      favorites.remove(placeId);
    } else {
      favorites.add(placeId);
    }
    await saveFavorites(favorites);
    return !isFav;
  }

  /// Cek apakah suatu tempat difavoritkan.
  Future<bool> isFavorite(String placeId) async {
    final favorites = await getFavorites();
    return favorites.contains(placeId);
  }
}
