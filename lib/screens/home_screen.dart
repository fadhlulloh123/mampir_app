import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';
import '../services/api_service.dart';
import '../services/preference_service.dart';
import 'place_detail_screen.dart';
import 'add_place_screen.dart';

/// ============================================================
/// HOME SCREEN — HALAMAN UTAMA APLIKASI MAMPIR
/// ============================================================
/// Layar utama dengan BottomNavigationBar 3 tab:
/// 1. Tab Explore: Rekomendasi tempat berbasis Smart Scoring,
///    Quick Adjust budget & kota, serta filter tag.
/// 2. Tab Peta: Visualisasi sebaran tempat di BARLINGMASCAKEB
///    menggunakan OpenStreetMap (flutter_map) gratis tanpa API key.
/// 3. Tab Favorit: Daftar tempat yang telah di-bookmark oleh pengguna.
/// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Warna tema aplikasi MAMPIR (Material 3)
  static const Color _primaryColor = Color(0xFFFF6B35); // Warm Orange
  static const Color _secondaryColor = Color(0xFF004E64); // Deep Teal
  static const Color _backgroundColor = Color(0xFFF8F9FA); // Soft Cream

  final ApiService _apiService = ApiService();
  final PreferenceService _preferenceService = PreferenceService();

  static const List<String> _cities = [
    'Semua Wilayah',
    'Banyumas',
    'Purbalingga',
    'Banjarnegara',
    'Cilacap',
    'Kebumen',
  ];

  static const List<String> _availableTags = [
    'Cafe & Ngopi',
    'Makanan Berat',
    'Murah Meriah',
    'Wi-Fi & Colokan',
    'Outdoor/Santai',
    'Buka 24 Jam',
  ];

  // Tab yang aktif (0: Explore, 1: Peta, 2: Favorit)
  int _currentIndex = 0;

  // Data tempat dari API Service
  List<PlaceModel> _allPlaces = [];
  bool _isLoading = true;

  // Preferensi Pengguna
  int _userBudget = 50000;
  String _selectedCity = 'Semua Wilayah';
  List<String> _userTags = [];
  List<String> _favoriteIds = [];

  // Filter tag aktif pada tab Explore
  final Set<String> _activeFilterTags = {};

  // Tempat yang dipilih pada tab Peta untuk preview card
  PlaceModel? _selectedMapPlace;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  /// Memuat tempat dari Web Service dan preferensi lokal secara bersamaan
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.fetchPlaces(),
        _preferenceService.getBudget(),
        _preferenceService.getCity(),
        _preferenceService.getTags(),
        _preferenceService.getFavorites(),
      ]);

      if (mounted) {
        setState(() {
          _allPlaces = results[0] as List<PlaceModel>;
          _userBudget = results[1] as int;
          _selectedCity = results[2] as String;
          _userTags = results[3] as List<String>;
          _favoriteIds = results[4] as List<String>;
          // Default filter tag awal mengikuti preferensi user jika ada
          _activeFilterTags.addAll(_userTags);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Refresh data favorit saja (dipanggil setelah kembali dari detail screen)
  Future<void> _refreshFavorites() async {
    final favs = await _preferenceService.getFavorites();
    if (mounted) {
      setState(() => _favoriteIds = favs);
    }
  }

  /// Toggle favorit dari list view
  Future<void> _toggleFavorite(String placeId) async {
    final newStatus = await _preferenceService.toggleFavorite(placeId);
    await _refreshFavorites();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Disimpan ke daftar favorit'
                : 'Dihapus dari daftar favorit',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Reset semua filter ke kondisi awal
  Future<void> _resetFilter() async {
    setState(() {
      _selectedCity = 'Semua Wilayah';
      _userBudget = 100000;
      _activeFilterTags.clear();
    });
    await _preferenceService.saveCity('Semua Wilayah');
    await _preferenceService.saveBudget(100000);
  }

  /// Filter tempat berdasarkan kota, budget, dan tag;
  /// lalu diurutkan dengan algoritma Smart Scoring (kecocokan tag + rating)
  List<PlaceModel> get _filteredAndSortedPlaces {
    return _allPlaces.where((place) {
      // 1. Filter Kota
      if (_selectedCity != 'Semua Wilayah' && place.city != _selectedCity) {
        return false;
      }
      // 2. Filter Budget (avgPrice <= userBudget)
      if (place.avgPrice > _userBudget) {
        return false;
      }
      // 3. Filter Tag (jika ada tag aktif, minimal cocok 1 tag)
      if (_activeFilterTags.isNotEmpty &&
          !place.tags.any((t) => _activeFilterTags.contains(t))) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        // Smart Scoring: (matchScore * 1.5) + rating
        final scoreA = (a.matchScore(_userTags) * 1.5) + a.rating;
        final scoreB = (b.matchScore(_userTags) * 1.5) + b.rating;
        return scoreB.compareTo(scoreA); // Descending (tertinggi di atas)
      });
  }

  /// Format angka ke Rupiah (cth: 25.000)
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

  /// Bottom Sheet untuk Quick Adjust (Budget, Kota, & Tag)
  void _showQuickAdjustBottomSheet() {
    double tempBudget = _userBudget.toDouble();
    String tempCity = _selectedCity;
    final Set<String> tempTags = Set.from(_userTags);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ubah Filter & Preferensi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2B2D42),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    // 1. Pilih Kota
                    const Text(
                      'Wilayah',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tempCity,
                          isExpanded: true,
                          items: _cities.map((city) {
                            return DropdownMenuItem(
                              value: city,
                              child: Text(city,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => tempCity = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Budget Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Budget Maksimal per Orang',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2B2D42),
                          ),
                        ),
                        Text(
                          'Rp${formatRupiah(tempBudget.toInt())}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _primaryColor,
                        inactiveTrackColor: _primaryColor.withValues(alpha: 0.2),
                        thumbColor: _primaryColor,
                      ),
                      child: Slider(
                        min: 10000,
                        max: 100000,
                        divisions: 18,
                        value: tempBudget,
                        label: 'Rp${formatRupiah(tempBudget.toInt())}',
                        onChanged: (val) {
                          setModalState(() => tempBudget = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. Tag Preferensi
                    const Text(
                      'Suasana Favorit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSel = tempTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSel,
                          selectedColor: _secondaryColor,
                          backgroundColor: _backgroundColor,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : const Color(0xFF2B2D42),
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                tempTags.add(tag);
                              } else {
                                tempTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Simpan
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final newBudget = tempBudget.toInt();
                          final newCity = tempCity;
                          final newTags = tempTags.toList();

                          await _preferenceService.saveBudget(newBudget);
                          await _preferenceService.saveCity(newCity);
                          await _preferenceService.saveTags(newTags);

                          if (mounted) {
                            setState(() {
                              _userBudget = newBudget;
                              _selectedCity = newCity;
                              _userTags = newTags;
                              _activeFilterTags.clear();
                              _activeFilterTags.addAll(newTags);
                            });
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Terapkan Preferensi',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MAMPIR',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: _primaryColor,
              ),
            ),
            Text(
              'Kuliner & Nongkrong BARLINGMASCAKEB',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined, color: _primaryColor),
            tooltip: 'Usulkan Tempat Baru',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPlaceScreen(),
                ),
              );
              if (result == true) {
                _loadAllData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _secondaryColor),
            tooltip: 'Segarkan Data',
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _primaryColor),
                  SizedBox(height: 16),
                  Text(
                    'Mengambil data tempat mampir...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ],
              ),
            )
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildExploreTab(),
                _buildMapTab(),
                _buildFavoritesTab(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // Jika berpindah ke favorit, segarkan datanya
            if (index == 2) _refreshFavorites();
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Peta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'Favorit',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: EXPLORE
  // ===========================================================================
  Widget _buildExploreTab() {
    final places = _filteredAndSortedPlaces;

    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: _loadAllData,
      child: CustomScrollView(
        slivers: [
          // Quick Adjust Bar di bagian atas
          SliverToBoxAdapter(
            child: _buildQuickAdjustHeader(),
          ),

          // Filter Chips Horizontal untuk Tag
          SliverToBoxAdapter(
            child: _buildTagFilterBar(),
          ),

          // Header Jumlah Hasil
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${places.length} Tempat Ditemukan',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                  if (_activeFilterTags.isNotEmpty ||
                      _selectedCity != 'Semua Wilayah' ||
                      _userBudget < 100000)
                    GestureDetector(
                      onTap: _resetFilter,
                      child: const Text(
                        'Reset Filter',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // List Cards Tempat atau Empty State
          if (places.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final place = places[index];
                    return _buildPlaceCard(place);
                  },
                  childCount: places.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Widget Quick Adjust menampilkan kota & budget saat ini
  Widget _buildQuickAdjustHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Info Kota & Budget
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: _primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      _selectedCity,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        size: 16, color: _secondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Max: Rp${formatRupiah(_userBudget)} / orang',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tombol Ubah / Edit
          ElevatedButton.icon(
            onPressed: _showQuickAdjustBottomSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor.withValues(alpha: 0.12),
              foregroundColor: _primaryColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, size: 16),
            label: const Text(
              'Ubah',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// Bar Tag Filter horizontal
  Widget _buildTagFilterBar() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _availableTags.length,
        itemBuilder: (context, index) {
          final tag = _availableTags[index];
          final isSelected = _activeFilterTags.contains(tag);
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(tag),
              selected: isSelected,
              selectedColor: _secondaryColor,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF495057),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? _secondaryColor : Colors.grey.shade300,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _activeFilterTags.add(tag);
                  } else {
                    _activeFilterTags.remove(tag);
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }

  /// Card untuk setiap item tempat makan
  Widget _buildPlaceCard(PlaceModel place) {
    final isWithinBudget = place.isWithinBudget(_userBudget);
    final isFav = _favoriteIds.contains(place.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaceDetailScreen(
                place: place,
                userBudget: _userBudget,
              ),
            ),
          );
          _refreshFavorites();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Utama + Badge Pas di Kantong + Favorite Icon
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    place.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        color: _secondaryColor.withValues(alpha: 0.2),
                        child: const Center(
                          child: Icon(Icons.restaurant,
                              size: 48, color: _secondaryColor),
                        ),
                      );
                    },
                  ),
                ),
                // Badge "Pas di Kantong!"
                if (isWithinBudget)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2EC4B6),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Pas di Kantong!',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Tombol Bookmark Favorit
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    radius: 18,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.redAccent : Colors.grey.shade700,
                        size: 20,
                      ),
                      onPressed: () => _toggleFavorite(place.id),
                    ),
                  ),
                ),
              ],
            ),

            // Informasi Tempat
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama & Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2B2D42),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 15, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              place.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF856404),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Kota & Kategori
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: _primaryColor),
                      const SizedBox(width: 2),
                      Text(
                        place.city,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  ${place.category}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rentang Harga
                  Text(
                    place.priceRange,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Chips Tag Kecil
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: place.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _secondaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tampilan Empty State jika tidak ada tempat yang cocok filter
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 60,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Tidak Ada Tempat yang Sesuai',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2B2D42),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba naikkan budget, pilih wilayah lain, atau hapus filter tag untuk melihat rekomendasi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _resetFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset Filter'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: PETA (OPENSTREETMAP VIA FLUTTER_MAP)
  // ===========================================================================
  Widget _buildMapTab() {
    final places = _filteredAndSortedPlaces;

    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-7.45, 109.25), // Area BARLINGMASCAKEB
            initialZoom: 9.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.mampir.mampir_app',
            ),
            MarkerLayer(
              markers: places.map((place) {
                final isSelected = _selectedMapPlace?.id == place.id;
                return Marker(
                  point: LatLng(place.latitude, place.longitude),
                  width: isSelected ? 48 : 40,
                  height: isSelected ? 48 : 40,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedMapPlace = place);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? _secondaryColor : _primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Map Header Banner
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: _secondaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Menampilkan ${places.length} titik tempat di peta',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2B2D42),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Preview Card saat Marker Ditekan
        if (_selectedMapPlace != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _selectedMapPlace!.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 70,
                        height: 70,
                        color: _primaryColor.withValues(alpha: 0.1),
                        child: const Icon(Icons.restaurant, color: _primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedMapPlace!.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2B2D42),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedMapPlace!.city} • ${_selectedMapPlace!.priceRange}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlaceDetailScreen(
                                    place: _selectedMapPlace!,
                                    userBudget: _userBudget,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Lihat Detail',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() => _selectedMapPlace = null);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: FAVORIT / BOOKMARK
  // ===========================================================================
  Widget _buildFavoritesTab() {
    final favoritePlaces = _allPlaces
        .where((place) => _favoriteIds.contains(place.id))
        .toList();

    if (favoritePlaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 64,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Belum Ada Tempat Favorit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2B2D42),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tandai tempat makan dan nongkrong yang kamu suka dengan menekan ikon hati.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favoritePlaces.length,
      itemBuilder: (context, index) {
        final place = favoritePlaces[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                place.imageUrl,
                width: 65,
                height: 65,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 65,
                  height: 65,
                  color: _primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.restaurant, color: _primaryColor),
                ),
              ),
            ),
            title: Text(
              place.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2D42),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  '${place.city} • ${place.priceRange}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              tooltip: 'Hapus dari Favorit',
              onPressed: () => _toggleFavorite(place.id),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaceDetailScreen(
                    place: place,
                    userBudget: _userBudget,
                  ),
                ),
              );
              _refreshFavorites();
            },
          ),
        );
      },
    );
  }
}
