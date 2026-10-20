import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================
/// PREFERENCE SERVICE — PENYIMPANAN LOKAL MAMPIR APP
/// ============================================================
/// File ini menangani penyimpanan data lokal pengguna menggunakan
/// package shared_preferences. Data yang disimpan:
/// - Budget maksimal per orang
/// - Kota/wilayah yang dipilih
/// - Tag preferensi/selera (multi-select)
/// - Riwayat tag yang sering dipilih (untuk Smart Scoring)
/// - Daftar ID tempat favorit/langganan (bookmark)
/// - Status onboarding (sudah selesai atau belum)
/// ============================================================
class PreferenceService {
  static const String _keyBudget = 'user_budget';
  static const String _keyCity = 'user_city';
  static const String _keyTags = 'user_tags';
  static const String _keyTagHistory = 'tag_history';
  static const String _keyFavorites = 'favorite_ids';
  static const String _keyOnboarded = 'is_onboarded';

  // ======================== BUDGET ========================

  /// Simpan budget maksimal per orang (dalam Rupiah).
  Future<void> saveBudget(int budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBudget, budget);
  }

  /// Ambil budget terakhir yang disimpan. Default: 50000 (Rp50.000).
  Future<int> getBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBudget) ?? 50000;
  }

  // ======================== KOTA ========================

  /// Simpan kota/wilayah pilihan pengguna.
  Future<void> saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCity, city);
  }

  /// Ambil kota terakhir yang dipilih. Default: 'Semua Wilayah'.
  Future<String> getCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCity) ?? 'Semua Wilayah';
  }

  // ======================== TAG PREFERENSI ========================

  /// Simpan daftar tag preferensi yang dipilih pengguna.
  Future<void> saveTags(List<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTags, jsonEncode(tags));
    // Update riwayat tag untuk Smart Scoring
    await _updateTagHistory(tags);
  }

  /// Ambil daftar tag preferensi terakhir.
  Future<List<String>> getTags() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTags);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  // ======================== RIWAYAT TAG (SMART SCORING) ========================

  /// Update riwayat tag — setiap kali tag dipilih, counter-nya naik.
  /// Digunakan untuk menghitung skor kecocokan (Smart Scoring).
  Future<void> _updateTagHistory(List<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTagHistory);
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
    await prefs.setString(_keyTagHistory, jsonEncode(history));
  }

  /// Ambil riwayat tag untuk Smart Scoring.
  /// Return: Map<tagName, frequency>
  Future<Map<String, int>> getTagHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTagHistory);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  // ======================== FAVORIT / LANGGANAN ========================

  /// Simpan daftar ID tempat favorit.
  Future<void> saveFavorites(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFavorites, jsonEncode(ids));
  }

  /// Ambil daftar ID tempat favorit.
  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFavorites);
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
    final isFavorite = favorites.contains(placeId);
    if (isFavorite) {
      favorites.remove(placeId);
    } else {
      favorites.add(placeId);
    }
    await saveFavorites(favorites);
    return !isFavorite; // return true jika sekarang jadi favorit
  }

  /// Cek apakah tempat tertentu sudah di-bookmark.
  Future<bool> isFavorite(String placeId) async {
    final favorites = await getFavorites();
    return favorites.contains(placeId);
  }

  // ======================== STATUS ONBOARDING ========================

  /// Tandai bahwa user sudah menyelesaikan onboarding.
  Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, true);
  }

  /// Cek apakah user sudah pernah onboarding.
  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarded) ?? false;
  }
}
