import 'dart:convert';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const List<String> availablePurwokertoZones = [
  'Purwokerto Kota',
  'Baturraden',
  'Purwokerto Utara (Unsoed)',
  'Sokaraja',
  'Purwokerto Timur & Sumbang',
  'Purwokerto Barat & Selatan',
];

List<Map<String, dynamic>> parseMenuHighlights(dynamic raw) {
  dynamic decoded = raw;
  if (raw is String && raw.trim().isNotEmpty) {
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map(
            (e) => <String, dynamic>{
              'name': e,
              'price': 0,
              'image_url': '',
            },
          )
          .toList();
    }
  }
  if (decoded is! List) return [];
  final result = <Map<String, dynamic>>[];
  for (final item in decoded) {
    if (item is Map) {
      final name = '${item['name'] ?? ''}'.trim();
      if (name.isEmpty) continue;
      final priceNum = item['price'];
      final price = priceNum is num
          ? priceNum.toInt()
          : int.tryParse('$priceNum') ?? 0;
      final imageUrl = '${item['image_url'] ?? ''}'.trim();
      result.add({
        'name': name,
        'price': price < 0 ? 0 : price,
        'image_url': imageUrl,
      });
    } else if (item != null) {
      final name = item.toString().trim();
      if (name.isNotEmpty) {
        result.add({'name': name, 'price': 0, 'image_url': ''});
      }
    }
  }
  return result;
}

String formatRupiahDesktop(int price) {
  final str = price.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(str[i]);
  }
  return buffer.toString();
}

Widget buildSmartImage(
  String url, {
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  final trimmed = url.trim();
  if (trimmed.startsWith('data:image')) {
    final commaIdx = trimmed.indexOf(',');
    if (commaIdx != -1) {
      try {
        final bytes = base64Decode(trimmed.substring(commaIdx + 1));
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: errorBuilder,
        );
      } catch (e, st) {
        if (errorBuilder != null) {
          return Builder(builder: (ctx) => errorBuilder(ctx, e, st));
        }
      }
    }
  }
  return Image.network(
    trimmed,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}

Widget buildDialogSectionHeader(
  String title,
  IconData icon,
  Color amberPrimary,
  Color navyBorder,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: amberPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: amberPrimary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: amberPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: navyBorder, thickness: 1)),
      ],
    ),
  );
}

Widget buildDialogCard(Widget child, Color navyInput, Color navyBorder) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: navyInput.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: navyBorder, width: 1.2),
    ),
    child: child,
  );
}

class ImageUploadDropZone extends StatefulWidget {
  const ImageUploadDropZone({
    super.key,
    required this.controller,
    required this.label,
    required this.amberPrimary,
    required this.navyInput,
    required this.navyBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    this.compact = false,
    this.previewBadgeText = 'Pratinjau Foto',
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final Color amberPrimary;
  final Color navyInput;
  final Color navyBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool compact;
  final String previewBadgeText;
  final VoidCallback? onChanged;

  @override
  State<ImageUploadDropZone> createState() => _ImageUploadDropZoneState();
}

class _ImageUploadDropZoneState extends State<ImageUploadDropZone> {
  static const int _maxBytes = 2 * 1024 * 1024;
  bool _isDragging = false;
  bool _isProcessing = false;
  String? _uploadedFileName;

  String _mimeFromFilename(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _applyImageBytes(Uint8List bytes, String fileName) async {
    if (bytes.length > _maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ukuran gambar maksimal 2 MB.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    final mime = _mimeFromFilename(fileName);
    final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
    setState(() {
      _uploadedFileName = fileName;
      widget.controller.text = dataUri;
    });
    widget.onChanged?.call();
  }

  Future<void> _pickFile() async {
    setState(() => _isProcessing = true);
    try {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.xFile.readAsBytes();
        await _applyImageBytes(bytes, file.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membaca file gambar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _clearImage() {
    setState(() {
      _uploadedFileName = null;
      widget.controller.clear();
    });
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final currentVal = widget.controller.text.trim();
    final hasImage = currentVal.isNotEmpty;
    final isDataUri = currentVal.startsWith('data:image');
    final dropHeight = widget.compact ? 110.0 : 145.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: widget.textPrimary,
                  fontSize: widget.compact ? 12.5 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (hasImage)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _clearImage,
                icon: const Icon(Icons.delete_outline_rounded, size: 15),
                label: const Text('Hapus Foto', style: TextStyle(fontSize: 11.5)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        DropTarget(
          onDragEntered: (_) => setState(() => _isDragging = true),
          onDragExited: (_) => setState(() => _isDragging = false),
          onDragDone: (details) async {
            final messenger = ScaffoldMessenger.of(context);
            setState(() {
              _isDragging = false;
              _isProcessing = true;
            });
            try {
              if (details.files.isNotEmpty) {
                final xfile = details.files.first;
                final bytes = await xfile.readAsBytes();
                await _applyImageBytes(bytes, xfile.name);
              }
            } catch (e) {
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal memuat file yang di-drop: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            } finally {
              if (mounted) setState(() => _isProcessing = false);
            }
          },
          child: InkWell(
            onTap: _isProcessing ? null : _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: dropHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _isDragging
                    ? widget.amberPrimary.withValues(alpha: 0.14)
                    : widget.navyInput,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDragging
                      ? widget.amberPrimary
                      : (hasImage ? widget.amberPrimary.withValues(alpha: 0.5) : widget.navyBorder),
                  width: _isDragging ? 2 : 1.3,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _isProcessing
                  ? Center(
                      child: CircularProgressIndicator(
                        color: widget.amberPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : hasImage
                  ? Stack(
                      children: [
                        Positioned.fill(
                          child: buildSmartImage(
                            currentVal,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, error, stackTrace) => Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image_rounded,
                                    color: widget.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pratinjau gambar gagal dimuat',
                                    style: TextStyle(
                                      color: widget.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.68),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_rounded,
                                  size: 12,
                                  color: widget.amberPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _uploadedFileName ?? widget.previewBadgeText,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.amberPrimary.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.upload_file_rounded,
                                  size: 13,
                                  color: widget.amberPrimary,
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Ganti / Drop File Baru',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isDragging
                                  ? Icons.file_download_done_rounded
                                  : Icons.cloud_upload_outlined,
                              color: _isDragging
                                  ? widget.amberPrimary
                                  : widget.textMuted,
                              size: widget.compact ? 24 : 30,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isDragging
                                  ? 'Lepaskan file gambar di sini'
                                  : 'Klik untuk pilih file atau seret & lepas (drag & drop) gambar di sini',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isDragging
                                    ? widget.amberPrimary
                                    : widget.textSecondary,
                                fontSize: widget.compact ? 11.5 : 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Format: PNG, JPG, WEBP • Maksimal 2 MB',
                              style: TextStyle(
                                color: widget.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
        if (!isDataUri) ...[
          const SizedBox(height: 10),
          TextField(
            controller: widget.controller,
            style: TextStyle(color: widget.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Atau masukkan URL gambar secara manual (Opsional)',
              hintText: 'https://...',
              prefixIcon: const Icon(Icons.link_rounded, size: 18),
            ),
            onChanged: (_) {
              setState(() {});
              widget.onChanged?.call();
            },
          ),
        ],
      ],
    );
  }
}

Widget buildMenuCatalogSection({
  required BuildContext context,
  required List<Map<String, dynamic>> menuItems,
  required TextEditingController menuNameController,
  required TextEditingController menuPriceController,
  required TextEditingController menuImageController,
  required int? editingIndex,
  required ValueChanged<int?> onEditingIndexChanged,
  required StateSetter setModalState,
  required Color amberPrimary,
  required Color navyInput,
  required Color navyBorder,
  required Color textPrimary,
  required Color textSecondary,
  required Color textMuted,
}) {
  void submitMenuItem() {
    final itemName = menuNameController.text.trim();
    if (itemName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama menu wajib diisi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    final parsedPrice = int.tryParse(menuPriceController.text.trim()) ?? 0;
    final entry = <String, dynamic>{
      'name': itemName,
      'price': parsedPrice < 0 ? 0 : parsedPrice,
      'image_url': menuImageController.text.trim(),
    };
    setModalState(() {
      if (editingIndex != null &&
          editingIndex >= 0 &&
          editingIndex < menuItems.length) {
        menuItems[editingIndex] = entry;
        onEditingIndexChanged(null);
      } else {
        menuItems.add(entry);
      }
      menuNameController.clear();
      menuPriceController.clear();
      menuImageController.clear();
    });
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildDialogSectionHeader(
        'KATALOG MENU ANDALAN',
        Icons.restaurant_menu_rounded,
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
                  child: Text(
                    'Tambahkan daftar menu beserta harga dan foto sampul (opsional) agar tampil di aplikasi mobile & web.',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: amberPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: amberPrimary.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    '${menuItems.length} Menu',
                    style: TextStyle(
                      color: amberPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: menuNameController,
                    style: TextStyle(color: textPrimary),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama Menu',
                      hintText: 'Mis. Kopi Susu Gula Aren',
                      prefixIcon: Icon(
                        Icons.restaurant_menu_rounded,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: menuPriceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(color: textPrimary),
                    onSubmitted: (_) => submitMenuItem(),
                    decoration: const InputDecoration(
                      labelText: 'Harga (Rp)',
                      hintText: '18000',
                      prefixIcon: Icon(Icons.payments_outlined, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: amberPrimary,
                      foregroundColor: const Color(0xFF0D1326),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: submitMenuItem,
                    icon: Icon(
                      editingIndex != null
                          ? Icons.check_rounded
                          : Icons.add_rounded,
                      size: 18,
                    ),
                    label: Text(
                      editingIndex != null ? 'Simpan' : 'Tambah',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (editingIndex != null) ...[
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: IconButton(
                      tooltip: 'Batal edit menu',
                      onPressed: () {
                        setModalState(() {
                          onEditingIndexChanged(null);
                          menuNameController.clear();
                          menuPriceController.clear();
                          menuImageController.clear();
                        });
                      },
                      icon: Icon(Icons.close_rounded, color: textSecondary),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            ImageUploadDropZone(
              controller: menuImageController,
              label: 'Foto Sampul Menu (Opsional)',
              compact: true,
              previewBadgeText: 'Foto Menu',
              amberPrimary: amberPrimary,
              navyInput: navyInput,
              navyBorder: navyBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
              onChanged: () => setModalState(() {}),
            ),
            const SizedBox(height: 14),
            if (menuItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: navyInput.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: navyBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 18,
                      color: textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Belum ada menu ditambahkan. Isi nama, harga & foto (opsional) di atas.',
                      style: TextStyle(color: textMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: List.generate(menuItems.length, (index) {
                  final item = menuItems[index];
                  final itemName = '${item['name'] ?? ''}';
                  final itemPrice = (item['price'] as num?)?.toInt() ?? 0;
                  final itemImage = '${item['image_url'] ?? ''}'.trim();
                  final isEditingThis = editingIndex == index;
                  return Container(
                    margin: EdgeInsets.only(
                      bottom: index == menuItems.length - 1 ? 0 : 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isEditingThis
                          ? amberPrimary.withValues(alpha: 0.1)
                          : navyInput.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isEditingThis ? amberPrimary : navyBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: amberPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: amberPrimary.withValues(alpha: 0.3),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: itemImage.isNotEmpty
                              ? buildSmartImage(
                                  itemImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, st) => Icon(
                                    Icons.restaurant_menu_rounded,
                                    size: 18,
                                    color: amberPrimary,
                                  ),
                                )
                              : Icon(
                                  Icons.restaurant_menu_rounded,
                                  size: 18,
                                  color: amberPrimary,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemName,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                itemPrice > 0
                                    ? 'Rp ${formatRupiahDesktop(itemPrice)}'
                                    : 'Harga belum diatur',
                                style: TextStyle(
                                  color: itemPrice > 0
                                      ? amberPrimary
                                      : textMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit menu',
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: textSecondary,
                          ),
                          onPressed: () {
                            setModalState(() {
                              onEditingIndexChanged(index);
                              menuNameController.text = itemName;
                              menuPriceController.text =
                                  itemPrice > 0 ? '$itemPrice' : '';
                              menuImageController.text = itemImage;
                            });
                          },
                        ),
                        IconButton(
                          tooltip: 'Hapus menu',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            setModalState(() {
                              menuItems.removeAt(index);
                              if (editingIndex == index) {
                                onEditingIndexChanged(null);
                                menuNameController.clear();
                                menuPriceController.clear();
                                menuImageController.clear();
                              } else if (editingIndex != null &&
                                  editingIndex > index) {
                                onEditingIndexChanged(editingIndex - 1);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),
          ],
        ),
        navyInput,
        navyBorder,
      ),
    ],
  );
}
