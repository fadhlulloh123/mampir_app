import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place_model.dart';
import '../services/preference_service.dart';

/// ============================================================
/// PLACE DETAIL SCREEN — MAMPIR APP
/// ============================================================
/// Halaman detail tempat makan/nongkrong yang menampilkan:
/// - Gambar utama dengan hero animation & fallback icon
/// - Nama tempat, kota, kategori, dan rating
/// - Badge "Pas di Kantong!" jika harga rata-rata <= budget pengguna
/// - Rentang harga (Min - Max) & jam operasional
/// - Tag fasilitas / suasana
/// - Daftar Menu Andalan (Menu Highlights) beserta harga Rupiah
/// - Alamat lengkap & tombol "Buka Rute di Google Maps"
/// - Tombol bookmark / favorit di AppBar (terintegrasi PreferenceService)
/// ============================================================
class PlaceDetailScreen extends StatefulWidget {
  final PlaceModel place;
  final int? userBudget;

  const PlaceDetailScreen({
    super.key,
    required this.place,
    this.userBudget,
  });

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  // Warna tema aplikasi MAMPIR (Material 3)
  static const Color _primaryColor = Color(0xFFFF6B35); // Warm Orange
  static const Color _secondaryColor = Color(0xFF004E64); // Deep Teal
  static const Color _backgroundColor = Color(0xFFF8F9FA); // Soft Cream

  final PreferenceService _preferenceService = PreferenceService();

  bool _isFavorite = false;
  int _effectiveBudget = 50000;
  bool _isLoadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Memuat status favorit dan budget pengguna
  Future<void> _loadPreferences() async {
    final fav = await _preferenceService.isFavorite(widget.place.id);
    final budget = widget.userBudget ?? await _preferenceService.getBudget();

    if (mounted) {
      setState(() {
        _isFavorite = fav;
        _effectiveBudget = budget;
        _isLoadingFavorite = false;
      });
    }
  }

  /// Toggle bookmark favorit di SharedPreferences
  Future<void> _handleToggleFavorite() async {
    final newStatus = await _preferenceService.toggleFavorite(widget.place.id);
    if (mounted) {
      setState(() {
        _isFavorite = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Disimpan ke daftar favorit!'
                : 'Dihapus dari daftar favorit.',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: newStatus ? _secondaryColor : Colors.grey.shade800,
        ),
      );
    }
  }

  /// Buka Google Maps menggunakan url_launcher
  Future<void> _openGoogleMaps() async {
    final lat = widget.place.latitude;
    final lng = widget.place.longitude;
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka Google Maps.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka rute: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Helper format Rupiah (cth: 25.000)
  String formatRupiah(int amount) {
    final str = amount.toString();
    final result = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(str[i]);
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final isBudgetFit = place.isWithinBudget(_effectiveBudget);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        slivers: [
          // =================== APP BAR DENGAN GAMBAR ===================
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: _secondaryColor,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: _isLoadingFavorite
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _isFavorite ? Colors.redAccent : Colors.white,
                            size: 22,
                          ),
                    tooltip: 'Simpan ke Favorit',
                    onPressed: _handleToggleFavorite,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    place.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: _secondaryColor,
                        child: const Center(
                          child: Icon(
                            Icons.restaurant_rounded,
                            size: 80,
                            color: Colors.white54,
                          ),
                        ),
                      );
                    },
                  ),
                  // Gradient shadow bawah agar teks terbaca jelas
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color.fromARGB(160, 0, 0, 0),
                        ],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =================== KONTEN DETAIL ===================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges: Kategori & "Pas di Kantong!"
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _secondaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          place.category.isNotEmpty
                              ? place.category
                              : 'Tempat Makan',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _secondaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isBudgetFit)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2EC4B6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2EC4B6),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: Color(0xFF0F9B8E),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Pas di Kantong!',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F9B8E),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nama Tempat
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2B2D42),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Kota & Rating
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: _primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        place.city,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF495057),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              place.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF856404),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // =================== INFO BOX RENTANG HARGA & JAM BUKA ===================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Rentang Harga
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.payments_outlined,
                                    color: _primaryColor, size: 22),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Rentang Harga',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6C757D),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      place.priceRange,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2B2D42),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.grey.shade200,
                        ),
                        // Jam Buka
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _secondaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.access_time_rounded,
                                      color: _secondaryColor, size: 22),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Jam Buka',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6C757D),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        place.openHours.isNotEmpty
                                            ? place.openHours
                                            : 'Setiap Hari',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2B2D42),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // =================== DESKRIPSI ===================
                  const Text(
                    'Tentang Tempat Ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2B2D42),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.description.isNotEmpty
                        ? place.description
                        : 'Belum ada deskripsi untuk tempat ini.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF495057),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // =================== TAG FASILITAS / SUASANA ===================
                  const Text(
                    'Fasilitas & Suasana',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2B2D42),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: place.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _secondaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // =================== MENU HIGHLIGHTS ===================
                  if (place.menuHighlights.isNotEmpty) ...[
                    const Text(
                      'Menu Andalan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: place.menuHighlights.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final item = place.menuHighlights[index];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fastfood_rounded,
                                size: 16,
                                color: _primaryColor,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2B2D42),
                              ),
                            ),
                            trailing: Text(
                              'Rp${formatRupiah(item.price)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _primaryColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // =================== ALAMAT ===================
                  const Text(
                    'Alamat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2B2D42),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 20,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            place.address.isNotEmpty
                                ? place.address
                                : 'Alamat lengkap belum tersedia.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF495057),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // =================== TOMBOL BUKA RUTE ===================
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _openGoogleMaps,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.directions_rounded, size: 22),
                      label: const Text(
                        'Buka Rute di Google Maps',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
