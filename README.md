# MAMPIR App

**MAMPIR** (Makan, Ampir, Pilih, dan Rekomendasi) adalah aplikasi Flutter untuk membantu pengguna menemukan tempat makan dan nongkrong terbaik di **Kota Purwokerto dan sekitarnya** (Baturraden, Sokaraja, Sumbang, Unsoed, dll.).

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
- **Near Me / Tempat Terdekat**
  - Deteksi GPS real-time, filter radius (0–1, 1–3, 3–5, 5–10, >10 km),
    filter kategori, sorting terdekat/rating tertinggi, peta Google Maps,
    dan daftar kartu tempat dengan detail serta petunjuk arah.


- **Pengaturan & Notifikasi**
  - Halaman pelengkap sesuai desain UI.

## Teknologi yang Dipakai

- **Flutter** + **Dart**
- `http` (REST API)
- `shared_preferences` (penyimpanan lokal)
- `google_maps_flutter` (peta Google Maps untuk Near Me)
- `geolocator` (deteksi GPS real-time)
- `flutter_map` + `latlong2` (peta alternatif/OpenStreetMap)
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
3. Jalankan aplikasi dengan konfigurasi runtime:
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
     --dart-define=GOOGLE_PLACES_API_KEY=YOUR_PLACES_KEY \
     --dart-define=GOOGLE_ROUTES_API_KEY=YOUR_ROUTES_KEY
   ```

## Konfigurasi Google Maps dan Supabase

Google Places dan Google Routes memerlukan API key Google Cloud. Aktifkan
Places API (New) dan Routes API, lalu batasi setiap key berdasarkan API dan
platform. Jangan menulis key langsung ke source code atau commit ke GitHub.
Key yang pernah dibagikan atau tertanam di source sebaiknya segera di-rotate
dari Google Cloud Console.

Untuk Android, tambahkan key yang sudah dibatasi ke `android/local.properties`
sebagai `GOOGLE_MAPS_API_KEY=...`; file tersebut sudah di-gitignore sehingga
key tidak ikut ter-commit. Manifest mengambilnya melalui placeholder dari
`android/app/build.gradle.kts`.

Jalankan [supabase_setup.sql](supabase_setup.sql) pada SQL Editor Supabase.
Katalog mobile membaca tabel `places`; nilai Google menjadi baseline dan
perubahan admin disimpan sebagai override. Operasi admin dilindungi Supabase
Auth dan role `admin` di tabel `user_profiles`.

Jika konfigurasi belum diisi atau jaringan gagal, aplikasi tetap menampilkan
data cache/fallback lokal dan pencarian Google menghasilkan kosong, bukan
mengarang koordinat, rating, menu, atau jam buka.

## Menjalankan Admin Desktop

Aplikasi admin terpisah berada di [desktop/](desktop/). Jalankan:

```bash
cd desktop
flutter pub get
flutter run -d windows \
  --dart-define=SUPABASE_URL=https://vdqdithxujxvzyybjtpn.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkcWRpdGh4dWp4dnp5eWJqdHBuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMyMzA2NTIsImV4cCI6MjEwODgwNjY1Mn0.7zE0gLxh0a2DNzdVcRfTj3EZDaqXWZ09kL5gcXTETXY
```

Ganti `-d linux` dengan `-d windows` atau `-d macos`. Login memakai akun
Supabase Auth yang sudah diberi `role = 'admin'`. Sinkronisasi Google terjadwal
memakai [Edge Function sync-places](supabase/functions/sync-places/index.ts)
agar secret tidak masuk aplikasi. Deploy dan isi secret function dari Supabase
CLI:

```bash
supabase functions deploy sync-places
supabase secrets set GOOGLE_PLACES_API_KEY=YOUR_PLACES_SERVER_KEY
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
```

Jalankan function secara manual dari tombol `Sinkron Google`; untuk jadwal,
hubungkan function tersebut ke Supabase Cron/Edge Function schedule. Nilai
yang pernah diubah admin disimpan di `override_fields` dan tidak ditimpa saat
sinkronisasi berikutnya.

## Alur Penggunaan Singkat

1. Buka aplikasi dan selesaikan onboarding.
2. Pilih budget/wilayah yang diinginkan.
3. Lihat rekomendasi di beranda atau cari langsung lewat tab cari.
4. Simpan tempat favorit.
5. Buka detail tempat lalu gunakan fitur peta/rute untuk navigasi.

## Catatan

- Proyek ini menggunakan tema gelap khas MAMPIR.
- Data user seperti budget, preferensi, riwayat pencarian, dan favorit disimpan lokal via `SharedPreferences`.
