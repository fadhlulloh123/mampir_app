import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';
import '../services/api_service.dart';
import '../services/preference_service.dart';
import '../services/recommendation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/budget_filter_modal.dart';
import 'add_place_screen.dart';
import 'notification_screen.dart';
import 'place_detail_screen.dart';
import 'route_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// ============================================================
/// HOME SCREEN — SESUAI beranda.jpeg & SPESIFIKASI #8
/// ============================================================
/// Fitur Lengkap:
/// - Header: Pin Oranye + Dropdown Purwokerto & Sekitarnya + Lonceng Notifikasi + Pengaturan
/// - Search Bar + Filter Modal
/// - 5 Tombol Kategori Bulat Gradasi: Makan, Nongkrong, Cafe, Restoran, Lainnya
/// - Rekomendasi untuk kamu (Featured Card & Carousel Cerdas)
/// - Tempat Populer (2-Column Grid)
/// - 4-Tab Bottom Navigation: Beranda, Cari, Favorit, Peta
/// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final PreferenceService _prefService = PreferenceService();

  int _currentTabIndex = 0; // 0: Beranda, 1: Cari, 2: Favorit, 3: Peta

  // Data State
  List<PlaceModel> _allPlaces = [];
  bool _isLoading = true;

  // Filter State
  String _selectedRegion = 'Purwokerto Kota';
  int _userBudget = 25000;
  Set<String> _userPreferences = {'WiFi', 'Colokan'};
  Set<String> _favoriteIds = {};
  String? _selectedCategory; // null = semua, or Makan, Nongkrong, Cafe, Restoran, Lainnya

  // Map state
  PlaceModel? _selectedMapPlace;

  // Favorit tab category filter
  String _selectedFavCategory = 'Semua';

  static const List<String> _purwokertoRegions = [
    'Semua Wilayah',
    'Purwokerto Kota',
    'Baturraden',
    'Purwokerto Utara (Unsoed)',
    'Sokaraja',
    'Purwokerto Timur & Sumbang',
    'Purwokerto Barat & Selatan',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferencesAndData();
  }

  Future<void> _loadPreferencesAndData() async {
    setState(() => _isLoading = true);

    final region = await _prefService.getSelectedRegion();
    final budget = await _prefService.getBudget();
    final prefs = await _prefService.getUserPreferences();
    final favs = await _prefService.getFavorites();

    final places = await _apiService.fetchPlaces();

    if (mounted) {
      setState(() {
        _selectedRegion = region;
        _userBudget = budget;
        if (prefs.isNotEmpty) _userPreferences = prefs.toSet();
        _favoriteIds = favs.toSet();
        _allPlaces = places;
        _isLoading = false;
      });
    }
  }

  Future<void> _onRegionChanged(String? newRegion) async {
    if (newRegion == null) return;
    setState(() => _selectedRegion = newRegion);
    await _prefService.saveSelectedRegion(newRegion);
  }

  Future<void> _toggleFavorite(String placeId) async {
    final isFav = await _prefService.toggleFavorite(placeId);
    setState(() {
      if (isFav) {
        _favoriteIds.add(placeId);
      } else {
        _favoriteIds.remove(placeId);
      }
    });
  }

  Future<void> _openFilterModal() async {
    final result = await BudgetFilterModal.show(
      context,
      currentBudget: _userBudget,
      currentPreferences: _userPreferences,
    );

    if (result != null) {
      setState(() {
        _userBudget = result.budget;
        _userPreferences = result.preferences;
      });
      await _prefService.saveBudget(result.budget);
      await _prefService.saveUserPreferences(result.preferences.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.gold),
            )
          : IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildHomeTab(),
                _buildSearchTab(),
                _buildFavoritesTab(),
                _buildMapTab(),
              ],
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION BAR (4 TABS SESUAI SPESIFIKASI #8)
  // ===========================================================================
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1426),
        border: const Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Beranda'),
              _buildNavItem(1, Icons.search_rounded, 'Cari'),
              _buildNavItem(2, Icons.favorite_rounded, 'Favorit'),
              _buildNavItem(3, Icons.map_outlined, 'Peta'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentTabIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppTheme.gold : const Color(0xFF64748B),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.gold : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: BERANDA (SESUAI beranda.jpeg)
  // ===========================================================================
  Widget _buildHomeTab() {
    // Jalankan Algoritma Rekomendasi Cerdas Hybrid
    final recommendations = RecommendationService.getRecommendations(
      allPlaces: _allPlaces,
      userBudget: _userBudget,
      selectedRegion: _selectedRegion,
      selectedCategory: _selectedCategory,
      userPreferences: _userPreferences.toList(),
    );

    // Tempat Populer di wilayah terpilih
    List<PlaceModel> popularPlaces = _allPlaces.where((p) {
      if (_selectedRegion.isNotEmpty &&
          !_selectedRegion.toLowerCase().contains('semua')) {
        final regClean = _selectedRegion.split('(')[0].trim().toLowerCase();
        final pCity = p.city.toLowerCase();
        final pAddr = p.address.toLowerCase();
        if (!pCity.contains(regClean) && !pAddr.contains(regClean)) {
          return false;
        }
      }
      return true;
    }).toList();
    if (popularPlaces.isEmpty) {
      popularPlaces = List.from(_allPlaces);
    }
    popularPlaces.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));

    final featured = recommendations.isNotEmpty
        ? recommendations.first.place
        : (_allPlaces.isNotEmpty ? _allPlaces.first : null);

    return Stack(
      children: [
        // Background Mandala Batik
        Positioned(
          top: 0,
          right: 0,
          width: 280,
          height: 280,
          child: CustomPaint(
            painter: MandalaOrnamentPainter(scale: 0.95),
          ),
        ),

        SafeArea(
          child: RefreshIndicator(
            color: AppTheme.gold,
            backgroundColor: AppTheme.surfaceNavy,
            onRefresh: _loadPreferencesAndData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // 1. Header: Pin Oranye + Dropdown Purwokerto & Sekitarnya + Lonceng
                  _buildTopHeader(),
                  const SizedBox(height: 18),

                  // 2. Search Bar + Filter Button
                  _buildSearchBar(),
                  const SizedBox(height: 22),

                  // 3. Section Kategori
                  _buildCategorySection(),
                  const SizedBox(height: 26),

                  // 4. Section "Rekomendasi untuk kamu"
                  _buildRecommendationSection(featured, recommendations),
                  const SizedBox(height: 26),

                  // 5. Section "Tempat Populer"
                  _buildPopularSection(popularPlaces),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 1. Top Header: Pin Oranye + Region Dropdown + Bell + Setting Icon
  Widget _buildTopHeader() {
    return Row(
      children: [
        // Pin Oranye
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.orange.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on,
            color: AppTheme.orange,
            size: 22,
          ),
        ),
        const SizedBox(width: 8),

        // Dropdown Wilayah
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRegion,
              isDense: true,
              dropdownColor: AppTheme.surfaceNavy,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Colors.white, size: 20),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              items: _purwokertoRegions.map((region) {
                return DropdownMenuItem<String>(
                  value: region,
                  child: Text(
                    region,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _onRegionChanged,
            ),
          ),
        ),

        // Tombol Tambah Tempat Baru (+)
        IconButton(
          icon: const Icon(Icons.add_circle_outline,
              color: AppTheme.gold, size: 24),
          tooltip: 'Tambah Tempat Baru',
          onPressed: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const AddPlaceScreen()),
            );
            if (res == true) _loadPreferencesAndData();
          },
        ),

        // Lonceng Notifikasi
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded,
              color: AppTheme.gold, size: 26),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const NotificationScreen()),
            );
          },
        ),

        // Pengaturan
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: Colors.white70, size: 24),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  /// 2. Search Bar + Filter Button (Sesuai mockup)
  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.searchNavy,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.borderNavy),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: AppTheme.textMuted, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => SearchScreen(
                      allPlaces: _allPlaces,
                      autoFocus: true,
                    ),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: const Text(
                'Cari tempat makan / nongkrong...',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: AppTheme.borderNavy,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppTheme.gold, size: 22),
            onPressed: _openFilterModal,
            tooltip: 'Filter Budget & Preferensi',
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// 3. Section Kategori: 5 Tombol Lingkaran Bergradasi Emas-Oranye
  Widget _buildCategorySection() {
    final categories = [
      {'name': 'Makan', 'icon': Icons.ramen_dining_rounded},
      {'name': 'Nongkrong', 'icon': Icons.wine_bar_rounded},
      {'name': 'Cafe', 'icon': Icons.coffee_rounded},
      {'name': 'Restoran', 'icon': Icons.restaurant_rounded},
      {'name': 'Lainnya', 'icon': Icons.more_horiz_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: categories.map((cat) {
            final name = cat['name'] as String;
            final isSelected = _selectedCategory == name;

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (_selectedCategory == name) {
                    _selectedCategory = null;
                  } else {
                    _selectedCategory = name;
                  }
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppTheme.warmGradient
                          : AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.orange.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      size: 26,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? AppTheme.gold : Colors.white,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 4. Section "Rekomendasi untuk kamu"
  Widget _buildRecommendationSection(
      PlaceModel? featured, List<RecommendationResult> recs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rekomendasi untuk kamu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => SearchScreen(allPlaces: _allPlaces),
                  ),
                );
              },
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (featured == null)
          const Center(
            child: Text(
              'Belum ada rekomendasi tempat',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          )
        else
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => PlaceDetailScreen(
                    place: featured,
                    userBudget: _userBudget,
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                // Featured Card Container
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderNavy),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image
                        Image.network(
                          featured.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            color: AppTheme.surfaceNavy,
                            child: const Icon(Icons.restaurant,
                                color: AppTheme.orange, size: 50),
                          ),
                        ),

                        // Dark Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.2),
                                Colors.black.withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                        ),

                        // Text Details
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                featured.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${featured.category} • ${featured.priceRange}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: AppTheme.gold, size: 18),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${featured.rating.toStringAsFixed(1)} (${featured.formattedReviewCount})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.location_on,
                                      color: AppTheme.orange, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    featured.formattedDistance(),
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tombol Hati (Favorit)
                Positioned(
                  top: 12,
                  right: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    radius: 20,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _favoriteIds.contains(featured.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _favoriteIds.contains(featured.id)
                            ? AppTheme.orange
                            : Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _toggleFavorite(featured.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 5. Section "Tempat Populer" (2-Column Grid)
  Widget _buildPopularSection(List<PlaceModel> places) {
    final list = places.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tempat Populer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => SearchScreen(allPlaces: _allPlaces),
                  ),
                );
              },
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final place = list[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => PlaceDetailScreen(
                      place: place,
                      userBudget: _userBudget,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardNavy,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderNavy),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        place.imageUrl,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => Container(
                          height: 100,
                          color: AppTheme.surfaceNavy,
                          child: const Icon(Icons.store, color: AppTheme.orange),
                        ),
                      ),
                    ),

                    // Info
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${place.category} • ${place.priceRange}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppTheme.gold, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                '${place.rating.toStringAsFixed(1)} (${place.formattedReviewCount})',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                place.formattedDistance(),
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: CARI (MENYEDIAKAN SEARCHSCREEN LENGKAP DENGAN RIWAYAT & FILTER)
  // ===========================================================================
  Widget _buildSearchTab() {
    return SearchScreen(allPlaces: _allPlaces);
  }

  // ===========================================================================
  // TAB 3: FAVORIT (SESUAI simpanFavorit_mampir.jpeg)
  // ===========================================================================
  Widget _buildFavoritesTab() {
    final savedPlaces = _allPlaces
        .where((place) => _favoriteIds.contains(place.id))
        .toList();

    final filtered = _selectedFavCategory == 'Semua'
        ? savedPlaces
        : savedPlaces
            .where((p) => p.category
                .toLowerCase()
                .contains(_selectedFavCategory.toLowerCase()))
            .toList();

    return Stack(
      children: [
        // Background Mandala
        Positioned(
          top: 0,
          right: 0,
          width: 260,
          height: 260,
          child: CustomPaint(
            painter: MandalaOrnamentPainter(scale: 0.9),
          ),
        ),

        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Favorit
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Favorit',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${savedPlaces.length} tempat disimpan',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded,
                          color: AppTheme.gold, size: 24),
                      onPressed: _openFilterModal,
                    ),
                  ],
                ),
              ),

              // Filter Chips: Semua, Cafe, Restoran
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: ['Semua', 'Cafe', 'Restoran'].map((cat) {
                    final isSel = _selectedFavCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFavCategory = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSel ? AppTheme.primaryGradient : null,
                          color: isSel ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel ? Colors.transparent : AppTheme.gold,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSel ? Colors.white : AppTheme.gold,
                            fontWeight:
                                isSel ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Daftar Kartu Favorit
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceNavy,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.borderNavy),
                              ),
                              child: const Icon(
                                Icons.favorite_border_rounded,
                                size: 54,
                                color: AppTheme.orange,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada tempat favorit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Sentuh ikon hati untuk menyimpan tempat makan favoritmu.',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final place = filtered[index];

                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => PlaceDetailScreen(
                                    place: place,
                                    userBudget: _userBudget,
                                  ),
                                ),
                              );
                              final favs = await _prefService.getFavorites();
                              if (mounted) {
                                setState(() => _favoriteIds = favs.toSet());
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceNavy,
                                borderRadius: BorderRadius.circular(18),
                                border:
                                    Border.all(color: AppTheme.borderNavy),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      place.imageUrl,
                                      width: 85,
                                      height: 85,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) =>
                                          Container(
                                        width: 85,
                                        height: 85,
                                        color: AppTheme.searchNavy,
                                        child: const Icon(Icons.store,
                                            color: AppTheme.orange),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                place.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () =>
                                                  _toggleFavorite(place.id),
                                              child: const Icon(
                                                Icons.favorite,
                                                color: AppTheme.orange,
                                                size: 22,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                color: AppTheme.gold,
                                                size: 16),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${place.rating.toStringAsFixed(1)} (${place.formattedReviewCount})',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '• ${place.formattedDistance()}',
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${place.category} • ${place.priceRange}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 4: PETA (OPENSTREETMAP VIA FLUTTER_MAP)
  // ===========================================================================
  Widget _buildMapTab() {
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-7.3850, 109.2380), // Poros Purwokerto - Baturraden
            initialZoom: 12.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.mampir.mampir_app',
            ),
            MarkerLayer(
              markers: _allPlaces.map((place) {
                final isSelected = _selectedMapPlace?.id == place.id;
                return Marker(
                  point: LatLng(place.latitude, place.longitude),
                  width: isSelected ? 52 : 42,
                  height: isSelected ? 52 : 42,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedMapPlace = place);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? AppTheme.warmGradient
                            : AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
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

        // Header Banner Peta
        Positioned(
          top: 14,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.scaffoldBg.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderNavy),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    size: 18, color: AppTheme.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Menampilkan ${_allPlaces.length} tempat di Purwokerto & Sekitarnya',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Preview Card saat Marker Peta Ditekan
        if (_selectedMapPlace != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.orange),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _selectedMapPlace!.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        width: 70,
                        height: 70,
                        color: AppTheme.surfaceNavy,
                        child: const Icon(Icons.store, color: AppTheme.orange),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_selectedMapPlace!.city} • ${_selectedMapPlace!.priceRange}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => PlaceDetailScreen(
                                      place: _selectedMapPlace!,
                                      userBudget: _userBudget,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.surfaceNavy,
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                    color: AppTheme.borderNavy),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Detail',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => RouteScreen(
                                        place: _selectedMapPlace!),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Rute',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () =>
                        setState(() => _selectedMapPlace = null),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
