import 'package:flutter/material.dart';

import 'place_form_widgets.dart';

Future<Map<String, dynamic>?> showAddPlaceDialog(
  BuildContext context, {
  required List<Map<String, dynamic>> categories,
  required List<Map<String, dynamic>> preferences,
}) {
  final name = TextEditingController();
  final address = TextEditingController();
  final description = TextEditingController();
  final image = TextEditingController();
  final openHours = TextEditingController(text: '09.00 - 22.00 WIB');
  final minPrice = TextEditingController(text: '15000');
  final maxPrice = TextEditingController(text: '40000');
  final latitude = TextEditingController(text: '-7.4244');
  final longitude = TextEditingController(text: '109.2302');
  final customFacilities = TextEditingController();
  final List<Map<String, dynamic>> menuItems = [];
  final menuNameController = TextEditingController();
  final menuPriceController = TextEditingController();
  final menuImageController = TextEditingController();
  int? editingMenuIndex;

  var selectedCategory = categories.firstOrNull?['name']?.toString() ?? 'Cafe';
  var selectedCity = 'Purwokerto Kota';

  final Set<String> selectedFacilities = {'WiFi', 'Colokan', 'Parkir'};

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final navyCard = isDark ? const Color(0xFF162035) : Colors.white;
  final navyBorder = isDark ? const Color(0xFF263353) : const Color(0xFFE2E8F0);
  final navyInput = isDark ? const Color(0xFF131B30) : const Color(0xFFF1F5F9);
  final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
  final textSecondary = isDark ? Colors.white70 : const Color(0xFF475569);
  final textMuted = isDark ? Colors.white54 : const Color(0xFF94A3B8);
  const amberPrimary = Color(0xFFD99B25);

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final currentCategory =
            categories.any((item) => item['name'] == selectedCategory)
            ? selectedCategory
            : (categories.firstOrNull?['name']?.toString() ?? 'Cafe');

        return AlertDialog(
          backgroundColor: navyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: navyBorder, width: 1.5),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: amberPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: amberPrimary.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.add_business_rounded,
                  color: amberPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tambah Tempat Baru (WADM-3)',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Daftarkan tempat kuliner atau wisata baru ke database Supabase',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(dialogCtx),
                icon: Icon(Icons.close_rounded, color: textMuted),
              ),
            ],
          ),
          content: SizedBox(
            width: 740,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(dialogCtx).height * 0.82,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: INFORMASI UTAMA & KATEGORI
                    buildDialogSectionHeader(
                      'INFORMASI UTAMA & KATEGORI',
                      Icons.storefront_rounded,
                      amberPrimary,
                      navyBorder,
                    ),
                    buildDialogCard(
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: name,
                                  style: TextStyle(color: textPrimary),
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Tempat Kuliner *',
                                    hintText: 'Mis. Kopi Pagi Purwokerto',
                                    prefixIcon: Icon(
                                      Icons.store_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  initialValue: currentCategory,
                                  dropdownColor: navyCard,
                                  style: TextStyle(color: textPrimary),
                                  decoration: const InputDecoration(
                                    labelText: 'Kategori Tempat *',
                                    prefixIcon: Icon(
                                      Icons.category_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  items: categories
                                      .map(
                                        (item) => DropdownMenuItem<String>(
                                          value: '${item['name']}',
                                          child: Text('${item['name']}'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setModalState(
                                        () => selectedCategory = value,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedCity,
                                  dropdownColor: navyCard,
                                  style: TextStyle(color: textPrimary),
                                  decoration: const InputDecoration(
                                    labelText: 'Zona Wilayah Banyumas *',
                                    prefixIcon: Icon(
                                      Icons.map_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  items: availablePurwokertoZones
                                      .map(
                                        (z) => DropdownMenuItem(
                                          value: z,
                                          child: Text(z),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setModalState(() => selectedCity = value);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: openHours,
                                  style: TextStyle(color: textPrimary),
                                  decoration: const InputDecoration(
                                    labelText: 'Jam Operasional',
                                    hintText: 'Mis. 08.00 - 22.00 WIB',
                                    prefixIcon: Icon(
                                      Icons.access_time_rounded,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      navyInput,
                      navyBorder,
                    ),

                    const SizedBox(height: 22),

                    // SECTION 2: LOKASI & KOORDINAT GPS
                    buildDialogSectionHeader(
                      'LOKASI & KOORDINAT GPS',
                      Icons.pin_drop_outlined,
                      amberPrimary,
                      navyBorder,
                    ),
                    buildDialogCard(
                      Column(
                        children: [
                          TextField(
                            controller: address,
                            style: TextStyle(color: textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Alamat Lengkap Tempat *',
                              hintText: 'Jl. Prof. Dr. HR Bunyamin No. 12...',
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: latitude,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                  style: TextStyle(color: textPrimary),
                                  decoration: const InputDecoration(
                                    labelText:
                                        'Latitude GPS (-7.6 s/d -7.2) *',
                                    prefixIcon: Icon(
                                      Icons.my_location_rounded,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: longitude,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                  style: TextStyle(color: textPrimary),
                                  decoration: const InputDecoration(
                                    labelText:
                                        'Longitude GPS (109.0 s/d 109.5) *',
                                    prefixIcon: Icon(
                                      Icons.explore_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      navyInput,
                      navyBorder,
                    ),

                    const SizedBox(height: 22),

                    // SECTION 3: RENTANG BUDGET & FASILITAS
                    buildDialogSectionHeader(
                      'RENTANG BUDGET & FASILITAS',
                      Icons.local_offer_outlined,
                      amberPrimary,
                      navyBorder,
                    ),
                    buildDialogCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: minPrice,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: textPrimary),
                                  decoration: const InputDecoration(
                                    labelText: 'Budget Minimum (Rp)',
                                    prefixIcon: Icon(
                                      Icons.payments_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: maxPrice,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: textPrimary),
                                  decoration: const InputDecoration(
                                    labelText: 'Budget Maksimum (Rp)',
                                    prefixIcon: Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Pilih Fasilitas & Preferensi (Klik untuk aktifkan):',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: preferences.map((pref) {
                              final pName = pref['name']?.toString() ?? '';
                              final isSelected =
                                  selectedFacilities.contains(pName);
                              return FilterChip(
                                label: Text(
                                  pName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? amberPrimary
                                        : textSecondary,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: amberPrimary.withValues(
                                  alpha: 0.16,
                                ),
                                backgroundColor: navyCard,
                                checkmarkColor: amberPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected
                                        ? amberPrimary
                                        : navyBorder,
                                  ),
                                ),
                                onSelected: (val) {
                                  setModalState(() {
                                    if (val) {
                                      selectedFacilities.add(pName);
                                    } else {
                                      selectedFacilities.remove(pName);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: customFacilities,
                            style: TextStyle(color: textPrimary),
                            decoration: const InputDecoration(
                              labelText:
                                  'Fasilitas Tambahan Lainnya (Opsional)',
                              hintText: 'Pisahkan koma, mis. Rooftop, Proyektor',
                              prefixIcon: Icon(
                                Icons.playlist_add_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      navyInput,
                      navyBorder,
                    ),

                    const SizedBox(height: 22),

                    // SECTION 4: MEDIA BANNER & DESKRIPSI
                    buildDialogSectionHeader(
                      'MEDIA BANNER & DESKRIPSI',
                      Icons.image_outlined,
                      amberPrimary,
                      navyBorder,
                    ),
                    buildDialogCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ImageUploadDropZone(
                            controller: image,
                            label: 'Foto Banner Tempat (Upload / Drag & Drop)',
                            previewBadgeText: 'Pratinjau Banner',
                            amberPrimary: amberPrimary,
                            navyInput: navyInput,
                            navyBorder: navyBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            textMuted: textMuted,
                            onChanged: () => setModalState(() {}),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: description,
                            maxLines: 3,
                            style: TextStyle(color: textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Deskripsi Singkat Tempat',
                              hintText:
                                  'Deskripsikan konsep, keunikan, atau menu favorit tempat...',
                              prefixIcon: Icon(
                                Icons.description_outlined,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      navyInput,
                      navyBorder,
                    ),

                    const SizedBox(height: 22),

                    // SECTION 5: KATALOG MENU ANDALAN
                    buildMenuCatalogSection(
                      context: context,
                      menuItems: menuItems,
                      menuNameController: menuNameController,
                      menuPriceController: menuPriceController,
                      menuImageController: menuImageController,
                      editingIndex: editingMenuIndex,
                      onEditingIndexChanged: (val) => editingMenuIndex = val,
                      setModalState: setModalState,
                      amberPrimary: amberPrimary,
                      navyInput: navyInput,
                      navyBorder: navyBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: navyBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Batal', style: TextStyle(color: textSecondary)),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: amberPrimary,
                foregroundColor: isDark
                    ? const Color(0xFF0D1326)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                final n = name.text.trim();
                final addr = address.text.trim();
                final lat = double.tryParse(latitude.text.trim());
                final lng = double.tryParse(longitude.text.trim());
                final min = int.tryParse(minPrice.text.trim()) ?? 0;
                final max = int.tryParse(maxPrice.text.trim()) ?? 0;

                if (n.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama tempat wajib diisi.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                if (addr.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alamat tempat wajib diisi.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                if (lat == null || lat < -7.6 || lat > -7.2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Latitude tidak valid untuk wilayah Purwokerto/Banyumas (-7.6 s/d -7.2).',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                if (lng == null || lng < 109.0 || lng > 109.5) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Longitude tidak valid untuk wilayah Purwokerto/Banyumas (109.0 s/d 109.5).',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                final customExtras = customFacilities.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty);
                final facList = {
                  ...selectedFacilities,
                  ...customExtras,
                }.toList();

                final newId = 'pwt-${DateTime.now().millisecondsSinceEpoch}';
                final newPlace = {
                  'id': newId,
                  'name': n,
                  'city': selectedCity,
                  'category': selectedCategory,
                  'address': addr,
                  'description': description.text.trim(),
                  'open_hours': openHours.text.trim(),
                  'image_url': image.text.trim(),
                  'latitude': lat,
                  'longitude': lng,
                  'min_price': min,
                  'max_price': max,
                  'avg_price': (min + max) ~/ 2,
                  'rating': 4.5,
                  'review_count': 10,
                  'facilities': facList,
                  'menu_highlights': menuItems,
                  'data_source': 'admin',
                };

                Navigator.pop(dialogCtx, newPlace);
              },
              icon: const Icon(Icons.add_location_alt_rounded, size: 18),
              label: const Text(
                'Simpan Tempat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ),
  );
}
