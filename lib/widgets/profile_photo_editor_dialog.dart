import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_theme.dart';

/// Preset filter warna untuk editor foto profil.
enum ProfilePhotoFilter {
  normal('Normal'),
  bright('Cerah'),
  warm('Hangat'),
  mono('Monokrom'),
  contrast('Kontras');

  final String label;
  const ProfilePhotoFilter(this.label);

  ColorFilter? get colorFilter {
    switch (this) {
      case ProfilePhotoFilter.normal:
        return null;
      case ProfilePhotoFilter.bright:
        return const ColorFilter.matrix(<double>[
          1.12, 0, 0, 0, 18,
          0, 1.12, 0, 0, 18,
          0, 0, 1.12, 0, 18,
          0, 0, 0, 1, 0,
        ]);
      case ProfilePhotoFilter.warm:
        return const ColorFilter.matrix(<double>[
          1.12, 0.04, 0, 0, 10,
          0, 1.04, 0, 0, 4,
          0, 0, 0.9, 0, -4,
          0, 0, 0, 1, 0,
        ]);
      case ProfilePhotoFilter.mono:
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ProfilePhotoFilter.contrast:
        return const ColorFilter.matrix(<double>[
          1.25, 0, 0, 0, -24,
          0, 1.25, 0, 0, -24,
          0, 0, 1.25, 0, -24,
          0, 0, 0, 1, 0,
        ]);
    }
  }
}

/// Dialog interaktif untuk mengedit foto profil (geser/crop, zoom, putar,
/// balik horizontal, dan filter warna) sebelum disimpan.
class ProfilePhotoEditorDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final String title;

  const ProfilePhotoEditorDialog({
    super.key,
    required this.imageBytes,
    this.title = 'Edit Foto Profil',
  });

  /// Menampilkan editor foto profil dan mengembalikan PNG bytes hasil edit,
  /// atau `null` jika pengguna membatalkan.
  static Future<Uint8List?> show(
    BuildContext context, {
    required Uint8List imageBytes,
    String title = 'Edit Foto Profil',
  }) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ProfilePhotoEditorDialog(imageBytes: imageBytes, title: title),
    );
  }

  @override
  State<ProfilePhotoEditorDialog> createState() =>
      _ProfilePhotoEditorDialogState();
}

class _ProfilePhotoEditorDialogState extends State<ProfilePhotoEditorDialog> {
  static const double _previewSize = 190.0;
  static const double _minZoom = 0.8;
  static const double _maxZoom = 4.0;

  final GlobalKey _cropBoundaryKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();

  int _quarterTurns = 0;
  bool _flipHorizontal = false;
  ProfilePhotoFilter _activeFilter = ProfilePhotoFilter.normal;
  double _zoom = 1.0;
  bool _isSaving = false;

  double? _sourceWidth;
  double? _sourceHeight;

  @override
  void initState() {
    super.initState();
    _decodeImageDimensions();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _decodeImageDimensions() {
    ui.decodeImageFromList(widget.imageBytes, (ui.Image image) {
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _sourceWidth = image.width.toDouble();
        _sourceHeight = image.height.toDouble();
      });
      image.dispose();
      _centerImageTransform();
    });
  }

  Size _computeRenderSize() {
    final w = _sourceWidth;
    final h = _sourceHeight;
    if (w == null || h == null || w <= 0 || h <= 0) {
      return const Size(_previewSize, _previewSize);
    }
    final effectiveW = _quarterTurns.isOdd ? h : w;
    final effectiveH = _quarterTurns.isOdd ? w : h;

    if (effectiveW >= effectiveH) {
      return Size(_previewSize * (effectiveW / effectiveH), _previewSize);
    }
    return Size(_previewSize, _previewSize * (effectiveH / effectiveW));
  }

  void _centerImageTransform() {
    final renderSize = _computeRenderSize();
    final dx = (_previewSize - renderSize.width) / 2;
    final dy = (_previewSize - renderSize.height) / 2;
    _transformController.value = Matrix4.translationValues(dx, dy, 0.0);
    if (mounted) {
      setState(() => _zoom = 1.0);
    }
  }

  void _rotate(int deltaTurns) {
    setState(() {
      _quarterTurns = (_quarterTurns + deltaTurns) % 4;
      if (_quarterTurns < 0) _quarterTurns += 4;
    });
    _centerImageTransform();
  }

  void _toggleFlip() {
    setState(() => _flipHorizontal = !_flipHorizontal);
  }

  void _resetAll() {
    setState(() {
      _quarterTurns = 0;
      _flipHorizontal = false;
      _activeFilter = ProfilePhotoFilter.normal;
    });
    _centerImageTransform();
  }

  void _onZoomSliderChanged(double targetScale) {
    final current = _transformController.value.clone();
    final currentScale = current.getMaxScaleOnAxis();
    if (currentScale <= 0) return;

    final factor = targetScale / currentScale;
    const center = _previewSize / 2;
    final scaleAroundCenter = Matrix4.identity()
      ..translateByDouble(center, center, 0.0, 1.0)
      ..scaleByDouble(factor, factor, 1.0, 1.0)
      ..translateByDouble(-center, -center, 0.0, 1.0);

    _transformController.value = scaleAroundCenter * current;
    setState(() => _zoom = targetScale);
  }

  Future<void> _exportAndSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final renderObject = _cropBoundaryKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        if (mounted) Navigator.pop(context, widget.imageBytes);
        return;
      }

      // Ekspor area crop 330x330 px (pixelRatio 1.5 * 220)
      final ui.Image rendered = await renderObject.toImage(pixelRatio: 1.5);
      final byteData = await rendered.toByteData(
        format: ui.ImageByteFormat.png,
      );
      rendered.dispose();

      if (byteData == null) {
        throw StateError('Gagal mengonversi gambar hasil edit.');
      }
      final pngBytes = byteData.buffer.asUint8List();
      if (mounted) {
        Navigator.pop(context, pngBytes);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memproses foto. Silakan coba lagi.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);
    final renderSize = _computeRenderSize();

    Widget imageWidget = Image.memory(
      widget.imageBytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (ctx, err, st) => Container(
        color: colors.cardNavy,
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppTheme.orange,
          size: 48,
        ),
      ),
    );

    final filter = _activeFilter.colorFilter;
    if (filter != null) {
      imageWidget = ColorFiltered(colorFilter: filter, child: imageWidget);
    }

    if (_quarterTurns != 0) {
      imageWidget = RotatedBox(quarterTurns: _quarterTurns, child: imageWidget);
    }

    if (_flipHorizontal) {
      imageWidget = Transform.flip(flipX: true, child: imageWidget);
    }

    return Dialog(
      backgroundColor: colors.surfaceNavy,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.borderNavy),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.crop_rounded,
                    color: AppTheme.orange,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isSaving ? null : _resetAll,
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Geser & perbesar gambar agar pas di dalam lingkaran',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Circular Crop Preview
                      Container(
                        width: _previewSize + 8,
                        height: _previewSize + 8,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.orange, width: 2),
                        ),
                        child: ClipOval(
                          child: RepaintBoundary(
                            key: _cropBoundaryKey,
                            child: Container(
                              width: _previewSize,
                              height: _previewSize,
                              color: colors.cardNavy,
                              child: InteractiveViewer(
                                transformationController: _transformController,
                                constrained: false,
                                boundaryMargin: const EdgeInsets.all(140),
                                minScale: _minZoom,
                                maxScale: _maxZoom,
                                onInteractionUpdate: (_) {
                                  final scale = _transformController.value
                                      .getMaxScaleOnAxis()
                                      .clamp(_minZoom, _maxZoom);
                                  if ((scale - _zoom).abs() > 0.02) {
                                    setState(() => _zoom = scale);
                                  }
                                },
                                child: SizedBox(
                                  width: renderSize.width,
                                  height: renderSize.height,
                                  child: imageWidget,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Zoom Slider
                      Row(
                        children: [
                          Icon(
                            Icons.zoom_out_rounded,
                            color: colors.textSecondary,
                            size: 18,
                          ),
                          Expanded(
                            child: Slider(
                              value: _zoom.clamp(_minZoom, _maxZoom),
                              min: _minZoom,
                              max: _maxZoom,
                              activeColor: AppTheme.orange,
                              inactiveColor: colors.borderNavy,
                              onChanged: _isSaving ? null : _onZoomSliderChanged,
                            ),
                          ),
                          Icon(
                            Icons.zoom_in_rounded,
                            color: colors.textSecondary,
                            size: 18,
                          ),
                        ],
                      ),

                      // Transform Buttons (Putar Kiri, Putar Kanan, Balik)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildToolButton(
                            colors: colors,
                            icon: Icons.rotate_left_rounded,
                            label: 'Putar Kiri',
                            onTap: _isSaving ? null : () => _rotate(-1),
                          ),
                          _buildToolButton(
                            colors: colors,
                            icon: Icons.rotate_right_rounded,
                            label: 'Putar Kanan',
                            onTap: _isSaving ? null : () => _rotate(1),
                          ),
                          _buildToolButton(
                            colors: colors,
                            icon: Icons.flip_rounded,
                            label: 'Balik',
                            isActive: _flipHorizontal,
                            onTap: _isSaving ? null : _toggleFlip,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Filter Presets
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Filter Warna',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: ProfilePhotoFilter.values.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final preset = ProfilePhotoFilter.values[idx];
                            final selected = preset == _activeFilter;
                            return ChoiceChip(
                              label: Text(preset.label),
                              selected: selected,
                              selectedColor: AppTheme.orange,
                              backgroundColor: colors.cardNavy,
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : colors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? AppTheme.orange
                                    : colors.borderNavy,
                              ),
                              onSelected: _isSaving
                                  ? null
                                  : (_) => setState(
                                      () => _activeFilter = preset,
                                    ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Actions (Selalu terlihat di bawah)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(
                      'Batal',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onPressed: _isSaving ? null : _exportAndSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                    label: Text(
                      _isSaving ? 'Menyimpan...' : 'Simpan Foto',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required AppColors colors,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isActive = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.orange.withValues(alpha: 0.18)
              : colors.cardNavy,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.orange : colors.borderNavy,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppTheme.orange : AppTheme.gold,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
