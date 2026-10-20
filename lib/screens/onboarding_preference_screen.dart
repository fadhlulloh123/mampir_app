import 'package:flutter/material.dart';
import '../services/preference_service.dart';
import 'home_screen.dart';

/// ============================================================
/// ONBOARDING PREFERENCE SCREEN — MAMPIR APP
/// ============================================================
/// Layar pertama yang dilihat pengguna baru untuk mengatur:
/// 1. Kota pilihan di wilayah BARLINGMASCAKEB
/// 2. Budget maksimal per orang (Slider & Quick Pick Chips)
/// 3. Tag preferensi / selera tempat nongkrong (Multi-select)
///
/// Setelah disimpan, preferensi ini digunakan oleh Smart Scoring
/// di HomeScreen untuk merekomendasikan tempat terbaik.
/// ============================================================
class OnboardingPreferenceScreen extends StatefulWidget {
  const OnboardingPreferenceScreen({super.key});

  @override
  State<OnboardingPreferenceScreen> createState() =>
      _OnboardingPreferenceScreenState();
}

class _OnboardingPreferenceScreenState
    extends State<OnboardingPreferenceScreen> {
  // Warna tema aplikasi MAMPIR (Material 3)
  static const Color _primaryColor = Color(0xFFFF6B35); // Warm Orange
  static const Color _secondaryColor = Color(0xFF004E64); // Deep Teal
  static const Color _backgroundColor = Color(0xFFF8F9FA); // Soft Cream

  final PreferenceService _preferenceService = PreferenceService();

  // Daftar opsi kota BARLINGMASCAKEB
  static const List<String> _cities = [
    'Semua Wilayah',
    'Banyumas',
    'Purbalingga',
    'Banjarnegara',
    'Cilacap',
    'Kebumen',
  ];

  // Daftar tag preferensi yang tersedia
  static const List<String> _availableTags = [
    'Cafe & Ngopi',
    'Makanan Berat',
    'Murah Meriah',
    'Wi-Fi & Colokan',
    'Outdoor/Santai',
    'Buka 24 Jam',
  ];

  // Quick pick opsi budget
  static const List<int> _quickBudgets = [20000, 35000, 50000, 75000];

  // State input pengguna
  String _selectedCity = 'Semua Wilayah';
  double _currentBudget = 50000.0;
  final Set<String> _selectedTags = {'Cafe & Ngopi', 'Murah Meriah'};
  bool _isLoading = false;

  /// Helper untuk memformat angka menjadi format Rupiah (cth: 50.000)
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

  /// Simpan semua preferensi dan lanjut ke HomeScreen
  Future<void> _handleSaveAndContinue() async {
    setState(() => _isLoading = true);

    try {
      await _preferenceService.saveBudget(_currentBudget.toInt());
      await _preferenceService.saveCity(_selectedCity);
      await _preferenceService.saveTags(_selectedTags.toList());
      await _preferenceService.setOnboarded();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan preferensi: $e'),
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
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // =================== HEADER SECTION ===================
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 38,
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MAMPIR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Makan, Ampir, & Temukan Tempat Nongkrong Pas di Kantong se-BARLINGMASCAKEB',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _secondaryColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // =================== CARD 1: PILIH WILAYAH ===================
              _buildSectionCard(
                icon: Icons.location_on_outlined,
                title: 'Pilih Wilayah',
                subtitle: 'Cari rekomendasi tempat di kota tujuanmu',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCity,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: _primaryColor),
                      items: _cities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(
                            city,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2B2D42),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCity = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // =================== CARD 2: BUDGET SLIDER ===================
              _buildSectionCard(
                icon: Icons.payments_outlined,
                title: 'Budget Maksimal per Orang',
                subtitle: 'Sesuaikan dengan isi dompetmu saat ini',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tampilan Angka Budget
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Rp${formatRupiah(_currentBudget.toInt())}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Slider Budget (10.000 - 100.000, step 5.000 -> 18 divisi)
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _primaryColor,
                        inactiveTrackColor: _primaryColor.withValues(alpha: 0.2),
                        thumbColor: _primaryColor,
                        overlayColor: _primaryColor.withValues(alpha: 0.15),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        min: 10000,
                        max: 100000,
                        divisions: 18,
                        value: _currentBudget,
                        label: 'Rp${formatRupiah(_currentBudget.toInt())}',
                        onChanged: (val) {
                          setState(() => _currentBudget = val);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rp10.000',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                        Text('Rp100.000',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick Pick Chips
                    const Text(
                      'Pilihan Cepat:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickBudgets.map((budget) {
                        final isSelected =
                            _currentBudget.toInt() == budget;
                        return ChoiceChip(
                          label: Text('Rp${formatRupiah(budget)}'),
                          selected: isSelected,
                          selectedColor: _primaryColor,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : _secondaryColor,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? _primaryColor
                                : Colors.grey.shade300,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _currentBudget = budget.toDouble());
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // =================== CARD 3: TAG PREFERENSI ===================
              _buildSectionCard(
                icon: Icons.tune_rounded,
                title: 'Suasana & Kebutuhan',
                subtitle: 'Pilih apa saja yang kamu cari saat mampir',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      selectedColor: _secondaryColor,
                      backgroundColor: Colors.white,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF2B2D42),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? _secondaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // =================== SUBMIT BUTTON ===================
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSaveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: _primaryColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.explore_rounded, size: 22),
                  label: Text(
                    _isLoading ? 'Menyimpan...' : 'Cari Tempat Mampir!',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper untuk membuat Card section yang seragam dan elegan
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: _primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
