import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ============================================================
/// NOTIFICATION SCREEN — SESUAI notifikasi_mampir.jpeg
/// ============================================================
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedTabIndex = 0; // 0: Semua, 1: Pembaruan

  final List<Map<String, dynamic>> _allNotifications = [
    {
      'title': 'Tempat favorit kamu sedang promo!',
      'subtitle': 'The Local Space, diskon 20%',
      'time': '2 jam yang lalu',
      'unread': true,
      'image':
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=400&q=80',
      'isMascot': false,
    },
    {
      'title': 'Rekomendasi baru untuk kamu',
      'subtitle': '3 tempat sesuai budget 50rb',
      'time': '5 jam yang lalu',
      'unread': true,
      'image': 'assets/images/app_icon.jpeg',
      'isMascot': true,
    },
    {
      'title': 'Tempat yang kamu simpan',
      'subtitle': 'ada update menu terbaru!',
      'time': '1 hari yang lalu',
      'unread': false,
      'image':
          'https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&w=400&q=80',
      'isMascot': false,
    },
    {
      'title': 'Kuliner Baru di Baturraden',
      'subtitle': 'Kopi Keprok & Massapi Baturraden kini tersedia di MAMPIR',
      'time': '3 hari yang lalu',
      'unread': false,
      'image':
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=400&q=80',
      'isMascot': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final displayedList = _selectedTabIndex == 0
        ? _allNotifications
        : _allNotifications.where((n) => n['unread'] == true).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Stack(
        children: [
          // Background Mandala
          Positioned(
            top: 0,
            right: 0,
            width: 250,
            height: 250,
            child: CustomPaint(
              painter: MandalaOrnamentPainter(scale: 0.8),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Notifikasi',
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

                // Tabs: Semua vs Pembaruan
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: _selectedTabIndex == 0
                                  ? AppTheme.primaryGradient
                                  : null,
                              color: _selectedTabIndex == 0
                                  ? null
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: _selectedTabIndex == 0
                                    ? Colors.transparent
                                    : AppTheme.borderNavy,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Semua',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: _selectedTabIndex == 0
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: _selectedTabIndex == 1
                                  ? AppTheme.primaryGradient
                                  : null,
                              color: _selectedTabIndex == 1
                                  ? null
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: _selectedTabIndex == 1
                                    ? Colors.transparent
                                    : AppTheme.borderNavy,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Pembaruan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: _selectedTabIndex == 1
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // List Notifikasi
                Expanded(
                  child: displayedList.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada notifikasi',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          itemCount: displayedList.length,
                          separatorBuilder: (context, index) =>
                              const Divider(color: AppTheme.borderNavy, height: 28),
                          itemBuilder: (context, index) {
                            final notif = displayedList[index];
                            final isMascot = notif['isMascot'] == true;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail / Icon
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceNavy,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.borderNavy),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: isMascot
                                        ? Image.asset(
                                            'assets/images/app_icon.jpeg',
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            notif['image'] as String,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, st) =>
                                                const Icon(
                                              Icons.local_cafe_rounded,
                                              color: AppTheme.gold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Detail Notifikasi
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif['title'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif['subtitle'] as String,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        notif['time'] as String,
                                        style: const TextStyle(
                                          color: AppTheme.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Indicator unread
                                if (notif['unread'] == true)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
