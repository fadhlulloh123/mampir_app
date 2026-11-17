/**
 * MAMPIR Web - Tongkrongan Roulette & Smart Decision Maker
 * Mengintegrasikan Spin Wheel Canvas Interaktif, Algoritma Analisis "Worth It" Multi-Faktor,
 * Sound Synthesizer Web Audio API, dan Efek Konfeti Perayaan.
 */

const RouletteController = {
  // State
  candidates: [], // Array of max 4 place objects
  mode: 'weighted', // 'weighted' (Smart Worth It) atau 'luck' (Murni Acak)
  soundEnabled: true,
  isSpinning: false,
  currentAngle: 0,
  targetWinner: null,
  activeSlotSearchIndex: null,

  // Palette warna juring roda selang-seling identitas MAMPIR
  colors: [
    '#EA580C', // Oranye khas MAMPIR
    '#1E293B', // Deep Navy Slate
    '#D97706', // Emas Amber
    '#0F172A', // Midnight Dark
    '#F59E0B', // Kuning Emas
    '#334155'  // Cool Slate
  ],

  init() {
    console.log('Inisialisasi Roulette & Smart Decision Maker...');
    this.bindEvents();
  },

  bindEvents() {
    // Tutup popup pencarian saat klik di luar
    document.addEventListener('click', (e) => {
      const dropdown = document.getElementById('roulette-search-dropdown');
      if (dropdown && !dropdown.contains(e.target) && !e.target.closest('.roulette-slot-card')) {
        dropdown.style.display = 'none';
        this.activeSlotSearchIndex = null;
      }
    });

    // Invalidate size / redraw saat resize
    window.addEventListener('resize', () => {
      if (document.getElementById('modal-roulette')?.classList.contains('active')) {
        this.drawWheel();
      }
    });
  },

  // ==================== CANDIDATE MANAGEMENT ====================
  toggleCandidate(placeId) {
    const place = window.App?.getPlaceById(placeId);
    if (!place) return;

    const idx = this.candidates.findIndex(c => c.id === placeId);
    if (idx >= 0) {
      // Hapus
      this.candidates.splice(idx, 1);
      if (window.App?.showToast) {
        window.App.showToast(window.t('toast_candidate_removed', 'Dihapus dari adu tongkrongan'));
      }
    } else {
      // Tambah
      if (this.candidates.length >= 4) {
        if (window.App?.showToast) {
          window.App.showToast(window.t('wheel_max_4_reached', 'Maksimal 4 kafe yang dapat dipilih sekaligus.'));
        }
        return;
      }
      this.candidates.push(place);
      if (window.App?.showToast) {
        const count = this.candidates.length;
        window.App.showToast(window.t('toast_candidate_added', `Ditambahkan ke adu tongkrongan (${count}/4)`, { count }));
      }
    }

    this.updateCardButtons();
    this.updateFloatingDrawer();
    this.renderSlotCards();
    this.drawWheel();
  },

  isCandidateSelected(placeId) {
    return this.candidates.some(c => c.id === placeId);
  },

  clearSelection() {
    this.candidates = [];
    this.updateCardButtons();
    this.updateFloatingDrawer();
    this.renderSlotCards();
    this.drawWheel();
    if (window.App?.showToast) {
      window.App.showToast(window.t('toast_candidate_cleared', 'Daftar adu tongkrongan dikosongkan.'));
    }
  },

  updateCardButtons() {
    document.querySelectorAll('.btn-card-vs').forEach(btn => {
      const pid = btn.getAttribute('data-place-id');
      const isSelected = this.isCandidateSelected(pid);
      btn.classList.toggle('active', isSelected);
      btn.innerHTML = isSelected
        ? `<span>✓</span> <span>${window.t('wheel_card_btn_added', 'Terpilih')}</span>`
        : `<span>⚔️</span> <span>${window.t('wheel_card_btn_add', 'Adu')}</span>`;
    });
  },

  updateFloatingDrawer() {
    const drawer = document.getElementById('vs-bottom-drawer');
    const badge = document.getElementById('vs-badge-count');
    const thumbsContainer = document.getElementById('vs-thumbnails-list');
    const label = document.getElementById('vs-drawer-label');
    if (!drawer) return;

    const count = this.candidates.length;
    if (count >= 2) {
      drawer.style.display = 'flex';
      drawer.classList.add('visible');
      if (badge) badge.textContent = count.toString();
      if (label) {
        label.textContent = window.t('wheel_drawer_title', `${count} Kafe Dipilih untuk Diadu`, { count });
      }
      if (thumbsContainer) {
        thumbsContainer.innerHTML = this.candidates.map(c => `
          <div class="vs-thumb-item" title="${c.name}">
            <img src="${c.image_url || 'assets/images/beranda_mockup.jpeg'}" alt="${c.name}" />
          </div>
        `).join('');
      }
    } else {
      drawer.classList.remove('visible');
      setTimeout(() => {
        if (this.candidates.length < 2) drawer.style.display = 'none';
      }, 250);
    }
  },

  // ==================== ALGORITMA "PALING WORTH IT" ====================
  /**
   * Menghitung nilai kelayakan objektif kafe berdasarkan 4 pilar bobot:
   * 1. Value for Money / Budget (35%)
   * 2. Kualitas & Reputasi (30%)
   * 3. Fasilitas & Jam Operasional (20%)
   * 4. Kedekatan Lokasi (15%)
   */
  calculateWorthItScores(cafes) {
    if (!cafes || cafes.length === 0) return [];

    // Kumpulkan parameter batas min & max untuk normalisasi
    const prices = cafes.map(c => c.min_price || 20000);
    const minPriceAll = Math.min(...prices);
    const maxPriceAll = Math.max(...prices);

    const ratings = cafes.map(c => c.rating || 4.5);
    const minRating = Math.min(...ratings);
    const maxRating = Math.max(...ratings);

    const distances = cafes.map(c => {
      return c.distance || (RecommendationService ? RecommendationService.calculateDistance(c.latitude, c.longitude) : 2.5);
    });
    const minDistance = Math.min(...distances);
    const maxDistance = Math.max(...distances);

    return cafes.map((cafe, idx) => {
      const minPrice = cafe.min_price || 20000;
      const avgPrice = cafe.avg_price || Math.round((minPrice + (cafe.max_price || minPrice)) / 2);
      const rating = cafe.rating || 4.5;
      const reviewCount = cafe.review_count || 100;
      const distance = distances[idx];
      const facilities = (cafe.facilities || []).map(f => f.toLowerCase());

      // 1. Value for Money (Bobot 35%)
      // Harga terendah mendapat skor penuh
      let valueScore = 0;
      if (maxPriceAll === minPriceAll) {
        valueScore = 35.0;
      } else {
        const priceRatio = (avgPrice - minPriceAll) / (maxPriceAll - minPriceAll);
        valueScore = Math.max(12.0, 35.0 - priceRatio * 23.0);
      }

      // 2. Kualitas & Reputasi (Bobot 30%)
      const ratingRatio = (rating - 3.5) / 1.5; // 0.0 sampai 1.0
      const ratingBase = Math.max(0, Math.min(1.0, ratingRatio)) * 22.0;
      const reviewBonus = Math.min(8.0, (reviewCount / 800.0) * 8.0);
      const qualityScore = ratingBase + reviewBonus;

      // 3. Fasilitas & Jam Operasional (Bobot 20%)
      let facScore = 0;
      // Periksa jam operasional buka sekarang
      let isOpenNow = true;
      try {
        const nowHour = new Date().getHours();
        // Mayoritas kafe buka siang-malam
        if (nowHour >= 10 && nowHour <= 23) isOpenNow = true;
      } catch(e) {}

      if (isOpenNow) facScore += 6.0;
      if (facilities.includes('wifi')) facScore += 4.0;
      if (facilities.includes('colokan')) facScore += 4.0;
      if (facilities.includes('outdoor')) facScore += 3.0;
      if (facilities.includes('parkir')) facScore += 3.0;

      // 4. Kedekatan Lokasi (Bobot 15%)
      let distScore = 0;
      if (maxDistance === minDistance) {
        distScore = 15.0;
      } else {
        const distRatio = (distance - minDistance) / (maxDistance - minDistance || 1);
        distScore = Math.max(3.0, 15.0 - distRatio * 12.0);
      }

      const totalScore = parseFloat((valueScore + qualityScore + facScore + distScore).toFixed(1));

      // Buat alasan komparatif keunggulan (3 poin)
      const reasons = [];

      // Poin 1: Harga
      const avgOthers = Math.round(
        cafes.filter(c => c.id !== cafe.id).reduce((a, b) => a + (b.min_price || 20000), 0) /
        Math.max(1, cafes.length - 1)
      );
      if (minPrice <= minPriceAll) {
        reasons.push(window.t('wheel_reason_price_best', `💰 Harga paling hemat (mulai ${RecommendationService.formatRupiah(minPrice)} vs rata-rata ${RecommendationService.formatRupiah(avgOthers)})`, {
          min: RecommendationService.formatRupiah(minPrice),
          avg: RecommendationService.formatRupiah(avgOthers)
        }));
      } else {
        reasons.push(`💰 Harga bersahabat mulai ${RecommendationService.formatRupiah(minPrice)}`);
      }

      // Poin 2: Rating
      if (rating >= maxRating) {
        reasons.push(window.t('wheel_reason_rating_best', `⭐ Rating tertinggi: ${rating} dari ${reviewCount}+ ulasan pengunjung`, {
          rating: rating.toString(),
          reviews: reviewCount.toString()
        }));
      } else {
        reasons.push(`⭐ Kualitas terpercaya rating ${rating} (${reviewCount}+ ulasan)`);
      }

      // Poin 3: Fasilitas / Jarak
      const facNames = (cafe.facilities || []).slice(0, 3).join(', ');
      if (distance <= minDistance) {
        reasons.push(window.t('wheel_reason_distance_best', `📍 Paling dekat: hanya ${distance} km dari Alun-Alun`, {
          dist: distance.toString()
        }));
      } else if (facNames) {
        reasons.push(window.t('wheel_reason_facilities_best', `⚡ Fasilitas lengkap: ${facNames}`, {
          fac: facNames
        }));
      } else {
        reasons.push(`🕒 Jam operasional nyaman: ${cafe.open_hours || '09.00 - 23.00'}`);
      }

      return {
        ...cafe,
        distance,
        worthItScore: totalScore,
        worthItBreakdown: { valueScore, qualityScore, facScore, distScore },
        topReasons: reasons.slice(0, 3)
      };
    });
  },

  // ==================== MODAL & SLOT UI ====================
  openModal() {
    const modal = document.getElementById('modal-roulette');
    if (!modal) return;

    // Jika belum ada kandidat atau baru 1, coba isi otomatis jika kosong
    if (this.candidates.length === 0) {
      this.autoFillNearbyCandidates(2);
    }

    modal.classList.add('active');
    this.switchToView('setup');
    this.renderSlotCards();
    this.updateModeToggleUI();
    setTimeout(() => this.drawWheel(), 150);
  },

  closeModal() {
    const modal = document.getElementById('modal-roulette');
    if (modal) modal.classList.remove('active');
    this.isSpinning = false;
  },

  switchToView(viewName) {
    const setupView = document.getElementById('roulette-view-setup');
    const winnerView = document.getElementById('roulette-view-winner');
    if (viewName === 'setup') {
      if (setupView) setupView.style.display = 'block';
      if (winnerView) winnerView.style.display = 'none';
      this.drawWheel();
    } else if (viewName === 'winner') {
      if (setupView) setupView.style.display = 'none';
      if (winnerView) winnerView.style.display = 'block';
    }
  },

  setMode(newMode) {
    this.mode = newMode;
    this.updateModeToggleUI();
    this.drawWheel();
  },

  updateModeToggleUI() {
    const btnLuck = document.getElementById('btn-mode-luck');
    const btnWeighted = document.getElementById('btn-mode-weighted');
    const descEl = document.getElementById('roulette-mode-description');

    if (btnLuck) btnLuck.classList.toggle('active', this.mode === 'luck');
    if (btnWeighted) btnWeighted.classList.toggle('active', this.mode === 'weighted');

    if (descEl) {
      descEl.textContent = this.mode === 'luck'
        ? window.t('wheel_mode_luck_desc', 'Semua kafe memiliki ukuran juring & peluang menang yang sama rata.')
        : window.t('wheel_mode_weighted_desc', 'Ukuran juring menyesuaikan skor analisis (kafe paling worth it berpeluang lebih besar menang).');
    }
  },

  toggleSound() {
    this.soundEnabled = !this.soundEnabled;
    const btn = document.getElementById('btn-roulette-sound');
    if (btn) {
      btn.innerHTML = this.soundEnabled ? '🔊' : '🔇';
      btn.title = this.soundEnabled
        ? window.t('wheel_sound_on', 'Suara Aktif')
        : window.t('wheel_sound_off', 'Suara Nonaktif');
    }
  },

  autoFillNearbyCandidates(count = 3) {
    const all = window.App?.places || FALLBACK_PLACES || [];
    if (!all || all.length === 0) return;

    // Filter kafe berdasarkan wilayah aktif atau urutkan terdekat
    const region = window.App?.selectedRegion || 'Purwokerto Kota';
    let pool = all;
    if (region && !region.toLowerCase().includes('semua')) {
      const regClean = region.split('(')[0].trim().toLowerCase();
      const filtered = all.filter(p => (p.city || '').toLowerCase().includes(regClean));
      if (filtered.length >= count) pool = filtered;
    }

    // Acak pilihan
    const shuffled = [...pool].sort(() => 0.5 - Math.random());
    this.candidates = shuffled.slice(0, count);

    this.updateCardButtons();
    this.updateFloatingDrawer();
    this.renderSlotCards();
    this.drawWheel();
    if (window.App?.showToast) {
      window.App.showToast(window.t('toast_candidate_added', `Terpilih ${this.candidates.length} kafe untuk adu tongkrongan!`));
    }
  },

  fillFromFavorites() {
    const favIds = StorageService?.getFavorites() || [];
    const all = window.App?.places || FALLBACK_PLACES || [];
    const favPlaces = all.filter(p => favIds.includes(p.id));

    if (favPlaces.length === 0) {
      alert(window.t('no_recent_searches', 'Belum ada kafe yang disimpan di Favorit. Silakan tandai kafe favorit Anda terlebih dahulu!'));
      return;
    }

    this.candidates = favPlaces.slice(0, 4);
    this.updateCardButtons();
    this.updateFloatingDrawer();
    this.renderSlotCards();
    this.drawWheel();
    if (window.App?.showToast) {
      window.App.showToast(`Memuat ${this.candidates.length} kafe dari Favorit Saya ❤️`);
    }
  },

  renderSlotCards() {
    const container = document.getElementById('roulette-slots-container');
    if (!container) return;

    let html = '';
    for (let i = 0; i < 4; i++) {
      const cafe = this.candidates[i];
      const isRequired = i < 2;
      const slotNum = i + 1;

      if (cafe) {
        html += `
          <div class="roulette-slot-card filled">
            <span class="slot-badge">#${slotNum}</span>
            <img src="${cafe.image_url || 'assets/images/beranda_mockup.jpeg'}" alt="${cafe.name}" class="slot-thumb" />
            <div class="slot-info">
              <h5 class="slot-title">${cafe.name}</h5>
              <div class="slot-meta">
                <span>⭐ ${cafe.rating || 4.5}</span>
                <span>•</span>
                <span>📍 ${cafe.city}</span>
              </div>
              <div class="slot-price">${RecommendationService.formatPrice(cafe)}</div>
            </div>
            <button class="slot-remove-btn" onclick="window.Roulette.removeSlot(${i})" title="Hapus Slot">✕</button>
          </div>
        `;
      } else {
        html += `
          <div class="roulette-slot-card empty" onclick="window.Roulette.openSlotPicker(${i}, event)">
            <span class="slot-badge ${isRequired ? 'req' : 'opt'}">#${slotNum} ${isRequired ? window.t('wheel_slot_required', 'Wajib') : window.t('wheel_slot_optional', 'Opsional')}</span>
            <div class="slot-empty-content">
              <span style="font-size: 22px;">➕</span>
              <p>${window.t('wheel_slot_empty', 'Pilih Kafe...')}</p>
            </div>
          </div>
        `;
      }
    }

    container.innerHTML = html;

    // Perbarui status tombol Spin
    const spinBtn = document.getElementById('btn-spin-roulette');
    if (spinBtn) {
      const canSpin = this.candidates.length >= 2;
      spinBtn.disabled = !canSpin;
      spinBtn.classList.toggle('disabled', !canSpin);
    }
  },

  removeSlot(index) {
    if (this.candidates[index]) {
      this.candidates.splice(index, 1);
      this.updateCardButtons();
      this.updateFloatingDrawer();
      this.renderSlotCards();
      this.drawWheel();
    }
  },

  openSlotPicker(slotIndex, event) {
    this.activeSlotSearchIndex = slotIndex;
    const dropdown = document.getElementById('roulette-search-dropdown');
    const input = document.getElementById('roulette-search-input');
    if (!dropdown || !input) return;

    dropdown.style.display = 'block';
    input.value = '';
    this.renderDropdownPlaces('');
    setTimeout(() => input.focus(), 50);
  },

  renderDropdownPlaces(query = '') {
    const listEl = document.getElementById('roulette-search-list');
    if (!listEl) return;

    const all = window.App?.places || FALLBACK_PLACES || [];
    const q = (query || '').toLowerCase().trim();
    const existingIds = this.candidates.map(c => c.id);

    // Filter kafe yang belum dipilih
    const filtered = all.filter(p => {
      if (existingIds.includes(p.id)) return false;
      if (!q) return true;
      return (p.name || '').toLowerCase().includes(q) || (p.city || '').toLowerCase().includes(q);
    });

    if (filtered.length === 0) {
      listEl.innerHTML = `<div style="padding: 16px; text-align: center; color: var(--text-muted); font-size: 12px;">Tidak ada kafe yang cocok</div>`;
      return;
    }

    listEl.innerHTML = filtered.slice(0, 8).map(p => `
      <div class="roulette-dropdown-item" onclick="window.Roulette.pickPlaceForSlot('${p.id}')">
        <img src="${p.image_url || 'assets/images/beranda_mockup.jpeg'}" alt="${p.name}" class="dropdown-item-thumb" />
        <div style="flex: 1; overflow: hidden;">
          <div style="font-weight: 700; font-size: 13px; color: var(--text-primary); text-overflow: ellipsis; white-space: nowrap; overflow: hidden;">${p.name}</div>
          <div style="font-size: 11px; color: var(--text-secondary);">⭐ ${p.rating || 4.5} • 📍 ${p.city} • ${RecommendationService.formatPrice(p)}</div>
        </div>
      </div>
    `).join('');
  },

  pickPlaceForSlot(placeId) {
    const place = window.App?.getPlaceById(placeId);
    if (!place) return;

    if (this.activeSlotSearchIndex !== null && this.activeSlotSearchIndex < 4) {
      this.candidates[this.activeSlotSearchIndex] = place;
    } else {
      if (this.candidates.length < 4) {
        this.candidates.push(place);
      }
    }

    const dropdown = document.getElementById('roulette-search-dropdown');
    if (dropdown) dropdown.style.display = 'none';
    this.activeSlotSearchIndex = null;

    this.updateCardButtons();
    this.updateFloatingDrawer();
    this.renderSlotCards();
    this.drawWheel();
  },

  // ==================== AUDIO SYNTHESIZER ====================
  playClickSound() {
    if (!this.soundEnabled) return;
    try {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      if (!AudioContext) return;
      const ctx = new AudioContext();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'triangle';
      osc.frequency.setValueAtTime(650, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(140, ctx.currentTime + 0.035);

      gain.gain.setValueAtTime(0.15, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.035);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.04);
    } catch (e) {}
  },

  playWinChime() {
    if (!this.soundEnabled) return;
    try {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      if (!AudioContext) return;
      const ctx = new AudioContext();
      const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
      notes.forEach((freq, idx) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, ctx.currentTime + idx * 0.08);

        gain.gain.setValueAtTime(0.2, ctx.currentTime + idx * 0.08);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + idx * 0.08 + 0.3);

        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(ctx.currentTime + idx * 0.08);
        osc.stop(ctx.currentTime + idx * 0.08 + 0.35);
      });
    } catch (e) {}
  },

  // ==================== SPIN WHEEL CANVAS RENDERING ====================
  getSlicesData() {
    const count = this.candidates.length;
    if (count === 0) return [];

    const scored = this.calculateWorthItScores(this.candidates);

    if (this.mode === 'luck' || count === 1) {
      const anglePerSlice = (2 * Math.PI) / count;
      return scored.map((c, i) => ({
        ...c,
        startAngle: i * anglePerSlice,
        endAngle: (i + 1) * anglePerSlice,
        sliceAngle: anglePerSlice,
        color: this.colors[i % this.colors.length]
      }));
    }

    // Mode Weighted: Proporsional terhadap worthItScore
    const totalScore = scored.reduce((acc, c) => acc + c.worthItScore, 0);
    let cur = 0;
    return scored.map((c, i) => {
      const sliceAngle = (c.worthItScore / Math.max(1, totalScore)) * (2 * Math.PI);
      const startAngle = cur;
      const endAngle = cur + sliceAngle;
      cur = endAngle;
      return {
        ...c,
        startAngle,
        endAngle,
        sliceAngle,
        color: this.colors[i % this.colors.length]
      };
    });
  },

  drawWheel() {
    const canvas = document.getElementById('roulette-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    const centerX = width / 2;
    const centerY = height / 2;
    const radius = width / 2 - 16;

    ctx.clearRect(0, 0, width, height);

    const slices = this.getSlicesData();

    if (slices.length === 0) {
      // Empty state wheel
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
      ctx.fillStyle = '#1E293B';
      ctx.fill();
      ctx.lineWidth = 4;
      ctx.strokeStyle = '#F57C00';
      ctx.stroke();

      ctx.fillStyle = '#94A3B8';
      ctx.font = 'bold 14px Poppins, sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(window.t('wheel_need_at_least_2', 'Pilih minimal 2 kafe...'), centerX, centerY);
      return;
    }

    // 1. Gambar Juring Roda
    ctx.save();
    ctx.translate(centerX, centerY);
    ctx.rotate(this.currentAngle);

    slices.forEach((slice, idx) => {
      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.arc(0, 0, radius, slice.startAngle, slice.endAngle);
      ctx.closePath();
      ctx.fillStyle = slice.color;
      ctx.fill();

      // Garis batas sektor
      ctx.lineWidth = 2.5;
      ctx.strokeStyle = '#0F172A';
      ctx.stroke();

      // Teks Radial Nama Kafe
      ctx.save();
      const midAngle = slice.startAngle + slice.sliceAngle / 2;
      ctx.rotate(midAngle);
      ctx.textAlign = 'right';
      ctx.textBaseline = 'middle';
      ctx.fillStyle = '#FFFFFF';
      ctx.font = 'bold 13px Poppins, sans-serif';

      // Potong nama agar rapi di kanvas
      const maxLen = radius > 160 ? 16 : 12;
      const cleanName = slice.name.length > maxLen ? slice.name.substring(0, maxLen - 1) + '…' : slice.name;

      // Gambar ikon & teks
      const textDist = radius - 24;
      ctx.shadowColor = 'rgba(0, 0, 0, 0.6)';
      ctx.shadowBlur = 4;
      ctx.fillText(`☕ ${cleanName}`, textDist, 0);

      // Tampilkan persentase jika mode weighted
      if (this.mode === 'weighted' && slices.length > 1) {
        ctx.font = '600 10.5px Poppins, sans-serif';
        ctx.fillStyle = '#FDE68A';
        const pct = Math.round((slice.sliceAngle / (2 * Math.PI)) * 100);
        ctx.fillText(`${pct}%`, textDist, 16);
      }

      ctx.restore();
    });

    // 2. Lingkaran Border Luar Emas Mewah
    ctx.beginPath();
    ctx.arc(0, 0, radius, 0, 2 * Math.PI);
    ctx.lineWidth = 6;
    ctx.strokeStyle = '#F59E0B';
    ctx.stroke();

    // Titik-titik lampu dekoratif di sekeliling roda
    const totalBulbs = 24;
    for (let b = 0; b < totalBulbs; b++) {
      const bAngle = (b * 2 * Math.PI) / totalBulbs;
      const bx = (radius + 2) * Math.cos(bAngle);
      const by = (radius + 2) * Math.sin(bAngle);
      ctx.beginPath();
      ctx.arc(bx, by, 3.5, 0, 2 * Math.PI);
      ctx.fillStyle = b % 2 === 0 ? '#FFFFFF' : '#FFD700';
      ctx.fill();
    }

    ctx.restore();

    // 3. Lingkaran Hub Tengah (Pusat Roda)
    ctx.beginPath();
    ctx.arc(centerX, centerY, 32, 0, 2 * Math.PI);
    const grad = ctx.createRadialGradient(centerX, centerY, 5, centerX, centerY, 32);
    grad.addColorStop(0, '#334155');
    grad.addColorStop(1, '#0F172A');
    ctx.fillStyle = grad;
    ctx.fill();
    ctx.lineWidth = 3.5;
    ctx.strokeStyle = '#F59E0B';
    ctx.stroke();

    // Ikon Dadu di tengah
    ctx.fillStyle = '#FFFFFF';
    ctx.font = '20px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('🎲', centerX, centerY);

    // 4. Jarum Penunjuk (Pointer Arrow) di Atas Tengah (Tetap Diam Mengarah ke Bawah)
    this.drawPointer(ctx, centerX, 14);
  },

  drawPointer(ctx, x, y) {
    ctx.save();
    ctx.translate(x, y);

    // Bayangan jarum
    ctx.shadowColor = 'rgba(0, 0, 0, 0.45)';
    ctx.shadowBlur = 8;
    ctx.shadowOffsetY = 4;

    ctx.beginPath();
    ctx.moveTo(-14, 0);
    ctx.lineTo(14, 0);
    ctx.lineTo(0, 28);
    ctx.closePath();

    ctx.fillStyle = '#EA580C';
    ctx.fill();
    ctx.lineWidth = 2.5;
    ctx.strokeStyle = '#FFFFFF';
    ctx.stroke();

    // Titik pin poros jarum
    ctx.beginPath();
    ctx.arc(0, 2, 4, 0, 2 * Math.PI);
    ctx.fillStyle = '#FFD700';
    ctx.fill();

    ctx.restore();
  },

  // ==================== SPIN ANIMATION & DECISION ENGINE ====================
  spinWheel() {
    if (this.isSpinning) return;
    if (this.candidates.length < 2) {
      alert(window.t('wheel_need_at_least_2', 'Pilih minimal 2 kafe untuk memulai putaran roda!'));
      return;
    }

    this.isSpinning = true;
    const spinBtn = document.getElementById('btn-spin-roulette');
    if (spinBtn) {
      spinBtn.disabled = true;
      spinBtn.classList.add('spinning');
      spinBtn.innerHTML = `<span>⏳</span> <span>${window.t('wheel_spinning', 'Memutar Roda...')}</span>`;
    }

    const slices = this.getSlicesData();
    const scored = this.calculateWorthItScores(this.candidates);

    // Tentukan pemenang (Winner Selection)
    let winnerIndex = 0;
    if (this.mode === 'weighted') {
      // Bobot probabilitas kumulatif
      const totalScore = scored.reduce((a, b) => a + b.worthItScore, 0);
      const r = Math.random() * totalScore;
      let acc = 0;
      for (let i = 0; i < scored.length; i++) {
        acc += scored[i].worthItScore;
        if (r <= acc) {
          winnerIndex = i;
          break;
        }
      }
    } else {
      // Murni acak
      winnerIndex = Math.floor(Math.random() * scored.length);
    }

    const winnerSlice = slices[winnerIndex];
    this.targetWinner = scored[winnerIndex];

    // Posisi Jarum ada di atas tengah = sudut 270 derajat (3*PI/2)
    // Sektor pemenang harus berhenti di bawah jarum:
    // (currentAngle + winnerMidAngle) % 2PI = 3*PI/2
    const targetSectorMid = (winnerSlice.startAngle + winnerSlice.endAngle) / 2;
    const pointerAngle = (3 * Math.PI) / 2;

    // Tambahkan 5 hingga 7 putaran penuh agar putaran terasa dramatis (4.5 detik)
    const fullRotations = (5 + Math.floor(Math.random() * 3)) * (2 * Math.PI);
    const targetOffset = (pointerAngle - targetSectorMid + 2 * Math.PI) % (2 * Math.PI);

    // Tambahkan sedikit variasi acak di dalam juring agar tidak tepat di tengah mati
    const jitter = (Math.random() - 0.5) * (winnerSlice.sliceAngle * 0.5);

    const startAngle = this.currentAngle;
    const totalRotationAngle = fullRotations + targetOffset + jitter;

    const duration = 4500; // 4.5 detik
    const startTime = performance.now();
    let lastSlicePassed = -1;

    // Cubic Easing Out
    const easeOutCubic = (t) => 1 - Math.pow(1 - t, 3.8);

    const animate = (currentTime) => {
      const elapsed = currentTime - startTime;
      const progress = Math.min(1.0, elapsed / duration);
      const easedProgress = easeOutCubic(progress);

      this.currentAngle = startAngle + totalRotationAngle * easedProgress;

      // Deteksi perpindahan sektor untuk sound tick
      const normalizedAngle = (this.currentAngle % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI);
      const currentPointerRelative = ((3 * Math.PI / 2) - normalizedAngle + 2 * Math.PI) % (2 * Math.PI);

      let currentSliceIndex = 0;
      for (let s = 0; s < slices.length; s++) {
        if (currentPointerRelative >= slices[s].startAngle && currentPointerRelative < slices[s].endAngle) {
          currentSliceIndex = s;
          break;
        }
      }

      if (currentSliceIndex !== lastSlicePassed) {
        lastSlicePassed = currentSliceIndex;
        this.playClickSound();
      }

      this.drawWheel();

      if (progress < 1.0) {
        requestAnimationFrame(animate);
      } else {
        // Putaran Selesai
        this.isSpinning = false;
        if (spinBtn) {
          spinBtn.disabled = false;
          spinBtn.classList.remove('spinning');
          spinBtn.innerHTML = `<span>🎯</span> <span data-i18n="wheel_btn_spin">${window.t('wheel_btn_spin', 'PUTAR RODA SEKARANG!')}</span>`;
        }

        this.playWinChime();
        this.triggerConfetti();
        setTimeout(() => {
          this.renderWinnerView(this.targetWinner);
        }, 500);
      }
    };

    requestAnimationFrame(animate);
  },

  // ==================== WINNER VIEW & CONFETTI ====================
  renderWinnerView(winner) {
    if (!winner) return;
    this.switchToView('winner');

    const cardContainer = document.getElementById('roulette-winner-card-container');
    if (!cardContainer) return;

    const catLabel = typeof I18nService !== 'undefined'
      ? I18nService.translateCategory(winner.category || 'Cafe')
      : (winner.category || 'Cafe');

    cardContainer.innerHTML = `
      <div class="winner-hero-card">
        <div class="winner-badge-ribbon">
          🏆 ${window.t('wheel_winner_header', 'Pilihan Terbaik Hari Ini:')}
        </div>
        
        <div class="winner-card-top">
          <img src="${winner.image_url || 'assets/images/beranda_mockup.jpeg'}" alt="${winner.name}" class="winner-card-img" />
          <div class="winner-card-details">
            <span class="badge-cat">${catLabel}</span>
            <h2 class="winner-name">${winner.name}</h2>
            <p class="winner-location">📍 ${winner.address || winner.city} (${winner.distance || 0} km)</p>
            <div class="winner-stats-row">
              <div class="winner-stat">
                <small>Rating</small>
                <strong>⭐ ${winner.rating || 4.5}</strong>
              </div>
              <div class="winner-stat">
                <small>Mulai</small>
                <strong style="color: var(--accent-orange);">${RecommendationService.formatPrice(winner)}</strong>
              </div>
              <div class="winner-stat">
                <small>${window.t('wheel_worth_score_label', 'Skor Kelayakan')}</small>
                <strong style="color: #10B981;">${winner.worthItScore}/100</strong>
              </div>
            </div>
          </div>
        </div>

        <!-- Banner Analisis Sistem (Why It's Worth It) -->
        <div class="winner-analysis-box">
          <h4 class="analysis-box-title">
            <span>🧠</span>
            <span>${window.t('wheel_why_worth_it', 'Analisis Sistem: Kenapa Paling Worth It?')}</span>
          </h4>
          <ul class="analysis-reasons-list">
            ${winner.topReasons.map(r => `<li>${r}</li>`).join('')}
          </ul>
        </div>

        <!-- Tombol Aksi Lanjutan -->
        <div class="winner-actions-grid" style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
          <button class="btn-primary" onclick="window.Roulette.focusOnMap('${winner.id}', ${winner.latitude}, ${winner.longitude})">
            ${window.t('wheel_action_route', '🗺️ Buka Rute di Peta')}
          </button>
          <button class="btn-secondary" onclick="window.Roulette.switchToView('setup')">
            ${window.t('wheel_action_spin_again', '🔄 Putar Ulang / Ganti Pilihan')}
          </button>
        </div>
      </div>
    `;
  },

  focusOnMap(placeId, lat, lng) {
    this.closeModal();
    if (window.App?.focusMap) {
      window.App.focusMap(placeId, lat, lng);
    }
  },

  triggerConfetti() {
    const canvas = document.getElementById('roulette-confetti-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    canvas.width = canvas.parentElement.clientWidth;
    canvas.height = canvas.parentElement.clientHeight;

    const confettiCount = 80;
    const particles = [];
    const colors = ['#EA580C', '#F59E0B', '#10B981', '#3B82F6', '#EC4899', '#8B5CF6', '#FFD700'];

    for (let i = 0; i < confettiCount; i++) {
      particles.push({
        x: canvas.width / 2,
        y: canvas.height / 2,
        r: Math.random() * 6 + 3,
        color: colors[Math.floor(Math.random() * colors.length)],
        vx: (Math.random() - 0.5) * 16,
        vy: (Math.random() - 0.8) * 18,
        gravity: 0.35,
        tilt: Math.random() * 10 - 5,
        tiltAngle: 0,
        tiltAngleInc: Math.random() * 0.08 + 0.04,
        alpha: 1.0
      });
    }

    let animationFrame;
    const render = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      let alive = false;

      particles.forEach(p => {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += p.gravity;
        p.tiltAngle += p.tiltAngleInc;
        p.tilt = Math.sin(p.tiltAngle) * 12;
        p.alpha -= 0.009;

        if (p.alpha > 0) {
          alive = true;
          ctx.save();
          ctx.beginPath();
          ctx.lineWidth = p.r;
          ctx.strokeStyle = p.color;
          ctx.globalAlpha = Math.max(0, p.alpha);
          ctx.moveTo(p.x + p.tilt + p.r / 2, p.y);
          ctx.lineTo(p.x + p.tilt, p.y + p.tilt + p.r / 2);
          ctx.stroke();
          ctx.restore();
        }
      });

      if (alive) {
        animationFrame = requestAnimationFrame(render);
      } else {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
      }
    };

    render();
  }
};

// Shorthand helper global
window.Roulette = RouletteController;

// Auto init on DOMContentLoaded
document.addEventListener('DOMContentLoaded', () => {
  window.Roulette.init();
});
