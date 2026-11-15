/**
 * MAMPIR Web - Google Places API (New) & Real-Time Geolocation Service
 * Mengelola deteksi GPS presisi, pencarian tempat terdekat (Near Me ala Gojek),
 * multi-kategori (Restoran, Warung Makan, Cafe, Coffee Shop, Fast Food, Street Food, Nongkrong),
 * status buka/tutup (openNow), dan perhitungan jarak matematis akurat (Haversine).
 */
const GooglePlacesService = {
  currentGps: null,
  isDetecting: false,
  cachedPlaces: {},
  categoryCache: {},

  /**
   * Cek apakah koordinat GPS berada dalam wilayah operasional Purwokerto & Sekitarnya
   * Lat: -7.60 s.d. -7.22 | Lng: 109.05 s.d. 109.42 (Banyumas Raya)
   */
  isWithinPurwokerto(lat, lng) {
    if (typeof lat !== 'number' || typeof lng !== 'number' || isNaN(lat) || isNaN(lng)) return false;
    const bounds = AppConfig.purwokertoBounds || {
      minLat: -7.60,
      maxLat: -7.22,
      minLng: 109.05,
      maxLng: 109.42,
      maxRadiusKm: 28.0
    };

    const inBox = (
      lat >= bounds.minLat &&
      lat <= bounds.maxLat &&
      lng >= bounds.minLng &&
      lng <= bounds.maxLng
    );

    if (inBox) return true;

    // Toleransi radius lingkaran dari titik pusat Alun-Alun
    const distCenter = this.calculateDistanceKm(
      AppConfig.centerCoordinates.lat,
      AppConfig.centerCoordinates.lng,
      lat,
      lng
    );
    return distCenter <= (bounds.maxRadiusKm || 28.0);
  },

  /**
   * Menghitung jarak garis lurus (Haversine formula) dalam kilometer secara matematis
   */
  calculateDistanceKm(lat1, lon1, lat2, lon2) {
    if (typeof lat1 !== 'number' || typeof lon1 !== 'number' || typeof lat2 !== 'number' || typeof lon2 !== 'number') return 0;
    const R = 6371; // Radius bumi dalam km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = (
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2)
    );
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return parseFloat((R * c).toFixed(2));
  },

  /**
   * Format jarak ramah pengguna (Gojek-style: meter jika < 1km, km jika >= 1km)
   */
  formatDistance(distanceKm) {
    if (typeof distanceKm !== 'number' || isNaN(distanceKm)) return '0 m';
    if (distanceKm < 1.0) {
      const meters = Math.round(distanceKm * 1000);
      return `${meters} m`;
    }
    return `${distanceKm.toFixed(1)} km`;
  },

  /**
   * Mendeteksi lokasi GPS pengguna secara real-time via Geolocation API browser
   */
  async detectGpsLocation(forceRefresh = false) {
    if (!forceRefresh && this.currentGps) {
      return this.currentGps;
    }

    this.isDetecting = true;

    return new Promise((resolve) => {
      if (!('geolocation' in navigator)) {
        console.warn('Geolocation API tidak didukung di browser ini.');
        this.currentGps = this.getFallbackPurwokertoGps('Browser tidak mendukung Geolocation', true);
        this.isDetecting = false;
        resolve(this.currentGps);
        return;
      }

      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const lat = pos.coords.latitude;
          const lng = pos.coords.longitude;
          const accuracy = pos.coords.accuracy;
          const inPwt = this.isWithinPurwokerto(lat, lng);

          if (inPwt) {
            this.currentGps = {
              lat: lat,
              lng: lng,
              accuracy: accuracy,
              isWithinPurwokerto: true,
              isSimulated: false,
              permissionDenied: false,
              label: 'Lokasi Anda (Purwokerto)'
            };
          } else {
            // Pengguna berada di luar Purwokerto (misal pengujian dari kota lain)
            this.currentGps = {
              lat: AppConfig.centerCoordinates.lat,
              lng: AppConfig.centerCoordinates.lng,
              actualLat: lat,
              actualLng: lng,
              accuracy: accuracy,
              isWithinPurwokerto: false,
              isSimulated: true,
              permissionDenied: false,
              label: 'Simulasi Alun-Alun (GPS Asli di Luar Purwokerto)'
            };
          }

          this.isDetecting = false;
          resolve(this.currentGps);
        },
        (err) => {
          console.warn('Izin akses lokasi GPS belum diberikan atau timeout:', err.message);
          this.currentGps = this.getFallbackPurwokertoGps('Izin Lokasi Belum Aktif', true);
          this.isDetecting = false;
          resolve(this.currentGps);
        },
        {
          enableHighAccuracy: true,
          timeout: 8000,
          maximumAge: forceRefresh ? 0 : 30000
        }
      );
    });
  },

  /**
   * Mengatur lokasi manual / simulasi titik uji di Purwokerto (Alun-Alun, Unsoed, Baturraden, Sokaraja)
   */
  setManualLocation(lat, lng, label = 'Lokasi Manual') {
    this.currentGps = {
      lat: lat,
      lng: lng,
      accuracy: 25,
      isWithinPurwokerto: this.isWithinPurwokerto(lat, lng),
      isSimulated: true,
      permissionDenied: false,
      label: label
    };
    return this.currentGps;
  },

  getFallbackPurwokertoGps(reason = 'Simulasi Pusat Purwokerto', permissionDenied = false) {
    return {
      lat: AppConfig.centerCoordinates.lat,
      lng: AppConfig.centerCoordinates.lng,
      accuracy: 50,
      isWithinPurwokerto: true,
      isSimulated: true,
      permissionDenied: permissionDenied,
      label: `Alun-Alun Purwokerto (${reason})`
    };
  },

  /**
   * Mengambil tempat kuliner di sekitar koordinat GPS menggunakan Google Places API (New)
   * Mendukung filter radius dan kategori tempat
   */
  async fetchPlacesNearLocation(lat, lng, radius = 3000, category = 'all', force = false) {
    const centerLat = lat || AppConfig.centerCoordinates.lat;
    const centerLng = lng || AppConfig.centerCoordinates.lng;
    const cacheKey = `${centerLat.toFixed(3)}_${centerLng.toFixed(3)}_${radius}_${category}`;

    if (!force && this.cachedPlaces[cacheKey] && this.cachedPlaces[cacheKey].length > 0) {
      return this.cachedPlaces[cacheKey];
    }

    const apiKey = AppConfig.googlePlacesApiKey;
    if (!apiKey) {
      console.warn('Google Places API Key belum dikonfigurasi.');
      return [];
    }

    try {
      let rawPlaces = [];

      // 1. Tentukan query spesifik jika kategori bukan 'all'
      if (category && category !== 'all') {
        rawPlaces = await this.fetchPlacesByCategoryQuery(category, centerLat, centerLng, radius);
      } else {
        // Query searchNearby multi-tipe dengan rankPreference: DISTANCE agar tempat terdekat (30m - 1km) diprioritaskan
        const safeRadius = Math.max(3000.0, Math.min(radius, 25000.0));
        const nearbyUrl = 'https://places.googleapis.com/v1/places:searchNearby';
        const body = {
          includedTypes: [
            'restaurant',
            'indonesian_restaurant',
            'cafe',
            'coffee_shop',
            'fast_food_restaurant',
            'bakery',
            'diner',
            'meal_takeaway'
          ],
          maxResultCount: 20,
          rankPreference: 'DISTANCE',
          locationRestriction: {
            circle: {
              center: { latitude: centerLat, longitude: centerLng },
              radius: safeRadius
            }
          }
        };

        const response = await fetch(nearbyUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.priceLevel,places.primaryType,places.editorialSummary,places.googleMapsUri,places.regularOpeningHours.openNow,places.regularOpeningHours.weekdayDescriptions'
          },
          body: JSON.stringify(body)
        });

        if (response.ok) {
          const data = await response.json();
          rawPlaces = data.places || [];
        }

        // Fallback searchText jika searchNearby sedikit
        if (!rawPlaces || rawPlaces.length < 5) {
          const fallbackList = await this.fetchPlacesBySearchText('tempat makan warung cafe resto Purwokerto', centerLat, centerLng, safeRadius);
          rawPlaces = [...rawPlaces, ...fallbackList];
        }
      }

      // Saring agar hanya tempat makan & minum asli (bukan hotel/penginapan murni)
      const foodKeywords = ['warung', 'makan', 'resto', 'cafe', 'kafe', 'kopi', 'coffee', 'mie', 'soto', 'bakso', 'ayam', 'bebek', 'dapur', 'kedai', 'angkringan', 'bistro', 'pizza', 'burger', 'steak', 'snack', 'bakery', 'roti', 'sepuran', 'gacoan', 'wizzmie', 'kuliner'];
      const nonFoodTypes = ['hotel', 'lodging', 'resort_hotel', 'motel'];

      const validFoodPlaces = (rawPlaces || []).filter(p => {
        const type = (p.primaryType || '').toLowerCase();
        const name = (p.displayName?.text || '').toLowerCase();
        if (nonFoodTypes.includes(type)) {
          return foodKeywords.some(kw => name.includes(kw));
        }
        return true;
      });

      // Deduplikasi berdasarkan Google Place ID atau Koordinat
      const seen = new Set();
      const uniqueList = [];
      for (const p of validFoodPlaces) {
        const key = p.id || `${p.location?.latitude}_${p.location?.longitude}`;
        if (!seen.has(key)) {
          seen.add(key);
          uniqueList.push(p);
        }
      }

      const formatted = uniqueList.map(item => this.mapGooglePlaceToMampir(item, centerLat, centerLng));
      this.cachedPlaces[cacheKey] = formatted;
      return formatted;
    } catch (e) {
      console.warn('Gagal memanggil Google Places API:', e);
      return [];
    }
  },

  /**
   * Mengambil tempat kuliner spesifik per kategori Google Maps
   */
  async fetchPlacesByCategoryQuery(categoryKey, centerLat, centerLng, radius = 5000) {
    const categoryTypesMap = {
      'Cafe': ['cafe', 'coffee_shop'],
      'Coffee Shop': ['coffee_shop', 'cafe'],
      'Restoran': ['restaurant', 'indonesian_restaurant'],
      'Warung Makan': ['diner', 'indonesian_restaurant', 'meal_takeaway'],
      'Tempat Nongkrong': ['cafe', 'coffee_shop', 'diner'],
      'Fast Food': ['fast_food_restaurant', 'meal_takeaway'],
      'Street Food': ['diner', 'meal_takeaway']
    };

    const types = categoryTypesMap[categoryKey];
    if (types && types.length > 0) {
      try {
        const nearbyUrl = 'https://places.googleapis.com/v1/places:searchNearby';
        const safeRadius = Math.max(3000.0, Math.min(radius, 25000.0));
        const body = {
          includedTypes: types,
          maxResultCount: 20,
          rankPreference: 'DISTANCE',
          locationRestriction: {
            circle: {
              center: { latitude: centerLat, longitude: centerLng },
              radius: safeRadius
            }
          }
        };
        const response = await fetch(nearbyUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': AppConfig.googlePlacesApiKey,
            'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.priceLevel,places.primaryType,places.editorialSummary,places.googleMapsUri,places.regularOpeningHours.openNow,places.regularOpeningHours.weekdayDescriptions'
          },
          body: JSON.stringify(body)
        });
        if (response.ok) {
          const data = await response.json();
          if (data.places && data.places.length > 0) {
            return data.places;
          }
        }
      } catch (err) {
        console.warn('searchNearby category error:', err);
      }
    }

    const categoryQueryMap = {
      'Restoran': 'restoran rumah makan keluarga Purwokerto',
      'Warung Makan': 'warung makan soto bakso mendoan Purwokerto',
      'Cafe': 'cafe kafe hits Purwokerto',
      'Coffee Shop': 'coffee shop kedai kopi roastery Purwokerto',
      'Tempat Nongkrong': 'tempat nongkrong cafe warkop Purwokerto',
      'Fast Food': 'fast food burger fried chicken Purwokerto',
      'Street Food': 'street food angkringan kuliner malam kaki lima Purwokerto'
    };

    const q = categoryQueryMap[categoryKey] || `${categoryKey} Purwokerto`;
    return this.fetchPlacesBySearchText(q, centerLat, centerLng, radius);
  },

  /**
   * Endpoint searchText untuk pencarian teks di sekitar koordinat
   */
  async fetchPlacesBySearchText(query, centerLat, centerLng, radius = 8000) {
    const apiKey = AppConfig.googlePlacesApiKey;
    const url = 'https://places.googleapis.com/v1/places:searchText';

    const body = {
      textQuery: query.includes('Purwokerto') ? query : `${query} Purwokerto`,
      locationBias: {
        circle: {
          center: { latitude: centerLat, longitude: centerLng },
          radius: Math.min(radius, 20000.0)
        }
      },
      languageCode: 'id',
      maxResultCount: 20
    };

    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.priceLevel,places.primaryType,places.editorialSummary,places.googleMapsUri,places.regularOpeningHours.openNow,places.regularOpeningHours.weekdayDescriptions'
      },
      body: JSON.stringify(body)
    });

    if (!res.ok) return [];
    const data = await res.json();
    return data.places || [];
  },

  /**
   * Konversi data Google Places API (New) ke struktur objek Tempat MAMPIR
   */
  mapGooglePlaceToMampir(item, userLat, userLng) {
    const rawId = item.id || `${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
    const id = `gplace_${rawId}`;
    const name = item.displayName?.text || 'Tempat Kuliner Purwokerto';
    const lat = item.location?.latitude || userLat;
    const lng = item.location?.longitude || userLng;
    const address = item.formattedAddress || 'Purwokerto, Banyumas, Jawa Tengah';
    const rating = typeof item.rating === 'number' ? parseFloat(item.rating.toFixed(1)) : 4.5;
    const reviewCount = item.userRatingCount || 120;
    const primaryType = item.primaryType || '';
    const mapsUri = item.googleMapsUri || `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(name)}`;

    // Status Buka Sekarang (Open Now) dari Google Places
    const isOpenNow = (typeof item.regularOpeningHours?.openNow === 'boolean')
      ? item.regularOpeningHours.openNow
      : null;

    const weekdayDesc = item.regularOpeningHours?.weekdayDescriptions || [];
    const openHours = weekdayDesc.length ? weekdayDesc[0] : (isOpenNow === true ? 'Buka Sekarang' : (isOpenNow === false ? 'Tutup' : '09.00 - 22.00 WIB'));

    // 1. Tentukan Wilayah Kecamatan dari Alamat Asli
    let city = 'Purwokerto Kota';
    const addrLower = address.toLowerCase();
    if (addrLower.includes('baturraden')) {
      city = 'Baturraden';
    } else if (addrLower.includes('sokaraja')) {
      city = 'Sokaraja';
    } else if (addrLower.includes('sumbang')) {
      city = 'Purwokerto Timur & Sumbang';
    } else if (addrLower.includes('utara') || addrLower.includes('unsoed') || addrLower.includes('grendeng')) {
      city = 'Purwokerto Utara (Unsoed)';
    } else if (addrLower.includes('timur')) {
      city = 'Purwokerto Timur & Sumbang';
    } else if (addrLower.includes('barat') || addrLower.includes('kober') || addrLower.includes('karanglewas')) {
      city = 'Purwokerto Barat & Selatan';
    } else if (addrLower.includes('selatan') || addrLower.includes('berkoh') || addrLower.includes('teluk')) {
      city = 'Purwokerto Barat & Selatan';
    }

    // 2. Tentukan Kategori Tempat Lengkap Sesuai Permintaan Pengguna:
    // Restoran, Warung Makan, Cafe, Coffee Shop, Tempat Nongkrong, Fast Food, Street Food
    let category = 'Restoran';
    const nameLower = name.toLowerCase();
    const typeLower = primaryType.toLowerCase();

    if (
      nameLower.includes('fast food') ||
      nameLower.includes('fried chicken') ||
      nameLower.includes('burger') ||
      nameLower.includes('pizza') ||
      nameLower.includes('gacoan') ||
      nameLower.includes('wizzmie') ||
      nameLower.includes('mcdonald') ||
      nameLower.includes('kfc') ||
      nameLower.includes('richeese') ||
      nameLower.includes('kaf fried') ||
      typeLower.includes('fast_food')
    ) {
      category = 'Fast Food';
    } else if (
      nameLower.includes('angkringan') ||
      nameLower.includes('kaki lima') ||
      nameLower.includes('kuliner malam') ||
      nameLower.includes('street food') ||
      nameLower.includes('pasar manis') ||
      nameLower.includes('dongkal') ||
      nameLower.includes('martabak') ||
      nameLower.includes('gorengan') ||
      nameLower.includes('pentol') ||
      typeLower.includes('street_food')
    ) {
      category = 'Street Food';
    } else if (
      nameLower.includes('coffee') ||
      nameLower.includes('coffe') ||
      nameLower.includes('kopi') ||
      nameLower.includes('kedai kopi') ||
      nameLower.includes('roastery') ||
      typeLower.includes('coffee_shop')
    ) {
      category = 'Coffee Shop';
    } else if (
      nameLower.includes('cafe') ||
      nameLower.includes('kafe') ||
      nameLower.includes('eatery') ||
      nameLower.includes('bistro') ||
      typeLower.includes('cafe')
    ) {
      category = 'Cafe';
    } else if (
      nameLower.includes('nongkrong') ||
      nameLower.includes('space') ||
      nameLower.includes('lounge')
    ) {
      category = 'Tempat Nongkrong';
    } else if (
      nameLower.includes('warung') ||
      nameLower.includes('warkop') ||
      nameLower.includes('warmindo') ||
      nameLower.includes('soto') ||
      nameLower.includes('bakso') ||
      nameLower.includes('mendoan') ||
      nameLower.includes('bubur') ||
      nameLower.includes('mie') ||
      nameLower.includes('sate') ||
      nameLower.includes('nasi') ||
      nameLower.includes('bebek') ||
      nameLower.includes('ayam') ||
      nameLower.includes('dapur') ||
      nameLower.includes('kedai') ||
      typeLower.includes('diner') ||
      typeLower.includes('noodle') ||
      typeLower.includes('snack_bar')
    ) {
      category = 'Warung Makan';
    } else {
      category = 'Restoran';
    }

    // 3. Estimasi Rentang Harga berdasarkan PriceLevel Google
    let minPrice = 15000;
    let maxPrice = 35000;
    if (item.priceLevel === 'PRICE_LEVEL_FREE') {
      minPrice = 0;
      maxPrice = 10000;
    } else if (item.priceLevel === 'PRICE_LEVEL_INEXPENSIVE') {
      minPrice = 10000;
      maxPrice = 25000;
    } else if (item.priceLevel === 'PRICE_LEVEL_MODERATE') {
      minPrice = 25000;
      maxPrice = 60000;
    } else if (item.priceLevel === 'PRICE_LEVEL_EXPENSIVE' || item.priceLevel === 'PRICE_LEVEL_VERY_EXPENSIVE') {
      minPrice = 50000;
      maxPrice = 120000;
    }

    // 4. Hitung Jarak Nyata dari Koordinat GPS Pengguna
    const dist = this.calculateDistanceKm(userLat, userLng, lat, lng);

    // 5. Kurasi Gambar Berdasarkan Kategori
    const categoryPhotos = {
      'Cafe': [
        'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80'
      ],
      'Coffee Shop': [
        'https://images.unsplash.com/photo-1511920170033-f8396924c348?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=800&q=80'
      ],
      'Warung Makan': [
        'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80'
      ],
      'Tempat Nongkrong': [
        'https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?auto=format&fit=crop&w=800&q=80'
      ],
      'Fast Food': [
        'https://images.unsplash.com/photo-1561758033-d89a9ad46330?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=800&q=80'
      ],
      'Street Food': [
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80'
      ],
      'Restoran': [
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80'
      ]
    };
    const photoList = categoryPhotos[category] || categoryPhotos['Restoran'];
    const chosenPhoto = photoList[Math.abs(this.hashCode(name)) % photoList.length];

    // 6. Fasilitas Deteksi
    const facilities = ['WiFi', 'Parkir'];
    if (category === 'Cafe' || category === 'Coffee Shop') facilities.push('Colokan', 'AC');
    if (category === 'Warung Makan' || category === 'Street Food') facilities.push('Outdoor');
    if (category === 'Restoran' || category === 'Fast Food') facilities.push('Indoor', 'Toilet');

    return {
      id: id,
      google_place_id: item.id || null,
      name: name,
      city: city,
      category: category,
      min_price: minPrice,
      max_price: maxPrice,
      avg_price: Math.round((minPrice + maxPrice) / 2),
      rating: rating,
      review_count: reviewCount,
      facilities: facilities,
      address: address,
      description: item.editorialSummary?.text || `Tempat kuliner asli terverifikasi Google Maps di area ${city}, dengan rating ⭐ ${rating} (${reviewCount.toLocaleString('id-ID')} ulasan pengunjung).`,
      open_hours: openHours,
      isOpenNow: isOpenNow,
      latitude: lat,
      longitude: lng,
      distance: dist,
      distanceFromGps: dist,
      image_url: chosenPhoto,
      menu_highlights: [
        { name: `Menu Favorit ${name}`, price: minPrice },
        { name: 'Minuman Kopi / Segar', price: Math.max(5000, Math.round(minPrice * 0.4)) },
        { name: 'Camilan Khas Mendoan Hangat', price: Math.max(8000, Math.round(minPrice * 0.5)) }
      ],
      isGoogleLive: true,
      googleMapsUri: mapsUri,
      data_source: 'google_places_live'
    };
  },

  hashCode(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      hash = ((hash << 5) - hash) + str.charCodeAt(i);
      hash |= 0;
    }
    return hash;
  }
};

window.GooglePlacesService = GooglePlacesService;
