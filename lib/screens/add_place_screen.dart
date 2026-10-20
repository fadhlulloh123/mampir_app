import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/place_model.dart';
import '../services/api_service.dart';

/// ============================================================
/// ADD PLACE SCREEN — FORM TAMBAH TEMPAT (HTTP POST DEMO)
/// ============================================================
/// Layar form untuk mengusulkan tempat makan/nongkrong baru.
///
/// TUJUAN PRAKTIKUM / DEMO DOSEN:
/// - Memperlihatkan validasi form input pengguna
/// - Memperlihatkan pembuatan objek PlaceModel dari input form
/// - Memperlihatkan pemanggilan HTTP POST ke REST API via ApiService
/// - Memperlihatkan penanganan respons (status 201 Created atau gagal)
/// - Menampilkan pesan ramah jika Web Service belum dikonfigurasi
/// ============================================================
class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  // Warna tema aplikasi MAMPIR (Material 3)
  static const Color _primaryColor = Color(0xFFFF6B35); // Warm Orange
  static const Color _secondaryColor = Color(0xFF004E64); // Deep Teal
  static const Color _backgroundColor = Color(0xFFF8F9FA); // Soft Cream

  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controller input form
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _openHoursController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Pilihan kota BARLINGMASCAKEB (tanpa 'Semua Wilayah' untuk form tambah)
  static const List<String> _cities = [
    'Banyumas',
    'Purbalingga',
    'Banjarnegara',
    'Cilacap',
    'Kebumen',
  ];

  // Tag yang tersedia untuk dipilih
  static const List<String> _availableTags = [
    'Cafe & Ngopi',
    'Makanan Berat',
    'Murah Meriah',
    'Wi-Fi & Colokan',
    'Outdoor/Santai',
    'Buka 24 Jam',
  ];

  String _selectedCity = 'Banyumas';
  final Set<String> _selectedTags = {'Cafe & Ngopi'};
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

  /// Proses submit data form tempat baru
  Future<void> _handleSubmit() async {
    // 1. Validasi input form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Cek apakah Web Service sudah dikonfigurasi
    if (!ApiConfig.isConfigured) {
      _showNotConfiguredDialog();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final minPrice = int.tryParse(_minPriceController.text.trim()) ?? 0;
      final maxPrice = int.tryParse(_maxPriceController.text.trim()) ?? 0;
      final avgPrice = ((minPrice + maxPrice) / 2).round();

      final lat = double.tryParse(_latController.text.trim()) ?? -7.45;
      final lng = double.tryParse(_lngController.text.trim()) ?? 109.25;

      final imageUrl = _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80';

      final newPlace = PlaceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        city: _selectedCity,
        category: _categoryController.text.trim().isNotEmpty
            ? _categoryController.text.trim()
            : 'Cafe & Resto',
        minPrice: minPrice,
        maxPrice: maxPrice,
        avgPrice: avgPrice,
        rating: 4.5,
        tags: _selectedTags.toList(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        openHours: _openHoursController.text.trim().isNotEmpty
            ? _openHoursController.text.trim()
            : '10.00 - 22.00 WIB',
        latitude: lat,
        longitude: lng,
        imageUrl: imageUrl,
        menuHighlights: [],
      );

      // 3. Kirim ke REST API via HTTP POST
      final success = await _apiService.submitPlace(newPlace);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil! Tempat baru telah dikirim ke Web Service.'),
            backgroundColor: Color(0xFF2EC4B6),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim data tempat ke server. Coba lagi.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Dialog edukatif jika Supabase belum dikonfigurasi
  void _showNotConfiguredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: _primaryColor),
            SizedBox(width: 10),
            Text('Web Service Belum Aktif', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Fitur ini membutuhkan koneksi ke Web Service Supabase. '
          'Silakan isi konfigurasi di api_config.dart untuk mengaktifkan pengiriman data via HTTP POST.\n\n'
          'Untuk saat ini, aplikasi tetap berfungsi normal menampilkan 15 tempat rekomendasi bawaan.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti', style: TextStyle(color: _primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Usulkan Tempat Baru',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2B2D42),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Info Web Service (HTTP POST)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _secondaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _secondaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cloud_upload_outlined,
                        color: _secondaryColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Data yang kamu kirim akan diunggah via HTTP POST ke REST API Supabase.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _secondaryColor.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bagian 1: Informasi Dasar
              _buildSectionTitle('Informasi Dasar'),
              _buildCard([
                _buildTextField(
                  controller: _nameController,
                  label: 'Nama Tempat',
                  hint: 'cth: Kopi Keprok, Mie Pak Slamet',
                  icon: Icons.storefront_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama tempat wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Dropdown Kota
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kota / Kabupaten',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF495057),
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
                          value: _selectedCity,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: _primaryColor),
                          items: _cities.map((city) {
                            return DropdownMenuItem(
                              value: city,
                              child: Text(
                                city,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _categoryController,
                  label: 'Kategori',
                  hint: 'cth: Cafe & Resto, Warung Makan, Warmindo',
                  icon: Icons.category_outlined,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _addressController,
                  label: 'Alamat Lengkap',
                  hint: 'Jl. Raya Baturraden, Purwokerto...',
                  icon: Icons.place_outlined,
                  maxLines: 2,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Alamat wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _openHoursController,
                  label: 'Jam Buka',
                  hint: 'cth: 09.00 - 23.00 WIB atau Buka 24 Jam',
                  icon: Icons.access_time_rounded,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Deskripsi Tempat',
                  hint: 'Ceritakan suasana atau keunikan tempat ini...',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
              ]),
              const SizedBox(height: 20),

              // Bagian 2: Estimasi Harga
              _buildSectionTitle('Estimasi Harga (per Orang)'),
              _buildCard([
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _minPriceController,
                        label: 'Harga Minimal',
                        hint: '10000',
                        prefixText: 'Rp ',
                        icon: Icons.arrow_downward_rounded,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          if (int.tryParse(val.trim()) == null) {
                            return 'Angka tidak valid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _maxPriceController,
                        label: 'Harga Maksimal',
                        hint: '35000',
                        prefixText: 'Rp ',
                        icon: Icons.arrow_upward_rounded,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          final max = int.tryParse(val.trim());
                          if (max == null) return 'Angka tidak valid';
                          final min = int.tryParse(_minPriceController.text.trim()) ?? 0;
                          if (max < min) return 'Harus >= Min';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 20),

              // Bagian 3: Tag / Fasilitas
              _buildSectionTitle('Pilih Tag & Suasana'),
              _buildCard([
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      selectedColor: _primaryColor,
                      backgroundColor: _backgroundColor,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF2B2D42),
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
              ]),
              const SizedBox(height: 20),

              // Bagian 4: Koordinat & Gambar (Opsional)
              _buildSectionTitle('Lokasi Peta & Gambar (Opsional)'),
              _buildCard([
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _latController,
                        label: 'Latitude',
                        hint: '-7.4215',
                        icon: Icons.map_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _lngController,
                        label: 'Longitude',
                        hint: '109.2380',
                        icon: Icons.map_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _imageUrlController,
                  label: 'URL Gambar',
                  hint: 'https://...',
                  icon: Icons.image_outlined,
                ),
              ]),
              const SizedBox(height: 30),

              // Tombol Submit
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    _isSubmitting ? 'Mengirim Data...' : 'Kirim Usulan Tempat',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2B2D42),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF495057),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixIcon: Icon(icon, size: 20, color: _primaryColor),
            filled: true,
            fillColor: _backgroundColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
