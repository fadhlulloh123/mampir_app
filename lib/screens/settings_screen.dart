import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ============================================================
/// SETTINGS SCREEN — SESUAI pengaturan mampir.jpeg
/// ============================================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Stack(
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
                // Header Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pengaturan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    children: [
                      _buildSettingItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifikasi',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifikasi aktif'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingItem(
                        icon: Icons.location_on_outlined,
                        title: 'Izin Lokasi',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Izin lokasi diaktifkan'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingItem(
                        icon: Icons.language_rounded,
                        title: 'Bahasa',
                        trailingText: 'Indonesia',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildSettingItem(
                        icon: Icons.nightlight_round,
                        title: 'Tema',
                        trailingText: 'Gelap',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildSettingItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Bantuan & Hubungi Kami',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTheme.surfaceNavy,
                              title: const Text('Bantuan & Kontak',
                                  style: TextStyle(color: Colors.white)),
                              content: const Text(
                                'Aplikasi MAMPIR — Khas Ngapak Se-BARLINGMASCAKEB\nHubungi: support@mampir.id',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Tutup',
                                      style: TextStyle(color: AppTheme.gold)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingItem(
                        icon: Icons.info_outline_rounded,
                        title: 'Tentang MAMPIR',
                        subtitle: 'Versi 1.0.0',
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'MAMPIR',
                            applicationVersion: '1.0.0',
                            applicationLegalese:
                                '© 2026 MAMPIR. Khas Ngapak se-BARLINGMASCAKEB.',
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingItem(
                        icon: Icons.share_rounded,
                        title: 'Bagikan Aplikasi',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tautan aplikasi berhasil disalin!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingItem(
                        icon: Icons.star_rounded,
                        title: 'Beri Rating MAMPIR',
                        iconColor: AppTheme.gold,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Terima kasih atas rating Anda! ⭐⭐⭐⭐⭐'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    Color iconColor = AppTheme.orange,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surfaceNavy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderNavy),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textSecondary,
            size: 20,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: AppTheme.borderNavy,
      height: 1,
      indent: 58,
    );
  }
}
