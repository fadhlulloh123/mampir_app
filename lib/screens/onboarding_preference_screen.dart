import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/preference_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// ============================================================
/// ONBOARDING & WELCOME SCREEN — SESUAI SplashS contoh.jpeg
/// ============================================================
/// Step 1: Layar Selamat Datang (MAMPIR, Subjudul Emas, Ilustrasi, Tombol "Mulai")
/// Step 2: Atur Budget, Wilayah BARLINGMASCAKEB, dan Preferensi
/// Setelah selesai -> is_first_launch = false -> Masuk HomeScreen
/// ============================================================
class OnboardingPreferenceScreen extends StatefulWidget {
  const OnboardingPreferenceScreen({super.key});

  @override
  State<OnboardingPreferenceScreen> createState() =>
      _OnboardingPreferenceScreenState();
}

class _OnboardingPreferenceScreenState
    extends State<OnboardingPreferenceScreen> {
  final PreferenceService _prefService = PreferenceService();
  final PageController _pageController = PageController();

  bool _isLoading = false;

  // Preferensi pengguna
  String _selectedRegion = 'Purwokerto / Banyumas';
  int _selectedBudget = 25000;
  final Set<String> _selectedPreferences = {'WiFi', 'Colokan', 'Nongkrong'};

  late TextEditingController _budgetController;
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static const List<String> _regions = [
    'Purwokerto / Banyumas',
    'Purbalingga',
    'Banjarnegara',
    'Cilacap',
    'Kebumen',
  ];

  static const List<Map<String, dynamic>> _quickChips = [
    {'label': '15K', 'value': 15000},
    {'label': '25K', 'value': 25000},
    {'label': '50K', 'value': 50000},
    {'label': '75K', 'value': 75000},
    {'label': '100K', 'value': 100000},
    {'label': 'Bebas', 'value': 150000},
  ];

  static const List<String> _allPreferences = [
    'WiFi',
    'Colokan',
    'AC',
    'Parkir',
    'Nongkrong',
    'Outdoor',
    'Indoor',
    'Rooftop',
    'Romantis',
    'Ramah Hewan',
    'Musik',
  ];

  @override
  void initState() {
    super.initState();
    _budgetController = TextEditingController(
      text: _currencyFormatter.format(_selectedBudget),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _onBudgetSliderChanged(int val) {
    setState(() {
      _selectedBudget = val;
      if (val >= 150000) {
        _budgetController.text = 'Bebas';
      } else {
        _budgetController.text = _currencyFormatter.format(val);
      }
    });
  }

  void _onManualBudgetChanged(String val) {
    final cleanDigits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.isEmpty) return;
    final int? parsed = int.tryParse(cleanDigits);
    if (parsed != null) {
      setState(() {
        _selectedBudget = parsed.clamp(5000, 200000);
      });
    }
  }

  Future<void> _handleFinishOnboarding() async {
    setState(() => _isLoading = true);
    try {
      await _prefService.saveBudget(_selectedBudget);
      await _prefService.saveSelectedRegion(_selectedRegion);
      await _prefService.saveUserPreferences(_selectedPreferences.toList());
      await _prefService.setFirstLaunch(false);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Stack(
        children: [
          // Mandala Batik Background Decoration
          Positioned(
            top: 0,
            right: 0,
            width: 260,
            height: 260,
            child: CustomPaint(
              painter: MandalaOrnamentPainter(scale: 0.9),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: MandalaOrnamentPainter(scale: 0.6),
            ),
          ),

          SafeArea(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildWelcomePage(),
                _buildPreferenceSetupPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Step 1: Halaman Selamat Datang (Sesuai SplashS contoh.jpeg)
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Logo Pin & Mascot
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(70),
                child: Image.asset(
                  'assets/images/app_icon.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Judul Utama "MAMPIR"
          const Text(
            'MAMPIR',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Colors.white,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 12),

          // Subjudul Emas
          const Text(
            'Makan, Ampir, Pilih, dan Rekomendasi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.gold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Deskripsi
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tempat Makan dan Nongkrong Berdasarkan Budget dan Preferensi Kamu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),

          const Spacer(flex: 2),

          // Ilustrasi Cafe / Urban Line Art
          Container(
            height: 160,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.surfaceNavy.withValues(alpha: 0.3),
              border: Border.all(color: AppTheme.borderNavy.withValues(alpha: 0.5)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.storefront_rounded,
                  size: 90,
                  color: AppTheme.borderNavy,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeatureMiniCard(Icons.local_cafe_rounded, 'Cafe & Resto'),
                    _buildFeatureMiniCard(Icons.payments_rounded, 'Pas Budget'),
                    _buildFeatureMiniCard(Icons.map_rounded, 'Se-BARLINGMASCAKEB'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Tombol "Mulai"
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.orange.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Mulai',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeatureMiniCard(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderNavy),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.gold, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Step 2: Pengaturan Awal (Wilayah, Budget & Preferensi)
  Widget _buildPreferenceSetupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tombol Kembali
          Row(
            children: [
              IconButton(
                onPressed: () {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                'Atur Preferensi Awal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pilih Wilayah
          const Text(
            'Wilayah Utama Kamu',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.searchNavy,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderNavy),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRegion,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceNavy,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.gold),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                items: _regions.map((region) {
                  return DropdownMenuItem<String>(
                    value: region,
                    child: Text(region),
                  );
                }).toList(),
                onChanged: (newRegion) {
                  if (newRegion != null) {
                    setState(() => _selectedRegion = newRegion);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Budget Maksimal
          const Text(
            'Budget Maksimal per Orang (Rp)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // TextFormField Manual
          Container(
            decoration: BoxDecoration(
              color: AppTheme.searchNavy,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderNavy),
            ),
            child: TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                hintText: 'Tulis nominal budget',
                hintStyle: TextStyle(color: AppTheme.textMuted),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
              onChanged: _onManualBudgetChanged,
            ),
          ),
          const SizedBox(height: 10),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.orange,
              inactiveTrackColor: AppTheme.borderNavy,
              thumbColor: AppTheme.gold,
              overlayColor: AppTheme.gold.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _selectedBudget.toDouble().clamp(5000.0, 150000.0),
              min: 5000,
              max: 150000,
              divisions: 29,
              onChanged: (val) => _onBudgetSliderChanged(val.toInt()),
            ),
          ),

          // Quick Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickChips.map((chip) {
              final val = chip['value'] as int;
              final isSelected = val >= 150000
                  ? _selectedBudget >= 150000
                  : (_selectedBudget - val).abs() < 5000;

              return GestureDetector(
                onTap: () => _onBudgetSliderChanged(val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected ? null : AppTheme.surfaceNavy,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : AppTheme.borderNavy,
                    ),
                  ),
                  child: Text(
                    chip['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),

          // Preferensi
          const Text(
            'Fasilitas & Suasana Favorit',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allPreferences.map((pref) {
              final isSelected = _selectedPreferences.contains(pref);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedPreferences.remove(pref);
                    } else {
                      _selectedPreferences.add(pref);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected ? null : AppTheme.surfaceNavy,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : AppTheme.borderNavy,
                    ),
                  ),
                  child: Text(
                    pref,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Tombol Selesai & Masuk Beranda
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.orange.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleFinishOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Simpan & Buka Beranda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
