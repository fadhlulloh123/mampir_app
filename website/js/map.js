/**
 * MAMPIR Web - Leaflet Interactive Map Controller (Powered by Google Maps API & Tiles)
 * Mengelola peta live dengan layer Google Maps, marker tempat kuliner,
 * lokasi GPS pengguna dengan radar radius, dan sinkronisasi navigasi rute Google Maps.
 */
const MapController = {
  map: null,
  markers: {},
  activePlaceId: null,
  userLocationMarker: null,
  userLocationCircle: null,
  tileLayers: {},

  init(containerId = 'live-map-container') {
    const el = document.getElementById(containerId);
    if (!el) return;

    if (this.map) {
      this.map.remove();
      this.map = null;
      this.markers = {};
      this.userLocationMarker = null;
      this.userLocationCircle = null;
    }

    // Default center Alun-Alun Purwokerto
    const center = [AppConfig.centerCoordinates.lat, AppConfig.centerCoordinates.lng];
    this.map = L.map(containerId, {
      center: center,
      zoom: AppConfig.centerCoordinates.zoom,
      zoomControl: true,
      scrollWheelZoom: true
    });

    // 1. Google Maps Roadmap Layer (Resmi & Akurat untuk Purwokerto)
    const googleRoadmap = L.tileLayer('https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', {
      maxZoom: 20,
      subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
      attribution: '&copy; Google Maps • MAMPIR Purwokerto'
    });

    // 2. Google Maps Hybrid / Satelit Layer
    const googleHybrid = L.tileLayer('https://{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}', {
      maxZoom: 20,
      subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
      attribution: '&copy; Google Maps Satelit • MAMPIR Purwokerto'
    });

    // 3. Google Maps Relief / Medan Layer
    const googleTerrain = L.tileLayer('https://{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}', {
      maxZoom: 20,
      subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
      attribution: '&copy; Google Maps Relief • MAMPIR Purwokerto'
    });

    // 4. OpenStreetMap Fallback Layer
    const osmLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap contributors'
    });

    // Pasang Google Maps Roadmap sebagai default
    googleRoadmap.addTo(this.map);

    this.tileLayers = {
      roadmap: googleRoadmap,
      hybrid: googleHybrid,
      terrain: googleTerrain,
      osm: osmLayer
    };

    // Layer Switcher Controller di sudut kanan atas peta
    L.control.layers({
      '🗺️ Google Maps': googleRoadmap,
      '🛰️ Google Satelit': googleHybrid,
      '⛰️ Google Relief': googleTerrain,
      '🌐 OpenStreetMap': osmLayer
    }, null, { position: 'topright' }).addTo(this.map);

    // Inisialisasi custom marker icon
    this.createCustomMarkerIcon();
  },

  createCustomMarkerIcon(options = false) {
    const opts = typeof options === 'boolean' ? { isActive: options } : (options || {});
    const isActive = !!opts.isActive;
    const isBestMatch = !!opts.isBestMatch;
    const isOutBudget = !!opts.isOutBudget;
    const isGoogleLive = !!opts.isGoogleLive;

    let bg = '#F57C00';
    let border = '#1A233A';
    let size = 32;
    let iconChar = '📍';
    let extraStyle = '';

    if (isActive) {
      bg = '#FF9800';
      border = '#FFFFFF';
      size = 40;
      iconChar = '📍';
      extraStyle = 'box-shadow: 0 0 16px rgba(255, 152, 0, 0.9); z-index: 1000;';
    } else if (isBestMatch) {
      bg = '#EA580C';
      border = '#FFD700';
      size = 38;
      iconChar = '✨';
      extraStyle = 'box-shadow: 0 0 14px rgba(255, 215, 0, 0.85);';
    } else if (isGoogleLive) {
      bg = '#2563EB'; // Blue accent for Google Maps live detected places
      border = '#FFFFFF';
      size = 34;
      iconChar = '🍴';
      extraStyle = 'box-shadow: 0 0 12px rgba(37, 99, 235, 0.7);';
    } else if (isOutBudget) {
      bg = '#94A3B8';
      border = '#64748B';
      size = 26;
      iconChar = '📍';
      extraStyle = 'opacity: 0.45; filter: grayscale(0.6);';
    }

    return L.divIcon({
      className: `mampir-map-pin ${isBestMatch ? 'marker-best-match' : ''} ${isOutBudget ? 'marker-out-budget' : ''}`,
      html: `
        <div style="
          width: ${size}px;
          height: ${size}px;
          background: ${bg};
          border: 2px solid ${border};
          border-radius: 50% 50% 50% 0;
          transform: rotate(-45deg);
          box-shadow: 0 4px 12px rgba(0,0,0,0.35);
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: all 0.25s ease;
          ${extraStyle}
        ">
          <span style="
            transform: rotate(45deg);
            color: #FFFFFF;
            font-size: ${size > 34 ? '16px' : (size < 30 ? '11px' : '13px')};
            font-weight: bold;
          ">${iconChar}</span>
        </div>
      `,
      iconSize: [size, size],
      iconAnchor: [size / 2, size]
    });
  },

  /**
   * Menampilkan titik lokasi GPS pengguna beserta radar radius deteksi
   */
  renderUserLocation(lat, lng, label = 'Lokasi GPS Anda', radiusMeters = 3000) {
    if (!this.map) return;

    this.clearUserLocation();

    // 1. Radar Circle Jangkauan Deteksi Tempat Makan
    this.userLocationCircle = L.circle([lat, lng], {
      color: '#2563EB',
      fillColor: '#3B82F6',
      fillOpacity: 0.12,
      weight: 1.5,
      dashArray: '4, 4',
      radius: radiusMeters
    }).addTo(this.map);

    // 2. Pulsing Radar Dot Marker
    const gpsIcon = L.divIcon({
      className: 'mampir-user-gps-marker',
      html: `
        <div class="gps-pulse-wrapper">
          <div class="gps-pulse-ring"></div>
          <div class="gps-dot"></div>
        </div>
      `,
      iconSize: [28, 28],
      iconAnchor: [14, 14]
    });

    this.userLocationMarker = L.marker([lat, lng], {
      icon: gpsIcon,
      zIndexOffset: 2000
    }).addTo(this.map);

    this.userLocationMarker.bindPopup(`
      <div style="font-size: 13px; font-weight: 700; color: #0F172A; text-align: center; padding: 4px;">
        <span style="font-size: 18px;">📍</span>
        <div style="margin-top: 4px;">${label}</div>
        <div style="font-size: 11px; font-weight: normal; color: #64748B; margin-top: 2px;">
          Koordinat: ${lat.toFixed(4)}, ${lng.toFixed(4)}
        </div>
        <div style="margin-top: 6px; font-size: 10px; color: #2563EB; font-weight: 700; background: rgba(37,99,235,0.1); padding: 3px 8px; border-radius: 99px;">
          📡 Area Deteksi Google Maps (${(radiusMeters / 1000).toFixed(1)} km)
        </div>
      </div>
    `, { className: 'mampir-gps-popup' });
  },

  clearUserLocation() {
    if (this.userLocationMarker && this.map) {
      this.map.removeLayer(this.userLocationMarker);
      this.userLocationMarker = null;
    }
    if (this.userLocationCircle && this.map) {
      this.map.removeLayer(this.userLocationCircle);
      this.userLocationCircle = null;
    }
  },

  renderMarkers(places, onSelectPlace, budgetFilterContext = null) {
    if (!this.map) return;

    // Bersihkan marker lama tempat
    Object.values(this.markers).forEach(m => this.map.removeLayer(m));
    this.markers = {};

    const isBudgetActive = budgetFilterContext && budgetFilterContext.isBudgetActive;
    const maxBudget = budgetFilterContext ? budgetFilterContext.userBudget : null;

    // Dapatkan koordinat GPS user jika ada untuk URL rute
    const userGps = (window.GooglePlacesService && window.GooglePlacesService.currentGps)
      ? window.GooglePlacesService.currentGps
      : null;

    places.forEach(place => {
      if (!place.latitude || !place.longitude) return;

      const isOutBudget = isBudgetActive && maxBudget && (place.min_price || 0) > maxBudget;
      const isBestMatch = isBudgetActive && !isOutBudget && !!place.isBestBudgetMatch;
      const isGoogleLive = !!place.isGoogleLive;

      const marker = L.marker([place.latitude, place.longitude], {
        icon: this.createCustomMarkerIcon({
          isActive: false,
          isBestMatch,
          isOutBudget,
          isBudgetActive,
          isGoogleLive
        }),
        opacity: isOutBudget ? 0.35 : 1.0
      }).addTo(this.map);

      // Simpan metadata di marker untuk highlight
      marker.placeMeta = { isBestMatch, isOutBudget, isBudgetActive, isGoogleLive };

      const catLabel = typeof I18nService !== 'undefined'
        ? I18nService.translateCategory(place.category || 'Cafe')
        : (place.category || 'Cafe');
      const detailLabel = typeof window.t === 'function' ? window.t('view_detail', 'Lihat Detail') : 'Lihat Detail';
      const routeLabel = typeof window.t === 'function' ? window.t('route_label', 'Rute Google Maps ↗') : 'Rute Google Maps ↗';
      const bestMatchLabel = typeof window.t === 'function' ? window.t('budget_badge_best_match', 'Pas di Budget') : 'Pas di Budget';
      const canGetPrefix = typeof window.t === 'function' ? window.t('budget_can_get_prefix', 'Bisa dapet:') : 'Bisa dapet:';

      // Rute Google Maps terintegrasi
      let routeUrl = `https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}`;
      if (userGps && userGps.lat && userGps.lng) {
        routeUrl += `&origin=${userGps.lat},${userGps.lng}`;
      }

      // Popup Content
      const popupHtml = `
        <div class="map-popup-card">
          <img src="${place.image_url || 'assets/images/beranda_mockup.jpeg'}" alt="${place.name}" class="map-popup-img" />
          <div class="map-popup-body">
            <div class="map-popup-header">
              <span class="badge-cat">${catLabel}</span>
              ${isGoogleLive ? '<span class="badge-google-pill" style="background:#2563EB; color:#fff; font-size:10px; font-weight:700; padding:2px 6px; border-radius:4px;">🗺️ Google Maps Live</span>' : ''}
              ${isBestMatch ? `<span class="badge-best-budget">✨ ${bestMatchLabel}</span>` : ''}
              <span class="badge-rating">⭐ ${place.rating || 4.5}</span>
            </div>
            <h4 class="map-popup-title">${place.name}</h4>
            <p class="map-popup-city">📍 ${place.city || 'Purwokerto'} ${place.distanceFromGps !== undefined ? `• ${place.distanceFromGps} km dari GPS` : ''}</p>
            <p class="map-popup-price">${RecommendationService.formatPrice(place)}</p>
            ${place.affordableCombo ? `
              <div class="map-popup-combo">
                💡 ${canGetPrefix} <strong>${place.affordableCombo.text}</strong> <span style="color: var(--accent-orange); font-weight: 700;">(${place.affordableCombo.priceFormatted})</span>
              </div>
            ` : ''}
            <div class="map-popup-actions">
              <button class="btn-popup-detail" onclick="window.App.openPlaceDetail('${place.id}')">${detailLabel}</button>
              <a href="${routeUrl}" target="_blank" class="btn-popup-route">${routeLabel}</a>
            </div>
          </div>
        </div>
      `;

      marker.bindPopup(popupHtml, { maxWidth: 300, className: 'mampir-leaflet-popup' });

      marker.on('click', () => {
        this.highlightMarker(place.id);
        if (onSelectPlace) onSelectPlace(place);

        // Sinkronisasi: scroll & highlight kartu di daftar (Gojek-style & Beranda)
        const cardEl = document.getElementById(`nearme-card-${place.id}`) || document.getElementById(`place-card-${place.id}`);
        if (cardEl) {
          cardEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
          cardEl.classList.add('card-map-highlight');
          setTimeout(() => cardEl.classList.remove('card-map-highlight'), 1800);
        }
      });

      this.markers[place.id] = marker;
    });
  },

  /**
   * Menyesuaikan tampilan bounds peta secara dinamis agar mencakup pengguna & tempat kuliner
   */
  fitBoundsToPlacesAndUser(places = [], userGps = null) {
    if (!this.map) return;
    const points = [];
    if (userGps && typeof userGps.lat === 'number' && typeof userGps.lng === 'number') {
      points.push([userGps.lat, userGps.lng]);
    }
    (places || []).forEach(p => {
      if (typeof p.latitude === 'number' && typeof p.longitude === 'number') {
        points.push([p.latitude, p.longitude]);
      }
    });

    if (points.length === 1) {
      this.map.setView(points[0], 15, { animate: true });
    } else if (points.length > 1) {
      const bounds = L.latLngBounds(points);
      this.map.fitBounds(bounds, {
        padding: [45, 45],
        maxZoom: 16,
        animate: true,
        duration: 0.8
      });
    }
  },

  highlightMarker(placeId) {
    // Reset marker sebelumnya
    if (this.activePlaceId && this.markers[this.activePlaceId]) {
      const prevMarker = this.markers[this.activePlaceId];
      const meta = prevMarker.placeMeta || {};
      prevMarker.setIcon(this.createCustomMarkerIcon({
        isActive: false,
        isBestMatch: meta.isBestMatch,
        isOutBudget: meta.isOutBudget,
        isBudgetActive: meta.isBudgetActive,
        isGoogleLive: meta.isGoogleLive
      }));
      prevMarker.setOpacity(meta.isOutBudget ? 0.35 : 1.0);
    }

    this.activePlaceId = placeId;
    if (this.markers[placeId]) {
      const marker = this.markers[placeId];
      const meta = marker.placeMeta || {};
      marker.setIcon(this.createCustomMarkerIcon({
        isActive: true,
        isBestMatch: meta.isBestMatch,
        isOutBudget: false,
        isBudgetActive: meta.isBudgetActive,
        isGoogleLive: meta.isGoogleLive
      }));
      marker.setOpacity(1.0);
      marker.openPopup();
      const pos = marker.getLatLng();
      this.map.panTo(pos, { animate: true, duration: 0.8 });
    }
  },

  panTo(lat, lng, zoom = 15) {
    if (this.map && typeof lat === 'number' && typeof lng === 'number' && !isNaN(lat) && !isNaN(lng)) {
      try {
        this.map.setView([lat, lng], zoom, { animate: true, duration: 0.8 });
      } catch (err) {
        this.map.setView([lat, lng], zoom);
      }
    }
  },

  invalidateSize() {
    if (this.map) {
      setTimeout(() => this.map.invalidateSize(), 200);
    }
  }
};

window.MapController = MapController;
window.MapService = MapController;
