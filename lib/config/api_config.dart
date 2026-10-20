/// ============================================================
/// KONFIGURASI WEB SERVICE — MAMPIR APP
/// ============================================================
/// File ini menyimpan URL dan API Key untuk koneksi ke Supabase REST API.
///
/// PETUNJUK UNTUK MAHASISWA:
/// 1. Buat akun gratis di https://supabase.com
/// 2. Buat project baru, lalu buat tabel 'places' sesuai struktur JSON di PRD.
/// 3. Salin URL dan anon key dari Settings > API di dashboard Supabase.
/// 4. Paste di bawah ini menggantikan string kosong.
///
/// JANGAN KHAWATIR: Jika URL/Key masih kosong atau salah,
/// aplikasi akan otomatis menggunakan data bawaan (fallback)
/// sehingga TIDAK AKAN CRASH.
/// ============================================================
class ApiConfig {
  /// URL dasar Supabase REST API (PostgREST).
  /// Contoh: 'https://abcdefghij.supabase.co/rest/v1'
  /// Kosongkan jika belum punya — aplikasi tetap jalan dengan data bawaan.
  static const String supabaseUrl = '';

  /// Supabase Anon (Public) Key.
  /// Contoh: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  /// Kosongkan jika belum punya — aplikasi tetap jalan dengan data bawaan.
  static const String supabaseAnonKey = '';

  /// Endpoint untuk mengambil data tempat (GET request)
  static String get placesEndpoint => '$supabaseUrl/places';

  /// Mengecek apakah konfigurasi Supabase sudah diisi oleh pengguna.
  /// Jika false, ApiService akan menggunakan data fallback bawaan.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Header standar untuk request ke Supabase REST API.
  /// Berisi API Key dan format response JSON.
  static Map<String, String> get headers => {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };
}
