/**
 * MAMPIR Web - Storage Service (LocalStorage)
 * Mengelola penyimpanan lokal preferensi pengguna, bookmark favorit,
 * riwayat pencarian, dan sesi autentikasi.
 */
const StorageService = {
  KEYS: {
    FIRST_LAUNCH: 'mampir_first_launch',
    BUDGET: 'user_budget',
    IS_BUDGET_ACTIVE: 'mampir_budget_active',
    REGION: 'selected_region',
    PREFERENCES: 'user_preferences',
    SEARCH_HISTORY: 'search_history',
    FAVORITES: 'favorite_places',
    IS_LOGGED_IN: 'is_logged_in',
    IS_GUEST: 'is_guest_mode',
    USER_NAME: 'user_name',
    USER_EMAIL: 'user_email',
    AUTH_TOKEN: 'mampir_auth_token',
    USER_ROLE: 'user_role', // 'user', 'partner', 'admin'
    PARTNER_CAFE_ID: 'partner_cafe_id',
    THEME: 'setting_theme',
    NOTIFICATION: 'setting_notification_enabled',
    NOTIFICATIONS: 'mampir_notifications',
    EVENT_REMINDERS: 'mampir_event_reminders',
    ACTIVITY_HISTORY: 'mampir_activity_history',
    CAFE_OVERRIDES: 'mampir_cafe_overrides',
    CAFE_EVENTS: 'mampir_cafe_events',
    PLACE_REVIEWS: 'mampir_place_reviews'
  },

  isFirstLaunch() {
    const val = localStorage.getItem(this.KEYS.FIRST_LAUNCH);
    return val === null; // true jika pertama kali buka
  },

  setFirstLaunchComplete() {
    localStorage.setItem(this.KEYS.FIRST_LAUNCH, 'false');
  },

  getBudget() {
    const val = localStorage.getItem(this.KEYS.BUDGET);
    return val ? parseInt(val, 10) : 25000;
  },

  setBudget(budget) {
    localStorage.setItem(this.KEYS.BUDGET, budget.toString());
  },

  isBudgetFilterActive() {
    return localStorage.getItem(this.KEYS.IS_BUDGET_ACTIVE) === 'true';
  },

  setBudgetFilterActive(active) {
    localStorage.setItem(this.KEYS.IS_BUDGET_ACTIVE, active ? 'true' : 'false');
  },

  getSelectedRegion() {
    return localStorage.getItem(this.KEYS.REGION) || 'Purwokerto Kota';
  },

  setSelectedRegion(region) {
    localStorage.setItem(this.KEYS.REGION, region);
  },

  getUserPreferences() {
    try {
      const val = localStorage.getItem(this.KEYS.PREFERENCES);
      return val ? JSON.parse(val) : ['WiFi', 'Colokan'];
    } catch {
      return ['WiFi', 'Colokan'];
    }
  },

  setUserPreferences(prefs) {
    localStorage.setItem(this.KEYS.PREFERENCES, JSON.stringify(prefs));
  },

  getFavorites() {
    try {
      const val = localStorage.getItem(this.KEYS.FAVORITES);
      return val ? JSON.parse(val) : [];
    } catch {
      return [];
    }
  },

  isFavorite(id) {
    return this.getFavorites().includes(id);
  },

  toggleFavorite(id) {
    let favs = this.getFavorites();
    if (favs.includes(id)) {
      favs = favs.filter(favId => favId !== id);
    } else {
      favs.push(id);
    }
    localStorage.setItem(this.KEYS.FAVORITES, JSON.stringify(favs));
    return favs.includes(id);
  },

  getSearchHistory() {
    try {
      const val = localStorage.getItem(this.KEYS.SEARCH_HISTORY);
      return val ? JSON.parse(val) : [];
    } catch {
      return [];
    }
  },

  addSearchHistory(query) {
    const clean = query.trim();
    if (!clean) return;
    let list = this.getSearchHistory().filter(q => q.toLowerCase() !== clean.toLowerCase());
    list.unshift(clean);
    if (list.length > 10) list = list.slice(0, 10);
    localStorage.setItem(this.KEYS.SEARCH_HISTORY, JSON.stringify(list));
  },

  removeSearchHistory(query) {
    let list = this.getSearchHistory().filter(q => q.toLowerCase() !== query.toLowerCase());
    localStorage.setItem(this.KEYS.SEARCH_HISTORY, JSON.stringify(list));
  },

  clearSearchHistory() {
    localStorage.removeItem(this.KEYS.SEARCH_HISTORY);
  },

  getUserSession() {
    const isLoggedIn = localStorage.getItem(this.KEYS.IS_LOGGED_IN) === 'true';
    const isGuest = localStorage.getItem(this.KEYS.IS_GUEST) === 'true';
    return {
      isLoggedIn,
      isGuest,
      name: localStorage.getItem(this.KEYS.USER_NAME) || (isGuest ? 'Tamu Purwokerto' : 'Pengguna MAMPIR'),
      email: localStorage.getItem(this.KEYS.USER_EMAIL) || ''
    };
  },

  setUserSession({ name, email, isGuest = false }) {
    localStorage.setItem(this.KEYS.IS_LOGGED_IN, isGuest ? 'false' : 'true');
    localStorage.setItem(this.KEYS.IS_GUEST, isGuest ? 'true' : 'false');
    localStorage.setItem(this.KEYS.USER_NAME, name);
    localStorage.setItem(this.KEYS.USER_EMAIL, email || '');
  },

  clearUserSession() {
    localStorage.removeItem(this.KEYS.IS_LOGGED_IN);
    localStorage.removeItem(this.KEYS.IS_GUEST);
    localStorage.removeItem(this.KEYS.USER_NAME);
    localStorage.removeItem(this.KEYS.USER_EMAIL);
    localStorage.removeItem(this.KEYS.AUTH_TOKEN);
    localStorage.removeItem(this.KEYS.USER_ROLE);
  },

  getAuthToken() {
    return localStorage.getItem(this.KEYS.AUTH_TOKEN) || '';
  },

  setAuthToken(token) {
    if (token) {
      localStorage.setItem(this.KEYS.AUTH_TOKEN, token);
    } else {
      localStorage.removeItem(this.KEYS.AUTH_TOKEN);
    }
  },

  getTheme() {
    return localStorage.getItem(this.KEYS.THEME) || 'Gelap';
  },

  setTheme(theme) {
    localStorage.setItem(this.KEYS.THEME, theme);
  },

  // ==================== ROLE-BASED ACCESS CONTROL (RBAC) ====================
  getUserRole() {
    return 'user';
  },

  isAdmin() {
    return false;
  },

  isPartnerOrAdmin() {
    return false;
  },

  getPartnerCafeId() {
    return localStorage.getItem(this.KEYS.PARTNER_CAFE_ID) || 'pwt-1';
  },

  setUserRole(role, cafeId = null) {
    localStorage.setItem(this.KEYS.USER_ROLE, role);
    if (cafeId) {
      localStorage.setItem(this.KEYS.PARTNER_CAFE_ID, cafeId);
    }
  },

  // ==================== USER ACTIVITY TRACKING ====================
  recordPlaceActivity(place) {
    if (!place) return;
    try {
      const history = this.getActivityHistory();
      const placeId = place.id;
      const category = place.category || 'Cafe';
      const city = place.city || 'Purwokerto Kota';

      history.viewedPlaceIds = history.viewedPlaceIds || [];
      if (!history.viewedPlaceIds.includes(placeId)) {
        history.viewedPlaceIds.unshift(placeId);
        if (history.viewedPlaceIds.length > 20) history.viewedPlaceIds.pop();
      }

      history.categoryCounts = history.categoryCounts || {};
      history.categoryCounts[category] = (history.categoryCounts[category] || 0) + 1;

      history.regionCounts = history.regionCounts || {};
      history.regionCounts[city] = (history.regionCounts[city] || 0) + 1;

      history.lastVisited = {
        placeId,
        category,
        city,
        name: place.name,
        timestamp: Date.now()
      };

      localStorage.setItem(this.KEYS.ACTIVITY_HISTORY, JSON.stringify(history));
    } catch (e) {
      console.warn('Gagal mencatat histori aktivitas:', e);
    }
  },

  getActivityHistory() {
    try {
      const val = localStorage.getItem(this.KEYS.ACTIVITY_HISTORY);
      return val ? JSON.parse(val) : { viewedPlaceIds: [], categoryCounts: {}, regionCounts: {}, lastVisited: null };
    } catch {
      return { viewedPlaceIds: [], categoryCounts: {}, regionCounts: {}, lastVisited: null };
    }
  },

  // ==================== CAFE MITRA PROFILE CRUD & WHATSAPP ====================
  getAllCafeOverrides() {
    try {
      const val = localStorage.getItem(this.KEYS.CAFE_OVERRIDES);
      return val ? JSON.parse(val) : {};
    } catch {
      return {};
    }
  },

  getCafeOverrides(placeId) {
    const all = this.getAllCafeOverrides();
    return all[placeId] || null;
  },

  saveCafeOverrides(placeId, data) {
    const all = this.getAllCafeOverrides();
    all[placeId] = {
      ...(all[placeId] || {}),
      ...data,
      updated_at: new Date().toISOString()
    };
    localStorage.setItem(this.KEYS.CAFE_OVERRIDES, JSON.stringify(all));
    return all[placeId];
  },

  // ==================== CAFE EVENTS & ANNOUNCEMENTS ====================
  getCafeEvents(placeId = null) {
    try {
      const val = localStorage.getItem(this.KEYS.CAFE_EVENTS);
      let list = val ? JSON.parse(val) : [];
      if (!Array.isArray(list) || list.length === 0) {
        list = this.getDefaultEvents();
        localStorage.setItem(this.KEYS.CAFE_EVENTS, JSON.stringify(list));
      } else {
        // Pastikan default events selalu tersedia
        const defaults = this.getDefaultEvents();
        defaults.forEach(def => {
          if (!list.some(e => e.id === def.id)) {
            list.push(def);
          }
        });
      }
      if (placeId) {
        const filtered = list.filter(e => e.placeId === placeId);
        if (filtered.length > 0) return filtered;

        // Fallback agenda mingguan reguler kafe agar setiap kafe selalu memiliki agenda & pengingat
        return [{
          id: `event-reg-${placeId}`,
          placeId: placeId,
          placeName: 'Kafe Purwokerto',
          title: 'Live Acoustic Weekend & Diskon Mahasiswa',
          category: 'Live Music',
          date: 'Setiap Sabtu & Minggu, 19.30 - 22.00 WIB',
          description: 'Nikmati suasana santai dengan iringan musik akustik santai dan promo spesial mahasiswa diskon 15% untuk semua menu kopi & camilan!',
          badge: 'Agenda Mingguan',
          created_at: new Date().toISOString()
        }];
      }
      return list;
    } catch {
      return this.getDefaultEvents();
    }
  },

  getDefaultEvents() {
    return [
      {
        id: 'event-1',
        placeId: 'pwt-1',
        placeName: 'Kopi Kenangan Sudirman',
        title: 'Akustik Santai Malam Minggu & Promo 20%',
        category: 'Live Music',
        date: 'Setiap Sabtu Malam, 19.30 - 22.00 WIB',
        description: 'Nikmati suasana santai dengan penampilan live acoustic musisi lokal Purwokerto plus diskon khusus 20% untuk semua menu kopi susu!',
        badge: 'Promo Spesial',
        created_at: new Date().toISOString()
      },
      {
        id: 'event-2',
        placeId: 'pwt-2',
        placeName: 'The Local Space',
        title: 'Workshop Manual Brew & Coffee Cupping',
        category: 'Workshop',
        date: 'Minggu, 15.00 - 17.00 WIB',
        description: 'Belajar teknik V60 dan Aeropress langsung dari barista bersertifikat. Gratis tester 3 varietas biji kopi Jawa & Sumatra.',
        badge: 'Edukasi Kopi',
        created_at: new Date().toISOString()
      },
      {
        id: 'event-3',
        placeId: 'pwt-3',
        placeName: 'Choco Klik Cafe & Resto',
        title: 'Choco Lava Weekend & Diskon Mahasiswa 25%',
        category: 'Promo Spesial',
        date: 'Jumat - Minggu, 16.00 - 21.00 WIB',
        description: 'Diskon khusus 25% bagi pelajar dan mahasiswa (cukup tunjukkan KTM) untuk menu signature Hot Choco Lava Cake.',
        badge: 'Diskon Mahasiswa',
        created_at: new Date().toISOString()
      },
      {
        id: 'event-4',
        placeId: 'pwt-7',
        placeName: 'Oemah Daun Cafe & Resto',
        title: 'Nonton Bareng Big Match & Live Jamming',
        category: 'Nonton Bareng',
        date: 'Sabtu Malam, Mulai 20.00 WIB',
        description: 'Nobar seru di layar proyektor outdoor Oemah Daun ditemani camilan khas Banyumas mendoan hangat dan kopi tubruk.',
        badge: 'Nobar Akbar',
        created_at: new Date().toISOString()
      }
    ];
  },

  addCafeEvent(event) {
    const list = this.getCafeEvents();
    const newEvent = {
      id: 'event-' + Date.now(),
      created_at: new Date().toISOString(),
      ...event
    };
    list.unshift(newEvent);
    localStorage.setItem(this.KEYS.CAFE_EVENTS, JSON.stringify(list));
    return newEvent;
  },

  deleteCafeEvent(eventId) {
    let list = this.getCafeEvents();
    list = list.filter(e => e.id !== eventId);
    localStorage.setItem(this.KEYS.CAFE_EVENTS, JSON.stringify(list));
  },

  // ==================== NOTIFICATIONS & REAL-TIME EVENT REMINDERS (Req 7) ====================
  getNotifications() {
    try {
      const val = localStorage.getItem(this.KEYS.NOTIFICATIONS);
      if (!val) {
        const defaults = this.getDefaultNotifications();
        localStorage.setItem(this.KEYS.NOTIFICATIONS, JSON.stringify(defaults));
        return defaults;
      }
      const parsed = JSON.parse(val);
      if (!Array.isArray(parsed) || parsed.length === 0) {
        const defaults = this.getDefaultNotifications();
        localStorage.setItem(this.KEYS.NOTIFICATIONS, JSON.stringify(defaults));
        return defaults;
      }
      return parsed;
    } catch {
      return this.getDefaultNotifications();
    }
  },

  getDefaultNotifications() {
    return [
      {
        id: 'notif-1',
        placeId: 'pwt-1',
        placeName: 'Kopi Kenangan Sudirman',
        title: 'Akustik Santai Malam Minggu & Promo 20%',
        category: 'Live Music',
        type: 'event',
        message: 'Kopi Kenangan Sudirman merilis agenda baru: Akustik Santai Malam Minggu dan diskon 20%!',
        date: '10 menit yang lalu',
        read: false,
        timestamp: Date.now() - 600000
      },
      {
        id: 'notif-2',
        placeId: 'pwt-2',
        placeName: 'The Local Space',
        title: 'Workshop Manual Brew & Coffee Cupping',
        category: 'Workshop',
        type: 'event',
        message: 'The Local Space mengundang Anda belajar teknik seduh V60 & Aeropress gratis tester 3 kopi pilihan.',
        date: '2 jam yang lalu',
        read: false,
        timestamp: Date.now() - 7200000
      },
      {
        id: 'notif-3',
        placeId: 'pwt-3',
        placeName: 'Choco Klik Cafe & Resto',
        title: 'Choco Lava Weekend & Diskon Mahasiswa 25%',
        category: 'Promo Spesial',
        type: 'promo',
        message: 'Promo akhir pekan di Choco Klik: Tunjukkan KTM mahasiswa dan dapatkan diskon 25%!',
        date: '1 hari yang lalu',
        read: true,
        timestamp: Date.now() - 86400000
      }
    ];
  },

  getUnreadNotificationCount() {
    const list = this.getNotifications();
    return list.filter(n => !n.read).length;
  },

  addNotification(notif) {
    try {
      const list = this.getNotifications();
      const newNotif = {
        id: 'notif-' + Date.now(),
        date: 'Baru saja',
        read: false,
        timestamp: Date.now(),
        ...notif
      };
      list.unshift(newNotif);
      if (list.length > 30) list.pop();
      localStorage.setItem(this.KEYS.NOTIFICATIONS, JSON.stringify(list));
      return newNotif;
    } catch (e) {
      console.warn('Gagal menambah notifikasi:', e);
      return null;
    }
  },

  markNotificationRead(notifId) {
    try {
      const list = this.getNotifications();
      const item = list.find(n => n.id === notifId);
      if (item) {
        item.read = true;
        localStorage.setItem(this.KEYS.NOTIFICATIONS, JSON.stringify(list));
      }
    } catch (e) {
      console.warn(e);
    }
  },

  markAllNotificationsRead() {
    try {
      const list = this.getNotifications();
      list.forEach(n => n.read = true);
      localStorage.setItem(this.KEYS.NOTIFICATIONS, JSON.stringify(list));
    } catch (e) {
      console.warn(e);
    }
  },

  getEventReminders() {
    try {
      const val = localStorage.getItem(this.KEYS.EVENT_REMINDERS);
      return val ? JSON.parse(val) : [];
    } catch {
      return [];
    }
  },

  isEventReminderSet(eventId) {
    const list = this.getEventReminders();
    return list.some(r => (typeof r === 'string' ? r === eventId : r.id === eventId));
  },

  toggleEventReminder(event) {
    let list = this.getEventReminders();
    const eventId = typeof event === 'string' ? event : event.id;
    const existingIdx = list.findIndex(r => (typeof r === 'string' ? r === eventId : r.id === eventId));
    let isSet = false;

    if (existingIdx >= 0) {
      list.splice(existingIdx, 1);
      isSet = false;
    } else {
      const remObj = typeof event === 'object' ? event : { id: eventId, setAt: Date.now() };
      list.push(remObj);
      isSet = true;

      // Buat notifikasi instan untuk pengingat ini
      this.addNotification({
        placeId: remObj.placeId,
        placeName: remObj.placeName || 'Kafe Purwokerto',
        title: `⏰ Pengingat: ${remObj.title || 'Agenda Kafe'}`,
        category: 'Pengingat',
        type: 'reminder',
        message: `Pengingat berhasil dipasang untuk agenda "${remObj.title || 'Agenda'}" di ${remObj.placeName || 'kafe'}. Jadwal: ${remObj.date || 'Sesuai agenda'}.`,
        date: 'Baru saja',
        read: false
      });
    }

    localStorage.setItem(this.KEYS.EVENT_REMINDERS, JSON.stringify(list));
    return isSet;
  },

  // ==================== PLACE REVIEWS & RATINGS ====================
  getPlaceReviews(placeId) {
    try {
      const val = localStorage.getItem(this.KEYS.PLACE_REVIEWS);
      const all = val ? JSON.parse(val) : {};
      return all[placeId] || this.getDefaultReviews(placeId);
    } catch {
      return this.getDefaultReviews(placeId);
    }
  },

  getDefaultReviews(placeId) {
    return [
      {
        id: 'rev-1',
        author: 'Rian Prasetyo',
        rating: 5,
        date: '2 hari yang lalu',
        comment: 'Tempatnya cozy banget buat nugas, wifi kenceng dan colokan banyak. Kopinya mantap!'
      },
      {
        id: 'rev-2',
        author: 'Dinda Lestari',
        rating: 5,
        date: '1 minggu yang lalu',
        comment: 'Pelayanan ramah, suasana sejuk dan playlist lagunya pas di telinga. Recommended!'
      }
    ];
  },

  addPlaceReview(placeId, review) {
    try {
      const val = localStorage.getItem(this.KEYS.PLACE_REVIEWS);
      const all = val ? JSON.parse(val) : {};
      all[placeId] = all[placeId] || this.getDefaultReviews(placeId);
      const newReview = {
        id: 'rev-' + Date.now(),
        date: 'Baru saja',
        ...review
      };
      all[placeId].unshift(newReview);
      localStorage.setItem(this.KEYS.PLACE_REVIEWS, JSON.stringify(all));
      return newReview;
    } catch (e) {
      console.warn('Gagal menyimpan ulasan:', e);
      return null;
    }
  }
};

