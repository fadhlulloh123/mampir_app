import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';
import '../models/place_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// ============================================================
/// ADD PLACE SCREEN — TAMBAH TEMPAT BARU DENGAN PETA INTERAKTIF
/// ============================================================
class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _nameController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Cafe');
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _openHoursController = TextEditingController(text: '09.00 - 22.00 WIB');
  final _latController = TextEditingController(text: '-7.4244');
  final _lngController = TextEditingController(text: '109.2302');
  final _imageUrlController = TextEditingController(
      text:
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80');

  static const List<String> _cities = [
    'Purwokerto / Banyumas',
    'Purbalingga',
    'Banjarnegara',
    'Cilacap',
    'Kebumen',
  ];

  static const List<String> _categories = [
    'Makan',
    'Nongkrong',
    'Cafe',
    'Restoran',
    'Warung',
  ];

  static const List<String> _availableFacilities = [
    'WiFi',
    'Colokan',
    'AC',
    'Parkir',
    'Outdoor',
    'Indoor',
    'Mushola',
    'Live Music',
    'Ramah Hewan',
    'Romantis',
  ];

  String _selectedCity = 'Purwokerto / Banyumas';
  String _selectedCategory = 'Cafe';
  final Set<String> _selectedFacilities = {'WiFi', 'Colokan'};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _openHoursController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  /// Buka modal peta interaktif untuk memilih titik koordinat
  void _pickLocationOnMap() {
    double currentLat = double.tryParse(_latController.text) ?? -7.4244;
    double currentLng = double.tryParse(_lngController.text) ?? 109.2302;
    LatLng picked = LatLng(currentLat, currentLng);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sentuh Peta untuk Memilih Titik Lokasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${picked.latitude.toStringAsFixed(5)}, Lng: ${picked.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: picked,
                          initialZoom: 14.0,
                          onTap: (tapPos, point) {
                            setModalState(() {
                              picked = point;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.mampir.mampir_app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: picked,
                                width: 44,
                                height: 44,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.borderNavy),
                            foregroundColor: Colors.white70,
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _latController.text =
                                  picked.latitude.toStringAsFixed(5);
                              _lngController.text =
                                  picked.longitude.toStringAsFixed(5);
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Pilih Titik Ini'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!ApiConfig.isConfigured) {
      _showNotConfiguredDialog();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final minPrice = int.tryParse(_minPriceController.text.trim()) ?? 0;
      final maxPrice = int.tryParse(_maxPriceController.text.trim()) ?? minPrice;
      final lat = double.tryParse(_latController.text.trim()) ?? -7.4244;
      final lng = double.tryParse(_lngController.text.trim()) ?? 109.2302;

      final newPlace = PlaceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        city: _selectedCity,
        category: _selectedCategory,
        minPrice: minPrice,
        maxPrice: maxPrice,
        rating: 4.8,
        reviewCount: 1,
        facilities: _selectedFacilities.toList(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        openHours: _openHoursController.text.trim(),
        latitude: lat,
        longitude: lng,
        imageUrl: _imageUrlController.text.trim(),
        menuHighlights: [],
      );

      final success = await _apiService.submitPlace(newPlace);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tempat baru berhasil diusulkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim ke server. Coba lagi.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showNotConfiguredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceNavy,
        title: const Text('Web Service Belum Aktif',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Supabase REST API belum dikonfigurasi di lib/config/api_config.dart. Untuk demo lokal, data tersimpan di sesi.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text('Simpan Demo',
                style: TextStyle(color: AppTheme.gold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Usulkan Tempat Baru'),
        backgroundColor: AppTheme.scaffoldBg,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Informasi Tempat'),
              _buildTextField(
                controller: _nameController,
                label: 'Nama Tempat Makan / Cafe',
                hint: 'Contoh: Cafe Senja Purwokerto',
                validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Wilayah
              _buildDropdown(
                label: 'Wilayah Kabupaten',
                value: _selectedCity,
                items: _cities,
                onChanged: (v) => setState(() => _selectedCity = v!),
              ),
              const SizedBox(height: 14),

              // Kategori
              _buildDropdown(
                label: 'Kategori Tempat',
                value: _selectedCategory,
                items: _categories,
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 14),

              // Rentang Harga
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _minPriceController,
                      label: 'Harga Minimal (Rp)',
                      hint: '10000',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v!.isEmpty ? 'Harga min wajib' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxPriceController,
                      label: 'Harga Maksimal (Rp)',
                      hint: '35000',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v!.isEmpty ? 'Harga max wajib' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildTextField(
                controller: _addressController,
                label: 'Alamat Lengkap',
                hint: 'Jl. HR Bunyamin No. 12',
                validator: (v) => v!.isEmpty ? 'Alamat wajib' : null,
              ),
              const SizedBox(height: 14),

              _buildTextField(
                controller: _openHoursController,
                label: 'Jam Operasional',
                hint: '09.00 - 22.00 WIB',
              ),
              const SizedBox(height: 14),

              _buildTextField(
                controller: _descriptionController,
                label: 'Deskripsi Singkat',
                hint: 'Tempat ngopi santai harga mahasiswa...',
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Fasilitas
              _buildSectionTitle('Fasilitas & Suasana'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableFacilities.map((fac) {
                  final isSelected = _selectedFacilities.contains(fac);
                  return FilterChip(
                    label: Text(fac),
                    selected: isSelected,
                    selectedColor: AppTheme.orange.withValues(alpha: 0.3),
                    checkmarkColor: AppTheme.gold,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    backgroundColor: AppTheme.surfaceNavy,
                    side: BorderSide(
                      color: isSelected ? AppTheme.gold : AppTheme.borderNavy,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedFacilities.add(fac);
                        } else {
                          _selectedFacilities.remove(fac);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Titik Koordinat & Peta
              _buildSectionTitle('Titik Koordinat Peta'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _latController,
                      label: 'Latitude',
                      hint: '-7.4244',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _lngController,
                      label: 'Longitude',
                      hint: '109.2302',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickLocationOnMap,
                icon: const Icon(Icons.map_rounded, color: Colors.white),
                label: const Text(
                  'Pilih Titik Langsung dari Peta Interaktif',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceNavy,
                  side: const BorderSide(color: AppTheme.orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Tombol Submit
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.orange.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Kirim Usulan Tempat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.gold,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        fillColor: AppTheme.surfaceNavy,
        filled: true,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceNavy,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderNavy),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceNavy,
              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.gold),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
