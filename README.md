# MAMPIR App

**MAMPIR** (Makan, Ampir, Pilih, dan Rekomendasi) adalah aplikasi Flutter untuk membantu pengguna menemukan tempat makan dan nongkrong di wilayah **BARLINGMASCAKEB** (Banjarnegara, Purbalingga, Banyumas, Cilacap, Kebumen).

Aplikasi ini berfokus pada rekomendasi tempat berdasarkan:
- budget pengguna,
- preferensi fasilitas/selera,
- wilayah,
- dan relevansi pencarian.

## Fitur Utama

- **Splash + Onboarding Preferensi**
  - Pengguna memilih wilayah, budget, dan preferensi awal.
- **Rekomendasi Cerdas**
  - Menggunakan kombinasi skor budget, kemiripan query/preferensi, dan rating.
- **Beranda Interaktif**
  - Highlight rekomendasi, tempat populer, quick filter budget/wilayah.
- **Pencarian + Riwayat**
  - Cari tempat, simpan riwayat, dan filter hasil.
- **Favorit**
  - Simpan tempat favorit dan lihat kembali di tab favorit.
- **Peta & Rute**
  - Tampilkan marker lokasi tempat dan buka navigasi ke Google Maps.
- **Tambah Tempat**
  - Form input tempat baru lalu kirim ke API (jika API aktif).
- **Pengaturan & Notifikasi**
  - Halaman pelengkap sesuai desain UI.

## Teknologi yang Dipakai

- **Flutter** + **Dart**
- `http` (REST API)
- `shared_preferences` (penyimpanan lokal)
- `flutter_map` + `latlong2` (OpenStreetMap)
- `url_launcher` (buka Google Maps)
- `intl` (format mata uang/dll)

## Struktur Folder Penting

```text
lib/
  config/        # konfigurasi API
  models/        # model data (PlaceModel, MenuHighlight)
  screens/       # seluruh halaman aplikasi
  services/      # API service, preference service, recommendation service
  theme/         # tema dan warna aplikasi
  widgets/       # komponen UI reusable
assets/images/   # aset gambar dan ikon
UIdanFitur/      # referensi tampilan/desain
```

## Cara Menjalankan

1. Pastikan Flutter SDK sudah terpasang.
2. Install dependency:
   ```bash
   flutter pub get
   ```
3. Jalankan aplikasi:
   ```bash
   flutter run
   ```

## Konfigurasi API (Opsional)

Secara default aplikasi tetap berjalan dengan **data fallback lokal**.

Jika ingin mengaktifkan backend Supabase:
1. Buka file: `lib/config/api_config.dart`
2. Isi nilai:
   - `supabaseUrl`
   - `supabaseAnonKey`
3. Pastikan endpoint tabel `places` sesuai format data yang dipakai aplikasi.

> Jika konfigurasi API kosong/salah, aplikasi akan otomatis memakai data fallback dan tidak crash.

## Alur Penggunaan Singkat

1. Buka aplikasi dan selesaikan onboarding.
2. Pilih budget/wilayah yang diinginkan.
3. Lihat rekomendasi di beranda atau cari langsung lewat tab cari.
4. Simpan tempat favorit.
5. Buka detail tempat lalu gunakan fitur peta/rute untuk navigasi.

## Catatan

- Proyek ini menggunakan tema gelap khas MAMPIR.
- Data user seperti budget, preferensi, riwayat pencarian, dan favorit disimpan lokal via `SharedPreferences`.
