/**
 * MAMPIR Web - Main Application Controller
 * Mengintegrasikan State Katalog, Supabase REST API, Algoritma Rekomendasi,
 * Peta Interaktif Leaflet, Modal Dialog, dan Web Admin Dashboard.
 */

window.App = {
  // State Utama
  places: typeof FALLBACK_PLACES !== 'undefined' ? [...FALLBACK_PLACES] : [],
  filteredPlaces: [],
  currentView: 'beranda', // 'beranda', 'cari', 'favorit', 'pengaturan'
  selectedRegion: 'Purwokerto Kota',
  selectedCategory: 'Semua',
  userBudget: 25000,
  userPreferences: ['WiFi', 'Colokan'],
  searchQuery: '',
  sortBy: 'rekomendasi', // 'rekomendasi', 'rating', 'jarak', 'harga_murah'
  isApiOnline: false,
  isBudgetFilterActive: false,
  lastUpsell: null,
  isGpsActive: false,
  userGps: null,
  detectedGooglePlaces: [],
  nearMeDistanceFilter: 'all', // 'all', '0-1', '1-3', '3-5', '5-10', '10+'
  nearMeCategoryFilter: 'all', // 'all', 'Restoran', 'Warung Makan', 'Cafe', 'Coffee Shop', 'Tempat Nongkrong', 'Fast Food', 'Street Food'
  nearMeSortBy: 'jarak',       // 'jarak', 'rating', 'populer', 'harga_murah'
  isNearMeLoading: false,

  async init() {
    console.log('Inisialisasi MAMPIR Web...');

    // Load initial user preferences from LocalStorage
    this.selectedRegion = StorageService.getSelectedRegion();
    this.userBudget = StorageService.getBudget();
    this.userPreferences = StorageService.getUserPreferences();
    this.isBudgetFilterActive = StorageService.isBudgetFilterActive();

    // Setup Theme & Localization
    this.applyTheme(StorageService.getTheme());
    if (typeof I18nService !== 'undefined') {
      I18nService.init();
      I18nService.applyDOMTranslations();
      I18nService.onLanguageChange(() => {
        this.updateBudgetButtonUI();
        this.render();
      });
    }

    // Setup UI Controls & Listeners
    this.bindHeaderControls();
    this.bindSidebarNav();
    this.bindFilterModal();
    this.bindAuthModal();
    this.initNotificationCenter();
    this.updateBudgetButtonUI();

    // Inisialisasi Peta Leaflet (Google Maps Layers)
    MapController.init('live-map-container');

    // Fetch Master Data
    await this.fetchPlaces();

    // Deteksi GPS & Sinkronkan Tempat Makan via Google Places API (New)
    await this.triggerGpsDetection(false);

    // Check first launch for onboarding
    if (StorageService.isFirstLaunch()) {
      this.openOnboardingModal();
    }

    // Update User Profile button
    this.updateUserProfileUI();

    // Render current view
    this.render();

    // Cek Deep Link URL Parameter (?place=pwt-1)
    const urlParams = new URLSearchParams(window.location.search);
    const placeParam = urlParams.get('place');
    if (placeParam) {
      setTimeout(() => this.openPlaceDetail(placeParam), 500);
    }
  },

  getPlaceById(id) {
    const raw = this.places.find(p => p.id === id);
    if (!raw) return null;
    const overrides = StorageService.getCafeOverrides(id) || {};
    return { ...raw, ...overrides };
  },

  getMergedPlacesList() {
    const allOverrides = StorageService.getAllCafeOverrides();
    return this.places.map(p => {
      const o = allOverrides[p.id];
      return o ? { ...p, ...o } : p;
    });
  },

  /**
   * Mengambil data tempat kuliner dari Supabase REST API dengan offline fallback
   */
  async fetchPlaces() {
    const statusTextEl = document.getElementById('api-status-text');
    const statusDotEl = document.getElementById('api-status-dot');

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 2500);

      const response = await fetch(AppConfig.placesEndpoint, {
        headers: AppConfig.headers,
        cache: 'no-store',
        signal: controller.signal
      });
      clearTimeout(timeoutId);

      if (response.ok) {
        const data = await response.json();
        if (Array.isArray(data) && data.length > 0) {
          this.places = data;
          this.isApiOnline = true;
          if (statusTextEl) {
            statusTextEl.textContent = window.t('api_places_count', `Supabase REST API (${this.places.length} Tempat)`, { n: this.places.length });
          }
          if (statusDotEl) {
            statusDotEl.classList.remove('offline');
            statusDotEl.title = 'Koneksi Live ke Supabase aktif';
          }
          console.log(`Berhasil memuat ${this.places.length} tempat dari Supabase.`);
          return;
        }
      }
      throw new Error('Response non-ok atau data kosong');
    } catch (e) {
      console.warn('Gagal memanggil Supabase REST API, menggunakan data cadangan lokal.', e);
      this.places = typeof FALLBACK_PLACES !== 'undefined' ? FALLBACK_PLACES : [];
      this.isApiOnline = false;
      if (statusTextEl) {
        statusTextEl.textContent = `Offline (${this.places.length})`;
      }
      if (statusDotEl) {
        statusDotEl.classList.add('offline');
        statusDotEl.title = 'Menggunakan data cadangan lokal';
      }
    }
  },

  /**
   * Menjalankan deteksi lokasi GPS & menarik tempat makan nyata via Google Places API (New)
   * @param {boolean} isManual - apakah dipicu oleh interaksi klik tombol pengguna
   */
  async triggerGpsDetection(isManual = false) {
    const btn = document.getElementById('btn-gps-detect');
    const label = document.getElementById('gps-status-label');

    if (btn) btn.classList.add('detecting');
    if (label) label.textContent = typeof window.t === 'function' ? window.t('gps_detecting', 'Mendeteksi GPS...') : 'Mendeteksi GPS...';

    try {
      const gps = await GooglePlacesService.detectGpsLocation();
      this.userGps = gps;
      this.isGpsActive = true;

      // Sinkronkan titik acuan jarak di RecommendationService
      if (typeof RecommendationService !== 'undefined') {
        RecommendationService.setCenterCoordinates(gps.lat, gps.lng);
      }

      // 1. Tampilkan marker GPS dan radar radius di Google Maps
      if (typeof MapController !== 'undefined') {
        MapController.renderUserLocation(
          gps.lat,
          gps.lng,
          gps.label,
          gps.isWithinPurwokerto ? 3500 : 5000
        );

        if (isManual) {
          MapController.panTo(gps.lat, gps.lng, 15);
        }
      }

      // 2. Ambil warung makan, cafe, resto nyata dari Google Places API (New)
      const nearbyGoogle = await GooglePlacesService.fetchPlacesNearLocation(gps.lat, gps.lng, 3000, this.nearMeCategoryFilter || 'all');

      if (nearbyGoogle && nearbyGoogle.length > 0) {
        this.detectedGooglePlaces = nearbyGoogle;
        this.mergeGooglePlaces(nearbyGoogle, gps);
      }

      // 3. Hitung ulang jarak semua tempat dari GPS pengguna
      this.recalculateAllDistances(gps.lat, gps.lng);

      // 4. Perbarui status tombol GPS di Header
      if (btn) {
        btn.classList.remove('detecting');
        btn.classList.add('active');
        if (!gps.isWithinPurwokerto) btn.classList.add('outside');
        else btn.classList.remove('outside');
      }
      if (label) {
        if (gps.isWithinPurwokerto && !gps.isSimulated) {
          label.textContent = `GPS: Purwokerto (${nearbyGoogle.length} terdeteksi)`;
        } else if (!gps.isWithinPurwokerto) {
          label.textContent = 'GPS: Simulasi Alun-Alun';
        } else {
          label.textContent = `GPS: Alun-Alun (${nearbyGoogle.length} terdeteksi)`;
        }
      }

      // 5. Berikan feedback Toast ke pengguna
      if (isManual) {
        if (gps.isWithinPurwokerto && !gps.isSimulated) {
          this.showToast(`📍 GPS Terdeteksi! Menemukan ${nearbyGoogle.length} warung & tempat makan via Google Maps.`);
        } else if (!gps.isWithinPurwokerto) {
          this.showToast(`ℹ️ GPS di luar Purwokerto. Menampilkan titik pusat Alun-Alun agar rekomendasi tetap akurat.`);
        } else {
          this.showToast(`📍 Titik GPS Purwokerto aktif (${nearbyGoogle.length} tempat makan dari Google Maps).`);
        }
      }

      this.render();
    } catch (e) {
      console.warn('Gagal mendeteksi GPS atau Google Places:', e);
      if (btn) btn.classList.remove('detecting');
      if (label) label.textContent = 'GPS Purwokerto';
    }
  },

  mergeGooglePlaces(googlePlaces, userGps) {
    if (!googlePlaces || googlePlaces.length === 0) return;

    const existingCoords = new Set(
      this.places.map(p => `${(p.latitude || 0).toFixed(3)}_${(p.longitude || 0).toFixed(3)}`)
    );
    const existingNames = new Set(
      this.places.map(p => (p.name || '').toLowerCase().trim())
    );

    const newPlaces = [];
    for (const gp of googlePlaces) {
      const coordKey = `${(gp.latitude || 0).toFixed(3)}_${(gp.longitude || 0).toFixed(3)}`;
      const nameKey = (gp.name || '').toLowerCase().trim();

      if (!existingCoords.has(coordKey) && !existingNames.has(nameKey)) {
        newPlaces.push(gp);
        existingCoords.add(coordKey);
        existingNames.add(nameKey);
      }
    }

    if (newPlaces.length > 0) {
      this.places = [...newPlaces, ...this.places];
      console.log(`Berhasil menambahkan ${newPlaces.length} tempat makan baru dari Google Maps ke direktori MAMPIR!`);
    }
  },

  recalculateAllDistances(userLat, userLng) {
    if (!userLat || !userLng) return;
    this.places.forEach(p => {
      if (p.latitude && p.longitude) {
        const d = GooglePlacesService.calculateDistanceKm(userLat, userLng, p.latitude, p.longitude);
        p.distance = d;
        p.distanceFromGps = d;
      }
    });
  },

  /**
   * Menghitung & menyaring data tempat kuliner untuk ditampilkan
   */
  getProcessedPlaces() {
    let list = this.getMergedPlacesList();

    // Jika di tab favorit, ambil hanya tempat yang di-bookmark
    if (this.currentView === 'favorit') {
      const favIds = StorageService.getFavorites();
      list = list.filter(p => favIds.includes(p.id));
    }

    // Rekomendasi scoring
    const recommendations = RecommendationService.getRecommendations({
      allPlaces: list,
      userBudget: this.userBudget,
      isBudgetActive: this.isBudgetFilterActive,
      selectedRegion: this.selectedRegion,
      selectedCategory: this.selectedCategory,
      userPreferences: this.userPreferences,
      searchQuery: this.searchQuery
    });

    this.lastUpsell = this.isBudgetFilterActive ? recommendations.upsell : null;

    let result = recommendations.map(r => ({
      ...r.place,
      recommendationScore: r.totalScore,
      reasonBadge: r.reasonBadge,
      affordableCombo: r.affordableCombo,
      isBestBudgetMatch: r.place.isBestBudgetMatch
    }));

    // Sorting
    if (this.sortBy === 'rating') {
      result.sort((a, b) => (b.rating || 0) - (a.rating || 0));
    } else if (this.sortBy === 'jarak') {
      result.sort((a, b) => (a.distance || 0) - (b.distance || 0));
    } else if (this.sortBy === 'harga_murah') {
      result.sort((a, b) => (a.avg_price || a.min_price) - (b.avg_price || b.min_price));
    }

    return result;
  },

  /**
   * Render utama tampilan berdasarkan currentView
   */
  render() {
    const catalogCol = document.getElementById('catalog-content-area');
    if (!catalogCol) return;

    if (this.currentView === 'pengaturan') {
      this.renderSettingsView(catalogCol);
      return;
    }

    if (this.currentView === 'bantuan') {
      this.renderHelpCenterView(catalogCol);
      return;
    }

    if (this.currentView === 'terdekat') {
      this.renderNearMeView(catalogCol);
      return;
    }

    const processed = this.getProcessedPlaces();

    // Render Markers on Map dengan highlight budget & translusensi
    MapController.renderMarkers(processed, (place) => {
      this.openPlaceDetail(place.id);
    }, {
      isBudgetActive: this.isBudgetFilterActive,
      userBudget: this.userBudget
    });

    // Render HTML Catalog
    let html = '';

    const hasSearch = (this.searchQuery || '').trim().length > 0;

    if (this.currentView === 'cari') {
      html += this.renderSearchTabHeader();
    } else if (this.currentView === 'favorit') {
      html += this.renderFavoritesHeader(processed.length);
    } else {
      // Default: Beranda view
      if (processed.length > 0 && !hasSearch) {
        html += this.renderFeaturedCard(processed[0]);
      }

      // Rekomendasi Berbasis Aktivitas Pengguna (Req 4)
      if (!hasSearch) {
        const activityRecs = RecommendationService.getActivityBasedRecommendations({
          allPlaces: this.getMergedPlacesList(),
          maxItems: 6
        });
        html += this.renderActivityRecommendationCarousel(activityRecs);
      }

      html += this.renderCategoryFilterBar();
    }

    // Grid of cards
    if (processed.length === 0) {
      html += `
        <div class="empty-state">
          <div class="empty-state-icon">🍽️</div>
          <h3>${window.t('no_places_title', 'Tidak ada tempat yang cocok')}</h3>
          <p>${window.t('no_places_desc', 'Coba sesuaikan filter wilayah, kategori, atau naikkan batas anggaran Anda.')}</p>
          <button class="btn-primary" onclick="window.App.resetFilters()">${window.t('btn_reset_filters', 'Reset Filter')}</button>
        </div>
      `;
    } else {
      // Smart Fallback / Dynamic Upsell Banner jika opsi mepet / sedikit (Req 3)
      if (this.isBudgetFilterActive && this.lastUpsell) {
        const extraFormatted = RecommendationService.formatRupiah(this.lastUpsell.neededExtra);
        html += `
          <div class="budget-upsell-banner">
            <div class="upsell-left">
              <div class="upsell-icon">💡</div>
              <div>
                <div class="upsell-title">${window.t('budget_upsell_banner_title', 'Rekomendasi Cerdas Budget')}</div>
                <div class="upsell-desc">
                  ${window.t('budget_upsell_banner_desc', `Hanya butuh tambah sedikit lagi (+ ${extraFormatted}) untuk membuka ${this.lastUpsell.unlockedCount} kafe populer lainnya di sekitar sini!`, { amount: extraFormatted, count: this.lastUpsell.unlockedCount })}
                </div>
              </div>
            </div>
            <button class="btn-upsell-action" onclick="window.App.applyUpsellBudget(${this.lastUpsell.newBudget})">
              ${window.t('budget_upsell_btn', `+ Tambah ${extraFormatted} Sekarang`, { amount: extraFormatted })}
            </button>
          </div>
        `;
      }

      html += `<div class="section-header">
        <h3 class="section-title">
          <span>${this.getSectionTitle()}</span>
          <small style="font-size: 13px; color: var(--text-secondary); font-weight: normal;">(${processed.length} ${window.t('places_found', 'tempat ditemukan')})</small>
        </h3>
      </div>`;

      html += `<div class="places-grid">`;
      // Jika di beranda dan ada featured, skip index 0
      const itemsToRender = (this.currentView === 'beranda' && !hasSearch && processed.length > 1)
        ? processed.slice(1)
        : processed;

      itemsToRender.forEach(p => {
        html += this.renderPlaceCard(p);
      });
      html += `</div>`;
    }

    catalogCol.innerHTML = html;

    // Sinkronisasi status tombol adu tongkrongan dan floating drawer
    if (window.Roulette) {
      window.Roulette.updateCardButtons();
      window.Roulette.updateFloatingDrawer();
    }
  },

  getSectionTitle() {
    if (this.currentView === 'cari') {
      return window.t('nav_search', 'Hasil Pencarian');
    }
    if (this.currentView === 'favorit') {
      return window.t('nav_favorites', 'Daftar Tempat Favorit Anda');
    }
    return window.t('all_recommendations_title', 'Rekomendasi Tempat Kuliner & Nongkrong');
  },

  renderFeaturedCard(place) {
    if (!place) return '';
    const isFav = StorageService.isFavorite(place.id);
    const catLabel = typeof I18nService !== 'undefined' ? I18nService.translateCategory(place.category) : place.category;
    const kmText = (this.isGpsActive && this.userGps)
      ? window.t('distance_from_gps', 'km dari lokasi GPS Anda')
      : window.t('km_from_center', 'km dari Alun-Alun');
    return `
      <div class="featured-card" onclick="window.App.openPlaceDetail('${place.id}')">
        <div class="featured-image-container">
          <img src="${place.image_url || 'assets/images/beranda_mockup.jpeg'}" alt="${place.name}" class="featured-image" />
          <div class="featured-overlay"></div>
          <div class="featured-badges">
            <span class="badge-featured">${window.t('top_recommendation', 'Rekomendasi Utama')}</span>
            ${place.isGoogleLive ? `<span class="badge-google-live">🗺️ Google Maps Live</span>` : ''}
            ${(this.isBudgetFilterActive && place.isBestBudgetMatch) ? `<span class="badge-featured" style="background: linear-gradient(135deg, #FFB74D, #F57C00);">✨ ${window.t('budget_badge_best_match', 'Pas di Budget')}</span>` : ''}
            <span class="badge-score">⭐ ${place.rating || 4.8}</span>
          </div>
          <button class="featured-bookmark-btn ${isFav ? 'active' : ''}" 
                  onclick="event.stopPropagation(); window.App.toggleFav('${place.id}')">
            ${isFav ? '❤️' : '🤍'}
          </button>
          <div class="featured-content">
            <div class="featured-reason">
              ${place.reasonBadge || window.t('best_budget_fit', 'Paling cocok dengan budget Anda')}
              ${place.affordableCombo ? ` • 💡 ${window.t('budget_can_get_prefix', 'Bisa dapet:')} ${place.affordableCombo.text} (${place.affordableCombo.priceFormatted})` : ''}
            </div>
            <h2 class="featured-title">${place.name}</h2>
            <div class="featured-meta">
              <span>📍 ${place.city} (${place.distance || 0} ${kmText})</span>
              <span>💰 ${RecommendationService.formatPrice(place)}</span>
              <span>🏷️ ${catLabel}</span>
            </div>
          </div>
        </div>
      </div>
    `;
  },

  renderActivityRecommendationCarousel(items) {
    if (!items || items.length === 0) return '';
    const hasActivity = StorageService.getActivityHistory().viewedPlaceIds.length > 0;
    const title = typeof I18nService !== 'undefined' ? I18nService.t('activity_recommendation_title') : '✨ Rekomendasi untuk Anda';
    const sub = hasActivity
      ? (typeof I18nService !== 'undefined' ? I18nService.t('activity_recommendation_sub') : 'Berdasarkan kafe dan wilayah yang sering Anda jelajahi')
      : (typeof I18nService !== 'undefined' ? I18nService.t('activity_fallback_sub') : 'Kafe paling populer dengan rating tertinggi di Purwokerto');

    return `
      <section class="activity-section">
        <div class="activity-header">
          <h3 class="activity-title">${title}</h3>
          <span class="activity-subtitle">${sub}</span>
        </div>
        <div class="activity-carousel-track">
          ${items.map(p => `
            <div class="activity-carousel-card" onclick="window.App.openPlaceDetail('${p.id}')">
              <div class="activity-card-img-box">
                <img src="${p.image_url || 'assets/images/beranda_mockup.jpeg'}" alt="${p.name}" class="activity-card-img" loading="lazy" />
                <span class="activity-reason-badge">${p.activityReason}</span>
              </div>
              <div class="activity-card-body">
                <h4 class="activity-card-name">${p.name}</h4>
                <div class="activity-card-meta">
                  <span>📍 ${p.city}</span>
                  <span style="color: #FBBF24; font-weight: bold;">⭐ ${p.rating || 4.6}</span>
                </div>
                <div class="activity-card-price">${RecommendationService.formatPrice(p)}</div>
              </div>
            </div>
          `).join('')}
        </div>
      </section>
    `;
  },

  renderCategoryFilterBar() {
    const cats = [
      { key: 'Semua', label: window.t('cat_all', '✨ Semua Tempat') },
      { key: 'Cafe', label: window.t('cat_cafe', '☕ Cafe') },
      { key: 'Warkop', label: window.t('cat_warkop', '🍵 Warkop') },
      { key: 'Restoran', label: window.t('cat_resto', '🍽️ Restoran') }
    ];
    return `
      <div class="category-pills">
        ${cats.map(c => `
          <button class="category-pill ${this.selectedCategory === c.key ? 'active' : ''}"
                  onclick="window.App.selectCategory('${c.key}')">
            ${c.label}
          </button>
        `).join('')}
      </div>
    `;
  },

  renderPlaceCard(place) {
    const isFav = StorageService.isFavorite(place.id);
    const facilities = (place.facilities || []).slice(0, 3);
    const catLabel = typeof I18nService !== 'undefined' ? I18nService.translateCategory(place.category) : (place.category || 'Cafe');
    const isBestMatch = this.isBudgetFilterActive && place.isBestBudgetMatch;
    const bestMatchBadge = isBestMatch
      ? `<span class="badge-best-budget">✨ ${window.t('budget_badge_best_match', 'Pas di Budget')}</span>`
      : '';
    const canGetPrefix = typeof window.t === 'function' ? window.t('budget_can_get_prefix', 'Bisa dapet:') : 'Bisa dapet:';
    const comboHtml = place.affordableCombo
      ? `<div class="place-card-menu-combo">💡 ${canGetPrefix} <strong>${place.affordableCombo.text}</strong> <span class="combo-price">(${place.affordableCombo.priceFormatted})</span></div>`
      : '';

    const isVsSelected = window.Roulette && window.Roulette.isCandidateSelected(place.id);
    const vsLabel = isVsSelected
      ? window.t('wheel_card_btn_added', 'Terpilih')
      : window.t('wheel_card_btn_add', 'Adu');

    return `
      <div class="place-card ${isBestMatch ? 'card-best-match' : ''}" onclick="window.App.openPlaceDetail('${place.id}')">
        <div class="place-card-image-wrapper">
          <img src="${place.image_url || 'assets/images/beranda_mockup.jpeg'}" alt="${place.name}" class="place-card-img" loading="lazy" />
          <button class="place-card-fav-btn ${isFav ? 'active' : ''}"
                  onclick="event.stopPropagation(); window.App.toggleFav('${place.id}')">
            ${isFav ? '❤️' : '🤍'}
          </button>
          <div style="position: absolute; bottom: 10px; left: 10px; display: flex; gap: 6px; align-items: center; z-index: 2; flex-wrap: wrap;">
            <span class="place-card-category-tag" style="position: static;">${catLabel}</span>
            ${bestMatchBadge}
          </div>
        </div>
        <div class="place-card-body">
          <div class="place-card-header">
            <h4 class="place-card-title">${place.name}</h4>
            <div class="place-card-rating">⭐ ${place.rating || 4.5}</div>
          </div>
          <div class="place-card-location">
            <span>📍 ${place.city} • ${place.distance || 0} km</span>
            ${place.isGoogleLive ? `<span class="badge-google-live" style="margin-left: 6px;">🗺️ Google Maps</span>` : ''}
          </div>
          <div class="place-card-reason">${place.reasonBadge || window.t('budget_friendly', 'Pas di kantong')}</div>
          ${comboHtml}
          <div class="place-card-facilities">
            ${facilities.map(f => {
              const fLabel = typeof I18nService !== 'undefined' ? I18nService.translateFacility(f) : f;
              return `<span class="facility-chip-mini">${fLabel}</span>`;
            }).join('')}
          </div>
          <div class="place-card-footer">
            <div class="place-card-price">
              ${RecommendationService.formatPrice(place)}
            </div>
            <div class="place-card-actions">
              <button class="btn-card-vs ${isVsSelected ? 'active' : ''}" data-place-id="${place.id}"
                      onclick="event.stopPropagation(); window.Roulette.toggleCandidate('${place.id}')"
                      title="${isVsSelected ? window.t('wheel_card_btn_added', 'Terpilih') : window.t('wheel_card_btn_add', '+ Adu Tongkrongan')}">
                <span>${isVsSelected ? '✓' : '⚔️'}</span>
                <span>${vsLabel}</span>
              </button>
              <button class="btn-card-locate" onclick="event.stopPropagation(); window.App.focusMap('${place.id}', ${place.latitude}, ${place.longitude})">
                ${window.t('pin_map', '🗺️ Pin Peta')}
              </button>
            </div>
          </div>
        </div>
      </div>
    `;
  },

  renderSearchTabHeader() {
    const history = StorageService.getSearchHistory();
    const queryDisplay = this.searchQuery || window.t('all_places_phrase', 'Semua Tempat');
    return `
      <div class="search-tab-view">
        <div class="history-section">
          <div class="history-header">
            <span>${window.t('recent_searches', 'Riwayat Pencarian Terakhir')}</span>
            ${history.length > 0 ? `<button class="btn-clear-history" onclick="window.App.clearSearchHistory()">${window.t('clear_all', 'Hapus Semua')}</button>` : ''}
          </div>
          <div class="history-chips">
            ${history.length === 0 ? `<span style="font-size: 12px; color: var(--text-muted);">${window.t('no_recent_searches', 'Belum ada riwayat pencarian.')}</span>` : ''}
            ${history.map(item => `
              <div class="history-chip" onclick="window.App.applySearchQuery('${item}')">
                <span>${item}</span>
                <span class="chip-remove" onclick="event.stopPropagation(); window.App.removeSearchHistoryItem('${item}')">×</span>
              </div>
            `).join('')}
          </div>
        </div>
        <div class="results-meta-bar">
          <span>${window.t('showing_results_for', 'Menampilkan hasil pencarian untuk:')} <strong>"${queryDisplay}"</strong></span>
          <select class="sort-select" onchange="window.App.setSort(this.value)">
            <option value="rekomendasi" ${this.sortBy === 'rekomendasi' ? 'selected' : ''}>${window.t('sort_recommended', '🎯 Paling Direkomendasikan')}</option>
            <option value="rating" ${this.sortBy === 'rating' ? 'selected' : ''}>${window.t('sort_rating', '⭐ Rating Tertinggi')}</option>
            <option value="jarak" ${this.sortBy === 'jarak' ? 'selected' : ''}>${window.t('sort_distance', '📍 Jarak Terdekat')}</option>
            <option value="harga_murah" ${this.sortBy === 'harga_murah' ? 'selected' : ''}>${window.t('sort_price_low', '💰 Harga Termurah')}</option>
          </select>
        </div>
      </div>
    `;
  },

  renderFavoritesHeader(count) {
    const cats = [
      { key: 'Semua', label: window.t('cat_all', '✨ Semua Tempat') },
      { key: 'Cafe', label: window.t('cat_cafe', '☕ Cafe') },
      { key: 'Warkop', label: window.t('cat_warkop', '🍵 Warkop') },
      { key: 'Restoran', label: window.t('cat_resto', '🍽️ Restoran') }
    ];
    return `
      <div style="margin-bottom: 20px;">
        <div class="category-pills" style="margin-bottom: 12px;">
          ${cats.map(c => `
            <button class="category-pill ${this.selectedCategory === c.key ? 'active' : ''}"
                    onclick="window.App.selectCategory('${c.key}')">
              ${c.label}
            </button>
          `).join('')}
        </div>
        <p style="font-size: 13px; color: var(--text-secondary);">
          ${window.t('fav_header_desc', `Tersimpan ${count} tempat di penyimpanan browser lokal Anda (❤️).`, { count })}
        </p>
      </div>
    `;
  },

  renderSettingsView(container) {
    const session = StorageService.getUserSession();
    const currentTheme = StorageService.getTheme();

    container.innerHTML = `
      <div style="max-width: 600px; display: flex; flex-direction: column; gap: 24px;">
        <h2 class="section-title">${window.t('settings_title', '⚙️ Pengaturan Aplikasi MAMPIR')}</h2>

        <div class="history-section">
          <h4 style="font-size: 14px; margin-bottom: 8px;">${window.t('account_info', 'Informasi Akun')}</h4>
          <p style="font-size: 13px; color: var(--text-secondary);">${window.t('logged_as', 'Masuk sebagai')}: <strong>${session.name}</strong> (${session.isGuest ? window.t('mode_guest', 'Mode Tamu') : session.email})</p>
          <div style="margin-top: 12px; display: flex; gap: 10px;">
            <button class="btn-secondary" onclick="window.App.openAuthModal()">${window.t('btn_switch_acc', 'Ganti Akun')}</button>
            <button class="btn-secondary" style="color: #EF4444;" onclick="window.App.logout()">${window.t('btn_logout', 'Keluar (Sign Out)')}</button>
          </div>
        </div>

        <div class="history-section">
          <h4 style="font-size: 14px; margin-bottom: 8px;">${window.t('theme_section_title', 'Tema Tampilan')}</h4>
          <div style="display: flex; gap: 12px;">
            <button class="category-pill ${currentTheme === 'Gelap' ? 'active' : ''}" onclick="window.App.setTheme('Gelap')">${window.t('theme_dark', '🌙 Mode Gelap')}</button>
            <button class="category-pill ${currentTheme === 'Terang' ? 'active' : ''}" onclick="window.App.setTheme('Terang')">${window.t('theme_light', '☀️ Mode Terang')}</button>
          </div>
        </div>

        <div class="history-section">
          <h4 style="font-size: 14px; margin-bottom: 8px;">${window.t('about_title', 'Tentang MAMPIR Web')}</h4>
          <p style="font-size: 13px; color: var(--text-secondary); line-height: 1.6;">
            ${window.t('about_desc', '<strong>MAMPIR</strong>: Makan, Ampir, Pilih, dan Rekomendasi Tempat Makan & Nongkrong di Kota Purwokerto dan Sekitarnya.<br/>Edisi Multiplatform Web v2.0 • PML 2026.')}
          </p>
        </div>
      </div>
    `;
  },

  // ==================== INTERACTION HANDLERS ====================
  bindHeaderControls() {
    const regionSelect = document.getElementById('global-region-select');
    if (regionSelect) {
      regionSelect.value = this.selectedRegion;
      regionSelect.addEventListener('change', (e) => {
        this.selectedRegion = e.target.value;
        StorageService.setSelectedRegion(this.selectedRegion);

        // Arahkan kamera Google Maps ke wilayah yang dipilih
        const regionCoordinates = {
          'Purwokerto Kota': { lat: -7.4243, lng: 109.2303, zoom: 14 },
          'Baturraden': { lat: -7.3150, lng: 109.2250, zoom: 14 },
          'Purwokerto Utara (Unsoed)': { lat: -7.4020, lng: 109.2450, zoom: 14 },
          'Sokaraja': { lat: -7.4580, lng: 109.2880, zoom: 14 },
          'Purwokerto Timur & Sumbang': { lat: -7.3850, lng: 109.2600, zoom: 13 },
          'Purwokerto Barat & Selatan': { lat: -7.4350, lng: 109.2150, zoom: 14 }
        };
        const coords = regionCoordinates[this.selectedRegion];
        if (coords && typeof MapController !== 'undefined') {
          MapController.panTo(coords.lat, coords.lng, coords.zoom);
        }

        this.render();
      });
    }

    const searchInput = document.getElementById('global-search-input');
    const searchClear = document.getElementById('global-search-clear');
    if (searchInput) {
      searchInput.addEventListener('input', (e) => {
        this.searchQuery = e.target.value;
        if (searchClear) searchClear.style.display = this.searchQuery ? 'block' : 'none';
        this.render();
      });
      searchInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
          StorageService.addSearchHistory(this.searchQuery);
          this.switchView('cari');
        }
      });
    }

    if (searchClear) {
      searchClear.addEventListener('click', () => {
        if (searchInput) searchInput.value = '';
        this.searchQuery = '';
        searchClear.style.display = 'none';
        this.render();
      });
    }

    // Language switcher
    const langSelect = document.getElementById('global-lang-select');
    if (langSelect && typeof I18nService !== 'undefined') {
      langSelect.value = I18nService.getLanguage();
      langSelect.addEventListener('change', (e) => {
        this.changeLanguage(e.target.value);
      });
    }

    // Toggle theme button
    const themeBtn = document.getElementById('btn-toggle-theme');
    if (themeBtn) {
      themeBtn.addEventListener('click', () => {
        const nextTheme = StorageService.getTheme() === 'Gelap' ? 'Terang' : 'Gelap';
        this.setTheme(nextTheme);
      });
    }
  },

  bindSidebarNav() {
    const navItems = document.querySelectorAll('.sidebar-nav .nav-item');
    navItems.forEach(item => {
      item.addEventListener('click', () => {
        const view = item.getAttribute('data-view');
        if (view) this.switchView(view);
      });
    });
  },

  switchView(viewName) {
    if (viewName === 'admin') viewName = 'beranda';
    this.currentView = viewName;
    document.querySelectorAll('.sidebar-nav .nav-item').forEach(el => {
      el.classList.toggle('active', el.getAttribute('data-view') === viewName);
    });

    // Invalidate map size when switching back
    MapController.invalidateSize();
    this.render();

    // Pastikan data tempat terdekat dari titik GPS aktif langsung diambil
    if (viewName === 'terdekat') {
      this.ensureNearMePlacesLoaded();
    }
  },

  selectCategory(cat) {
    this.selectedCategory = cat;
    this.render();
  },

  toggleFav(placeId) {
    const isNowFav = StorageService.toggleFavorite(placeId);
    this.render();
    this.showToast(isNowFav ? '❤️ Ditambahkan ke Favorit' : 'Dihapus dari Favorit');
  },

  focusMap(placeId, lat, lng) {
    MapController.highlightMarker(placeId);
    MapController.panTo(lat, lng, 16);
  },

  applySearchQuery(query) {
    this.searchQuery = query;
    const input = document.getElementById('global-search-input');
    if (input) input.value = query;
    this.render();
  },

  removeSearchHistoryItem(item) {
    StorageService.removeSearchHistory(item);
    this.render();
  },

  clearSearchHistory() {
    StorageService.clearSearchHistory();
    this.render();
  },

  setSort(val) {
    this.sortBy = val;
    this.render();
  },

  resetFilters() {
    this.searchQuery = '';
    this.selectedCategory = 'Semua';
    this.selectedRegion = 'Purwokerto Kota';
    this.userBudget = 25000;
    this.isBudgetFilterActive = false;
    this.lastUpsell = null;
    StorageService.setBudgetFilterActive(false);
    this.updateBudgetButtonUI();
    const regSelect = document.getElementById('global-region-select');
    if (regSelect) regSelect.value = 'Purwokerto Kota';
    const sInput = document.getElementById('global-search-input');
    if (sInput) sInput.value = '';
    this.render();
  },

  // ==================== DETAIL MODAL ====================
  openPlaceDetail(placeId) {
    const place = this.getPlaceById(placeId);
    if (!place) return;

    // Rekam aktivitas pengguna untuk personalisasi rekomendasi (Req 4)
    StorageService.recordPlaceActivity(place);

    const modal = document.getElementById('modal-place-detail');
    const body = document.getElementById('modal-place-detail-body');
    if (!modal || !body) return;

    const isFav = StorageService.isFavorite(place.id);
    const facilities = place.facilities || [];
    const menuHighlights = place.menu_highlights || [];
    const distance = RecommendationService.calculateDistance(place.latitude, place.longitude);
    const catLabel = typeof I18nService !== 'undefined' ? I18nService.translateCategory(place.category) : place.category;

    // Format Link WhatsApp Resmi Pengelola Kafe (Req 1)
    const rawPhone = place.whatsapp || '6281234567890';
    const cleanPhone = rawPhone.replace(/\D/g, '');
    const isEn = typeof I18nService !== 'undefined' && I18nService.getLanguage() === 'en';
    const waGreeting = isEn
      ? `Hello Admin ${place.name}, I found your cafe through MAMPIR and would like to ask:`
      : `Halo Admin ${place.name}, saya menemukan kafe Anda melalui Mampir dan ingin bertanya:`;
    const waUrl = `https://wa.me/${cleanPhone}?text=${encodeURIComponent(waGreeting)}`;

    // Agenda / Event Kafe Aktif (Req 2)
    const cafeEvents = StorageService.getCafeEvents(place.id);

    // Ulasan Pengunjung (Req 2)
    const reviews = StorageService.getPlaceReviews(place.id);

    body.innerHTML = `
      <img src="${place.image_url || 'assets/images/beranda_mockup.jpeg'}" alt="${place.name}" class="detail-modal-img" />
      
      <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 14px;">
        <div>
          <span class="badge-cat">${catLabel}</span>
          <h2 style="font-size: 22px; margin-top: 6px;">${place.name}</h2>
          <p style="color: var(--text-secondary); font-size: 13px;">📍 ${place.address || place.city}</p>
        </div>
        
        <div style="display: flex; gap: 8px; align-items: center;">
          <!-- Tombol Bagikan / Share Dialog (Req 5) -->
          <button class="btn-detail-action" title="${window.t('btn_share', 'Bagikan')}"
                  onclick="event.stopPropagation(); window.App.openShareModal('${place.id}')">
            ↗️
          </button>
          <!-- Tombol Favorit -->
          <button class="place-card-fav-btn ${isFav ? 'active' : ''}" style="position: static;"
                  onclick="window.App.toggleFav('${place.id}'); window.App.openPlaceDetail('${place.id}');">
            ${isFav ? '❤️' : '🤍'}
          </button>
        </div>
      </div>

      <div style="display: flex; gap: 16px; margin-bottom: 18px; padding: 12px; background: var(--bg-card); border-radius: var(--radius-sm); border: 1px solid var(--border-color); flex-wrap: wrap;">
        <div><small style="color: var(--text-muted);">${window.t('rating_label', 'Rating')}</small><div style="font-weight: bold; color: #FBBF24;">⭐ ${place.rating} (${place.review_count || 100}+)</div></div>
        <div><small style="color: var(--text-muted);">${window.t('price_range_label', 'Rentang Harga')}</small><div style="font-weight: bold; color: var(--accent-orange);">${RecommendationService.formatPrice(place)}</div></div>
        <div><small style="color: var(--text-muted);">${window.t('distance_label', 'Jarak')}</small><div style="font-weight: bold;">${distance} km</div></div>
        <div><small style="color: var(--text-muted);">${window.t('open_hours_label', 'Jam Operasional')}</small><div style="font-weight: bold;">${place.open_hours || '08.00 - 22.00'}</div></div>
      </div>

      <!-- Tombol Aksi: WhatsApp Kontak Pengelola (Req 1) & Google Maps -->
      <div style="display: flex; gap: 10px; margin-bottom: 20px; flex-wrap: wrap;">
        <!-- Tombol CTA WhatsApp Pengelola (Tanpa Nomor Mentah di Layar) -->
        <a href="${waUrl}" target="_blank" class="btn-cta-whatsapp" style="flex: 1; min-width: 220px;" title="${window.t('btn_contact_wa', 'Hubungi Pengelola')}">
          <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor">
            <path d="M12.031 6.172c-3.181 0-5.767 2.586-5.768 5.766-.001 1.298.38 2.27 1.019 3.287l-.582 2.128 2.182-.573c.978.58 1.911.928 3.145.929 3.178 0 5.767-2.587 5.768-5.766.001-3.187-2.575-5.77-5.764-5.771zm3.392 8.244c-.144.405-.837.774-1.17.824-.312.045-.694.04-1.077-.077-.738-.225-1.745-.732-2.839-1.826-1.094-1.094-1.601-2.101-1.826-2.839-.117-.383-.122-.765-.077-1.077.05-.333.419-1.026.824-1.17.203-.072.396-.062.54.021.162.093.522.86.567.971.045.111.072.24.009.366-.063.126-.135.216-.243.342-.108.126-.216.27-.306.378-.108.126-.225.261-.099.477.126.216.558.918 1.206 1.494.837.747 1.548.981 1.764 1.089.216.108.342.09.468-.054.126-.144.54-.63.684-.846.144-.216.288-.18.495-.108.207.072 1.323.624 1.548.738.225.114.378.171.432.27.054.099.054.576-.09 1.053z"/>
            <path d="M12 2C6.48 2 2 6.48 2 12c0 1.82.49 3.53 1.34 5L2 22l5.18-1.31C8.61 21.49 10.26 22 12 22c5.52 0 10-4.48 10-10S17.52 2 12 2zm0 18c-1.62 0-3.13-.48-4.4-1.31l-.31-.2-3.26.83.85-3.18-.22-.35C3.78 14.65 3.3 13.37 3.3 12c0-4.8 3.9-8.7 8.7-8.7s8.7 3.9 8.7 8.7-3.9 8.7-8.7 8.7z"/>
          </svg>
          <span>${window.t('btn_contact_wa', 'Hubungi Pengelola')}</span>
        </a>
        <a href="${(this.userGps && this.userGps.lat) ? `https://www.google.com/maps/dir/?api=1&origin=${this.userGps.lat},${this.userGps.lng}&destination=${place.latitude},${place.longitude}` : `https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}`}" target="_blank"
           class="btn-primary" style="flex: 1; min-width: 200px; text-align: center; text-decoration: none; justify-content: center;">
          🗺️ ${window.t('route_btn', 'Buka Rute di Google Maps')}
        </a>
        ${place.googleMapsUri ? `
          <a href="${place.googleMapsUri}" target="_blank"
             class="btn-secondary" style="font-size: 13px; padding: 10px 16px; text-decoration: none; display: flex; align-items: center; gap: 6px; white-space: nowrap;">
            📍 Google Maps Profile
          </a>
        ` : ''}
      </div>

      <!-- Agenda & Pengumuman Kafe (Req 2 & Req 7: Kalender & Pasang Pengingat) -->
      ${cafeEvents.length > 0 ? `
        <div class="cafe-events-wrapper">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
            <h4 style="font-size: 14px; font-weight: 700; color: var(--accent-gold); display: flex; align-items: center; gap: 6px; margin: 0;">
              ${window.t('events_upcoming_title', '📅 Agenda & Event Mendatang')}
            </h4>
            <span style="font-size: 11px; padding: 2px 8px; border-radius: 99px; background: rgba(255, 183, 77, 0.15); color: var(--accent-orange); font-weight: 700;">
              ${window.t('events_count', `${cafeEvents.length} Acara`, { count: cafeEvents.length })}
            </span>
          </div>
          ${cafeEvents.map(ev => {
            const isReminderSet = StorageService.isEventReminderSet(ev.id);
            return `
            <div class="cafe-event-card">
              <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 8px;">
                <span class="cafe-event-badge">${ev.badge || ev.category}</span>
                <span style="font-size: 11px; color: var(--text-muted);">MAMPIR Event</span>
              </div>
              <h5 style="font-size: 14px; font-weight: bold; margin: 4px 0;">${ev.title}</h5>
              <div style="font-size: 12px; color: var(--accent-orange); margin-bottom: 6px; font-weight: 600;">⏰ ${ev.date}</div>
              <p style="font-size: 12px; color: var(--text-secondary); line-height: 1.5; margin-bottom: 8px;">${ev.description}</p>

              <!-- Tombol CTA Pasang Pengingat & Tambah ke Kalender (Req 7) -->
              <div class="cafe-event-actions">
                <button class="btn-reminder ${isReminderSet ? 'active' : ''}" id="btn-remind-${ev.id}" onclick="window.App.toggleEventReminder('${ev.id}', '${place.id}')">
                  ${isReminderSet
                    ? window.t('btn_reminder_active', '✅ Pengingat Terpasang')
                    : window.t('btn_set_reminder', '⏰ Pasang Pengingat')
                  }
                </button>
                <button class="btn-secondary" style="font-size: 11px; padding: 6px 12px;" onclick="window.App.openCalendarExportModal('${ev.id}', '${place.id}')">
                  📅 ${window.t('btn_add_to_calendar', 'Tambah ke Kalender')}
                </button>
              </div>
            </div>
          `;}).join('')}
        </div>
      ` : ''}

      <div class="detail-section">
        <h4>${window.t('desc_title', 'Deskripsi')}</h4>
        <p style="font-size: 13px; color: var(--text-secondary); line-height: 1.6;">${place.description || 'Tempat kuliner favorit yang nyaman di kawasan Purwokerto.'}</p>
      </div>

      <div class="detail-section">
        <h4>${window.t('facilities_title', 'Fasilitas Tersedia')}</h4>
        <div style="display: flex; gap: 6px; flex-wrap: wrap;">
          ${facilities.map(f => {
            const fLabel = typeof I18nService !== 'undefined' ? I18nService.translateFacility(f) : f;
            return `<span class="category-pill" style="padding: 4px 10px; font-size: 11px;">✓ ${fLabel}</span>`;
          }).join('')}
        </div>
      </div>

      <div class="detail-section">
        <h4>${window.t('menu_title', 'Menu Andalan')}</h4>
        <div class="menu-highlight-list">
          ${menuHighlights.map(m => `
            <div class="menu-item-row">
              <span>☕ ${m.name}</span>
              <strong>${RecommendationService.formatRupiah(m.price)}</strong>
            </div>
          `).join('')}
        </div>
      </div>

      <!-- Ulasan & Rating Pengunjung (Req 2) -->
      <div class="reviews-container">
        <h4 style="font-size: 15px; font-weight: 800; margin-bottom: 12px;">${window.t('reviews_title', '⭐ Ulasan & Penilaian Pengunjung')}</h4>
        
        <div class="review-form-box">
          <h5 style="font-size: 13px; font-weight: 700; margin-bottom: 4px;">${window.t('add_review_title', 'Tulis Ulasan Anda')}</h5>
          <div class="stars-selector" id="detail-star-selector">
            <span class="star-rate active" data-val="1" onclick="window.App.setReviewStar(1)">★</span>
            <span class="star-rate active" data-val="2" onclick="window.App.setReviewStar(2)">★</span>
            <span class="star-rate active" data-val="3" onclick="window.App.setReviewStar(3)">★</span>
            <span class="star-rate active" data-val="4" onclick="window.App.setReviewStar(4)">★</span>
            <span class="star-rate active" data-val="5" onclick="window.App.setReviewStar(5)">★</span>
          </div>
          <input type="text" id="review-input-name" class="form-control" style="margin-bottom: 8px;" placeholder="${window.t('review_name_ph', 'Nama Anda...')}" value="${StorageService.getUserSession().name}" />
          <textarea id="review-input-comment" class="form-control" rows="2" style="margin-bottom: 8px;" placeholder="${window.t('review_comment_ph', 'Bagaimana pengalaman Anda di kafe ini?')}"></textarea>
          <button class="btn-primary" style="padding: 7px 16px; font-size: 12px;" onclick="window.App.submitReview('${place.id}')">
            ${window.t('btn_submit_review', 'Kirim Ulasan')}
          </button>
        </div>

        <div class="reviews-list">
          ${reviews.map(r => `
            <div class="review-item-card">
              <div class="review-item-header">
                <strong>${r.author}</strong>
                <span style="color: #FBBF24;">${'★'.repeat(r.rating || 5)}</span>
              </div>
              <p style="font-size: 12px; color: var(--text-secondary); margin-bottom: 4px;">${r.comment}</p>
              <small style="font-size: 10px; color: var(--text-muted);">${r.date}</small>
            </div>
          `).join('')}
        </div>
      </div>
    `;

    modal.classList.add('active');
  },

  // ==================== SHARE MODAL DIALOG (Req 5) ====================
  openShareModal(placeId) {
    const place = this.getPlaceById(placeId);
    if (!place) return;

    const modal = document.getElementById('modal-share-cafe');
    const body = document.getElementById('modal-share-body');
    const heading = document.getElementById('modal-share-heading');
    if (!modal || !body) return;

    if (heading && typeof I18nService !== 'undefined') {
      heading.textContent = window.t('share_modal_title', 'Bagikan Kafe Ini');
    }

    const shareUrl = `${window.location.origin}${window.location.pathname}?place=${place.id}`;
    const shareText = window.t('share_text_prefix', `Yuk cek ${place.name} di MAMPIR Purwokerto:`, { name: place.name });

    const waShareUrl = `https://api.whatsapp.com/send?text=${encodeURIComponent(`${shareText} ${shareUrl}`)}`;
    const xShareUrl = `https://twitter.com/intent/tweet?text=${encodeURIComponent(shareText)}&url=${encodeURIComponent(shareUrl)}`;
    const fbShareUrl = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(shareUrl)}`;

    body.innerHTML = `
      <div class="share-dialog-card">
        <p style="font-size: 13px; color: var(--text-secondary); line-height: 1.5;">
          ${window.t('share_subtitle', 'Ajak teman dan keluarga mampir ke tempat nongkrong asyik ini!')}
        </p>

        <div class="share-cafe-preview">
          <img src="${place.image_url || 'assets/images/beranda_mockup.jpeg'}" alt="${place.name}" class="share-cafe-thumb" />
          <div style="flex: 1; overflow: hidden;">
            <div style="font-weight: 800; font-size: 14px; color: var(--text-primary); text-overflow: ellipsis; white-space: nowrap; overflow: hidden;">
              ${place.name}
            </div>
            <div style="font-size: 11px; color: var(--text-secondary);">📍 ${place.city} • ⭐ ${place.rating}</div>
            <div style="font-size: 12px; font-weight: 700; color: var(--accent-orange);">${RecommendationService.formatPrice(place)}</div>
          </div>
        </div>

        <div class="share-link-row">
          <input type="text" class="share-link-input" id="share-input-field" value="${shareUrl}" readonly />
          <button class="btn-primary" onclick="window.App.copyShareUrl('${shareUrl}')">
            📋 ${window.t('btn_copy_link', 'Salin Tautan')}
          </button>
        </div>

        <div class="share-social-grid">
          <a href="${waShareUrl}" target="_blank" class="btn-social-share btn-share-wa">
            <span>💬 ${window.t('share_wa', 'WhatsApp')}</span>
          </a>
          <a href="${xShareUrl}" target="_blank" class="btn-social-share btn-share-x">
            <span>𝕏 ${window.t('share_x', 'Twitter / X')}</span>
          </a>
          <a href="${fbShareUrl}" target="_blank" class="btn-social-share btn-share-fb">
            <span>📘 ${window.t('share_fb', 'Facebook')}</span>
          </a>
        </div>
      </div>
    `;

    modal.classList.add('active');
  },

  copyShareUrl(url) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(url).then(() => {
        this.showToast(window.t('toast_link_copied', 'Tautan berhasil disalin!'));
      }).catch(() => {
        this.fallbackCopy(url);
      });
    } else {
      this.fallbackCopy(url);
    }
  },

  fallbackCopy(text) {
    const el = document.getElementById('share-input-field');
    if (el) {
      el.select();
      document.execCommand('copy');
      this.showToast(window.t('toast_link_copied', 'Tautan berhasil disalin!'));
    }
  },

  setReviewStar(val) {
    this.currentReviewRating = val;
    document.querySelectorAll('#detail-star-selector .star-rate').forEach(el => {
      const v = parseInt(el.getAttribute('data-val'), 10);
      el.classList.toggle('active', v <= val);
    });
  },

  submitReview(placeId) {
    const author = document.getElementById('review-input-name')?.value || 'Pengunjung MAMPIR';
    const comment = document.getElementById('review-input-comment')?.value;
    const rating = this.currentReviewRating || 5;

    if (!comment || !comment.trim()) {
      alert(window.t('review_alert_empty', 'Silakan tuliskan pengalaman ulasan Anda.'));
      return;
    }

    StorageService.addPlaceReview(placeId, {
      author,
      rating,
      comment
    });

    this.showToast(window.t('review_submitted', 'Ulasan berhasil diterbitkan!'));
    this.openPlaceDetail(placeId);
  },

  changeLanguage(lang) {
    if (typeof I18nService !== 'undefined') {
      I18nService.setLanguage(lang);
    }
    this.updateBudgetButtonUI();
    if (window.Roulette) {
      window.Roulette.drawWheel();
      window.Roulette.updateModeToggleUI();
      window.Roulette.updateFloatingDrawer();
    }
    this.render();
    this.showToast(lang === 'en' ? 'Language switched to English!' : 'Bahasa dialihkan ke Bahasa Indonesia!');
  },

  closeModal(modalId) {
    const el = document.getElementById(modalId);
    if (el) el.classList.remove('active');
  },

  // ==================== BUDGET FILTER & SMART RECOMMENDATION ====================
  updateBudgetButtonUI() {
    const btn = document.getElementById('btn-open-budget-modal');
    const labelEl = document.getElementById('btn-filter-budget-label');
    const clearEl = document.getElementById('btn-clear-budget-filter');
    if (!btn) return;

    if (this.isBudgetFilterActive) {
      btn.classList.add('active-filtered');
      const formattedBudget = RecommendationService.formatRupiah(this.userBudget);
      if (labelEl) {
        labelEl.textContent = window.t('budget_active_label', `Budget: ≤ ${formattedBudget}`, { budget: formattedBudget });
      }
      if (clearEl) {
        clearEl.style.display = 'inline-flex';
        clearEl.title = window.t('budget_clear_title', 'Hapus Filter Budget');
      }
    } else {
      btn.classList.remove('active-filtered');
      if (labelEl) {
        labelEl.textContent = window.t('btn_filter_budget', 'Filter Budget');
      }
      if (clearEl) {
        clearEl.style.display = 'none';
      }
    }
  },

  clearBudgetFilter() {
    this.isBudgetFilterActive = false;
    this.lastUpsell = null;
    StorageService.setBudgetFilterActive(false);
    this.updateBudgetButtonUI();
    this.render();
    this.showToast(window.t('toast_budget_cleared', 'Filter budget dinonaktifkan.'));
  },

  updateModalBudgetPreview(budgetVal) {
    const previewEl = document.getElementById('budget-modal-live-preview');
    if (!previewEl) return;

    const list = this.getMergedPlacesList();
    const inBudget = list.filter(p => (p.min_price || 0) <= budgetVal);
    const count = inBudget.length;

    if (count <= 1) {
      previewEl.classList.add('tight');
      previewEl.textContent = window.t('budget_preview_tight', '⚠️ Pilihan sangat terbatas. Naikkan sedikit budget untuk melihat lebih banyak opsi.');
    } else {
      previewEl.classList.remove('tight');
      previewEl.textContent = window.t('budget_preview_match', `✨ Ditemukan ${count} kafe yang cocok dengan kantongmu!`, { count });
    }

    // Update active highlight on quick preset chips
    document.querySelectorAll('.budget-preset-chip').forEach(chip => {
      const pVal = parseInt(chip.getAttribute('data-preset'), 10);
      chip.classList.toggle('active', pVal === budgetVal);
    });
  },

  setModalBudgetPreset(val) {
    const slider = document.getElementById('filter-budget-slider');
    const display = document.getElementById('filter-budget-val-display');
    if (slider) slider.value = val;
    if (display) display.textContent = RecommendationService.formatRupiah(val);
    this.updateModalBudgetPreview(val);
  },

  applyUpsellBudget(newBudget) {
    this.userBudget = newBudget;
    this.isBudgetFilterActive = true;
    this.lastUpsell = null;
    StorageService.setBudget(newBudget);
    StorageService.setBudgetFilterActive(true);
    this.updateBudgetButtonUI();
    this.render();
    const budgetFormatted = RecommendationService.formatRupiah(newBudget);
    this.showToast(window.t('toast_budget_upsell_applied', `Budget dinaikkan menjadi ${budgetFormatted}.`, { budget: budgetFormatted }));
  },

  bindFilterModal() {
    const openBtn = document.getElementById('btn-open-budget-modal');
    const modal = document.getElementById('modal-budget-filter');
    const slider = document.getElementById('filter-budget-slider');
    const display = document.getElementById('filter-budget-val-display');

    if (openBtn && modal) {
      openBtn.addEventListener('click', () => {
        if (slider) slider.value = this.userBudget;
        if (display) display.textContent = RecommendationService.formatRupiah(this.userBudget);
        this.updateModalBudgetPreview(this.userBudget);
        modal.classList.add('active');
      });
    }

    if (slider && display) {
      slider.addEventListener('input', (e) => {
        const val = parseInt(e.target.value, 10);
        display.textContent = RecommendationService.formatRupiah(val);
        this.updateModalBudgetPreview(val);
      });
    }

    const applyBtn = document.getElementById('btn-apply-budget-filter');
    if (applyBtn) {
      applyBtn.addEventListener('click', () => {
        if (slider) {
          this.userBudget = parseInt(slider.value, 10);
          StorageService.setBudget(this.userBudget);
        }
        this.isBudgetFilterActive = true;
        StorageService.setBudgetFilterActive(true);
        this.updateBudgetButtonUI();
        this.closeModal('modal-budget-filter');
        this.render();
        const budgetStr = RecommendationService.formatRupiah(this.userBudget);
        this.showToast(window.t('toast_budget_applied', `Filter diterapkan: Budget ${budgetStr}`, { budget: budgetStr }));
      });
    }
  },

  // ==================== AUTH / ONBOARDING ====================
  openOnboardingModal() {
    const m = document.getElementById('modal-onboarding');
    if (m) m.classList.add('active');
  },

  completeOnboarding(selectedRegion) {
    this.selectedRegion = selectedRegion;
    StorageService.setSelectedRegion(selectedRegion);
    StorageService.setFirstLaunchComplete();
    this.closeModal('modal-onboarding');
    const regSelect = document.getElementById('global-region-select');
    if (regSelect) regSelect.value = selectedRegion;
    this.render();
  },

  bindAuthModal() {
    const profileBtn = document.getElementById('btn-user-profile');
    const modal = document.getElementById('modal-auth');
    if (profileBtn && modal) {
      profileBtn.addEventListener('click', () => {
        modal.classList.add('active');
      });
    }
  },

  openAuthModal() {
    const m = document.getElementById('modal-auth');
    if (m) m.classList.add('active');
  },

  switchAuthTab(tab) {
    const tabLogin = document.getElementById('auth-tab-login');
    const tabRegister = document.getElementById('auth-tab-register');
    const formLogin = document.getElementById('form-login');
    const formRegister = document.getElementById('form-register');
    const alertBox = document.getElementById('auth-alert-box');

    if (alertBox) alertBox.style.display = 'none';

    if (tab === 'register') {
      if (tabLogin) tabLogin.classList.remove('active');
      if (tabRegister) tabRegister.classList.add('active');
      if (formLogin) formLogin.style.display = 'none';
      if (formRegister) formRegister.style.display = 'block';
    } else {
      if (tabRegister) tabRegister.classList.remove('active');
      if (tabLogin) tabLogin.classList.add('active');
      if (formRegister) formRegister.style.display = 'none';
      if (formLogin) formLogin.style.display = 'block';
    }
  },

  showAuthAlert(message, type = 'error') {
    const box = document.getElementById('auth-alert-box');
    if (!box) return;
    box.style.display = 'block';
    if (type === 'success') {
      box.style.background = 'rgba(16, 185, 129, 0.15)';
      box.style.border = '1px solid #10B981';
      box.style.color = '#10B981';
    } else {
      box.style.background = 'rgba(239, 68, 68, 0.15)';
      box.style.border = '1px solid #EF4444';
      box.style.color = '#EF4444';
    }
    box.innerHTML = message;
  },

  async handleLogin(email, password) {
    const btn = document.getElementById('btn-submit-login');
    if (btn) {
      btn.disabled = true;
      btn.textContent = 'Memverifikasi...';
    }

    const res = await AuthService.signIn(email, password);

    if (btn) {
      btn.disabled = false;
      btn.textContent = 'Masuk ke Akun';
    }

    if (res.success) {
      this.closeModal('modal-auth');
      this.updateUserProfileUI();
      this.showToast(`Selamat datang, ${res.name}! ✨`);
      this.render();
    } else {
      this.showAuthAlert(res.message, 'error');
    }
  },

  async handleRegister(name, email, password, confirmPassword) {
    if (password !== confirmPassword) {
      this.showAuthAlert('Konfirmasi kata sandi tidak cocok. Silakan ketik ulang kata sandi.', 'error');
      return;
    }
    if (password.length < 6) {
      this.showAuthAlert('Kata sandi harus terdiri dari minimal 6 karakter.', 'error');
      return;
    }

    const btn = document.getElementById('btn-submit-register');
    if (btn) {
      btn.disabled = true;
      btn.textContent = 'Mendaftarkan...';
    }

    const res = await AuthService.signUp(email, password, name);

    if (btn) {
      btn.disabled = false;
      btn.textContent = 'Daftar Akun Baru';
    }

    if (res.success) {
      this.showAuthAlert(
        `🎉 <strong>Pendaftaran Berhasil!</strong><br/>${res.message}<br/><br/><em>Catatan: Jika Supabase Anda mengaktifkan 'Confirm email', silakan klik tautan verifikasi di email Anda sebelum masuk.</em>`,
        'success'
      );
    } else {
      this.showAuthAlert(res.message, 'error');
    }
  },

  // ==================== GOJEK-STYLE NEAR ME (TEMPAT TERDEKAT) ====================

  /**
   * Menyaring dan mengurutkan daftar tempat terdekat berdasarkan GPS & filter aktif
   */
  getNearMeProcessedPlaces() {
    const all = this.getMergedPlacesList();
    const userLat = this.userGps ? this.userGps.lat : AppConfig.centerCoordinates.lat;
    const userLng = this.userGps ? this.userGps.lng : AppConfig.centerCoordinates.lng;

    // 1. Saring hanya tempat yang memiliki koordinat valid
    let list = all.filter(p => typeof p.latitude === 'number' && typeof p.longitude === 'number');

    // 2. Hitung jarak matematis presisi (Haversine) dari GPS pengguna
    list = list.map(p => {
      const dist = (window.GooglePlacesService && typeof window.GooglePlacesService.calculateDistanceKm === 'function')
        ? GooglePlacesService.calculateDistanceKm(userLat, userLng, p.latitude, p.longitude)
        : 0;
      return {
        ...p,
        distanceFromGps: dist,
        distance: dist
      };
    });

    // 3. Filter Jarak Terdekat (0-1 km, 1-3 km, 3-5 km, 5-10 km, > 10 km)
    if (this.nearMeDistanceFilter === '0-1') {
      list = list.filter(p => p.distanceFromGps >= 0 && p.distanceFromGps <= 1.0);
    } else if (this.nearMeDistanceFilter === '1-3') {
      list = list.filter(p => p.distanceFromGps > 1.0 && p.distanceFromGps <= 3.0);
    } else if (this.nearMeDistanceFilter === '3-5') {
      list = list.filter(p => p.distanceFromGps > 3.0 && p.distanceFromGps <= 5.0);
    } else if (this.nearMeDistanceFilter === '5-10') {
      list = list.filter(p => p.distanceFromGps > 5.0 && p.distanceFromGps <= 10.0);
    } else if (this.nearMeDistanceFilter === '10+') {
      list = list.filter(p => p.distanceFromGps > 10.0);
    }

    // 4. Filter Kategori Tempat (Restoran, Warung Makan, Cafe, Coffee Shop, Tempat Nongkrong, Fast Food, Street Food)
    if (this.nearMeCategoryFilter && this.nearMeCategoryFilter !== 'all') {
      const targetCat = this.nearMeCategoryFilter.toLowerCase();
      list = list.filter(p => {
        const cat = (p.category || '').toLowerCase();
        const name = (p.name || '').toLowerCase();
        if (targetCat === 'tempat nongkrong') {
          return cat.includes('nongkrong') || cat.includes('cafe') || cat.includes('coffee') || cat.includes('warkop') || name.includes('nongkrong') || name.includes('space');
        }
        if (targetCat === 'warung makan') {
          return cat.includes('warung') || cat.includes('soto') || cat.includes('bakso') || cat.includes('mendoan') || name.includes('warung') || name.includes('soto') || name.includes('bakso');
        }
        if (targetCat === 'fast food') {
          return cat.includes('fast') || name.includes('chicken') || name.includes('burger') || name.includes('pizza') || name.includes('gacoan') || name.includes('wizzmie');
        }
        if (targetCat === 'street food') {
          return cat.includes('street') || name.includes('angkringan') || name.includes('kaki lima') || name.includes('kuliner malam');
        }
        return cat.includes(targetCat) || targetCat.includes(cat);
      });
    }

    // 5. Pengurutan (Terdekat, Rating Tertinggi, Paling Populer, Harga Termurah)
    if (this.nearMeSortBy === 'rating') {
      list.sort((a, b) => (b.rating || 0) - (a.rating || 0) || (b.review_count || 0) - (a.review_count || 0));
    } else if (this.nearMeSortBy === 'populer') {
      list.sort((a, b) => (b.review_count || 0) - (a.review_count || 0));
    } else if (this.nearMeSortBy === 'harga_murah') {
      list.sort((a, b) => (a.min_price || 0) - (b.min_price || 0));
    } else {
      // Default: Terdekat dari lokasi pengguna (jarak terpendek)
      list.sort((a, b) => a.distanceFromGps - b.distanceFromGps);
    }

    return list;
  },

  /**
   * Render tampilan utama "Near Me" ala Gojek
   */
  renderNearMeView(container) {
    const nearMePlaces = this.getNearMeProcessedPlaces();
    const userLat = this.userGps ? this.userGps.lat : AppConfig.centerCoordinates.lat;
    const userLng = this.userGps ? this.userGps.lng : AppConfig.centerCoordinates.lng;
    const userLabel = this.userGps ? this.userGps.label : 'Pusat Alun-Alun Purwokerto';

    // 1. Sinkronisasi Marker Peta Google Maps
    MapController.renderMarkers(nearMePlaces, (place) => {
      this.openPlaceDetail(place.id);
    });

    // 2. Auto-fit bounds peta agar mencakup semua tempat dan lokasi pengguna
    MapController.fitBoundsToPlacesAndUser(nearMePlaces, this.userGps);

    // 3. Perbarui lingkaran radar jarak deteksi di peta sesuai filter aktif
    let radiusMeters = 5000;
    if (this.nearMeDistanceFilter === '0-1') radiusMeters = 1000;
    else if (this.nearMeDistanceFilter === '1-3') radiusMeters = 3000;
    else if (this.nearMeDistanceFilter === '3-5') radiusMeters = 5000;
    else if (this.nearMeDistanceFilter === '5-10') radiusMeters = 10000;
    else if (this.nearMeDistanceFilter === '10+') radiusMeters = 18000;

    if (this.userGps) {
      MapController.renderUserLocation(userLat, userLng, userLabel, radiusMeters);
    }

    // Pilihan Filter Jarak
    const distOptions = [
      { key: 'all', label: window.t('dist_all', 'Semua Jarak') },
      { key: '0-1', label: window.t('dist_0_1', '0–1 km') },
      { key: '1-3', label: window.t('dist_1_3', '1–3 km') },
      { key: '3-5', label: window.t('dist_3_5', '3–5 km') },
      { key: '5-10', label: window.t('dist_5_10', '5–10 km') },
      { key: '10+', label: window.t('dist_10_plus', '> 10 km') }
    ];

    // Pilihan Filter Kategori Tempat (7 Kategori Permintaan Pengguna)
    const catOptions = [
      { key: 'all', label: window.t('cat_all_food', 'Semua Kategori'), icon: '🍽️' },
      { key: 'Restoran', label: window.t('cat_resto', 'Restoran'), icon: '🍲' },
      { key: 'Warung Makan', label: window.t('cat_warung', 'Warung Makan'), icon: '🍛' },
      { key: 'Cafe', label: window.t('cat_cafe', 'Cafe'), icon: '☕' },
      { key: 'Coffee Shop', label: window.t('cat_coffee', 'Coffee Shop'), icon: '🧋' },
      { key: 'Tempat Nongkrong', label: window.t('cat_nongkrong', 'Tempat Nongkrong'), icon: '✨' },
      { key: 'Fast Food', label: window.t('cat_fastfood', 'Fast Food'), icon: '🍔' },
      { key: 'Street Food', label: window.t('cat_streetfood', 'Street Food'), icon: '🍢' }
    ];

    // Titik Pengujian Cepat di Sekitar Purwokerto
    const testLocations = [
      { name: 'Alun-Alun Pwt', lat: -7.4243, lng: 109.2302 },
      { name: 'Unsoed Grendeng', lat: -7.4087, lng: 109.2483 },
      { name: 'Baturraden', lat: -7.3150, lng: 109.2272 },
      { name: 'Sokaraja', lat: -7.4580, lng: 109.2880 },
      { name: 'Stasiun Pwt', lat: -7.4187, lng: 109.2217 }
    ];

    let html = `
      <div class="nearme-view-container">
        <!-- Header Banner Near Me -->
        <div class="nearme-header-banner">
          <div class="nearme-header-text">
            <h2 class="nearme-title">📍 ${window.t('nearme_title', 'Tempat Makan & Nongkrong Terdekat')}</h2>
            <p class="nearme-subtitle">${window.t('nearme_subtitle', 'Pencarian akurat berbasis GPS & Google Maps Platform ala Gojek')}</p>
          </div>
          <button class="btn-refresh-gps ${this.isNearMeLoading ? 'loading' : ''}" onclick="window.App.triggerGpsDetection(true)" title="${window.t('btn_refresh_location', 'Perbarui Lokasi')}">
            <span class="refresh-icon">🔄</span>
            <span>${window.t('btn_refresh_location', 'Perbarui Lokasi')}</span>
          </button>
        </div>

        <!-- Kartu Lokasi Pengguna & Titik Uji Cepat -->
        <div class="nearme-location-card">
          <div class="nearme-location-status">
            <span class="pulse-indicator-dot"></span>
            <div>
              <div class="location-label-title">Titik Pusat Pencarian Saat Ini:</div>
              <div class="location-name-bold">
                ${userLabel}
                <span class="coord-tag">(${userLat.toFixed(4)}, ${userLng.toFixed(4)})</span>
              </div>
            </div>
          </div>
          <div class="nearme-test-chips">
            <span class="test-chip-label">${window.t('nearme_test_location', 'Uji Titik Lokasi:')}</span>
            ${testLocations.map(tl => {
              const isActive = Math.abs(userLat - tl.lat) < 0.005 && Math.abs(userLng - tl.lng) < 0.005;
              return `
                <button class="btn-test-loc-chip ${isActive ? 'active' : ''}"
                        onclick="window.App.setNearMeManualLocation(${tl.lat}, ${tl.lng}, '${tl.name}')">
                  📍 ${tl.name}
                </button>
              `;
            }).join('')}
          </div>
        </div>

        <!-- Filter Jarak Terdekat (Chips) -->
        <div class="nearme-filter-section">
          <div class="filter-section-title">📏 Filter Jarak Terdekat:</div>
          <div class="nearme-chips-scroll">
            ${distOptions.map(opt => `
              <button class="chip-filter-item ${this.nearMeDistanceFilter === opt.key ? 'active' : ''}"
                      onclick="window.App.setNearMeDistanceFilter('${opt.key}')">
                ${opt.label}
              </button>
            `).join('')}
          </div>
        </div>

        <!-- Filter Kategori Tempat (Chips) -->
        <div class="nearme-filter-section">
          <div class="filter-section-title">🍴 Filter Kategori Tempat:</div>
          <div class="nearme-chips-scroll">
            ${catOptions.map(cat => `
              <button class="chip-filter-item ${this.nearMeCategoryFilter === cat.key ? 'active' : ''}"
                      onclick="window.App.setNearMeCategoryFilter('${cat.key}')">
                <span>${cat.icon}</span> <span>${cat.label}</span>
              </button>
            `).join('')}
          </div>
        </div>

        <!-- Baris Meta (Jumlah Hasil & Pengurutan) -->
        <div class="nearme-meta-row">
          <div class="nearme-results-count">
            ${window.t('nearme_places_found', '<strong>{count}</strong> tempat terdekat ditemukan', { count: nearMePlaces.length })}
            ${this.isNearMeLoading ? '<span class="loading-spinner-inline">⏳ Memuat data Google Maps...</span>' : ''}
          </div>
          <div class="nearme-sort-wrapper">
            <label for="nearme-sort-select">Urutkan:</label>
            <select id="nearme-sort-select" class="nearme-sort-select" onchange="window.App.setNearMeSortBy(this.value)">
              <option value="jarak" ${this.nearMeSortBy === 'jarak' ? 'selected' : ''}>📍 ${window.t('nearme_sort_nearest', 'Terdekat')}</option>
              <option value="rating" ${this.nearMeSortBy === 'rating' ? 'selected' : ''}>⭐ ${window.t('nearme_sort_rating', 'Rating Tertinggi')}</option>
              <option value="populer" ${this.nearMeSortBy === 'populer' ? 'selected' : ''}>🔥 ${window.t('nearme_sort_populer', 'Paling Populer')}</option>
              <option value="harga_murah" ${this.nearMeSortBy === 'harga_murah' ? 'selected' : ''}>💰 ${window.t('nearme_sort_cheap', 'Harga Termurah')}</option>
            </select>
          </div>
        </div>

        <!-- Daftar Kartu Tempat Terdekat Ala Gojek -->
        <div class="nearme-cards-list">
    `;

    if (nearMePlaces.length === 0) {
      html += `
        <div class="nearme-empty-card">
          <div class="empty-icon">📍</div>
          <h3 class="empty-title">${window.t('nearme_empty_title', 'Tidak Ada Tempat dalam Radius Ini')}</h3>
          <p class="empty-desc">${window.t('nearme_empty_desc', 'Belum ada tempat makan atau nongkrong dalam jarak yang dipilih. Sedang memeriksa Google Maps Platform...')}</p>
          <div style="display: flex; gap: 10px; justify-content: center; margin-top: 16px; flex-wrap: wrap;">
            <button class="btn-primary" onclick="window.App.ensureNearMePlacesLoaded(true)">
              🔄 Cari Ulang via Google Maps
            </button>
            <button class="btn-secondary" onclick="window.App.setNearMeDistanceFilter('all')">
              📏 ${window.t('btn_expand_radius', 'Perluas Radius Jarak')}
            </button>
            <button class="btn-secondary" onclick="window.App.setNearMeCategoryFilter('all')">
              🍽️ Reset Kategori
            </button>
          </div>
        </div>
      `;
    } else {
      html += nearMePlaces.map(place => this.renderGojekNearMeCard(place)).join('');
    }

    html += `
        </div>
      </div>
    `;

    container.innerHTML = html;

    // Auto-healing: Jika daftar 0 tempat dan tidak sedang loading, segera tarik tempat terdekat Google Places
    if (nearMePlaces.length === 0 && !this.isNearMeLoading && !this._isAutoFetchingNearMe) {
      this._isAutoFetchingNearMe = true;
      setTimeout(() => {
        this._isAutoFetchingNearMe = false;
        if (this.currentView === 'terdekat') {
          this.ensureNearMePlacesLoaded(true);
        }
      }, 50);
    }
  },

  /**
   * Render kartu tempat kuliner individual dengan layout & estetika ala Gojek
   */
  renderGojekNearMeCard(place) {
    const formattedDistance = (window.GooglePlacesService && typeof window.GooglePlacesService.formatDistance === 'function')
      ? GooglePlacesService.formatDistance(place.distanceFromGps)
      : `${(place.distanceFromGps || 0).toFixed(1)} km`;

    const catLabel = typeof I18nService !== 'undefined'
      ? I18nService.translateCategory(place.category || 'Cafe')
      : (place.category || 'Cafe');

    const isLive = !!place.isGoogleLive;

    // Status Buka Sekarang (Open Now)
    let openStatusBadge = '';
    if (place.isOpenNow === true) {
      openStatusBadge = `<span class="badge-open-now">● ${window.t('status_open', 'Buka Sekarang')}</span>`;
    } else if (place.isOpenNow === false) {
      openStatusBadge = `<span class="badge-closed">● ${window.t('status_closed', 'Tutup')}</span>`;
    } else {
      openStatusBadge = `<span class="badge-hours">🕒 ${place.open_hours || '09.00 - 22.00 WIB'}</span>`;
    }

    // Google Maps Direction URL Turn-by-Turn
    const userGps = this.userGps;
    let dirUrl = `https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}`;
    if (userGps && userGps.lat && userGps.lng) {
      dirUrl += `&origin=${userGps.lat},${userGps.lng}`;
    }

    const priceText = RecommendationService.formatPrice(place);
    const detailLabel = window.t('view_detail', 'Lihat Detail');
    const directionsLabel = window.t('btn_directions', 'Petunjuk Arah');
    const showMapLabel = window.t('nearme_show_map', 'Lihat di Peta');

    return `
      <div class="gojek-nearme-card" id="nearme-card-${place.id}">
        <div class="gojek-card-media">
          <img src="${place.image_url || 'assets/images/beranda_mockup.jpeg'}" alt="${place.name}" class="gojek-card-img" loading="lazy" />
          <div class="gojek-media-badges">
            <span class="badge-cat-pill">${catLabel}</span>
            ${openStatusBadge}
          </div>
        </div>
        <div class="gojek-card-content">
          <div class="gojek-card-top">
            <div class="gojek-title-row">
              <h3 class="gojek-card-title" onclick="window.App.openPlaceDetail('${place.id}')">${place.name}</h3>
              ${isLive ? '<span class="badge-google-live" title="Terverifikasi Google Maps Live">🗺️ Live</span>' : ''}
            </div>
            <div class="gojek-distance-badge" title="Jarak matematis dari lokasi Anda">
              <span class="dist-icon">📍</span>
              <strong class="dist-number">${formattedDistance}</strong>
            </div>
          </div>

          <div class="gojek-rating-row">
            <span class="gojek-rating-star">⭐</span>
            <strong class="gojek-rating-val">${(place.rating || 4.5).toFixed(1)}</strong>
            <span class="gojek-reviews-count">(${Number(place.review_count || 120).toLocaleString('id-ID')} ulasan)</span>
            <span class="gojek-dot-divider">•</span>
            <span class="gojek-price-range">${priceText}</span>
          </div>

          <p class="gojek-card-address" title="${place.address || place.city || 'Purwokerto'}">
            <span class="addr-icon">📌</span>
            <span>${place.address || place.city || 'Purwokerto, Jawa Tengah'}</span>
          </p>

          <div class="gojek-card-actions">
            <button class="btn-gojek-detail" onclick="window.App.openPlaceDetail('${place.id}')">
              ${detailLabel}
            </button>
            <a href="${dirUrl}" target="_blank" class="btn-gojek-direction" rel="noopener noreferrer">
              <span>🧭 ${directionsLabel}</span>
            </a>
            <button class="btn-gojek-map" onclick="window.MapController.highlightMarker('${place.id}')" title="${showMapLabel}">
              <span>🗺️ Peta</span>
            </button>
          </div>
        </div>
      </div>
    `;
  },

  /**
   * Mengubah filter jarak terdekat
   */
  async setNearMeDistanceFilter(dist) {
    this.nearMeDistanceFilter = dist;
    this.render();

    // Jika filter jarak 0-1 km atau 1-3 km dan belum ada hasil, segera fetch Google Places
    const currentMatches = this.getNearMeProcessedPlaces();
    if (currentMatches.length === 0) {
      await this.ensureNearMePlacesLoaded(true);
    }
  },

  /**
   * Memastikan tempat-tempat terdekat dari koordinat GPS aktif telah termuat di memori
   */
  async ensureNearMePlacesLoaded(force = false) {
    if (!window.GooglePlacesService) return;
    const userLat = this.userGps ? this.userGps.lat : AppConfig.centerCoordinates.lat;
    const userLng = this.userGps ? this.userGps.lng : AppConfig.centerCoordinates.lng;

    // Hitung berapa tempat yang ada dalam jarak <= 1.5 km
    const countUnder1500m = this.places.filter(p => {
      if (!p.latitude || !p.longitude) return false;
      const d = GooglePlacesService.calculateDistanceKm(userLat, userLng, p.latitude, p.longitude);
      return d <= 1.5;
    }).length;

    if (countUnder1500m >= 5 && !force) {
      return;
    }

    this.isNearMeLoading = true;
    this.render();

    try {
      const places = await GooglePlacesService.fetchPlacesNearLocation(
        userLat,
        userLng,
        3000,
        this.nearMeCategoryFilter || 'all'
      );
      if (places && places.length > 0) {
        this.mergeGooglePlaces(places, this.userGps);
        this.recalculateAllDistances(userLat, userLng);
      }
    } catch (e) {
      console.warn('Gagal memuat tempat terdekat Google Places:', e);
    } finally {
      this.isNearMeLoading = false;
      this.render();
    }
  },

  /**
   * Mengubah filter kategori tempat (dan menarik data Google Places API jika kategori baru)
   */
  async setNearMeCategoryFilter(category) {
    this.nearMeCategoryFilter = category;
    const userLat = this.userGps ? this.userGps.lat : AppConfig.centerCoordinates.lat;
    const userLng = this.userGps ? this.userGps.lng : AppConfig.centerCoordinates.lng;

    if (window.GooglePlacesService) {
      this.isNearMeLoading = true;
      this.render();
      try {
        const places = await GooglePlacesService.fetchPlacesNearLocation(userLat, userLng, 3000, category);
        if (places && places.length > 0) {
          this.mergeGooglePlaces(places, this.userGps);
          this.recalculateAllDistances(userLat, userLng);
        }
      } catch (e) {
        console.warn('Gagal memuat kategori dari Google Places:', e);
      } finally {
        this.isNearMeLoading = false;
      }
    }
    this.render();
  },

  /**
   * Mengubah metode pengurutan
   */
  setNearMeSortBy(sort) {
    this.nearMeSortBy = sort;
    this.render();
  },

  /**
   * Mengubah titik lokasi manual untuk simulasi/pengujian instan
   */
  async setNearMeManualLocation(lat, lng, label) {
    if (!window.GooglePlacesService) return;
    this.isNearMeLoading = true;
    const gps = GooglePlacesService.setManualLocation(lat, lng, label);
    this.userGps = gps;
    this.isGpsActive = true;

    if (typeof RecommendationService !== 'undefined') {
      RecommendationService.setCenterCoordinates(lat, lng);
    }

    if (typeof MapController !== 'undefined') {
      MapController.renderUserLocation(lat, lng, label, 3500);
      MapController.panTo(lat, lng, 14);
    }

    try {
      const places = await GooglePlacesService.fetchPlacesNearLocation(lat, lng, 3000, this.nearMeCategoryFilter || 'all');
      if (places && places.length > 0) {
        this.mergeGooglePlaces(places, gps);
      }
      this.recalculateAllDistances(lat, lng);
    } catch (e) {
      console.warn('Gagal memperbarui tempat manual:', e);
    } finally {
      this.isNearMeLoading = false;
    }

    this.showToast(`📍 Lokasi diubah ke: ${label}`);
    this.render();
  },

  // ==================== HELP CENTER & EDUKASI (Req 6) ====================
  renderHelpCenterView(container) {
    const isEn = typeof I18nService !== 'undefined' && I18nService.getLanguage() === 'en';
    const faqs = [
      {
        cat: 'general',
        q: isEn ? 'How does MAMPIR calculate recommendations for me?' : 'Bagaimana MAMPIR menentukan rekomendasi kafe terbaik untuk saya?',
        a: isEn
          ? 'MAMPIR uses a hybrid content-based recommendation algorithm that analyzes budget alignment, facility preferences (WiFi, plugs, AC), distance from Purwokerto Square, customer ratings, and your browsing activity history.'
          : 'MAMPIR menggunakan algoritma hybrid content-based recommendation yang menggabungkan kesesuaian anggaran, ketersediaan fasilitas (WiFi, colokan, AC), jarak dari Alun-Alun Purwokerto, rating pengunjung, dan riwayat tempat yang sering Anda jelajahi.'
      },
      {
        cat: 'filter',
        q: isEn ? 'How does the budget filter work?' : 'Bagaimana cara kerja filter anggaran per orang?',
        a: isEn
          ? 'You can set your maximum budget per person from Rp 10.000 to Rp 100.000 via the "Filter Budget" button. Places with average prices within your budget receive higher priority and special savings badges.'
          : 'Anda dapat menentukan batas anggaran per orang dari Rp 10.000 hingga Rp 100.000 melalui tombol "Filter Budget". Tempat yang rata-rata harganya sesuai atau di bawah anggaran Anda akan diprioritaskan dengan skor rekomendasi lebih tinggi dan badge hemat.'
      },
      {
        cat: 'contact',
        q: isEn ? 'How do I contact cafe managers directly?' : 'Bagaimana cara menghubungi pengelola kafe secara langsung?',
        a: isEn
          ? 'Open any cafe detail modal, then click the green "Contact Manager" button. You will be directed straight to the manager’s official WhatsApp chat with an automated greeting without exposing private phone numbers.'
          : 'Buka modal detail kafe mana saja, lalu klik tombol hijau "Hubungi Pengelola". Anda akan langsung diarahkan ke chat WhatsApp resmi admin kafe tersebut dengan pesan pembuka otomatis tanpa menampilkan nomor pribadi secara terbuka.'
      },
      {
        cat: 'partner',
        q: isEn ? 'How can cafe owners list or update their cafe on MAMPIR?' : 'Bagaimana jika pengelola ingin mendaftarkan atau memperbarui data kafe di MAMPIR?',
        a: isEn
          ? 'Cafe owners can easily contact the MAMPIR Helpdesk directly via WhatsApp. Our team will verify and update your operating hours, menu highlights, and photos within 24 hours.'
          : 'Pengelola kafe dapat menghubungi Helpdesk MAMPIR secara langsung via WhatsApp. Tim kami akan memverifikasi dan memperbarui data jam buka, menu unggulan, hingga foto kafe dalam 1x24 jam.'
      },
      {
        cat: 'general',
        q: isEn ? 'Which regions are covered by MAMPIR?' : 'Wilayah mana saja yang dicakup oleh MAMPIR?',
        a: isEn
          ? 'MAMPIR covers Purwokerto City, Baturraden mountain slope cafes, North Purwokerto (Unsoed student hub), Sokaraja culinary center, East Purwokerto & Sumbang, as well as West & South Purwokerto.'
          : 'MAMPIR mencakup Purwokerto Kota, Baturraden (lereng Gunung Slamet & kafe alam), Purwokerto Utara (kawasan mahasiswa Unsoed), Sokaraja (pusat kuliner & soto), Purwokerto Timur & Sumbang, serta Purwokerto Barat & Selatan.'
      }
    ];

    container.innerHTML = `
      <div class="help-center-wrapper">
        <div>
          <h2 class="section-title">❓ ${typeof I18nService !== 'undefined' ? I18nService.t('help_title') : 'Pusat Bantuan & Edukasi MAMPIR'}</h2>
          <p style="font-size: 13px; color: var(--text-secondary); margin-top: 4px;">${typeof I18nService !== 'undefined' ? I18nService.t('help_subtitle') : 'Panduan lengkap jelajah kuliner dan informasi aplikasi MAMPIR Purwokerto.'}</p>
        </div>

        <div class="faq-search-box">
          <span>🔍</span>
          <input type="text" id="faq-search-input" placeholder="${typeof I18nService !== 'undefined' ? I18nService.t('help_search_ph') : 'Cari pertanyaan bantuan atau panduan...'}" oninput="window.App.filterFaqs(this.value)" />
        </div>

        <div class="faq-accordion-list" id="faq-accordion-list">
          ${faqs.map((f, idx) => `
            <div class="faq-accordion-item" id="faq-item-${idx}">
              <div class="faq-accordion-header" onclick="document.getElementById('faq-item-${idx}').classList.toggle('open')">
                <span>💡 ${f.q}</span>
                <span class="faq-arrow" style="transition: transform 0.2s;">▼</span>
              </div>
              <div class="faq-accordion-body">
                ${f.a}
              </div>
            </div>
          `).join('')}
        </div>

        <!-- Callout Banner Helpdesk -->
        <div class="mitra-callout-card">
          <h3 style="font-size: 16px; font-weight: 800; color: var(--text-primary); display: flex; align-items: center; gap: 8px;">
            🤝 ${typeof I18nService !== 'undefined' ? I18nService.t('mitra_guide_box_title') : 'Butuh Bantuan atau Ingin Mendaftarkan Kafe?'}
          </h3>
          <p style="font-size: 13px; color: var(--text-secondary); line-height: 1.5;">
            ${typeof I18nService !== 'undefined' ? I18nService.t('mitra_guide_box_desc') : 'Hubungi tim layanan bantuan resmi MAMPIR via WhatsApp untuk pertanyaan seputar aplikasi atau informasi pendaftaran direktori kafe.'}
          </p>
          <div style="display: flex; gap: 10px; flex-wrap: wrap; margin-top: 6px;">
            <a href="https://wa.me/6281234567890?text=${encodeURIComponent('Halo Helpdesk MAMPIR, saya tertarik mendaftarkan / memperbarui data kafe saya:')}" target="_blank"
               class="btn-cta-whatsapp" style="text-decoration: none;">
              💬 ${typeof I18nService !== 'undefined' ? I18nService.t('btn_contact_support') : 'Hubungi Helpdesk MAMPIR (WhatsApp)'}
            </a>
          </div>
        </div>
      </div>
    `;
  },

  filterFaqs(query) {
    const clean = (query || '').toLowerCase().trim();
    document.querySelectorAll('.faq-accordion-item').forEach(item => {
      const text = item.textContent.toLowerCase();
      item.style.display = text.includes(clean) ? 'block' : 'none';
    });
  },

  handleGuestLogin() {
    AuthService.signInAsGuest(this.selectedRegion);
    this.closeModal('modal-auth');
    this.updateUserProfileUI();
    this.showToast(window.t('toast_guest', 'Masuk sebagai Tamu.'));
    this.render();
  },

  logout() {
    AuthService.signOut();
    this.updateUserProfileUI();
    this.showToast(window.t('toast_logged_out', 'Berhasil keluar.'));
    this.switchView('beranda');
  },

  updateUserProfileUI() {
    const session = StorageService.getUserSession();
    const nameEl = document.getElementById('user-profile-name');
    if (nameEl) nameEl.textContent = session.name;
  },

  // ==================== THEME ====================
  setTheme(theme) {
    StorageService.setTheme(theme);
    this.applyTheme(theme);
    this.render();
  },

  applyTheme(theme) {
    const isLight = theme === 'Terang';
    document.documentElement.setAttribute('data-theme', isLight ? 'light' : 'dark');
    const iconEl = document.getElementById('theme-icon');
    if (iconEl) iconEl.textContent = isLight ? '☀️' : '🌙';
  },

  // ==================== NOTIFICATION CENTER & CALENDAR (Req 7) ====================
  initNotificationCenter() {
    this.updateNotificationBadge();
    const btn = document.getElementById('btn-notifications');
    if (btn) {
      btn.onclick = (e) => {
        this.toggleNotificationPopover(e);
      };
    }
    document.addEventListener('click', (e) => {
      const wrapper = document.getElementById('notification-wrapper');
      const popover = document.getElementById('notification-popover');
      if (popover && wrapper && !wrapper.contains(e.target)) {
        popover.classList.remove('active');
      }
    });
  },

  updateNotificationBadge() {
    const count = StorageService.getUnreadNotificationCount();
    const badge = document.getElementById('notification-unread-badge');
    if (badge) {
      badge.style.display = count > 0 ? 'flex' : 'none';
      badge.textContent = count > 9 ? '9+' : count.toString();
    }
  },

  toggleNotificationPopover(e) {
    if (e && e.stopPropagation) e.stopPropagation();
    const popover = document.getElementById('notification-popover');
    if (!popover) return;
    const isOpen = popover.classList.contains('active');
    if (isOpen) {
      popover.classList.remove('active');
    } else {
      this.renderNotificationsList();
      popover.classList.add('active');
    }
  },

  renderNotificationsList() {
    const container = document.getElementById('notif-items-list');
    if (!container) return;
    const notifs = StorageService.getNotifications();

    if (!notifs || !Array.isArray(notifs) || notifs.length === 0) {
      container.innerHTML = `
        <div class="notif-empty">
          <div style="font-size: 28px; margin-bottom: 6px;">🔔</div>
          <p>${typeof I18nService !== 'undefined' ? I18nService.t('notif_empty') : 'Belum ada notifikasi baru saat ini.'}</p>
        </div>
      `;
      return;
    }

    container.innerHTML = notifs.map(n => {
      const icon = n.category === 'Live Music' ? '🎵'
        : n.category === 'Workshop' ? '☕'
        : n.category === 'Pengingat' ? '⏰'
        : n.category === 'Nonton Bareng' ? '⚽'
        : '🏷️';

      return `
        <div class="notif-item ${!n.read ? 'unread' : ''}" onclick="window.App.handleClickNotification('${n.id}', '${n.placeId}')">
          <div class="notif-icon-badge">${icon}</div>
          <div style="flex: 1; padding-right: 12px;">
            <div style="font-size: 13px; font-weight: 700; color: var(--text-primary); margin-bottom: 2px;">
              ${n.title}
            </div>
            <p style="font-size: 11px; color: var(--text-secondary); line-height: 1.4; margin: 0 0 4px 0;">
              ${n.message}
            </p>
            <div style="font-size: 10px; color: var(--text-muted); display: flex; align-items: center; gap: 6px;">
              <span>📍 ${n.placeName || 'Kafe Purwokerto'}</span>
              <span>•</span>
              <span>${n.date || 'Baru saja'}</span>
            </div>
          </div>
          ${!n.read ? '<div class="notif-unread-dot"></div>' : ''}
        </div>
      `;
    }).join('');
  },

  handleClickNotification(notifId, placeId) {
    StorageService.markNotificationRead(notifId);
    this.updateNotificationBadge();
    const popover = document.getElementById('notification-popover');
    if (popover) popover.classList.remove('active');
    if (placeId) {
      this.openPlaceDetail(placeId);
      setTimeout(() => {
        const eventsEl = document.querySelector('.cafe-events-wrapper');
        if (eventsEl) {
          eventsEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
          eventsEl.style.boxShadow = '0 0 20px rgba(245, 158, 11, 0.6)';
          eventsEl.style.borderColor = 'var(--accent-orange)';
          setTimeout(() => {
            eventsEl.style.boxShadow = '';
          }, 2000);
        }
      }, 300);
    }
  },

  markAllNotificationsRead() {
    StorageService.markAllNotificationsRead();
    this.updateNotificationBadge();
    this.renderNotificationsList();
    this.showToast(window.t('notif_toast_all_read', 'Semua notifikasi telah ditandai dibaca.'));
  },

  toggleEventReminder(eventId, placeId) {
    const events = StorageService.getCafeEvents();
    const event = events.find(e => e.id === eventId);
    if (!event) return;

    const isSet = StorageService.toggleEventReminder(event);
    this.updateNotificationBadge();

    // Update UI tombol
    const btn = document.getElementById(`btn-remind-${eventId}`);
    if (btn) {
      btn.classList.toggle('active', isSet);
      btn.innerHTML = isSet
        ? window.t('btn_reminder_active', '✅ Pengingat Terpasang')
        : window.t('btn_set_reminder', '⏰ Pasang Pengingat');
    }

    if (isSet) {
      this.showToast(window.t('toast_reminder_set', 'Pengingat agenda berhasil dipasang!'));
      // Request Web Notification permission jika didukung
      if ('Notification' in window && Notification.permission === 'default') {
        Notification.requestPermission();
      }
    } else {
      this.showToast(window.t('toast_reminder_cancelled', 'Pengingat agenda dinonaktifkan.'));
    }
  },

  openCalendarExportModal(eventId, placeId) {
    const events = StorageService.getCafeEvents();
    const event = events.find(e => e.id === eventId);
    const place = this.getPlaceById(placeId || event?.placeId);
    if (!event) return;

    const modal = document.getElementById('modal-calendar-export');
    const body = document.getElementById('modal-calendar-body');
    if (!modal || !body) return;

    const gcalUrl = this.generateGoogleCalendarUrl(event, place);

    body.innerHTML = `
      <div style="display: flex; flex-direction: column; gap: 14px;">
        <div style="padding: 12px; background: rgba(255, 183, 77, 0.1); border-radius: var(--radius-sm); border: 1px solid rgba(255, 183, 77, 0.3);">
          <span class="cafe-event-badge">${event.badge || event.category}</span>
          <h4 style="font-size: 15px; font-weight: 800; margin: 4px 0;">${event.title}</h4>
          <div style="font-size: 12px; color: var(--accent-orange); margin-bottom: 4px; font-weight: 600;">⏰ ${event.date}</div>
          <p style="font-size: 12px; color: var(--text-secondary); margin: 0;">📍 ${place?.name || event.placeName}, Purwokerto</p>
        </div>

        <p style="font-size: 13px; color: var(--text-secondary); margin: 0;">
          ${window.t('cal_modal_sub', 'Pilih metode integrasi ke kalender Anda agar tidak ketinggalan acara:')}
        </p>

        <div class="calendar-options-grid">
          <!-- Google Calendar -->
          <a href="${gcalUrl}" target="_blank" class="calendar-option-card" onclick="window.App.closeModal('modal-calendar-export');">
            <div style="font-size: 24px;">📅</div>
            <div style="flex: 1;">
              <div style="font-weight: 700; font-size: 13px;">${window.t('cal_gcal_title', 'Google Calendar')}</div>
              <small style="font-size: 11px; color: var(--text-secondary);">${window.t('cal_gcal_desc', 'Buka langsung agenda acara di Google Calendar web/aplikasi')}</small>
            </div>
            <span style="font-size: 16px; color: var(--accent-orange);">↗</span>
          </a>

          <!-- Download iCal .ics -->
          <div class="calendar-option-card" onclick="window.App.downloadIcsFile('${event.id}'); window.App.closeModal('modal-calendar-export');">
            <div style="font-size: 24px;">📥</div>
            <div style="flex: 1;">
              <div style="font-weight: 700; font-size: 13px;">${window.t('cal_ics_title', 'Unduh File Kalender (.ics)')}</div>
              <small style="font-size: 11px; color: var(--text-secondary);">${window.t('cal_ics_desc', 'Kompatibel dengan Apple Calendar (iPhone/Mac), Outlook & Android')}</small>
            </div>
            <span style="font-size: 16px; color: var(--accent-orange);">⬇</span>
          </div>

          <!-- Pasang Web Reminder -->
          <div class="calendar-option-card" onclick="window.App.toggleEventReminder('${event.id}', '${place?.id}'); window.App.closeModal('modal-calendar-export');">
            <div style="font-size: 24px;">🔔</div>
            <div style="flex: 1;">
              <div style="font-weight: 700; font-size: 13px;">${window.t('cal_web_title', 'Pasang Pengingat Notifikasi MAMPIR')}</div>
              <small style="font-size: 11px; color: var(--text-secondary);">${window.t('cal_web_desc', 'Simpan jadwal di Pusat Notifikasi akun MAMPIR Anda')}</small>
            </div>
            <span style="font-size: 16px; color: var(--accent-orange);">⭐</span>
          </div>
        </div>
      </div>
    `;

    modal.classList.add('active');
  },

  generateGoogleCalendarUrl(event, place) {
    const title = encodeURIComponent(`${event.title} - ${place?.name || event.placeName}`);
    const details = encodeURIComponent(`${event.description}\n\nTempat: ${place?.name || event.placeName}\nAlamat: ${place?.address || 'Purwokerto'}\nInformasi via MAMPIR App`);
    const location = encodeURIComponent(`${place?.name || event.placeName}, ${place?.address || 'Purwokerto, Jawa Tengah'}`);

    const now = new Date();
    now.setDate(now.getDate() + 1);
    const y = now.getFullYear();
    const m = String(now.getMonth() + 1).padStart(2, '0');
    const d = String(now.getDate()).padStart(2, '0');
    const dates = `${y}${m}${d}T123000Z/${y}${m}${d}T150000Z`;

    return `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${title}&details=${details}&location=${location}&dates=${dates}`;
  },

  downloadIcsFile(eventId) {
    const events = StorageService.getCafeEvents();
    const event = events.find(e => e.id === eventId);
    if (!event) return;

    const now = new Date();
    now.setDate(now.getDate() + 1);
    const y = now.getFullYear();
    const m = String(now.getMonth() + 1).padStart(2, '0');
    const d = String(now.getDate()).padStart(2, '0');
    const dtStart = `${y}${m}${d}T123000Z`;
    const dtEnd = `${y}${m}${d}T150000Z`;

    const icsContent = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//MAMPIR Purwokerto//Event Calendar//ID',
      'CALSCALE:GREGORIAN',
      'BEGIN:VEVENT',
      `UID:${event.id}@mampir.app`,
      `DTSTAMP:${y}${m}${d}T000000Z`,
      `DTSTART:${dtStart}`,
      `DTEND:${dtEnd}`,
      `SUMMARY:${event.title} - ${event.placeName}`,
      `DESCRIPTION:${event.description.replace(/\n/g, '\\n')}`,
      `LOCATION:${event.placeName}, Purwokerto`,
      'STATUS:CONFIRMED',
      'BEGIN:VALARM',
      'TRIGGER:-PT1H',
      'ACTION:DISPLAY',
      `DESCRIPTION:Pengingat: ${event.title}`,
      'END:VALARM',
      'END:VEVENT',
      'END:VCALENDAR'
    ].join('\r\n');

    const blob = new Blob([icsContent], { type: 'text/calendar;charset=utf-8' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `mampir-agenda-${event.id}.ics`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    this.showToast(window.t('toast_ics_downloaded', 'File kalender (.ics) berhasil diunduh!'));
  },

  // ==================== TOAST NOTIFICATION ====================
  showToast(msg) {
    let toast = document.getElementById('mampir-toast');
    if (!toast) {
      toast = document.createElement('div');
      toast.id = 'mampir-toast';
      toast.style.cssText = `
        position: fixed;
        bottom: 24px;
        right: 24px;
        background: rgba(13, 19, 38, 0.95);
        color: #FFFFFF;
        border: 1px solid var(--accent-gold);
        padding: 12px 20px;
        border-radius: var(--radius-md);
        box-shadow: var(--shadow-glow);
        font-size: 13px;
        font-weight: 600;
        z-index: 3000;
        transition: opacity 0.3s ease;
      `;
      document.body.appendChild(toast);
    }
    toast.textContent = msg;
    toast.style.opacity = '1';
    setTimeout(() => {
      toast.style.opacity = '0';
    }, 2500);
  }
};

// Auto start saat DOM loaded
document.addEventListener('DOMContentLoaded', () => {
  window.App.init();
});

