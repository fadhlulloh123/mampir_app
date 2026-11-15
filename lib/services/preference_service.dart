import 'dart:convert';
import 'dart:typed_data';
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
/// g. setting_notification_enabled (bool)
/// h. setting_location_enabled (bool)
/// i. setting_language (String)
/// j. setting_theme (String)
/// k. setting_app_rating (int)
/// l. is_logged_in (bool)
/// m. user_name & user_email (String)
/// ============================================================
class PreferenceService {
  static const String keyFirstLaunch = 'is_first_launch';
  static const String keyBudget = 'user_budget';
  static const String keyRegion = 'selected_region';
  static const String keyPreferences = 'user_preferences';
  static const String keySearchHistory = 'search_history';
  static const String keyFavorites = 'favorite_places';

  // Auth / User Profile Keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyIsGuest = 'is_guest_mode';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserPhoto = 'user_profile_photo';

  // Settings Keys
  static const String keyNotificationEnabled = 'setting_notification_enabled';
  static const String keyLocationEnabled = 'setting_location_enabled';
  static const String keyLanguage = 'setting_language';
  static const String keyTheme = 'setting_theme';
  static const String keyAppRating = 'setting_app_rating';

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

  // ======================== USER AUTHENTICATION ========================

  /// Format nama tamu berdasarkan wilayah yang dipilih:
  /// - Baturraden -> Tamu Baturraden
  /// - Sokaraja -> Tamu Sokaraja
  /// - Purwokerto Utara -> Tamu Purwokerto Utara
  /// - Purwokerto Timur -> Tamu Purwokerto Timur
  /// - Purwokerto Barat -> Tamu Purwokerto Barat
  /// - Purwokerto Selatan -> Tamu Purwokerto Selatan
  /// - Semua Wilayah -> Tamu Banyumas
  /// - Default -> Tamu Purwokerto Kota
  static String formatGuestName(String region) {
    final lower = region.toLowerCase();
    if (lower.contains('baturraden')) return 'Tamu Baturraden';
    if (lower.contains('sokaraja')) return 'Tamu Sokaraja';
    if (lower.contains('utara') || lower.contains('unsoed')) {
      return 'Tamu Purwokerto Utara';
    }
    if (lower.contains('timur') || lower.contains('sumbang')) {
      return 'Tamu Purwokerto Timur';
    }
    if (lower.contains('barat')) return 'Tamu Purwokerto Barat';
    if (lower.contains('selatan')) return 'Tamu Purwokerto Selatan';
    if (lower.contains('semua') || lower.contains('banyumas')) {
      return 'Tamu Banyumas';
    }
    return 'Tamu Purwokerto Kota';
  }

  static String formatGuestEmail(String region) {
    final lower = region.toLowerCase();
    if (lower.contains('baturraden')) return 'tamu.baturraden@mampir.id';
    if (lower.contains('sokaraja')) return 'tamu.sokaraja@mampir.id';
    if (lower.contains('utara') || lower.contains('unsoed')) {
      return 'tamu.unsoed@mampir.id';
    }
    if (lower.contains('timur') || lower.contains('sumbang')) {
      return 'tamu.purwokertotimur@mampir.id';
    }
    if (lower.contains('barat')) return 'tamu.purwokertobarat@mampir.id';
    if (lower.contains('selatan')) return 'tamu.purwokertoselatan@mampir.id';
    if (lower.contains('semua') || lower.contains('banyumas')) {
      return 'tamu.banyumas@mampir.id';
    }
    return 'tamu.purwokerto@mampir.id';
  }

  static String formatGuestBadge(String region) => formatExplorerBadge(region);

  /// Format badge penjelajah berdasarkan wilayah aktif
  static String formatExplorerBadge(String region) {
    final lower = region.toLowerCase();
    if (lower.contains('baturraden')) return '🌲 Penjelajah Baturraden';
    if (lower.contains('sokaraja')) return '🍲 Penjelajah Sokaraja';
    if (lower.contains('utara') || lower.contains('unsoed')) {
      return '🎓 Penjelajah Purwokerto Utara';
    }
    if (lower.contains('timur') || lower.contains('sumbang')) {
      return '🌅 Penjelajah Purwokerto Timur';
    }
    if (lower.contains('barat')) return '🚂 Penjelajah Purwokerto Barat';
    if (lower.contains('selatan')) return '🧭 Penjelajah Purwokerto Selatan';
    if (lower.contains('semua') || lower.contains('banyumas')) {
      return '🗺️ Penjelajah Banyumas';
    }
    return '🌟 Penjelajah Purwokerto Kota';
  }

  /// Cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsLoggedIn) ?? false;
  }

  /// Cek apakah user login sebagai tamu
  Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsGuest) ?? false;
  }

  /// Simpan sesi login user
  Future<void> login({
    String name = 'Penjelajah MAMPIR',
    String email = 'user@mampir.id',
    bool isGuest = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, true);
    await prefs.setBool(keyIsGuest, isGuest);
    await prefs.setString(keyUserName, name);
    await prefs.setString(keyUserEmail, email);
  }

  /// Ambil nama pengguna
  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserName) ?? 'Penjelajah MAMPIR';
  }

  /// Ambil email pengguna
  Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserEmail) ?? 'user@mampir.id';
  }

  /// Update profil pengguna
  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUserName, name);
    await prefs.setString(keyUserEmail, email);
  }

  /// Ambil bytes foto profil pengguna yang tersimpan lokal (null jika belum ada / korup)
  Future<Uint8List?> getUserPhotoBytes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyUserPhoto);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = base64Decode(raw);
      return decoded.isEmpty ? null : decoded;
    } catch (_) {
      return null;
    }
  }

  /// Simpan atau perbarui foto profil pengguna dari bytes gambar
  Future<void> saveUserPhotoBytes(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    if (bytes.isEmpty) {
      await prefs.remove(keyUserPhoto);
      return;
    }
    await prefs.setString(keyUserPhoto, base64Encode(bytes));
  }

  /// Hapus foto profil pengguna sehingga kembali ke avatar inisial default
  Future<void> deleteUserPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyUserPhoto);
  }

  /// Logout pengguna
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, false);
    await prefs.setBool(keyIsGuest, false);
    await prefs.remove(keyUserName);
    await prefs.remove(keyUserEmail);
    await prefs.remove(keyUserPhoto);
  }

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

  /// Simpan wilayah terpilih di Purwokerto dan sekitarnya.
  Future<void> saveSelectedRegion(String region) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyRegion, region);
    await prefs.setString(_legacyKeyCity, region);
  }

  /// Ambil wilayah terpilih. Default: "Purwokerto Kota".
  Future<String> getSelectedRegion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyRegion) ??
        prefs.getString(_legacyKeyCity) ??
        'Purwokerto Kota';
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
    final raw =
        prefs.getString(keyPreferences) ?? prefs.getString(_legacyKeyTags);
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

  /// Kunci riwayat pencarian terisolasi berdasarkan akun yang sedang aktif
  Future<String> _getScopedSearchHistoryKey() async {
    final loggedIn = await isLoggedIn();
    final guest = await isGuest();
    if (!loggedIn || guest) {
      return 'search_history_guest';
    }
    final email = await getUserEmail();
    final clean = email.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return clean.isNotEmpty ? 'search_history_$clean' : 'search_history_guest';
  }

  /// Kunci daftar favorit terisolasi per akun
  Future<String> _getScopedFavoritesKey() async {
    final loggedIn = await isLoggedIn();
    final guest = await isGuest();
    if (!loggedIn || guest) {
      return 'favorite_places_guest';
    }
    final email = await getUserEmail();
    final clean = email.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return clean.isNotEmpty ? 'favorite_places_$clean' : 'favorite_places_guest';
  }

  /// Ambil seluruh riwayat pencarian pengguna (maksimal 10 item).
  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedSearchHistoryKey();
    final raw = prefs.getString(key);
    if (raw == null) {
      // Kembalikan list kosong jika akun ini belum pernah melakukan pencarian
      return [];
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
    final key = await _getScopedSearchHistoryKey();
    final list = await getSearchHistory();

    // Hapus jika sudah pernah ada agar pindah ke urutan paling atas
    list.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
    list.insert(0, trimmed);

    if (list.length > 10) {
      list.removeRange(10, list.length);
    }

    await prefs.setString(key, jsonEncode(list));
  }

  /// Hapus satu kata kunci dari riwayat pencarian.
  Future<void> removeSearchKeyword(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedSearchHistoryKey();
    final list = await getSearchHistory();
    list.removeWhere(
      (item) => item.toLowerCase() == keyword.trim().toLowerCase(),
    );
    await prefs.setString(key, jsonEncode(list));
  }

  /// Hapus seluruh riwayat pencarian.
  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedSearchHistoryKey();
    await prefs.setString(key, jsonEncode([]));
  }

  // ======================== FAVORITE PLACES ========================

  /// Simpan daftar ID tempat favorit.
  Future<void> saveFavorites(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedFavoritesKey();
    await prefs.setString(key, jsonEncode(ids));
    await prefs.setString(keyFavorites, jsonEncode(ids));
    await prefs.setString(_legacyKeyFavorites, jsonEncode(ids));
  }

  /// Ambil daftar ID tempat favorit.
  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedFavoritesKey();
    final raw = prefs.getString(key) ??
        prefs.getString(keyFavorites) ??
        prefs.getString(_legacyKeyFavorites);
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

  // ======================== APP SETTINGS ========================

  /// Status notifikasi aktif/nonaktif
  Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyNotificationEnabled) ?? true;
  }

  Future<void> setNotificationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyNotificationEnabled, value);
  }

  /// Status izin lokasi
  Future<bool> isLocationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyLocationEnabled) ?? true;
  }

  Future<void> setLocationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyLocationEnabled, value);
  }

  /// Bahasa aplikasi terpilih (default: 'Indonesia')
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyLanguage) ?? 'Indonesia';
  }

  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyLanguage, language);
  }

  /// Tema aplikasi (default: 'Gelap')
  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyTheme) ?? 'Gelap';
  }

  Future<void> setThemeMode(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyTheme, theme);
  }

  /// Rating aplikasi terakhir yang diberikan user (1 - 5)
  Future<int> getAppRating() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyAppRating) ?? 5;
  }

  Future<void> saveAppRating(int rating) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyAppRating, rating);
  }
}
