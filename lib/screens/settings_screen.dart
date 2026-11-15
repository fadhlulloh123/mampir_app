import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/preference_service.dart';
import '../services/profile_photo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_photo_editor_dialog.dart';
import 'login_screen.dart';

/// ============================================================
/// SETTINGS & USER PROFILE SCREEN — PENGATURAN MAMPIR APP
/// ============================================================
/// Mengelola profil pengguna dan seluruh menu pengaturan:
/// 1. Profil Pengguna (Avatar, Nama, Email, Edit Profil)
/// 2. Notifikasi (Direct switch toggle notifikasi)
/// 3. Izin Lokasi (Status GPS & penjelasan akses wilayah Purwokerto)
/// 4. Tema (Pilihan Gelap, Terang, Ikuti Sistem)
/// 5. Tentang MAMPIR (Informasi versi, deskripsi, & tim pengembang)
/// 6. Keluar Akun (Logout dengan konfirmasi)
/// ============================================================
class SettingsScreen extends StatefulWidget {
  final bool isRootTab;
  final String? currentRegion;
  final ProfilePhotoService? photoService;

  const SettingsScreen({
    super.key,
    this.isRootTab = false,
    this.currentRegion,
    this.photoService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferenceService _prefService = PreferenceService();

  String _userName = 'Penjelajah MAMPIR';
  String _userEmail = 'user@mampir.id';
  String _userBadge = '🌟 Penjelajah Purwokerto';
  Uint8List? _userPhotoBytes;
  bool _isGuest = false;
  bool _isNotificationEnabled = true;
  bool _isLocationEnabled = true;
  String _selectedTheme = 'Gelap';

  ProfilePhotoService get _photoService =>
      widget.photoService ?? ProfilePhotoService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRegion != widget.currentRegion) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final isGuest = await _prefService.isGuest();
    final region =
        widget.currentRegion ?? await _prefService.getSelectedRegion();
    String name;
    String email;
    final badge = PreferenceService.formatExplorerBadge(region);

    if (isGuest) {
      name = PreferenceService.formatGuestName(region);
      email = PreferenceService.formatGuestEmail(region);
    } else {
      name = await _prefService.getUserName();
      email = await _prefService.getUserEmail();
    }

    final photoBytes = await _prefService.getUserPhotoBytes();
    final notif = await _prefService.isNotificationEnabled();
    final loc = await _prefService.isLocationEnabled();
    final theme = await _prefService.getThemeMode();

    if (mounted) {
      setState(() {
        _isGuest = isGuest;
        _userName = name;
        _userEmail = email;
        _userBadge = badge;
        _userPhotoBytes = photoBytes;
        _isNotificationEnabled = notif;
        _isLocationEnabled = loc;
        _selectedTheme = theme;
      });
    }
  }

  Future<void> _importAndEditPhoto() async {
    final pickResult = await _photoService.pickFromLocalFolder();
    if (!mounted) return;
    if (pickResult.cancelled) return;

    if (!pickResult.hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pickResult.errorMessage ?? 'Gagal mengimpor gambar dari folder lokal.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final editedBytes = await ProfilePhotoEditorDialog.show(
      context,
      imageBytes: pickResult.bytes!,
      title: _userPhotoBytes == null
          ? 'Tambah Foto Profil'
          : 'Ubah Foto Profil',
    );
    if (editedBytes == null || !mounted) return;

    await _prefService.saveUserPhotoBytes(editedBytes);
    if (!mounted) return;
    setState(() => _userPhotoBytes = editedBytes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Foto profil berhasil disimpan ✨'),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  Future<void> _editCurrentPhoto() async {
    final current = _userPhotoBytes;
    if (current == null) {
      await _importAndEditPhoto();
      return;
    }

    final editedBytes = await ProfilePhotoEditorDialog.show(
      context,
      imageBytes: current,
      title: 'Edit Foto Profil',
    );
    if (editedBytes == null || !mounted) return;

    await _prefService.saveUserPhotoBytes(editedBytes);
    if (!mounted) return;
    setState(() => _userPhotoBytes = editedBytes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Foto profil berhasil diperbarui ✨'),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  Future<void> _confirmDeletePhoto() async {
    if (_userPhotoBytes == null) return;
    final colors = AppTheme.colors(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Hapus Foto Profil',
              style: TextStyle(color: colors.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Foto profil akan dihapus dan dikembalikan ke avatar inisial default. Lanjutkan?',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _prefService.deleteUserPhoto();
    if (!mounted) return;
    setState(() => _userPhotoBytes = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto profil berhasil dihapus'),
        backgroundColor: AppTheme.orange,
      ),
    );
  }

  void _showProfilePhotoOptions() {
    final colors = AppTheme.colors(context);
    final hasPhoto = _userPhotoBytes != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderNavy,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildProfileAvatar(size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelola Foto Profil',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasPhoto
                                ? 'Ubah, edit tampilan, atau hapus foto profil Anda'
                                : 'Impor gambar dari folder lokal perangkat',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: colors.borderNavy, height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.folder_open_rounded,
                    color: AppTheme.orange,
                  ),
                  title: Text(
                    hasPhoto
                        ? 'Ubah Foto dari Folder Lokal'
                        : 'Tambah Foto dari Folder Lokal',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Impor file gambar (JPG, PNG, WEBP) dari penyimpanan lokal',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _importAndEditPhoto();
                  },
                ),
                if (hasPhoto) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.tune_rounded,
                      color: AppTheme.gold,
                    ),
                    title: Text(
                      'Edit Foto Saat Ini',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Crop, zoom, putar, balik, dan atur filter warna',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _editCurrentPhoto();
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Hapus Foto Profil',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Kembali ke avatar inisial default',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _confirmDeletePhoto();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar({
    required double size,
    bool showCameraBadge = false,
  }) {
    final photo = _userPhotoBytes;
    final avatarCircle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: photo == null ? AppTheme.primaryGradient : null,
        shape: BoxShape.circle,
        border: photo != null
            ? Border.all(color: AppTheme.orange, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.orange.withAlpha(80),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: photo != null
            ? Image.memory(
                photo,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (ctx, err, st) => _buildInitialAvatarChild(size),
              )
            : _buildInitialAvatarChild(size),
      ),
    );

    if (!showCameraBadge) return avatarCircle;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarCircle,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppTheme.orange,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.colors(context).cardNavy, width: 2),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialAvatarChild(double size) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      alignment: Alignment.center,
      child: Text(
        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'M',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final colors = AppTheme.colors(context);
    final nameCtrl = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _userEmail);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: colors.surfaceNavy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Edit Profil Pengguna',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await _importAndEditPhoto();
                      if (dialogCtx.mounted) setDialogState(() {});
                    },
                    child: _buildProfileAvatar(size: 72, showCameraBadge: true),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await _importAndEditPhoto();
                          if (dialogCtx.mounted) setDialogState(() {});
                        },
                        icon: const Icon(
                          Icons.folder_open_rounded,
                          size: 16,
                          color: AppTheme.orange,
                        ),
                        label: Text(
                          _userPhotoBytes == null ? 'Impor Foto' : 'Ubah Foto',
                          style: const TextStyle(
                            color: AppTheme.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_userPhotoBytes != null) ...[
                        TextButton.icon(
                          onPressed: () async {
                            await _editCurrentPhoto();
                            if (dialogCtx.mounted) setDialogState(() {});
                          },
                          icon: const Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: AppTheme.gold,
                          ),
                          label: const Text(
                            'Edit',
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await _confirmDeletePhoto();
                            if (dialogCtx.mounted) setDialogState(() {});
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            'Hapus',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Nama Pengguna',
                      labelStyle: const TextStyle(color: AppTheme.gold),
                      filled: true,
                      fillColor: colors.cardNavy,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colors.borderNavy),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colors.borderNavy),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: emailCtrl,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: AppTheme.gold),
                      filled: true,
                      fillColor: colors.cardNavy,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colors.borderNavy),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colors.borderNavy),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Batal',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  final newEmail = emailCtrl.text.trim();
                  Navigator.pop(ctx);
                  if (newName.isNotEmpty) {
                    await _prefService.updateProfile(
                      name: newName,
                      email: newEmail,
                    );
                    if (mounted) {
                      setState(() {
                        _userName = newName;
                        _userEmail = newEmail;
                      });
                    }
                  }
                },
                child: const Text(
                  'Simpan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleLogout() {
    final colors = AppTheme.colors(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              'Keluar Akun',
              style: TextStyle(color: colors.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun MAMPIR?',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _prefService.logout();

              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Keluar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colors(context);
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Stack(
        children: [
          // Background Mandala & Batik Multi-Sudut
          const AppBackgroundOrnament(),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      if (!widget.isRootTab) ...[
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back, color: colors.iconColor),
                          tooltip: 'Kembali',
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        'Profil Pengguna',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      // USER PROFILE CARD
                      _buildUserProfileCard(),
                      const SizedBox(height: 16),

                      // 1. Notifikasi (Direct Switch Toggle)
                      _buildSwitchSettingItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifikasi',
                        subtitle: _isNotificationEnabled
                            ? 'Notifikasi rekomendasi & promo aktif'
                            : 'Notifikasi dimatikan',
                        value: _isNotificationEnabled,
                        onChanged: (val) async {
                          setState(() => _isNotificationEnabled = val);
                          await _prefService.setNotificationEnabled(val);
                        },
                      ),
                      _buildDivider(),

                      // 2. Izin Lokasi
                      _buildSettingItem(
                        icon: Icons.location_on_outlined,
                        title: 'Izin Lokasi',
                        trailingText: _isLocationEnabled
                            ? 'Diizinkan'
                            : 'Ditolak',
                        onTap: _showLocationSettingsModal,
                      ),
                      _buildDivider(),

                      // 3. Tema
                      _buildSettingItem(
                        icon: Icons.nightlight_round,
                        title: 'Tema',
                        trailingText: _selectedTheme,
                        onTap: _showThemeSelectorModal,
                      ),
                      _buildDivider(),

                      // 4. Tentang MAMPIR
                      _buildSettingItem(
                        icon: Icons.info_outline_rounded,
                        title: 'Tentang MAMPIR',
                        subtitle: 'Versi 1.0.0',
                        onTap: _showAboutMampirDialog,
                      ),
                      const SizedBox(height: 24),

                      // TOMBOL LOGOUT
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.redAccent,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.redAccent.withAlpha(25),
                          ),
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          label: const Text(
                            'Keluar dari Akun',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _handleLogout,
                        ),
                      ),
                      const SizedBox(height: 32),
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

  // ======================== USER PROFILE CARD ========================
  Widget _buildUserProfileCard() {
    final colors = AppTheme.colors(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderNavy),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(colors.isDark ? 40 : 12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar Lingkaran (Ketuk untuk Tambah/Ubah/Edit/Hapus Foto)
          Tooltip(
            message: 'Kelola Foto Profil',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _showProfilePhotoOptions,
              child: _buildProfileAvatar(size: 56, showCameraBadge: true),
            ),
          ),
          const SizedBox(width: 14),

          // Info Nama & Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _userEmail,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.gold.withAlpha(80)),
                  ),
                  child: Text(
                    _userBadge,
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tombol Kelola Foto & Edit Profil
          IconButton(
            icon: const Icon(
              Icons.photo_camera_outlined,
              color: AppTheme.orange,
              size: 20,
            ),
            tooltip: 'Kelola Foto Profil',
            onPressed: _showProfilePhotoOptions,
          ),
          if (!_isGuest)
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppTheme.gold,
                size: 20,
              ),
              tooltip: 'Edit Profil',
              onPressed: _showEditProfileDialog,
            ),
        ],
      ),
    );
  }

  // ======================== MODAL: IZIN LOKASI ========================
  void _showLocationSettingsModal() {
    final colors = AppTheme.colors(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Pengaturan Izin Lokasi (GPS)',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'MAMPIR membutuhkan izin lokasi agar dapat merekomendasikan kuliner terdekat serta memandu rute perjalanan di Purwokerto, Baturraden, dan Sokaraja.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    activeThumbColor: AppTheme.orange,
                    activeTrackColor: AppTheme.orange.withAlpha(120),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Akses Lokasi Perangkat',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _isLocationEnabled
                          ? 'GPS aktif untuk Purwokerto & Sekitarnya'
                          : 'Lokasi nonaktif (menggunakan titik pusat kota)',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    value: _isLocationEnabled,
                    onChanged: (val) async {
                      final messenger = ScaffoldMessenger.of(context);
                      setModalState(() => _isLocationEnabled = val);
                      setState(() => _isLocationEnabled = val);
                      await _prefService.setLocationEnabled(val);

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            val
                                ? 'Izin lokasi berhasil diaktifkan'
                                : 'Izin lokasi dinonaktifkan',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ======================== MODAL: PILIH TEMA ========================
  void _showThemeSelectorModal() {
    final colors = AppTheme.colors(context);
    final themes = [
      {
        'code': 'Gelap',
        'title': 'Tema Gelap (Dark)',
        'icon': Icons.nightlight_round,
      },
      {
        'code': 'Terang',
        'title': 'Tema Terang (Light)',
        'icon': Icons.wb_sunny_rounded,
      },
      {
        'code': 'Sistem',
        'title': 'Ikuti Pengaturan Sistem',
        'icon': Icons.settings_brightness_rounded,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.palette_rounded,
                    color: AppTheme.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Pilih Tema Tampilan',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ...themes.map((theme) {
                final isSelected = _selectedTheme == theme['code'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (colors.isDark
                              ? AppTheme.cardNavy
                              : const Color(0xFFFFF7ED))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.orange : colors.borderNavy,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      theme['icon'] as IconData,
                      color: isSelected
                          ? AppTheme.orange
                          : colors.textSecondary,
                    ),
                    title: Text(
                      theme['title'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.orange
                            : colors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.orange,
                          )
                        : null,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final newTheme = theme['code'] as String;
                      Navigator.pop(ctx);
                      setState(() => _selectedTheme = newTheme);
                      await _prefService.setThemeMode(newTheme);
                      AppTheme.setThemeFromString(newTheme);

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Tema diatur ke ${theme['title']}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ======================== DIALOG: TENTANG MAMPIR ========================
  void _showAboutMampirDialog() {
    final colors = AppTheme.colors(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.orange.withAlpha(40),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.orange, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Transform.scale(
                  scale: 1.35,
                  alignment: const Alignment(0, -0.04),
                  child: Image.asset(
                    'assets/images/app_icon.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Icon(
                      Icons.restaurant_menu_rounded,
                      color: AppTheme.orange,
                      size: 38,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'MAMPIR',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
                letterSpacing: 1.2,
              ),
            ),
            const Text(
              'Makan • Ampir • Pilih • Rekomendasi',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: colors.isDark
                    ? Colors.white10
                    : Colors.black.withAlpha(15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Versi 1.0.0 (Release Build)',
                style: TextStyle(color: colors.textSecondary, fontSize: 11),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Aplikasi panduan dan rekomendasi tempat kuliner, cafe santai, dan tempat nongkrong favorit di Kota Purwokerto dan sekitarnya (Baturraden, Sokaraja) berbasis filter budget & peta interaktif.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: colors.borderNavy),
            Text(
              'Tugas Praktikum PML Semester 5\n© 2026 MAMPIR Purwokerto',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Tutup',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================== WIDGET HELPER ========================
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    Color iconColor = AppTheme.orange,
    required VoidCallback onTap,
  }) {
    final colors = AppTheme.colors(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surfaceNavy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderNavy),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            Icons.chevron_right_rounded,
            color: colors.textSecondary,
            size: 20,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color iconColor = AppTheme.orange,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = AppTheme.colors(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surfaceNavy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderNavy),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            )
          : null,
      trailing: Switch.adaptive(
        value: value,
        activeThumbColor: AppTheme.orange,
        activeTrackColor: AppTheme.orange.withAlpha(120),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider() {
    final colors = AppTheme.colors(context);
    return Divider(color: colors.borderNavy, height: 1, indent: 58);
  }
}
