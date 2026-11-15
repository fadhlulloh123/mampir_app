/**
 * MAMPIR Web - Recommendation & Utilities Service
 * Mengimplementasikan Algoritma Hybrid Content-Based & Budget Scoring
 * serta kalkulasi jarak Haversine dari Alun-Alun Purwokerto.
 * Terintegrasi penuh dengan I18nService.
 */
const RecommendationService = {
  // Titik Acuan (Default: Alun-Alun Purwokerto, dapat disinkronkan ke GPS Pengguna)
  CENTER_LAT: -7.4243,
  CENTER_LNG: 109.2303,

  setCenterCoordinates(lat, lng) {
    if (typeof lat === 'number' && typeof lng === 'number') {
      this.CENTER_LAT = lat;
      this.CENTER_LNG = lng;
    }
  },

  /**
   * Menghitung jarak garis lurus (km) menggunakan Haversine Formula
   */
  calculateDistance(lat1, lon1, lat2 = this.CENTER_LAT, lon2 = this.CENTER_LNG) {
    if (!lat1 || !lon1) return 0;
    const R = 6371; // Radius bumi dalam kilometer
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return parseFloat((R * c).toFixed(1));
  },

  /**
   * Format mata uang Rupiah
   */
  formatRupiah(num) {
    return 'Rp ' + Number(num || 0).toLocaleString('id-ID');
  },

  /**
   * Format label harga terintegrasi i18n (misal: "Mulai Rp 20.000" / "From Rp 20.000")
   */
  formatPrice(place) {
    if (!place) return 'Rp 0';
    const min = place.min_price || 0;
    const max = place.max_price || min;
    if (min === max || max === 0) {
      return this.formatRupiah(min);
    }
    const fromLabel = typeof window.t === 'function' ? window.t('starting_from', 'Mulai') : 'Mulai';
    return `${fromLabel} ${this.formatRupiah(min)}`;
  },

  /**
   * Menghitung kombinasi menu yang terjangkau sesuai batas budget pengguna.
   * Mengoptimalkan pasangan menu (Combo) atau single menu terbaik yang <= budget.
   */
  getAffordableMenuCombo(place, userBudget) {
    if (!place || !userBudget || userBudget <= 0) return null;
    const highlights = place.menu_highlights || [];
    if (!highlights || highlights.length === 0) {
      if (place.min_price && place.min_price <= userBudget) {
        return {
          fits: true,
          items: [{ name: 'Menu Hemat', price: place.min_price }],
          totalPrice: place.min_price,
          text: 'Menu Pilihan Hemat',
          priceFormatted: this.formatRupiah(place.min_price)
        };
      }
      return null;
    }

    // Filter menu highlights yang harganya <= userBudget
    const affordable = highlights.filter(m => m.price && m.price <= userBudget);
    if (affordable.length === 0) {
      return null;
    }

    // 1. Coba cari kombo 2 menu terbaik (misal: Kopi + Camilan) dengan jumlah harga tertinggi <= userBudget
    let bestPair = null;
    let maxPairSum = 0;

    for (let i = 0; i < affordable.length; i++) {
      for (let j = i + 1; j < affordable.length; j++) {
        const sum = affordable[i].price + affordable[j].price;
        if (sum <= userBudget && sum > maxPairSum) {
          maxPairSum = sum;
          bestPair = [affordable[i], affordable[j]];
        }
      }
    }

    if (bestPair) {
      return {
        fits: true,
        items: bestPair,
        totalPrice: maxPairSum,
        text: `${bestPair[0].name} + ${bestPair[1].name}`,
        priceFormatted: this.formatRupiah(maxPairSum)
      };
    }

    // 2. Jika tidak ada kombinasi 2 menu yang masuk budget, ambil 1 menu terbaik (harga tertinggi <= budget)
    affordable.sort((a, b) => b.price - a.price);
    const bestSingle = affordable[0];
    return {
      fits: true,
      items: [bestSingle],
      totalPrice: bestSingle.price,
      text: bestSingle.name,
      priceFormatted: this.formatRupiah(bestSingle.price)
    };
  },

  /**
   * Mengambil rekomendasi tempat berdasarkan budget, preferensi fasilitas,
   * wilayah terpilih, dan query opsional dengan Algoritma Smart Auto-Recommendation.
   */
  getRecommendations({
    allPlaces = [],
    userBudget = 25000,
    isBudgetActive = false,
    selectedRegion = 'Purwokerto Kota',
    selectedCategory = 'Semua',
    userPreferences = ['WiFi', 'Colokan'],
    searchQuery = ''
  }) {
    if (!allPlaces || allPlaces.length === 0) return [];

    let candidates = [...allPlaces];

    // 1. Filter Regional
    if (selectedRegion && !selectedRegion.toLowerCase().includes('semua')) {
      const regionClean = selectedRegion.split('(')[0].trim().toLowerCase();
      const filtered = candidates.filter(p => {
        const c = (p.city || '').toLowerCase();
        const a = (p.address || '').toLowerCase();
        return c.includes(regionClean) || a.includes(regionClean);
      });
      if (filtered.length > 0) candidates = filtered;
    }

    // 2. Filter Kategori
    if (selectedCategory && selectedCategory !== 'Semua') {
      const catLower = selectedCategory.toLowerCase();
      const filtered = candidates.filter(p => (p.category || '').toLowerCase().includes(catLower));
      if (filtered.length > 0) candidates = filtered;
    }

    const queryTokens = (searchQuery || '').trim().toLowerCase().split(/\s+/).filter(Boolean);

    const scored = candidates.map(place => {
      const minPrice = place.min_price || 0;
      const maxPrice = place.max_price || minPrice;
      const avgPrice = place.avg_price || Math.round((minPrice + maxPrice) / 2) || 25000;
      const rating = place.rating || 4.5;
      const reviewCount = place.review_count || 50;
      const distance = this.calculateDistance(place.latitude, place.longitude);

      // Hitung kombinasi menu terjangkau
      const affordableCombo = this.getAffordableMenuCombo(place, userBudget);
      const isWithinBudget = minPrice <= userBudget;

      // ==================== ALGORITMA SMART RANKING ====================
      // PRIORITAS 1: Best Value / Relevansi Tertinggi (Rating >= 4.5 dalam budget)
      let bestValueScore = 0;
      if (isWithinBudget) {
        if (rating >= 4.5) {
          bestValueScore = 35.0 + ((rating - 4.5) / 0.5) * 10.0; // 35 - 45 poin
        } else {
          bestValueScore = (rating / 5.0) * 30.0; // hingga 30 poin
        }
      } else {
        // Penalti tempat di luar budget agar tempat dalam budget selalu di atas
        const priceOver = minPrice - userBudget;
        bestValueScore = Math.max(0.0, 15.0 - (priceOver / 5000.0) * 4.0);
      }

      // PRIORITAS 2: Kedekatan Lokasi (Proximity)
      // Kafe yang lebih dekat dengan pusat Alun-Alun / wilayah terpilih mendapat poin lebih tinggi
      const proximityScore = Math.max(0.0, 15.0 - distance * 1.2); // 0 - 15 poin

      // PRIORITAS 3: Budget Margin Matching & Popularitas
      // Kafe yang harga menunya mendekati batas maksimal budget pengguna (tapi tidak melewatinya)
      // dengan ulasan terbanyak ditaruh di urutan atas
      let budgetMarginScore = 0;
      if (isWithinBudget) {
        const effectivePrice = Math.min(avgPrice, userBudget);
        const marginRatio = effectivePrice / Math.max(userBudget, 1); // 0.0 - 1.0
        const marginPoints = marginRatio * 15.0; // Nilai mendekati batas dapat hingga 15 poin
        const popularityPoints = Math.min(1.0, reviewCount / 800.0) * 10.0; // Ulasan terbanyak hingga 10 poin
        budgetMarginScore = marginPoints + popularityPoints; // 0 - 25 poin
      }

      // B. Skor Kemiripan Fasilitas & Kata Kunci (0 - 25)
      const placeFacilities = (place.facilities || []).map(f => f.toLowerCase());
      let facilityMatches = 0;
      userPreferences.forEach(pref => {
        if (placeFacilities.includes(pref.toLowerCase())) facilityMatches++;
      });
      const facilityScore = userPreferences.length > 0
        ? (facilityMatches / userPreferences.length) * 15.0
        : 10.0;

      let keywordScore = 0;
      if (queryTokens.length > 0) {
        const combined = `${place.name} ${place.description || ''} ${place.address || ''} ${place.category || ''}`.toLowerCase();
        let matches = 0;
        queryTokens.forEach(token => {
          if (combined.includes(token)) matches++;
        });
        keywordScore = (matches / queryTokens.length) * 10.0;
      } else {
        keywordScore = 10.0;
      }

      const totalScore = parseFloat(
        (bestValueScore + proximityScore + budgetMarginScore + facilityScore + keywordScore).toFixed(1)
      );

      // D. Badge Alasan Cerdas (Terlokalisasi i18n)
      let reasonBadge = '';
      const priceStr = this.formatRupiah(avgPrice);
      if (isWithinBudget && avgPrice <= userBudget * 0.7) {
        reasonBadge = typeof window.t === 'function'
          ? window.t('budget_super_saver', `Sangat Hemat (${priceStr}) • Rating ${rating}`, { price: priceStr, rating })
          : `Sangat Hemat (${priceStr}) • Rating ${rating}`;
      } else if (isWithinBudget) {
        reasonBadge = typeof window.t === 'function'
          ? window.t('budget_friendly', `Pas di Kantong (${priceStr}) • Rating ${rating}`, { price: priceStr, rating })
          : `Pas di Kantong (${priceStr}) • Rating ${rating}`;
      } else {
        reasonBadge = typeof window.t === 'function'
          ? window.t('budget_popular_choice', `Pilihan Populer • Rating ${rating} (${reviewCount}+ ulasan)`, { count: reviewCount, rating })
          : `Pilihan Populer • Rating ${rating} (${reviewCount}+ ulasan)`;
      }

      return {
        place: {
          ...place,
          distance,
          isWithinBudget,
          affordableCombo,
          isBestBudgetMatch: false // di-set setelah sorting
        },
        totalScore,
        bestValueScore,
        proximityScore,
        budgetMarginScore,
        facilityScore,
        keywordScore,
        isWithinBudget,
        affordableCombo,
        reasonBadge
      };
    });

    // Urutkan skor tertinggi ke terendah
    scored.sort((a, b) => b.totalScore - a.totalScore);

    // Tandai 2-3 kafe teratas yang masuk budget sebagai "Best Budget Match"
    let matchCount = 0;
    scored.forEach(item => {
      if (item.isWithinBudget && matchCount < 3) {
        item.place.isBestBudgetMatch = true;
        matchCount++;
      }
    });

    // Hitung metadata Dynamic Fallback / Smart Upsell
    const inBudgetCount = scored.filter(s => s.isWithinBudget).length;
    let upsell = null;

    if (inBudgetCount <= 3) {
      const outOfBudgetPlaces = candidates
        .filter(p => (p.min_price || 0) > userBudget)
        .sort((a, b) => (a.min_price || 0) - (b.min_price || 0));

      if (outOfBudgetPlaces.length > 0) {
        const minGap = (outOfBudgetPlaces[0].min_price || 20000) - userBudget;
        const suggestedBump = Math.max(5000, Math.ceil(minGap / 5000) * 5000);
        const targetBudget = userBudget + suggestedBump;
        const countUnlocked = candidates.filter(p => (p.min_price || 0) <= targetBudget).length - inBudgetCount;

        upsell = {
          neededExtra: suggestedBump,
          newBudget: targetBudget,
          unlockedCount: Math.max(countUnlocked, 1),
          samplePlaces: outOfBudgetPlaces.slice(0, 3)
        };
      }
    }

    // Sertakan metadata upsell & inBudgetCount pada array hasil
    scored.upsell = upsell;
    scored.inBudgetCount = inBudgetCount;

    return scored;
  },

  /**
   * Rekomendasi Berbasis Aktivitas Pengguna (User Activity-Based Recommendation)
   * Menganalisis riwayat klik/kunjungan kategori dan wilayah pengguna,
   * dengan fallback ke tempat paling populer & rating tertinggi.
   */
  getActivityBasedRecommendations({ allPlaces = [], maxItems = 6 }) {
    if (!allPlaces || allPlaces.length === 0) return [];

    const activity = StorageService.getActivityHistory();
    const catCounts = activity.categoryCounts || {};
    const regCounts = activity.regionCounts || {};

    const totalViews = Object.values(catCounts).reduce((a, b) => a + b, 0);

    // KASUS 1: Ada riwayat aktivitas
    if (totalViews > 0) {
      // Cari kategori & wilayah paling sering dikunjungi
      let topCategory = '';
      let topCategoryMax = 0;
      for (const [cat, count] of Object.entries(catCounts)) {
        if (count > topCategoryMax) {
          topCategoryMax = count;
          topCategory = cat;
        }
      }

      let topRegion = '';
      let topRegionMax = 0;
      for (const [reg, count] of Object.entries(regCounts)) {
        if (count > topRegionMax) {
          topRegionMax = count;
          topRegion = reg;
        }
      }

      const topCatLabel = typeof I18nService !== 'undefined'
        ? I18nService.translateCategory(topCategory)
        : topCategory;

      const scored = allPlaces.map(place => {
        let affinityScore = 0;
        const placeCat = place.category || '';
        const placeCity = place.city || '';

        // Bobot Kategori
        if (catCounts[placeCat]) {
          affinityScore += (catCounts[placeCat] / totalViews) * 50;
        }

        // Bobot Wilayah
        if (regCounts[placeCity]) {
          affinityScore += (regCounts[placeCity] / totalViews) * 30;
        }

        // Bobot Rating & Popularitas
        affinityScore += ((place.rating || 4.5) / 5.0) * 20;

        let reasonTag = '';
        if (placeCat === topCategory && placeCity === topRegion) {
          reasonTag = typeof window.t === 'function'
            ? window.t('activity_fav_format', `Favorit Anda: ${topCatLabel} di ${topRegion}`, { category: topCatLabel, region: topRegion })
            : `Favorit Anda: ${topCatLabel} di ${topRegion}`;
        } else if (placeCat === topCategory) {
          reasonTag = typeof window.t === 'function'
            ? window.t('activity_interest_format', `Kategori Minat: ${topCatLabel}`, { category: topCatLabel })
            : `Kategori Minat: ${topCatLabel}`;
        } else if (placeCity === topRegion) {
          reasonTag = typeof window.t === 'function'
            ? window.t('activity_frequent_format', `Sering Dikunjungi di ${topRegion}`, { region: topRegion })
            : `Sering Dikunjungi di ${topRegion}`;
        } else {
          reasonTag = typeof window.t === 'function'
            ? window.t('activity_similar', 'Rekomendasi Serupa')
            : 'Rekomendasi Serupa';
        }

        const distance = this.calculateDistance(place.latitude, place.longitude);

        return {
          ...place,
          distance,
          affinityScore,
          activityReason: reasonTag
        };
      });

      // Urutkan berdasarkan affinityScore tertinggi
      scored.sort((a, b) => b.affinityScore - a.affinityScore);
      return scored.slice(0, maxItems);
    }

    // KASUS 2 (FALLBACK): Belum ada riwayat aktivitas (Pengguna Baru)
    // Ambil kafe dengan rating & jumlah ulasan tertinggi
    const fallbackList = [...allPlaces].map(place => {
      const distance = this.calculateDistance(place.latitude, place.longitude);
      const rating = place.rating || 4.8;
      const tag = typeof window.t === 'function'
        ? window.t('activity_top_fav', `⭐ Pilihan Terfavorit (Rating ${rating})`, { rating })
        : `⭐ Pilihan Terfavorit (Rating ${rating})`;

      return {
        ...place,
        distance,
        affinityScore: (place.rating || 4.5) * 100 + (place.review_count || 50),
        activityReason: tag
      };
    });

    fallbackList.sort((a, b) => b.affinityScore - a.affinityScore);
    return fallbackList.slice(0, maxItems);
  }
};
