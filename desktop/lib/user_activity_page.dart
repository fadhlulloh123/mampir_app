import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// ==============================================================
/// USER ACTIVITY & ACCOUNT MONITORING PAGE (MAMPIR ADMIN DASHBOARD)
/// ==============================================================
/// Halaman khusus untuk memantau akun terdaftar, status online/terakhir login,
/// dan linimasa aktivitas pengguna langsung dari Supabase.
/// ==============================================================
class UserActivityPage extends StatefulWidget {
  final String token;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final ValueChanged<int>? onUserCountChanged;

  const UserActivityPage({
    super.key,
    required this.token,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.onUserCountChanged,
  });

  @override
  State<UserActivityPage> createState() => _UserActivityPageState();
}

class _UserActivityPageState extends State<UserActivityPage> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> userActivities = [];
  bool loadingUsers = false;
  String? usersError;

  final TextEditingController userSearchController = TextEditingController();
  String selectedUserStatusFilter = 'Semua Status';
  int userActiveTab = 0; // 0 = Daftar Pengguna, 1 = Linimasa Aktivitas

  Map<String, String> get headers => {
        'apikey': widget.supabaseAnonKey,
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  @override
  void initState() {
    super.initState();
    loadUsersAndActivities();
  }

  @override
  void dispose() {
    userSearchController.dispose();
    super.dispose();
  }

  static String _formatDateTime(String? rawIso) {
    if (rawIso == null || rawIso.isEmpty) return 'Belum Pernah';
    try {
      final dt = DateTime.parse(rawIso).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute WIB';
    } catch (_) {
      return rawIso;
    }
  }

  static String _timeAgo(String? rawIso) {
    if (rawIso == null || rawIso.isEmpty) return 'Belum pernah login';
    try {
      final dt = DateTime.parse(rawIso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.isNegative) return 'Baru saja';
      if (diff.inSeconds < 60) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return _formatDateTime(rawIso);
    } catch (_) {
      return rawIso;
    }
  }

  List<Map<String, dynamic>> get filteredUsers {
    final query = userSearchController.text.trim().toLowerCase();
    return users.where((u) {
      final email = (u['email'] as String? ?? '').toLowerCase();
      final name = (u['display_name'] as String? ?? '').toLowerCase();
      final id = (u['id'] as String? ?? '').toLowerCase();
      final status = (u['online_status'] as String? ?? 'Offline').trim();

      if (selectedUserStatusFilter == 'Sedang Online' && status != 'Online') {
        return false;
      }
      if (selectedUserStatusFilter == 'Pernah Login' &&
          (u['last_sign_in_at'] == null)) {
        return false;
      }
      if (selectedUserStatusFilter == 'Belum Login' &&
          (u['last_sign_in_at'] != null)) {
        return false;
      }

      if (query.isNotEmpty) {
        if (!email.contains(query) &&
            !name.contains(query) &&
            !id.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> loadUsersAndActivities() async {
    setState(() {
      loadingUsers = true;
      usersError = null;
    });

    try {
      final userResp = await http.get(
        Uri.parse('${widget.supabaseUrl}/rest/v1/admin_user_list?select=*'),
        headers: headers,
      );

      final actResp = await http.get(
        Uri.parse(
          '${widget.supabaseUrl}/rest/v1/user_activities?select=*&order=created_at.desc&limit=200',
        ),
        headers: headers,
      );

      if (userResp.statusCode == 200) {
        final decodedUsers = (jsonDecode(userResp.body) as List<dynamic>)
            .cast<Map<String, dynamic>>();
        if (mounted) {
          setState(() {
            users = decodedUsers;
          });
          widget.onUserCountChanged?.call(decodedUsers.length);
        }
      } else {
        throw Exception('Gagal memuat daftar akun (${userResp.statusCode}).');
      }

      if (actResp.statusCode == 200) {
        final decodedActs = (jsonDecode(actResp.body) as List<dynamic>)
            .cast<Map<String, dynamic>>();
        if (mounted) {
          setState(() {
            userActivities = decodedActs;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          usersError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loadingUsers = false;
        });
      }
    }
  }

  Future<void> sendTestActivityLog() async {
    try {
      final resp = await http.post(
        Uri.parse('${widget.supabaseUrl}/rest/v1/user_activities'),
        headers: headers,
        body: jsonEncode({
          'email': 'admin@mampir.id',
          'action': 'ADMIN_MONITOR',
          'details': 'Administrator memantau koneksi data & aktivitas pengguna',
        }),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catatan aktivitas uji coba berhasil dikirim ke Supabase!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
        await loadUsersAndActivities();
      } else {
        throw Exception('Status ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim log: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void showUserDetailDialog(Map<String, dynamic> user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navyCard = isDark ? const Color(0xFF162035) : Colors.white;
    final navySurface =
        isDark ? const Color(0xFF1A233A) : const Color(0xFFF1F5F9);
    final navyBorder =
        isDark ? const Color(0xFF263353) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF475569);
    final textMuted = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF94A3B8);
    const amberPrimary = Color(0xFFD99B25);

    final userId = (user['id'] as String? ?? '').trim();
    final userEmail = (user['email'] as String? ?? '').trim();
    final displayName = (user['display_name'] as String? ?? '-').trim();
    final status = (user['online_status'] as String? ?? 'Offline').trim();
    final createdAt = user['created_at'] as String?;
    final lastSignIn = user['last_sign_in_at'] as String?;

    // Filter aktivitas terkait akun ini
    final userSpecificActivities = userActivities.where((a) {
      final actEmail = (a['email'] as String? ?? '').trim().toLowerCase();
      final actUid = (a['user_id'] as String? ?? '').trim().toLowerCase();
      return (userEmail.isNotEmpty && actEmail == userEmail.toLowerCase()) ||
          (userId.isNotEmpty && actUid == userId.toLowerCase());
    }).toList();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: navyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: navyBorder, width: 1.5),
        ),
        child: Container(
          width: 650,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Modal
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: amberPrimary.withValues(alpha: 0.2),
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName
                              .substring(0, math.min(2, displayName.length))
                              .toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: amberPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textMuted),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(height: 1, color: navyBorder),
              const SizedBox(height: 18),

              // UID Badge with Copy
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: navySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: navyBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fingerprint_rounded,
                      size: 18,
                      color: amberPrimary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SUPABASE UID',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            userId,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      tooltip: 'Salin UID',
                      color: amberPrimary,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: userId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'UID akun berhasil disalin ke clipboard!',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Detail Info Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: navySurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: navyBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STATUS LOGIN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: status == 'Online'
                                      ? const Color(0xFF10B981)
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: status == 'Online'
                                      ? const Color(0xFF10B981)
                                      : textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _timeAgo(lastSignIn),
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: navySurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: navyBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TANGGAL BERGABUNG',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Terdaftar di Supabase Auth',
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Riwayat Aktivitas Akun
              Text(
                'Riwayat Aktivitas Akun (${userSpecificActivities.length} Catatan):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: userSpecificActivities.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: navySurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: navyBorder),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 36,
                              color: textMuted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada log aktivitas tercatat untuk akun ini.',
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: userSpecificActivities.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final act = userSpecificActivities[idx];
                          final action = (act['action'] as String? ??
                                  'AKTIVITAS')
                              .toUpperCase();
                          final details = act['details'] as String? ?? '-';
                          final time = act['created_at'] as String?;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: navySurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: navyBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: amberPrimary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    action,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: amberPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    details,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  _timeAgo(time),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: navySurface,
                    foregroundColor: textPrimary,
                    side: BorderSide(color: navyBorder),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color navyCard,
    required Color navyBorder,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: navyBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const amberPrimary = Color(0xFFD99B25);
    final navyCard = isDark ? const Color(0xFF162035) : Colors.white;
    final navySurface =
        isDark ? const Color(0xFF1A233A) : const Color(0xFFF1F5F9);
    final navyInput =
        isDark ? const Color(0xFF131B30) : const Color(0xFFF1F5F9);
    final navyBorder =
        isDark ? const Color(0xFF263353) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF475569);
    final textMuted = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF94A3B8);

    final onlineCount = users
        .where((u) => (u['online_status'] as String? ?? '') == 'Online')
        .length;
    final loggedInCount =
        users.where((u) => u['last_sign_in_at'] != null).length;
    final displayUsers = filteredUsers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Top Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Pemantauan Aktivitas & Akun',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Supabase Connected',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Memantau ${displayUsers.length} dari ${users.length} akun terdaftar di Supabase & linimasa aktivitas',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Kirim Log Uji Coba'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: amberPrimary,
                    side: BorderSide(
                      color: amberPrimary.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: sendTestActivityLog,
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  icon: loadingUsers
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black87,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Segarkan Data'),
                  style: FilledButton.styleFrom(
                    backgroundColor: amberPrimary,
                    foregroundColor: const Color(0xFF0D1326),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onPressed: loadingUsers ? null : loadUsersAndActivities,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 2. Metrics Cards
        Row(
          children: [
            _buildStatCard(
              title: 'TOTAL PENGGUNA',
              value: '${users.length}',
              subtitle: 'Akun di Supabase Auth',
              icon: Icons.people_alt_rounded,
              color: amberPrimary,
              navyCard: navyCard,
              navyBorder: navyBorder,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
            const SizedBox(width: 14),
            _buildStatCard(
              title: 'SEDANG ONLINE',
              value: '$onlineCount',
              subtitle: 'Aktif 15 menit terakhir',
              icon: Icons.wifi_tethering_rounded,
              color: const Color(0xFF10B981),
              navyCard: navyCard,
              navyBorder: navyBorder,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
            const SizedBox(width: 14),
            _buildStatCard(
              title: 'PERNAH LOGIN',
              value: '$loggedInCount',
              subtitle: 'Memiliki riwayat sesi',
              icon: Icons.login_rounded,
              color: const Color(0xFF38BDF8),
              navyCard: navyCard,
              navyBorder: navyBorder,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
            const SizedBox(width: 14),
            _buildStatCard(
              title: 'LOG AKTIVITAS',
              value: '${userActivities.length}',
              subtitle: 'Total interaksi tersimpan',
              icon: Icons.history_rounded,
              color: const Color(0xFFA855F7),
              navyCard: navyCard,
              navyBorder: navyBorder,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 3. Tab Switcher
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: navyCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: navyBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => userActiveTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: userActiveTab == 0
                        ? amberPrimary.withValues(alpha: isDark ? 0.2 : 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: userActiveTab == 0
                        ? Border.all(
                            color: amberPrimary.withValues(alpha: 0.5),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.table_chart_rounded,
                        size: 16,
                        color: userActiveTab == 0 ? amberPrimary : textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Daftar Akun Pengguna (${displayUsers.length})',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: userActiveTab == 0
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: userActiveTab == 0
                              ? (isDark ? Colors.white : amberPrimary)
                              : textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => userActiveTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: userActiveTab == 1
                        ? amberPrimary.withValues(alpha: isDark ? 0.2 : 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: userActiveTab == 1
                        ? Border.all(
                            color: amberPrimary.withValues(alpha: 0.5),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: userActiveTab == 1 ? amberPrimary : textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Linimasa Log Aktivitas (${userActivities.length})',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: userActiveTab == 1
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: userActiveTab == 1
                              ? (isDark ? Colors.white : amberPrimary)
                              : textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 4. Tab Content Area
        Expanded(
          child: userActiveTab == 0
              ? _buildUserListTab(
                  context: context,
                  isDark: isDark,
                  amberPrimary: amberPrimary,
                  navyCard: navyCard,
                  navySurface: navySurface,
                  navyInput: navyInput,
                  navyBorder: navyBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                  displayUsers: displayUsers,
                )
              : _buildActivityTimelineTab(
                  isDark: isDark,
                  amberPrimary: amberPrimary,
                  navyCard: navyCard,
                  navyBorder: navyBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                ),
        ),
      ],
    );
  }

  Widget _buildUserListTab({
    required BuildContext context,
    required bool isDark,
    required Color amberPrimary,
    required Color navyCard,
    required Color navySurface,
    required Color navyInput,
    required Color navyBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required List<Map<String, dynamic>> displayUsers,
  }) {
    return Column(
      children: [
        // Filter & Search Toolbar
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: TextField(
                  controller: userSearchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    hintText: 'Cari berdasarkan nama, email, atau UID akun...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    suffixIcon: userSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              userSearchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: navyInput,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: navyBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedUserStatusFilter,
                  dropdownColor: navyCard,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  items: const [
                    DropdownMenuItem(
                      value: 'Semua Status',
                      child: Text('Semua Status'),
                    ),
                    DropdownMenuItem(
                      value: 'Sedang Online',
                      child: Text('🟢 Sedang Online'),
                    ),
                    DropdownMenuItem(
                      value: 'Pernah Login',
                      child: Text('🔵 Pernah Login'),
                    ),
                    DropdownMenuItem(
                      value: 'Belum Login',
                      child: Text('🟡 Belum Login'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedUserStatusFilter = val);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Users List Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: navySurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: navyBorder),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'PENGGUNA & UID',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: textMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'EMAIL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: textMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'STATUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: textMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'TERAKHIR LOGIN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: textMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'TANGGAL DAFTAR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: textMuted,
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  'AKSI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Users List View
        Expanded(
          child: displayUsers.isEmpty
              ? Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: navyCard,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    border: Border.all(color: navyBorder),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 48,
                          color: textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada akun yang sesuai dengan pencarian atau filter.',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: navyCard,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    border: Border(
                      left: BorderSide(color: navyBorder),
                      right: BorderSide(color: navyBorder),
                      bottom: BorderSide(color: navyBorder),
                    ),
                  ),
                  child: ListView.separated(
                    itemCount: displayUsers.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: navyBorder.withValues(alpha: 0.6),
                    ),
                    itemBuilder: (context, idx) {
                      final u = displayUsers[idx];
                      final uid = (u['id'] as String? ?? '').trim();
                      final email = (u['email'] as String? ?? '').trim();
                      final displayName =
                          (u['display_name'] as String? ?? '-').trim();
                      final status =
                          (u['online_status'] as String? ?? 'Offline').trim();
                      final lastSignIn = u['last_sign_in_at'] as String?;
                      final createdAt = u['created_at'] as String?;

                      final isOnline = status == 'Online';
                      final isNever = lastSignIn == null;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // 1. Pengguna & UID
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 17,
                                    backgroundColor:
                                        amberPrimary.withValues(alpha: 0.2),
                                    child: Text(
                                      displayName.isNotEmpty
                                          ? displayName
                                              .substring(
                                                0,
                                                math.min(
                                                  2,
                                                  displayName.length,
                                                ),
                                              )
                                              .toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: amberPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              uid.length > 12
                                                  ? '${uid.substring(0, 8)}...${uid.substring(uid.length - 4)}'
                                                  : uid,
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 10.5,
                                                color: textMuted,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            InkWell(
                                              onTap: () {
                                                Clipboard.setData(
                                                  ClipboardData(text: uid),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'UID disalin ke clipboard!',
                                                    ),
                                                    duration:
                                                        Duration(seconds: 1),
                                                  ),
                                                );
                                              },
                                              child: Icon(
                                                Icons.copy_rounded,
                                                size: 12,
                                                color: textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 2. Email
                            Expanded(
                              flex: 3,
                              child: Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textSecondary,
                                ),
                              ),
                            ),

                            // 3. Status
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOnline
                                        ? const Color(0xFF10B981)
                                            .withValues(alpha: 0.15)
                                        : isNever
                                            ? Colors.amber
                                                .withValues(alpha: 0.15)
                                            : Colors.grey
                                                .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isOnline
                                          ? const Color(0xFF10B981)
                                              .withValues(alpha: 0.4)
                                          : isNever
                                              ? Colors.amber
                                                  .withValues(alpha: 0.4)
                                              : Colors.grey
                                                  .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isOnline
                                              ? const Color(0xFF10B981)
                                              : isNever
                                                  ? Colors.amber
                                                  : Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isOnline
                                              ? const Color(0xFF10B981)
                                              : isNever
                                                  ? Colors.amber
                                                  : textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 4. Terakhir Login
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _timeAgo(lastSignIn),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isNever ? textMuted : textPrimary,
                                    ),
                                  ),
                                  if (!isNever)
                                    Text(
                                      _formatDateTime(lastSignIn),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // 5. Tanggal Daftar
                            Expanded(
                              flex: 3,
                              child: Text(
                                _formatDateTime(createdAt),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textSecondary,
                                ),
                              ),
                            ),

                            // 6. Aksi
                            SizedBox(
                              width: 110,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  side: BorderSide(
                                    color: amberPrimary.withValues(alpha: 0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => showUserDetailDialog(u),
                                child: Text(
                                  'Detail & Log',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: amberPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildActivityTimelineTab({
    required bool isDark,
    required Color amberPrimary,
    required Color navyCard,
    required Color navyBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    if (userActivities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: navyBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 54, color: textMuted),
            const SizedBox(height: 14),
            Text(
              'Belum ada rekaman aktivitas pengguna.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Aktivitas akan otomatis muncul saat pengguna login atau melakukan aksi di aplikasi mobile/desktop.',
              style: TextStyle(fontSize: 12.5, color: textMuted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Buat Log Uji Coba Sekarang'),
              style: FilledButton.styleFrom(
                backgroundColor: amberPrimary,
                foregroundColor: Colors.black87,
              ),
              onPressed: sendTestActivityLog,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: navyBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: ListView.separated(
        itemCount: userActivities.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: navyBorder.withValues(alpha: 0.6)),
        itemBuilder: (context, idx) {
          final act = userActivities[idx];
          final action =
              (act['action'] as String? ?? 'AKTIVITAS').toUpperCase();
          final email = (act['email'] as String? ?? 'Pengguna').trim();
          final details = (act['details'] as String? ?? '-').trim();
          final time = act['created_at'] as String?;

          Color actionColor;
          IconData actionIcon;
          if (action.contains('LOGIN')) {
            actionColor = const Color(0xFF10B981);
            actionIcon = Icons.login_rounded;
          } else if (action.contains('ADMIN')) {
            actionColor = amberPrimary;
            actionIcon = Icons.admin_panel_settings_rounded;
          } else if (action.contains('REGISTER') || action.contains('SIGNUP')) {
            actionColor = const Color(0xFFA855F7);
            actionIcon = Icons.person_add_rounded;
          } else {
            actionColor = const Color(0xFF38BDF8);
            actionIcon = Icons.touch_app_rounded;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(actionIcon, size: 18, color: actionColor),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: actionColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    action,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: actionColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        details,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _timeAgo(time),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      _formatDateTime(time),
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
