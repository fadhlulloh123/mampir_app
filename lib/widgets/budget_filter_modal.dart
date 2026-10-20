import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Callback result dari modal filter budget & preferensi
class BudgetFilterData {
  final int budget;
  final Set<String> placeTypes;
  final Set<String> preferences;

  BudgetFilterData({
    required this.budget,
    required this.placeTypes,
    required this.preferences,
  });
}

/// ============================================================
/// BUDGET FILTER MODAL — SESUAI MOCKUP cariFavorit_mampir.jpeg
/// ============================================================
/// Menampilkan:
/// 1. Input Ketik Manual (TextFormField) format Rupiah
/// 2. Interactive Slider Rp 5.000 - Rp 150.000+
/// 3. Quick Chips: 25K, 50K, 75K, 100K, Bebas
/// 4. Jenis Tempat: Makan, Nongkrong, Cafe, Restoran, Outdoor, Indoor, Rooftop, Rumahan
/// 5. Preferensi: WiFi, Colokan, AC, Parkir, Musik, Romantis, Ramah Hewan
/// 6. Tombol "Terapkan Filter" & "Reset"
/// ============================================================
class BudgetFilterModal extends StatefulWidget {
  final int initialBudget;
  final Set<String> initialPlaceTypes;
  final Set<String> initialPreferences;
  final Function(BudgetFilterData) onApply;

  const BudgetFilterModal({
    super.key,
    required this.initialBudget,
    this.initialPlaceTypes = const {},
    this.initialPreferences = const {},
    required this.onApply,
  });

  static Future<BudgetFilterData?> show(
    BuildContext context, {
    required int currentBudget,
    Set<String> currentPlaceTypes = const {},
    Set<String> currentPreferences = const {},
  }) {
    return showModalBottomSheet<BudgetFilterData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BudgetFilterModal(
        initialBudget: currentBudget,
        initialPlaceTypes: currentPlaceTypes,
        initialPreferences: currentPreferences,
        onApply: (data) => Navigator.pop(ctx, data),
      ),
    );
  }

  @override
  State<BudgetFilterModal> createState() => _BudgetFilterModalState();
}

class _BudgetFilterModalState extends State<BudgetFilterModal> {
  late int _selectedBudget;
  late TextEditingController _textController;
  late Set<String> _selectedPlaceTypes;
  late Set<String> _selectedPreferences;

  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Quick Chips sesuai mockup
  static const List<Map<String, dynamic>> _quickChips = [
    {'label': '25K', 'value': 25000},
    {'label': '50K', 'value': 50000},
    {'label': '75K', 'value': 75000},
    {'label': '100K', 'value': 100000},
    {'label': 'Bebas', 'value': 150000},
  ];

  static const List<String> _allPlaceTypes = [
    'Makan',
    'Nongkrong',
    'Cafe',
    'Restoran',
    'Outdoor',
    'Indoor',
    'Rooftop',
    'Rumahan',
  ];

  static const List<String> _allPreferences = [
    'WiFi',
    'Colokan',
    'AC',
    'Parkir',
    'Musik',
    'Romantis',
    'Ramah Hewan',
  ];

  @override
  void initState() {
    super.initState();
    _selectedBudget = widget.initialBudget;
    _selectedPlaceTypes = Set<String>.from(widget.initialPlaceTypes);
    _selectedPreferences = Set<String>.from(widget.initialPreferences);

    if (_selectedPlaceTypes.isEmpty) {
      _selectedPlaceTypes.addAll(['Nongkrong', 'Cafe']);
    }
    if (_selectedPreferences.isEmpty) {
      _selectedPreferences.addAll(['WiFi', 'Colokan']);
    }

    _textController = TextEditingController(
      text: _selectedBudget >= 150000
          ? 'Bebas'
          : _currencyFormatter.format(_selectedBudget),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onBudgetChanged(int newBudget) {
    setState(() {
      _selectedBudget = newBudget;
      if (newBudget >= 150000) {
        _textController.text = 'Bebas';
      } else {
        _textController.text = _currencyFormatter.format(newBudget);
      }
    });
  }

  void _onManualTextChanged(String val) {
    final cleanDigits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.isEmpty) return;
    final int? parsed = int.tryParse(cleanDigits);
    if (parsed != null) {
      setState(() {
        _selectedBudget = parsed.clamp(5000, 200000);
      });
    }
  }

  void _reset() {
    setState(() {
      _selectedBudget = 25000;
      _selectedPlaceTypes = {'Nongkrong', 'Cafe'};
      _selectedPreferences = {'WiFi', 'Colokan'};
      _textController.text = _currencyFormatter.format(25000);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.scaffoldBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.borderNavy, width: 1.5),
        ),
      ),
      child: Stack(
        children: [
          // Background Mandala
          Positioned(
            top: 0,
            right: 0,
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: MandalaOrnamentPainter(scale: 0.6),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header Bar
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Filter Pencarian',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _reset,
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Section 1: Budget Maksimal
                  const Text(
                    'Budget Maksimal (Rp)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Manual TextField
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.searchNavy,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderNavy),
                    ),
                    child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Tulis nominal budget sendiri',
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: InputBorder.none,
                      ),
                      onChanged: _onManualTextChanged,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.orange,
                      inactiveTrackColor: AppTheme.borderNavy,
                      thumbColor: AppTheme.gold,
                      overlayColor: AppTheme.gold.withValues(alpha: 0.2),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 9),
                    ),
                    child: Slider(
                      value: _selectedBudget.toDouble().clamp(5000.0, 150000.0),
                      min: 5000,
                      max: 150000,
                      divisions: 29,
                      onChanged: (val) => _onBudgetChanged(val.toInt()),
                    ),
                  ),

                  // Quick Chips: 25K, 50K, 75K, 100K, Bebas
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickChips.map((chip) {
                      final val = chip['value'] as int;
                      final isSelected = val >= 150000
                          ? _selectedBudget >= 150000
                          : (_selectedBudget - val).abs() < 5000;

                      return GestureDetector(
                        onTap: () => _onBudgetChanged(val),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? AppTheme.primaryGradient
                                : null,
                            color: isSelected ? null : AppTheme.surfaceNavy,
                            borderRadius: BorderRadius.circular(24),
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
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // Section 2: Jenis Tempat
                  const Text(
                    'Jenis Tempat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allPlaceTypes.map((type) {
                      final isSelected = _selectedPlaceTypes.contains(type);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedPlaceTypes.remove(type);
                            } else {
                              _selectedPlaceTypes.add(type);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? AppTheme.primaryGradient
                                : null,
                            color: isSelected ? null : AppTheme.surfaceNavy,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : AppTheme.borderNavy,
                            ),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // Section 3: Preferensi
                  const Text(
                    'Preferensi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? AppTheme.primaryGradient
                                : null,
                            color: isSelected ? null : AppTheme.surfaceNavy,
                            borderRadius: BorderRadius.circular(24),
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
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Button Terapkan Filter
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.orange.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(BudgetFilterData(
                          budget: _selectedBudget,
                          placeTypes: _selectedPlaceTypes,
                          preferences: _selectedPreferences,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _reset,
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
