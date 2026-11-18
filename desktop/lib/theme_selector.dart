import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ==============================================================
/// THEME CONTROLLER & SELECTOR (MAMPIR ADMIN DASHBOARD)
/// ==============================================================
/// Pengelola tema mandiri yang mengadopsi fungsionalitas aplikasi mobile:
/// - Pilihan Mode: Gelap (Dark), Terang (Light), dan Ikuti Sistem (System).
/// - Sinkronisasi preferensi ke SharedPreferences ('admin_theme_mode').
/// - Dialog pemilih tema bergaya mobile sheet/dialog & widget toggle sidebar.
/// ==============================================================

class ThemeOptionItem {
  final String code;
  final String title;
  final String description;
  final IconData icon;
  final ThemeMode mode;

  const ThemeOptionItem({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.mode,
  });
}

class AdminThemeController {
  static const String prefKey = 'admin_theme_mode';

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  static const List<ThemeOptionItem> options = [
    ThemeOptionItem(
      code: 'Gelap',
      title: 'Tema Gelap (Dark)',
      description: 'Latar belakang navy elegan & aksen amber, nyaman di mata.',
      icon: Icons.nightlight_round,
      mode: ThemeMode.dark,
    ),
    ThemeOptionItem(
      code: 'Terang',
      title: 'Tema Terang (Light)',
      description: 'Tampilan bersih & cerah untuk pencahayaan ruangan terang.',
      icon: Icons.wb_sunny_rounded,
      mode: ThemeMode.light,
    ),
    ThemeOptionItem(
      code: 'Sistem',
      title: 'Ikuti Pengaturan Sistem',
      description: 'Menyesuaikan otomatis dengan preferensi tema sistem operasi.',
      icon: Icons.settings_brightness_rounded,
      mode: ThemeMode.system,
    ),
  ];

  /// Inisialisasi tema saat aplikasi pertama kali dijalankan
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefKey);
      if (saved == 'light' || saved == 'Terang') {
        themeModeNotifier.value = ThemeMode.light;
      } else if (saved == 'system' || saved == 'Sistem') {
        themeModeNotifier.value = ThemeMode.system;
      } else {
        themeModeNotifier.value = ThemeMode.dark;
      }
    } catch (_) {
      themeModeNotifier.value = ThemeMode.dark;
    }
  }

  /// Mengubah mode tema & menyimpannya ke local storage
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      String saveVal;
      switch (mode) {
        case ThemeMode.light:
          saveVal = 'light';
          break;
        case ThemeMode.system:
          saveVal = 'system';
          break;
        case ThemeMode.dark:
          saveVal = 'dark';
          break;
      }
      await prefs.setString(prefKey, saveVal);
    } catch (_) {}
  }

  /// Mengubah tema berdasarkan kode teks ('Gelap', 'Terang', 'Sistem')
  static Future<void> setThemeFromCode(String code) async {
    switch (code) {
      case 'Terang':
        await setThemeMode(ThemeMode.light);
        break;
      case 'Sistem':
        await setThemeMode(ThemeMode.system);
        break;
      case 'Gelap':
      default:
        await setThemeMode(ThemeMode.dark);
        break;
    }
  }

  static String get currentThemeCode {
    switch (themeModeNotifier.value) {
      case ThemeMode.light:
        return 'Terang';
      case ThemeMode.system:
        return 'Sistem';
      case ThemeMode.dark:
        return 'Gelap';
    }
  }

  static String get currentThemeTitle {
    switch (themeModeNotifier.value) {
      case ThemeMode.light:
        return 'Tema Terang (Light)';
      case ThemeMode.system:
        return 'Ikuti Pengaturan Sistem';
      case ThemeMode.dark:
        return 'Tema Gelap (Dark)';
    }
  }

  static bool isDark(BuildContext context) {
    if (themeModeNotifier.value == ThemeMode.light) return false;
    if (themeModeNotifier.value == ThemeMode.dark) return true;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }
}

/// ==============================================================
/// MODAL DIALOG PEMILIH TEMA (MIRIP TAMPILAN MOBILE)
/// ==============================================================
Future<void> showAdminThemeSelectorDialog(BuildContext context) async {
  final isDark = AdminThemeController.isDark(context);
  const amberPrimary = Color(0xFFD99B25);
  final navyCard = isDark ? const Color(0xFF162035) : Colors.white;
  final navySurface = isDark ? const Color(0xFF1A233A) : const Color(0xFFF1F5F9);
  final navyBorder = isDark ? const Color(0xFF263353) : const Color(0xFFE2E8F0);
  final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
  final textSecondary =
      isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF475569);
  final textMuted =
      isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF94A3B8);

  await showDialog<void>(
    context: context,
    builder: (dialogCtx) => Dialog(
      backgroundColor: navyCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: navyBorder, width: 1.5),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar Atas
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Judul
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: amberPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.palette_rounded,
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
                        'Pilih Tema Tampilan',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sesuaikan kenyamanan visual dashboard MAMPIR',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textMuted, size: 20),
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(height: 1, color: navyBorder),
            const SizedBox(height: 16),

            // 3 Pilihan Tema (Gelap, Terang, Sistem)
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AdminThemeController.themeModeNotifier,
              builder: (ctx, currentMode, _) {
                return Column(
                  children: AdminThemeController.options.map((option) {
                    final isSelected = currentMode == option.mode;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? amberPrimary.withValues(alpha: isDark ? 0.16 : 0.1)
                            : navySurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? amberPrimary
                              : navyBorder.withValues(alpha: 0.8),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            await AdminThemeController.setThemeMode(option.mode);
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        option.icon,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Text('Tema diatur ke ${option.title}'),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? amberPrimary.withValues(alpha: 0.2)
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : Colors.black.withValues(alpha: 0.04)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    option.icon,
                                    color: isSelected
                                        ? amberPrimary
                                        : textSecondary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.title,
                                        style: TextStyle(
                                          color: isSelected
                                              ? (isDark
                                                  ? Colors.white
                                                  : const Color(0xFFB45309))
                                              : textPrimary,
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        option.description,
                                        style: TextStyle(
                                          color: isSelected
                                              ? textSecondary
                                              : textMuted,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: amberPrimary,
                                    size: 22,
                                  )
                                else
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: textMuted.withValues(alpha: 0.5),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: textSecondary,
                ),
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// ==============================================================
/// WIDGET TOGGLE TEMA SIDEBAR (3 PILIHAN CEPAT: GELAP | TERANG | SISTEM)
/// ==============================================================
class AdminThemeToggleWidget extends StatelessWidget {
  const AdminThemeToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AdminThemeController.isDark(context);
    const amberPrimary = Color(0xFFD99B25);
    final navyInput = isDark ? const Color(0xFF131B30) : const Color(0xFFF1F5F9);
    final navyBorder = isDark ? const Color(0xFF263353) : const Color(0xFFE2E8F0);
    final textMuted =
        isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF94A3B8);

    return Column(
      children: [
        // 3-way Segmented Control
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: navyInput,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: navyBorder),
          ),
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: AdminThemeController.themeModeNotifier,
            builder: (context, currentMode, _) {
              return Row(
                children: [
                  _buildSegment(
                    context: context,
                    title: 'Gelap',
                    icon: Icons.dark_mode_rounded,
                    mode: ThemeMode.dark,
                    isActive: currentMode == ThemeMode.dark,
                    amberPrimary: amberPrimary,
                    textMuted: textMuted,
                    isDark: isDark,
                  ),
                  _buildSegment(
                    context: context,
                    title: 'Terang',
                    icon: Icons.light_mode_rounded,
                    mode: ThemeMode.light,
                    isActive: currentMode == ThemeMode.light,
                    amberPrimary: amberPrimary,
                    textMuted: textMuted,
                    isDark: isDark,
                  ),
                  _buildSegment(
                    context: context,
                    title: 'Sistem',
                    icon: Icons.settings_brightness_rounded,
                    mode: ThemeMode.system,
                    isActive: currentMode == ThemeMode.system,
                    amberPrimary: amberPrimary,
                    textMuted: textMuted,
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 6),

        // Tombol Buka Modal / Dialog Lengkap
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => showAdminThemeSelectorDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 13,
                  color: amberPrimary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  'Buka Dialog Pilihan Tema',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: amberPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required bool isActive,
    required Color amberPrimary,
    required Color textMuted,
    required bool isDark,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => AdminThemeController.setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF1E2D4A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: amberPrimary.withValues(alpha: isDark ? 0.4 : 0.6))
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: isDark
                          ? amberPrimary.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isActive
                    ? (isDark ? amberPrimary : const Color(0xFFD97706))
                    : textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
