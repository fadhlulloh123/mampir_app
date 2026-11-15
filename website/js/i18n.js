/**
 * MAMPIR Web - Centralized Localization & Internationalization (i18n) Engine
 * Mendukung Bahasa Indonesia (ID) & English (EN) dengan persistensi di LocalStorage.
 * Menyediakan kamus terjemahan 100% lengkap untuk seluruh komponen UI web.
 */

const I18nService = {
  currentLang: 'id',
  STORAGE_KEY: 'mampir_language',
  listeners: [],

  translations: {
    id: {
      // Navbar & Header
      brand_sub: 'Purwokerto & Sekitarnya',
      search_placeholder: 'Cari kafe, mendoan, warkop, budget...',
      btn_filter_budget: 'Filter Budget',
      guest_user: 'Tamu Purwokerto',
      lang_select: 'Bahasa',
      btn_theme_title: 'Ganti Tema Tampilan',
      btn_notif_title: 'Pusat Notifikasi & Agenda Kafe',
      btn_user_profile: 'Akun Pengguna',
      sync_success: 'Data berhasil disinkronkan!',
      sync_connecting: 'Menghubungkan...',
      api_places_count: 'Supabase REST API ({n} Tempat)',
      api_sync_title: 'Klik untuk sinkronisasi ulang data dengan Supabase',
      map_btn_center: '📍 Pusat Alun-Alun',

      // Sidebar Navigation
      nav_home: 'Beranda',
      nav_search: 'Cari Tempat',
      nav_favorites: 'Favorit Saya',
      nav_help: 'Pusat Bantuan',
      nav_admin: 'Admin & Mitra',
      nav_settings: 'Pengaturan',

      // Regions
      region_all: 'Semua Wilayah',
      region_pwt_kota: 'Purwokerto Kota',
      region_baturraden: 'Baturraden',
      region_pwt_utara: 'Purwokerto Utara (Unsoed)',
      region_sokaraja: 'Sokaraja',
      region_pwt_timur: 'Purwokerto Timur & Sumbang',
      region_pwt_barat: 'Purwokerto Barat & Selatan',
      region_banyumas_all: 'Semua Wilayah Banyumas',

      // Categories
      cat_all: '✨ Semua Tempat',
      cat_cafe: '☕ Cafe',
      cat_warkop: '🍵 Warkop',
      cat_resto: '🍽️ Restoran',
      cat_cafe_label: 'Cafe',
      cat_warkop_label: 'Warkop',
      cat_resto_label: 'Restoran',

      // Facilities
      fac_wifi: 'WiFi Cepat',
      fac_power: 'Colokan Listrik',
      fac_ac: 'Ruangan Ber-AC',
      fac_outdoor: 'Area Outdoor',
      fac_parking: 'Parkir Luas',
      fac_prayer: 'Musholla',
      fac_livemusic: 'Live Music',
      fac_smoking: 'Area Merokok',
      fac_indoor: 'Indoor Nyaman',

      // Search Tab, History, & Sorting
      recent_searches: 'Riwayat Pencarian Terakhir',
      clear_all: 'Hapus Semua',
      no_recent_searches: 'Belum ada riwayat pencarian.',
      showing_results_for: 'Menampilkan hasil pencarian untuk:',
      all_places_phrase: 'Semua Tempat',
      sort_recommended: '🎯 Paling Direkomendasikan',
      sort_rating: '⭐ Rating Tertinggi',
      sort_distance: '📍 Jarak Terdekat',
      sort_price_low: '💰 Harga Termurah',

      // Place Cards & Home Sections
      top_recommendation: 'REKOMENDASI UTAMA',
      best_budget_fit: 'Paling cocok dengan budget Anda',
      km_from_center: 'km dari Alun-Alun',
      activity_recommendation_title: '✨ Rekomendasi untuk Anda',
      activity_recommendation_sub: 'Berdasarkan kafe dan wilayah yang sering Anda jelajahi',
      activity_fallback_sub: 'Kafe paling populer dengan rating tertinggi di Purwokerto',
      activity_fav_format: 'Favorit Anda: {category} di {region}',
      activity_interest_format: 'Kategori Minat: {category}',
      activity_frequent_format: 'Sering Dikunjungi di {region}',
      activity_similar: 'Rekomendasi Serupa',
      activity_top_fav: '⭐ Pilihan Terfavorit (Rating {rating})',
      all_recommendations_title: 'Rekomendasi Tempat Kuliner & Nongkrong',
      places_found: 'tempat ditemukan',
      no_places_title: 'Tidak ada tempat yang cocok',
      no_places_desc: 'Coba sesuaikan filter wilayah, kategori, atau naikkan batas anggaran Anda.',
      btn_reset_filters: 'Reset Filter',
      pin_map: '🗺️ Pin Peta',
      starting_from: 'Mulai',
      per_person: '/org',
      budget_super_saver: 'Sangat Hemat ({price}) • Rating {rating}',
      budget_friendly: 'Pas di Kantong ({price}) • Rating {rating}',
      budget_popular_choice: 'Pilihan Populer • Rating {rating} ({count}+ ulasan)',
      reviews_word: 'ulasan',
      view_detail: 'Lihat Detail',
      route_label: 'Rute ↗',
      fav_header_desc: 'Tersimpan {count} tempat di penyimpanan browser lokal Anda (❤️).',

      // Cafe Detail Modal
      detail_title: 'Detail Tempat Kuliner',
      rating_label: 'Rating',
      price_range_label: 'Rentang Harga',
      distance_label: 'Jarak',
      open_hours_label: 'Jam Operasional',
      desc_title: 'Deskripsi',
      facilities_title: 'Fasilitas Tersedia',
      menu_title: 'Menu Andalan',
      events_title: '🎉 Agenda & Pengumuman Kafe',
      events_upcoming_title: '📅 Agenda & Event Mendatang',
      events_count: '{count} Acara',
      route_btn: 'Buka Rute di Google Maps',
      btn_contact_wa: 'Hubungi Pengelola',
      btn_share: 'Bagikan',
      reviews_title: '⭐ Ulasan & Penilaian Pengunjung',
      add_review_title: 'Tulis Ulasan Anda',
      review_name_ph: 'Nama Anda...',
      review_comment_ph: 'Bagaimana pengalaman Anda di kafe ini?',
      btn_submit_review: 'Kirim Ulasan',
      review_submitted: 'Terima kasih! Ulasan Anda berhasil diterbitkan.',
      review_alert_empty: 'Silakan tuliskan pengalaman ulasan Anda.',
      btn_set_reminder: '⏰ Pasang Pengingat',
      btn_reminder_active: '✅ Pengingat Terpasang',
      btn_add_to_calendar: 'Tambah ke Kalender',

      // Share Modal
      share_modal_title: 'Bagikan Kafe Ini',
      share_subtitle: 'Ajak teman dan keluarga mampir ke tempat nongkrong asyik ini!',
      btn_copy_link: 'Salin Tautan',
      toast_link_copied: 'Tautan berhasil disalin ke clipboard!',
      share_wa: 'WhatsApp',
      share_x: 'Twitter / X',
      share_fb: 'Facebook',
      share_text_prefix: 'Yuk cek {name} di MAMPIR Purwokerto:',

      // Budget Modal & Smart Recommendations
      budget_modal_title: '💰 Filter Anggaran & Fasilitas',
      budget_max_label: 'Batas Maksimal Anggaran / Orang:',
      budget_cheap: 'Hemat',
      budget_luxury: 'Sultan',
      fac_priority_label: 'Prioritas Fasilitas:',
      btn_cancel: 'Batal',
      btn_apply_filter: 'Terapkan Filter',
      toast_budget_applied: 'Filter diterapkan: Budget {budget}',
      budget_active_label: 'Budget: ≤ {budget}',
      budget_clear_title: 'Hapus filter budget',
      budget_preset_label: 'Pilihan Cepat:',
      budget_preset_student: 'Mahasiswa (< 20k)',
      budget_preset_casual: 'Nongkrong Santai (20k - 40k)',
      budget_preset_wfc: 'Work from Cafe (40k+)',
      budget_preview_match: '✨ Ditemukan {count} kafe yang cocok dengan kantongmu!',
      budget_preview_tight: '⚠️ Pilihan sangat terbatas. Naikkan sedikit budget untuk melihat lebih banyak opsi.',
      budget_badge_best_match: 'Pas di Budget',
      budget_can_get_prefix: 'Bisa dapet:',
      budget_upsell_banner_title: 'Rekomendasi Cerdas Budget',
      budget_upsell_banner_desc: 'Hanya butuh tambah sedikit lagi (+ {amount}) untuk membuka {count} kafe populer lainnya di sekitar sini!',
      budget_upsell_btn: '+ Tambah {amount} Sekarang',
      toast_budget_cleared: 'Filter budget dinonaktifkan.',
      toast_budget_upsell_applied: 'Budget dinaikkan menjadi {budget}.',

      // Onboarding Modal
      onboarding_title: 'Selamat Datang di MAMPIR!',
      onboarding_desc: 'Temukan tempat makan, nongkrong, ngopi, dan kuliner autentik terbaik di wilayah Purwokerto dan sekitarnya (Baturraden, Sokaraja) sesuai selera dan isi kantongmu.',
      onboarding_select_label: 'Pilih Zona Jelajah Utama Anda:',
      onboarding_btn_start: 'Mulai Eksplorasi Sekarang 🚀',

      // Auth Modal
      auth_tab_login: '🔑 Masuk',
      auth_tab_register: '📝 Daftar Akun',
      auth_email_label: 'Alamat Email:',
      auth_pass_label: 'Kata Sandi:',
      auth_btn_login: 'Masuk ke Akun',
      auth_name_label: 'Nama Lengkap:',
      auth_pass_min: 'Kata Sandi (min. 6 karakter):',
      auth_pass_confirm: 'Konfirmasi Kata Sandi:',
      auth_btn_register: 'Daftar Akun Baru',
      auth_or: 'ATAU',
      auth_btn_guest: '👤 Lanjut Jelajah sebagai Tamu (Mode Tanpa Akun)',
      toast_logged_in: 'Berhasil masuk!',
      toast_logged_out: 'Berhasil keluar.',
      toast_guest: 'Masuk sebagai Tamu.',

      // Admin Gate & Dashboard (RBAC)
      admin_gate_title: 'Area Khusus Administrator MAMPIR',
      admin_gate_desc: 'Halaman ini dilindungi sistem <strong>Role-Based Access Control (RBAC)</strong>. Pengguna umum <strong>tidak memiliki izin</strong> untuk mengelola data, mengubah kontak WhatsApp, atau mempublikasikan agenda kafe.',
      admin_status_your: 'Status Anda:',
      admin_role_user: 'ROLE: USER (HANYA BACA)',
      admin_gate_warning: '⛔ Anda hanya memiliki hak akses jelajah direktori. Untuk mengelola direktori kafe, silakan lakukan otentikasi menggunakan kredensial Administrator resmi di bawah.',
      admin_gate_email_label: 'Email / ID Administrator:',
      admin_gate_pass_label: 'Kata Sandi / Kunci Akses Admin:',
      admin_gate_btn_submit: '🔐 Verifikasi & Buka Panel Admin',
      admin_gate_verifying: 'Memverifikasi Akses Admin...',
      admin_gate_credentials_hint: 'Kredensial Admin Default:',
      admin_gate_err_invalid: '❌ Kredensial Administrator tidak valid. Pengguna biasa tidak diizinkan mengakses panel ini.',
      admin_panel_title: 'Panel Administrator Direktori MAMPIR',
      admin_panel_subtitle: 'Kelola profil kafe, jam operasional, tautan WhatsApp pengelola, dan publikasikan agenda acara.',
      admin_btn_exit: '🔒 Keluar dari Panel Admin',
      admin_stats_cafes: 'Kafe Dikelola',
      admin_stats_events: 'Agenda Aktif',
      admin_stats_views: 'Total Interaksi',
      admin_stats_active_badge: 'Aktif di MAMPIR',
      admin_stats_visitors_badge: 'Pengunjung Bulan Ini',
      admin_select_cafe_label: 'Pilih Kafe Anda:',
      admin_tab_profile: 'Profil & Kontak Kafe',
      admin_tab_events: 'Manajemen Agenda & Event',
      admin_form_cafe_name: 'Nama Kafe:',
      admin_form_wa_label: 'Nomor WhatsApp Pengelola (Format 62xxx):',
      admin_form_wa_hint: 'Digunakan untuk tombol langsung "Hubungi Pengelola" (tanpa menampilkan nomor mentah ke pengunjung).',
      admin_form_region: 'Wilayah:',
      admin_form_hours: 'Jam Operasional:',
      admin_form_address: 'Alamat Lengkap:',
      admin_form_desc: 'Deskripsi Kafe:',
      admin_form_facilities: 'Fasilitas (Pisahkan dengan koma):',
      btn_save_changes: 'Simpan Perubahan Profil',
      admin_events_list_title: 'Daftar Agenda & Promo untuk {cafe}',
      btn_add_event: 'Tambah Agenda / Promo Baru',
      admin_events_empty: 'Belum ada agenda atau promo aktif untuk kafe ini. Klik tombol di atas untuk menerbitkan event baru!',
      btn_delete: 'Hapus',
      confirm_delete_event: 'Yakin ingin menghapus agenda ini?',
      toast_admin_login_success: '✅ Otentikasi Administrator Berhasil! Hak akses penuh aktif.',
      toast_admin_logout: '🔒 Keluar dari Panel Administrator. Kembali ke mode Pengguna biasa.',
      toast_admin_denied: '⛔ Akses ditolak: Hanya Administrator resmi yang berwenang!',
      toast_admin_saved: 'Perubahan profil kafe berhasil disimpan!',
      toast_event_published: 'Agenda baru berhasil dipublikasikan!',
      toast_event_deleted: 'Agenda berhasil dihapus.',

      // Create Event Modal
      modal_event_title: '🎉 Tambah Agenda & Pengumuman Kafe',
      event_select_cafe: 'Pilih Kafe Anda:',
      event_title_label: 'Judul Agenda / Promo:',
      event_title_ph: 'Contoh: Live Acoustic Malam Minggu & Diskon 20%',
      event_cat_label: 'Kategori Acara:',
      event_cat_music: '🎵 Live Music / Konser Akustik',
      event_cat_promo: '🏷️ Promo Spesial / Diskon',
      event_cat_workshop: '☕ Workshop / Edukasi Kopi',
      event_cat_nobar: '⚽ Nonton Bareng (Nobar)',
      event_cat_other: '✨ Acara Lainnya',
      event_schedule_label: 'Jadwal / Waktu Pelaksanaan:',
      event_schedule_ph: 'Contoh: Sabtu, 19.30 - 22.00 WIB',
      event_desc_label: 'Deskripsi Acara & Ketentuan:',
      event_desc_ph: 'Jelaskan detail acara, syarat promo, dll...',
      event_badge_label: 'Label Badge Singkat:',
      event_badge_ph: 'Contoh: Promo Spesial / Free Entry',
      event_btn_publish: 'Publikasikan Agenda Kafe 🚀',

      // Calendar Modal & Notifications
      cal_modal_title: '📅 Pasang Pengingat Kalender',
      cal_modal_sub: 'Pilih metode integrasi ke kalender Anda agar tidak ketinggalan acara:',
      cal_gcal_title: 'Google Calendar',
      cal_gcal_desc: 'Buka langsung agenda acara di Google Calendar web/aplikasi',
      cal_ics_title: 'Unduh File Kalender (.ics)',
      cal_ics_desc: 'Kompatibel dengan Apple Calendar (iPhone/Mac), Outlook & Android',
      cal_web_title: 'Pasang Pengingat Notifikasi MAMPIR',
      cal_web_desc: 'Simpan jadwal di Pusat Notifikasi akun MAMPIR Anda',
      toast_reminder_set: 'Pengingat agenda berhasil dipasang!',
      toast_reminder_cancelled: 'Pengingat agenda dinonaktifkan.',
      toast_ics_downloaded: 'File kalender (.ics) berhasil diunduh!',
      notif_title: 'Pusat Notifikasi',
      notif_sub: 'Update agenda promo & kegiatan dari kafe favorit Anda',
      notif_mark_read: 'Tandai Dibaca',
      notif_empty: 'Belum ada notifikasi baru saat ini.',
      notif_toast_all_read: 'Semua notifikasi telah ditandai dibaca.',
      notif_just_now: 'Baru saja',

      // Settings View
      settings_title: '⚙️ Pengaturan Aplikasi MAMPIR',
      account_info: 'Informasi Akun',
      logged_as: 'Masuk sebagai',
      mode_guest: 'Mode Tamu',
      btn_switch_acc: 'Ganti Akun',
      btn_logout: 'Keluar (Sign Out)',
      theme_section_title: 'Tema Tampilan',
      theme_dark: '🌙 Mode Gelap',
      theme_light: '☀️ Mode Terang',
      about_title: 'Tentang MAMPIR Web',
      about_desc: '<strong>MAMPIR</strong>: Makan, Ampir, Pilih, dan Rekomendasi Tempat Makan & Nongkrong di Kota Purwokerto dan Sekitarnya.<br/>Edisi Multiplatform Web v2.0 • PML 2026.',

      // Help Center
      help_title: 'Pusat Bantuan & Edukasi MAMPIR',
      help_subtitle: 'Panduan lengkap jelajah kuliner dan informasi penggunaan aplikasi MAMPIR Purwokerto.',
      help_search_ph: 'Cari pertanyaan bantuan atau panduan...',
      mitra_guide_box_title: 'Butuh Bantuan atau Ingin Mendaftarkan Kafe?',
      mitra_guide_box_desc: 'Hubungi tim layanan bantuan resmi MAMPIR via WhatsApp untuk pertanyaan seputar aplikasi atau informasi pendaftaran direktori kafe.',
      btn_contact_support: 'Hubungi Helpdesk MAMPIR (WhatsApp)',

      // GPS Geolocation & Google Maps
      nav_near_me: 'Terdekat (Near Me)',
      gps_detect_btn_title: 'Deteksi Warung & Tempat Makan di Sekitar GPS Anda (Google Maps)',
      gps_status_btn: 'GPS Purwokerto',
      gps_detecting: 'Mendeteksi GPS...',
      gps_connected_pwt: 'GPS Aktif ({count} terdeteksi)',
      gps_outside_pwt: 'GPS di Luar Purwokerto (Simulasi Alun-Alun)',
      map_btn_gps: '🎯 Lokasi GPS Saya',
      badge_google_live: '🗺️ Google Maps Live',
      distance_from_gps: 'km dari lokasi GPS Anda',
      nearme_title: 'Tempat Makan & Nongkrong Terdekat',
      nearme_subtitle: 'Pencarian akurat berbasis GPS & Google Maps Platform ala Gojek',
      dist_all: 'Semua Jarak',
      dist_0_1: '0–1 km',
      dist_1_3: '1–3 km',
      dist_3_5: '3–5 km',
      dist_5_10: '5–10 km',
      dist_10_plus: '> 10 km',
      cat_all_food: 'Semua Kategori',
      cat_resto: 'Restoran',
      cat_warung: 'Warung Makan',
      cat_cafe: 'Cafe',
      cat_coffee: 'Coffee Shop',
      cat_nongkrong: 'Tempat Nongkrong',
      cat_fastfood: 'Fast Food',
      cat_streetfood: 'Street Food',
      status_open: 'Buka Sekarang',
      status_closed: 'Tutup',
      btn_directions: 'Petunjuk Arah',
      btn_refresh_location: 'Perbarui Lokasi',
      nearme_empty_title: 'Tidak Ada Tempat dalam Radius Ini',
      nearme_empty_desc: 'Belum ada tempat makan atau nongkrong dalam jarak yang dipilih. Coba perluas filter jarak atau ganti kategori.',
      btn_expand_radius: 'Perluas Radius Jarak',
      nearme_sort_nearest: 'Terdekat',
      nearme_sort_rating: 'Rating Tertinggi',
      nearme_sort_populer: 'Paling Populer',
      nearme_sort_cheap: 'Harga Termurah',
      nearme_places_found: '{count} tempat terdekat ditemukan',
      nearme_test_location: 'Uji Titik Lokasi:',
      nearme_show_map: 'Lihat di Peta',

      // Tongkrongan Roulette & Smart Decision Maker
      nav_roulette: 'Putar Roda Pilihan',
      wheel_fab_label: 'Bingung Pilih? Putar Roda',
      wheel_card_btn_add: '+ Adu Tongkrongan',
      wheel_card_btn_added: '✓ Terpilih',
      wheel_drawer_title: '{count} Kafe Dipilih untuk Diadu',
      wheel_drawer_cta: 'Mulai Adu & Putar Sekarang',
      wheel_modal_title: '🎲 Tongkrongan Roulette & Smart Decision Maker',
      wheel_modal_sub: 'Pilih 2 hingga 4 kafe kandidat, lalu putar roda untuk menemukan tempat yang paling objektif dan worth it!',
      wheel_mode_luck: '🎲 Murni Acak (Pure Luck)',
      wheel_mode_weighted: '🧠 Smart "Worth It" Weighted',
      wheel_mode_luck_desc: 'Semua kafe memiliki ukuran juring & peluang menang yang sama rata.',
      wheel_mode_weighted_desc: 'Ukuran juring menyesuaikan skor analisis (kafe paling worth it berpeluang lebih besar menang).',
      wheel_slot_required: 'Wajib diisi',
      wheel_slot_optional: 'Opsional',
      wheel_slot_empty: 'Klik untuk memilih kafe...',
      wheel_btn_random_fill: '⚡ Acak Otomatis dari Sekitarmu',
      wheel_btn_from_fav: '❤️ Dari Favorit Saya',
      wheel_btn_spin: 'PUTAR RODA SEKARANG! 🎯',
      wheel_spinning: 'Memutar roda keputusan...',
      wheel_need_at_least_2: 'Pilih minimal 2 kafe untuk memulai putaran roda.',
      wheel_max_4_reached: 'Maksimal 4 kafe yang dapat dipilih sekaligus.',
      wheel_sound_on: 'Suara Aktif',
      wheel_sound_off: 'Suara Nonaktif',
      wheel_winner_header: '🎉 Pilihan Terbaik Hari Ini:',
      wheel_why_worth_it: 'Analisis Sistem: Kenapa Paling Worth It?',
      wheel_worth_score_label: 'Skor Kelayakan:',
      wheel_action_route: '🗺️ Buka Rute di Peta',
      wheel_action_wa: '💬 Hubungi Pengelola (WhatsApp)',
      wheel_action_spin_again: '🔄 Putar Ulang / Ganti Kandidat',
      wheel_reason_price_best: '💰 Harga paling hemat (mulai {min} vs rata-rata {avg})',
      wheel_reason_rating_best: '⭐ Rating & ulasan tertinggi: {rating} dari {reviews}+ pengunjung',
      wheel_reason_facilities_best: '⚡ Fasilitas paling lengkap ({fac})',
      wheel_reason_distance_best: '📍 Lokasi paling dekat ({dist} km dari Alun-Alun)',
      wheel_reason_open_now: '🕒 Buka sekarang ({hours})',
      toast_candidate_added: 'Ditambahkan ke adu tongkrongan ({count}/4)',
      toast_candidate_removed: 'Dihapus dari adu tongkrongan',
      toast_candidate_cleared: 'Daftar adu tongkrongan dikosongkan.'
    },

    en: {
      // Navbar & Header
      brand_sub: 'Purwokerto & Surroundings',
      search_placeholder: 'Search cafe, coffee shop, budget...',
      btn_filter_budget: 'Budget Filter',
      guest_user: 'Purwokerto Guest',
      lang_select: 'Language',
      btn_theme_title: 'Toggle Display Theme',
      btn_notif_title: 'Notification Center & Cafe Agenda',
      btn_user_profile: 'User Account',
      sync_success: 'Data synchronized successfully!',
      sync_connecting: 'Connecting...',
      api_places_count: 'Supabase REST API ({n} Places)',
      api_sync_title: 'Click to re-synchronize data with Supabase',
      map_btn_center: '📍 Town Square Center',

      // Sidebar Navigation
      nav_home: 'Home',
      nav_search: 'Explore Places',
      nav_favorites: 'My Favorites',
      nav_help: 'Help Center',
      nav_admin: 'Partner & Admin',
      nav_settings: 'Settings',

      // Regions
      region_all: 'All Regions',
      region_pwt_kota: 'Purwokerto City',
      region_baturraden: 'Baturraden',
      region_pwt_utara: 'North Purwokerto (Unsoed)',
      region_sokaraja: 'Sokaraja',
      region_pwt_timur: 'East Purwokerto & Sumbang',
      region_pwt_barat: 'West & South Purwokerto',
      region_banyumas_all: 'All Banyumas Regions',

      // Categories
      cat_all: '✨ All Places',
      cat_cafe: '☕ Cafe',
      cat_warkop: '🍵 Coffee Stall',
      cat_resto: '🍽️ Restaurant',
      cat_cafe_label: 'Cafe',
      cat_warkop_label: 'Coffee Stall',
      cat_resto_label: 'Restaurant',

      // Facilities
      fac_wifi: 'High-speed WiFi',
      fac_power: 'Power Outlet',
      fac_ac: 'Air Conditioned',
      fac_outdoor: 'Outdoor Area',
      fac_parking: 'Spacious Parking',
      fac_prayer: 'Prayer Room',
      fac_livemusic: 'Live Music',
      fac_smoking: 'Smoking Area',
      fac_indoor: 'Cozy Indoor',

      // Search Tab, History, & Sorting
      recent_searches: 'Recent Searches',
      clear_all: 'Clear All',
      no_recent_searches: 'No search history yet.',
      showing_results_for: 'Showing search results for:',
      all_places_phrase: 'All Places',
      sort_recommended: '🎯 Most Recommended',
      sort_rating: '⭐ Top Rated',
      sort_distance: '📍 Nearest Distance',
      sort_price_low: '💰 Lowest Price',

      // Place Cards & Home Sections
      top_recommendation: 'TOP PICK FOR YOU',
      best_budget_fit: 'Best fit for your budget',
      km_from_center: 'km from Town Square',
      activity_recommendation_title: '✨ Recommended for You',
      activity_recommendation_sub: 'Based on cafes and areas you frequently explore',
      activity_fallback_sub: 'Most popular cafes with the highest ratings in Purwokerto',
      activity_fav_format: 'Your Favorite: {category} in {region}',
      activity_interest_format: 'Interest: {category}',
      activity_frequent_format: 'Frequently Visited in {region}',
      activity_similar: 'Similar Spot',
      activity_top_fav: '⭐ Top Favorite (Rating {rating})',
      all_recommendations_title: 'Authentic Spots & Hangouts',
      places_found: 'places found',
      no_places_title: 'No matching places found',
      no_places_desc: 'Try adjusting your region, category, or increasing your budget limit.',
      btn_reset_filters: 'Reset Filters',
      pin_map: '🗺️ Map Pin',
      starting_from: 'From',
      per_person: '/person',
      budget_super_saver: 'Super Saver ({price}) • Rating {rating}',
      budget_friendly: 'Budget Friendly ({price}) • Rating {rating}',
      budget_popular_choice: 'Popular Choice • Rating {rating} ({count}+ reviews)',
      reviews_word: 'reviews',
      view_detail: 'View Details',
      route_label: 'Route ↗',
      fav_header_desc: 'Saved {count} spots in your local browser storage (❤️).',

      // Cafe Detail Modal
      detail_title: 'Culinary Spot Details',
      rating_label: 'Rating',
      price_range_label: 'Price Range',
      distance_label: 'Distance',
      open_hours_label: 'Opening Hours',
      desc_title: 'Description',
      facilities_title: 'Available Facilities',
      menu_title: 'Signature Menu',
      events_title: '🎉 Cafe Announcements & Events',
      events_upcoming_title: '📅 Upcoming Cafe Events & Schedule',
      events_count: '{count} Events',
      route_btn: 'Open Route in Google Maps',
      btn_contact_wa: 'Contact Manager',
      btn_share: 'Share',
      reviews_title: '⭐ Visitor Reviews & Ratings',
      add_review_title: 'Write Your Review',
      review_name_ph: 'Your Name...',
      review_comment_ph: 'How was your experience at this cafe?',
      btn_submit_review: 'Submit Review',
      review_submitted: 'Thank you! Your review has been published.',
      review_alert_empty: 'Please write your review experience.',
      btn_set_reminder: '⏰ Set Reminder',
      btn_reminder_active: '✅ Reminder Set',
      btn_add_to_calendar: 'Add to Calendar',

      // Share Modal
      share_modal_title: 'Share This Cafe',
      share_subtitle: 'Invite friends and family to visit this great hangout spot!',
      btn_copy_link: 'Copy Link',
      toast_link_copied: 'Link copied to clipboard!',
      share_wa: 'WhatsApp',
      share_x: 'Twitter / X',
      share_fb: 'Facebook',
      share_text_prefix: 'Check out {name} on MAMPIR Purwokerto:',

      // Budget Modal & Smart Recommendations
      budget_modal_title: '💰 Budget & Facilities Filter',
      budget_max_label: 'Maximum Budget Limit / Person:',
      budget_cheap: 'Budget',
      budget_luxury: 'Luxury',
      fac_priority_label: 'Facility Priorities:',
      btn_cancel: 'Cancel',
      btn_apply_filter: 'Apply Filter',
      toast_budget_applied: 'Filter applied: Budget {budget}',
      budget_active_label: 'Budget: ≤ {budget}',
      budget_clear_title: 'Clear budget filter',
      budget_preset_label: 'Quick Presets:',
      budget_preset_student: 'Student Budget (< 20k)',
      budget_preset_casual: 'Casual Hangout (20k - 40k)',
      budget_preset_wfc: 'Work from Cafe (40k+)',
      budget_preview_match: '✨ Found {count} cafes matching your budget!',
      budget_preview_tight: '⚠️ Very limited options. Increase budget slightly to unlock more places.',
      budget_badge_best_match: 'Best Value',
      budget_can_get_prefix: 'Can get:',
      budget_upsell_banner_title: 'Smart Budget Recommendation',
      budget_upsell_banner_desc: 'Just add a little more (+ {amount}) to unlock {count} more popular cafes around here!',
      budget_upsell_btn: '+ Add {amount} Now',
      toast_budget_cleared: 'Budget filter cleared.',
      toast_budget_upsell_applied: 'Budget increased to {budget}.',

      // Onboarding Modal
      onboarding_title: 'Welcome to MAMPIR!',
      onboarding_desc: 'Discover the best dining, coffee shops, and authentic culinary spots in Purwokerto and surroundings (Baturraden, Sokaraja) fitting your taste and budget.',
      onboarding_select_label: 'Choose Your Main Exploration Zone:',
      onboarding_btn_start: 'Start Exploring Now 🚀',

      // Auth Modal
      auth_tab_login: '🔑 Login',
      auth_tab_register: '📝 Register',
      auth_email_label: 'Email Address:',
      auth_pass_label: 'Password:',
      auth_btn_login: 'Sign In',
      auth_name_label: 'Full Name:',
      auth_pass_min: 'Password (min. 6 characters):',
      auth_pass_confirm: 'Confirm Password:',
      auth_btn_register: 'Create Account',
      auth_or: 'OR',
      auth_btn_guest: '👤 Continue as Guest (No Account Mode)',
      toast_logged_in: 'Successfully signed in!',
      toast_logged_out: 'Signed out successfully.',
      toast_guest: 'Browsing as Guest.',

      // Admin Gate & Dashboard (RBAC)
      admin_gate_title: 'MAMPIR Administrator Protected Area',
      admin_gate_desc: 'This page is protected by <strong>Role-Based Access Control (RBAC)</strong>. Regular users <strong>do not have permission</strong> to manage data, edit WhatsApp contacts, or publish cafe events.',
      admin_status_your: 'Your Status:',
      admin_role_user: 'ROLE: USER (READ ONLY)',
      admin_gate_warning: '⛔ You only have directory browsing permissions. To manage the cafe directory, please authenticate using official Administrator credentials below.',
      admin_gate_email_label: 'Administrator Email / ID:',
      admin_gate_pass_label: 'Password / Admin Access Key:',
      admin_gate_btn_submit: '🔐 Verify & Open Admin Panel',
      admin_gate_verifying: 'Verifying Admin Access...',
      admin_gate_credentials_hint: 'Default Admin Credentials:',
      admin_gate_err_invalid: '❌ Invalid Administrator credentials. Regular users are not allowed to access this panel.',
      admin_panel_title: 'MAMPIR Directory Administrator Panel',
      admin_panel_subtitle: 'Manage cafe profiles, opening hours, WhatsApp contact links, and publish event promotions.',
      admin_btn_exit: '🔒 Exit Admin Panel',
      admin_stats_cafes: 'Managed Cafes',
      admin_stats_events: 'Active Events',
      admin_stats_views: 'Total Interactions',
      admin_stats_active_badge: 'Active on MAMPIR',
      admin_stats_visitors_badge: 'Visitors This Month',
      admin_select_cafe_label: 'Select Your Cafe:',
      admin_tab_profile: 'Cafe Profile & Contact',
      admin_tab_events: 'Event Management',
      admin_form_cafe_name: 'Cafe Name:',
      admin_form_wa_label: 'Manager WhatsApp Number (62xxx format):',
      admin_form_wa_hint: 'Used for the direct "Contact Manager" button (without showing raw phone number to visitors).',
      admin_form_region: 'Region:',
      admin_form_hours: 'Opening Hours:',
      admin_form_address: 'Full Address:',
      admin_form_desc: 'Cafe Description:',
      admin_form_facilities: 'Facilities (Comma-separated):',
      btn_save_changes: 'Save Profile Changes',
      admin_events_list_title: 'Events & Promo List for {cafe}',
      btn_add_event: 'Add New Event / Promo',
      admin_events_empty: 'No active events or promos for this cafe yet. Click the button above to publish a new event!',
      btn_delete: 'Delete',
      confirm_delete_event: 'Are you sure you want to delete this event?',
      toast_admin_login_success: '✅ Administrator authentication successful! Full access granted.',
      toast_admin_logout: '🔒 Exited Administrator Panel. Switched back to User mode.',
      toast_admin_denied: '⛔ Access denied: Official Administrator only!',
      toast_admin_saved: 'Cafe profile changes saved successfully!',
      toast_event_published: 'New cafe event successfully published!',
      toast_event_deleted: 'Event successfully deleted.',

      // Create Event Modal
      modal_event_title: '🎉 Add Cafe Event & Announcement',
      event_select_cafe: 'Select Your Cafe:',
      event_title_label: 'Event / Promo Title:',
      event_title_ph: 'Example: Saturday Acoustic Night & 20% Off',
      event_cat_label: 'Event Category:',
      event_cat_music: '🎵 Live Music / Acoustic Concert',
      event_cat_promo: '🏷️ Special Promo / Discount',
      event_cat_workshop: '☕ Coffee Workshop & Education',
      event_cat_nobar: '⚽ Match Watch Party (Nobar)',
      event_cat_other: '✨ Other Events',
      event_schedule_label: 'Schedule / Time:',
      event_schedule_ph: 'Example: Saturday, 19:30 - 22:00 WIB',
      event_desc_label: 'Event Description & Terms:',
      event_desc_ph: 'Explain event details, promo terms, etc...',
      event_badge_label: 'Short Badge Label:',
      event_badge_ph: 'Example: Special Promo / Free Entry',
      event_btn_publish: 'Publish Cafe Event 🚀',

      // Calendar Modal & Notifications
      cal_modal_title: '📅 Add Event to Calendar',
      cal_modal_sub: 'Choose your calendar integration method so you do not miss out:',
      cal_gcal_title: 'Google Calendar',
      cal_gcal_desc: 'Open the event directly in Google Calendar web/app',
      cal_ics_title: 'Download iCal File (.ics)',
      cal_ics_desc: 'Compatible with Apple Calendar (iPhone/Mac), Outlook & Android',
      cal_web_title: 'Set MAMPIR In-App Reminder',
      cal_web_desc: 'Save schedule in your MAMPIR Notification Center',
      toast_reminder_set: 'Event reminder successfully set!',
      toast_reminder_cancelled: 'Event reminder cancelled.',
      toast_ics_downloaded: 'Calendar file (.ics) downloaded successfully!',
      notif_title: 'Notification Center',
      notif_sub: 'Latest promo agendas & events from your favorite cafes',
      notif_mark_read: 'Mark as Read',
      notif_empty: 'No new notifications at the moment.',
      notif_toast_all_read: 'All notifications marked as read.',
      notif_just_now: 'Just now',

      // Settings View
      settings_title: '⚙️ MAMPIR Application Settings',
      account_info: 'Account Information',
      logged_as: 'Signed in as',
      mode_guest: 'Guest Mode',
      btn_switch_acc: 'Switch Account',
      btn_logout: 'Sign Out',
      theme_section_title: 'Display Theme',
      theme_dark: '🌙 Dark Mode',
      theme_light: '☀️ Light Mode',
      about_title: 'About MAMPIR Web',
      about_desc: '<strong>MAMPIR</strong>: Authentic Culinary Discovery & Cafe Directory for Purwokerto and Surroundings.<br/>Multiplatform Web Edition v2.0 • PML 2026.',

      // Help Center
      help_title: 'MAMPIR Help Center & Education',
      help_subtitle: 'Comprehensive guide to exploring Purwokerto food spots and using the MAMPIR app.',
      help_search_ph: 'Search help questions or guides...',
      mitra_guide_box_title: 'Need Help or Want to List Your Cafe?',
      mitra_guide_box_desc: 'Contact the official MAMPIR helpdesk via WhatsApp for questions about the app or cafe directory listing inquiries.',
      btn_contact_support: 'Contact MAMPIR Helpdesk (WhatsApp)',

      // GPS Geolocation & Google Maps
      nav_near_me: 'Near Me',
      gps_detect_btn_title: 'Detect Food Places Near Your GPS (Google Maps)',
      gps_status_btn: 'GPS Purwokerto',
      gps_detecting: 'Detecting GPS...',
      gps_connected_pwt: 'GPS Active ({count} detected)',
      gps_outside_pwt: 'GPS Outside Purwokerto (Alun-Alun Simulation)',
      map_btn_gps: '🎯 My GPS Location',
      badge_google_live: '🗺️ Google Maps Live',
      distance_from_gps: 'km from your GPS',
      nearme_title: 'Nearby Food & Hangout Spots',
      nearme_subtitle: 'Accurate GPS & Google Maps Platform search like Gojek',
      dist_all: 'All Distances',
      dist_0_1: '0–1 km',
      dist_1_3: '1–3 km',
      dist_3_5: '3–5 km',
      dist_5_10: '5–10 km',
      dist_10_plus: '> 10 km',
      cat_all_food: 'All Categories',
      cat_resto: 'Restaurant',
      cat_warung: 'Food Stall / Warung',
      cat_cafe: 'Cafe',
      cat_coffee: 'Coffee Shop',
      cat_nongkrong: 'Hangout Spot',
      cat_fastfood: 'Fast Food',
      cat_streetfood: 'Street Food',
      status_open: 'Open Now',
      status_closed: 'Closed',
      btn_directions: 'Directions',
      btn_refresh_location: 'Update Location',
      nearme_empty_title: 'No Places Found in this Radius',
      nearme_empty_desc: 'No dining or hangout spots within the selected distance yet. Try expanding the distance filter or switching category.',
      btn_expand_radius: 'Expand Distance Radius',
      nearme_sort_nearest: 'Nearest',
      nearme_sort_rating: 'Top Rated',
      nearme_sort_populer: 'Most Popular',
      nearme_sort_cheap: 'Lowest Price',
      nearme_places_found: '{count} nearby places found',
      nearme_test_location: 'Test Location:',
      nearme_show_map: 'Show on Map',

      // Tongkrongan Roulette & Smart Decision Maker
      nav_roulette: 'Decision Spin Wheel',
      wheel_fab_label: "Can't Decide? Spin the Wheel",
      wheel_card_btn_add: '+ Add to VS',
      wheel_card_btn_added: '✓ Added',
      wheel_drawer_title: '{count} Cafes Selected for Comparison',
      wheel_drawer_cta: 'Start Battle & Spin Now',
      wheel_modal_title: '🎲 Hangout Roulette & Smart Decision Maker',
      wheel_modal_sub: 'Pick 2 to 4 candidate cafes and spin the wheel to find the most worth-it spot objectively!',
      wheel_mode_luck: '🎲 Pure Luck',
      wheel_mode_weighted: '🧠 Smart "Worth It" Weighted',
      wheel_mode_luck_desc: 'All cafes have equal slice sizes & winning probability.',
      wheel_mode_weighted_desc: 'Slice sizes scale with worth-it scores (higher value spot has greater winning chances).',
      wheel_slot_required: 'Required',
      wheel_slot_optional: 'Optional',
      wheel_slot_empty: 'Click to select a cafe...',
      wheel_btn_random_fill: '⚡ Auto Pick from Nearby',
      wheel_btn_from_fav: '❤️ From My Favorites',
      wheel_btn_spin: 'SPIN THE WHEEL NOW! 🎯',
      wheel_spinning: 'Spinning the decision wheel...',
      wheel_need_at_least_2: 'Please pick at least 2 cafes to start spinning the wheel.',
      wheel_max_4_reached: 'Maximum of 4 cafes can be selected at once.',
      wheel_sound_on: 'Sound On',
      wheel_sound_off: 'Sound Muted',
      wheel_winner_header: "🎉 Today's Best Pick:",
      wheel_why_worth_it: 'System Analysis: Why It is the Most Worth It?',
      wheel_worth_score_label: 'Worth-It Score:',
      wheel_action_route: '🗺️ Open Route on Map',
      wheel_action_wa: '💬 Contact Manager (WhatsApp)',
      wheel_action_spin_again: '🔄 Spin Again / Change Candidates',
      wheel_reason_price_best: '💰 Most affordable price (from {min} vs avg {avg})',
      wheel_reason_rating_best: '⭐ Highest rating & reviews: {rating} from {reviews}+ visitors',
      wheel_reason_facilities_best: '⚡ Most complete facilities ({fac})',
      wheel_reason_distance_best: '📍 Closest location ({dist} km from Town Square)',
      wheel_reason_open_now: '🕒 Open now ({hours})',
      toast_candidate_added: 'Added to hangout showdown ({count}/4)',
      toast_candidate_removed: 'Removed from hangout showdown',
      toast_candidate_cleared: 'Hangout showdown list cleared.'
    }
  },

  init() {
    const saved = localStorage.getItem(this.STORAGE_KEY);
    if (saved && (saved === 'id' || saved === 'en')) {
      this.currentLang = saved;
    } else {
      this.currentLang = 'id';
    }
    this.applyDOMTranslations();
  },

  getLanguage() {
    return this.currentLang;
  },

  setLanguage(lang) {
    if (lang !== 'id' && lang !== 'en') return;
    this.currentLang = lang;
    localStorage.setItem(this.STORAGE_KEY, lang);
    document.documentElement.lang = lang;
    this.applyDOMTranslations();
    this.notifyListeners(lang);
  },

  onLanguageChange(fn) {
    if (typeof fn === 'function') {
      this.listeners.push(fn);
    }
  },

  notifyListeners(lang) {
    this.listeners.forEach(fn => {
      try {
        fn(lang);
      } catch (e) {
        console.error('Error in i18n listener:', e);
      }
    });
  },

  t(key, fallback = '', params = {}) {
    const dict = this.translations[this.currentLang] || this.translations.id;
    let text = dict[key] !== undefined ? dict[key] : (fallback || key);
    if (params && typeof params === 'object') {
      Object.keys(params).forEach(k => {
        text = text.replace(new RegExp(`\\{${k}\\}`, 'g'), params[k]);
      });
    }
    return text;
  },

  translateCategory(cat) {
    if (!cat) return '';
    const c = cat.toLowerCase().trim();
    if (c.includes('cafe') || c.includes('kafe')) return this.t('cat_cafe_label');
    if (c.includes('warkop') || c.includes('kedai')) return this.t('cat_warkop_label');
    if (c.includes('resto')) return this.t('cat_resto_label');
    return cat;
  },

  translateFacility(fac) {
    if (!fac) return '';
    const f = fac.toLowerCase().trim();
    if (f.includes('wifi')) return this.t('fac_wifi');
    if (f.includes('colokan') || f.includes('stopkontak') || f.includes('power')) return this.t('fac_power');
    if (f.includes('ac')) return this.t('fac_ac');
    if (f.includes('outdoor')) return this.t('fac_outdoor');
    if (f.includes('parkir') || f.includes('parking')) return this.t('fac_parking');
    if (f.includes('musholla') || f.includes('prayer')) return this.t('fac_prayer');
    if (f.includes('music') || f.includes('akustik')) return this.t('fac_livemusic');
    if (f.includes('merokok') || f.includes('smoking')) return this.t('fac_smoking');
    if (f.includes('indoor')) return this.t('fac_indoor');
    return fac;
  },

  translateRegion(region) {
    if (!region) return '';
    const r = region.toLowerCase().trim();
    if (r.includes('semua') && r.includes('banyumas')) return this.t('region_banyumas_all');
    if (r.includes('semua')) return this.t('region_all');
    if (r.includes('kota')) return this.t('region_pwt_kota');
    if (r.includes('baturraden')) return this.t('region_baturraden');
    if (r.includes('utara') || r.includes('unsoed')) return this.t('region_pwt_utara');
    if (r.includes('sokaraja')) return this.t('region_sokaraja');
    if (r.includes('timur')) return this.t('region_pwt_timur');
    if (r.includes('barat')) return this.t('region_pwt_barat');
    return region;
  },

  applyDOMTranslations() {
    document.documentElement.lang = this.currentLang;

    // 1. Text elements
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      if (key) {
        el.textContent = this.t(key, el.textContent);
      }
    });

    // 2. HTML elements
    document.querySelectorAll('[data-i18n-html]').forEach(el => {
      const key = el.getAttribute('data-i18n-html');
      if (key) {
        el.innerHTML = this.t(key, el.innerHTML);
      }
    });

    // 3. Placeholders
    document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
      const key = el.getAttribute('data-i18n-placeholder');
      if (key) {
        el.setAttribute('placeholder', this.t(key, el.getAttribute('placeholder')));
      }
    });

    // 4. Title attributes
    document.querySelectorAll('[data-i18n-title]').forEach(el => {
      const key = el.getAttribute('data-i18n-title');
      if (key) {
        el.setAttribute('title', this.t(key, el.getAttribute('title')));
      }
    });

    // 5. Select dropdowns
    const langSelect = document.getElementById('global-lang-select');
    if (langSelect) {
      langSelect.value = this.currentLang;
    }

    const regSelect = document.getElementById('global-region-select');
    if (regSelect) {
      Array.from(regSelect.options).forEach(opt => {
        opt.textContent = this.translateRegion(opt.value);
      });
    }

    const onbRegSelect = document.getElementById('onboarding-region-select');
    if (onbRegSelect) {
      Array.from(onbRegSelect.options).forEach(opt => {
        opt.textContent = this.translateRegion(opt.value);
      });
    }

    // 6. Map center button
    const mapCenterBtn = document.querySelector('.btn-map-control');
    if (mapCenterBtn) {
      mapCenterBtn.textContent = this.t('map_btn_center');
    }
  }
};

// Global shorthand helper
window.t = function(key, fallback = '', params = {}) {
  return I18nService.t(key, fallback, params);
};

window.I18nService = I18nService;

// Auto init on script load
I18nService.init();
