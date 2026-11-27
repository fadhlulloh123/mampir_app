import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'edit_tempat.dart';
import 'place_form_widgets.dart';
import 'tambah_tempat.dart';
import 'theme_selector.dart';
import 'user_activity_page.dart';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://vdqdithxujxvzyybjtpn.supabase.co',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkcWRpdGh4dWp4dnp5eWJqdHBuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMyMzA2NTIsImV4cCI6MjEwODgwNjY1Mn0.7zE0gLxh0a2DNzdVcRfTj3EZDaqXWZ09kL5gcXTETXY',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdminThemeController.init();
  runApp(const AdminApp());
}

ValueNotifier<ThemeMode> get adminThemeModeNotifier =>
    AdminThemeController.themeModeNotifier;

void toggleAdminTheme() {
  if (AdminThemeController.themeModeNotifier.value == ThemeMode.dark) {
    AdminThemeController.setThemeMode(ThemeMode.light);
  } else {
    AdminThemeController.setThemeMode(ThemeMode.dark);
  }
}

ThemeData _buildDarkTheme() {
  const amberPrimary = Color(0xFFD99B25);
  const navyBg = Color(0xFF0D1326);
  const navyCard = Color(0xFF162035);
  const navyInput = Color(0xFF131B30);
  const navyBorder = Color(0xFF263353);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: navyBg,
    primaryColor: amberPrimary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: amberPrimary,
      brightness: Brightness.dark,
      surface: navyCard,
      onSurface: Colors.white,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: navyCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: navyBorder, width: 1.5),
      ),
      elevation: 16,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: navyInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: navyBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: navyBorder),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: amberPrimary, width: 1.5),
      ),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: navyInput,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: navyCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: navyBorder, width: 1),
      ),
    ),
  );
}

ThemeData _buildLightTheme() {
  const amberPrimary = Color(0xFFD99B25);
  const lightBg = Color(0xFFF8FAFC);
  const lightCard = Colors.white;
  const lightInput = Color(0xFFF1F5F9);
  const lightBorder = Color(0xFFE2E8F0);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    primaryColor: amberPrimary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: amberPrimary,
      brightness: Brightness.light,
      surface: lightCard,
      onSurface: const Color(0xFF0F172A),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: lightBorder, width: 1.5),
      ),
      elevation: 16,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: amberPrimary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
    ),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: adminThemeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'MAMPIR Admin',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          home: const AdminLoginPage(),
        );
      },
    );
  }
}

enum OrnamentOrigin { topRight, bottomLeft, topLeft, bottomRight }

class MandalaOrnamentPainter extends CustomPainter {
  final double scale;
  final bool isDark;
  final double strokeWidth;
  final Color? color;
  final OrnamentOrigin origin;

  MandalaOrnamentPainter({
    this.scale = 1.0,
    required this.isDark,
    this.strokeWidth = 1.2,
    this.color,
    this.origin = OrnamentOrigin.topRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveColor =
        color ??
        (isDark
            ? const Color(0xFFFFB74D).withValues(alpha: 0.16)
            : const Color(0xFFD97706).withValues(alpha: 0.20));

    final paint = Paint()
      ..color = effectiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fillPaint = Paint()
      ..color = effectiveColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    late Offset center;
    switch (origin) {
      case OrnamentOrigin.topRight:
        center = Offset(size.width, 0);
        break;
      case OrnamentOrigin.bottomLeft:
        center = Offset(0, size.height);
        break;
      case OrnamentOrigin.topLeft:
        center = const Offset(0, 0);
        break;
      case OrnamentOrigin.bottomRight:
        center = Offset(size.width, size.height);
        break;
    }

    final maxRadius = size.width * 0.78 * scale;
    const int petals = 12;

    for (double r = 36; r <= maxRadius; r += 28) {
      canvas.drawCircle(center, r, paint);
    }

    for (int i = 0; i < petals; i++) {
      final angle = (i * 2 * math.pi) / petals;
      final midR = maxRadius * 0.58;
      final x = center.dx + math.cos(angle) * midR;
      final y = center.dy + math.sin(angle) * midR;

      canvas.drawCircle(Offset(x, y), 22 * scale, paint);

      final rx = center.dx + math.cos(angle) * maxRadius;
      final ry = center.dy + math.sin(angle) * maxRadius;
      canvas.drawLine(center, Offset(rx, ry), paint);

      canvas.drawCircle(Offset(rx, ry), 2.5 * scale, fillPaint);
    }

    final innerR = maxRadius * 0.32;
    for (int i = 0; i < petals; i++) {
      final angle = (i * 2 * math.pi) / petals + (math.pi / petals);
      final x = center.dx + math.cos(angle) * innerR;
      final y = center.dy + math.sin(angle) * innerR;
      canvas.drawCircle(Offset(x, y), 14 * scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MandalaOrnamentPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.scale != scale ||
        oldDelegate.isDark != isDark ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.origin != origin;
  }
}

class FloatingBatikAccentPainter extends CustomPainter {
  final bool isDark;
  final double strokeWidth;

  FloatingBatikAccentPainter({required this.isDark, this.strokeWidth = 1.6});

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = isDark
        ? const Color(0xFFFFB74D)
        : const Color(0xFFB45309);
    final double opacity = isDark ? 0.16 : 0.22;

    final strokePaint = Paint()
      ..color = baseColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fillPaint = Paint()
      ..color = baseColor.withValues(alpha: opacity * 0.6)
      ..style = PaintingStyle.fill;

    final List<Offset> points = [
      Offset(size.width * 0.14, size.height * 0.22),
      Offset(size.width * 0.88, size.height * 0.28),
      Offset(size.width * 0.18, size.height * 0.75),
      Offset(size.width * 0.84, size.height * 0.78),
      Offset(size.width * 0.50, size.height * 0.08),
    ];

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final double r = (i % 2 == 0) ? 14.0 : 10.0;

      final path = Path();
      path.moveTo(pt.dx, pt.dy - r);
      path.quadraticBezierTo(
        pt.dx + r * 0.25,
        pt.dy - r * 0.25,
        pt.dx + r,
        pt.dy,
      );
      path.quadraticBezierTo(
        pt.dx + r * 0.25,
        pt.dy + r * 0.25,
        pt.dx,
        pt.dy + r,
      );
      path.quadraticBezierTo(
        pt.dx - r * 0.25,
        pt.dy + r * 0.25,
        pt.dx - r,
        pt.dy,
      );
      path.quadraticBezierTo(
        pt.dx - r * 0.25,
        pt.dy - r * 0.25,
        pt.dx,
        pt.dy - r,
      );
      path.close();

      canvas.drawPath(path, strokePaint);
      canvas.drawCircle(pt, 2.2, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FloatingBatikAccentPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.strokeWidth != strokeWidth;
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;
  bool rememberMe = false;
  String? error;

  static const Color _amberPrimary = Color(0xFFD99B25);
  static const Color _navyBg = Color(0xFF0D1326);
  static const Color _navyCard = Color(0xFF162035);
  static const Color _navySurface = Color(0xFF1A233A);
  static const Color _navyInput = Color(0xFF131B30);
  static const Color _navyBorder = Color(0xFF263353);

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRemember = prefs.getBool('admin_remember_me') ?? false;
      final savedEmail = prefs.getString('admin_saved_email') ?? '';
      if (mounted) {
        setState(() {
          rememberMe = savedRemember;
          if (savedRemember && savedEmail.isNotEmpty) {
            email.text = savedEmail;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('admin_remember_me', rememberMe);
      if (rememberMe) {
        await prefs.setString('admin_saved_email', email.text.trim());
      } else {
        await prefs.remove('admin_saved_email');
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final cleanEmail = email.text.trim();
    final cleanPassword = password.text;

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      setState(() => error = 'Email dan kata sandi admin wajib diisi.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password'),
        headers: {
          'apikey': supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': cleanEmail, 'password': cleanPassword}),
      );

      if (response.statusCode != 200) {
        throw Exception('Email atau kata sandi admin tidak valid.');
      }

      final token =
          (jsonDecode(response.body) as Map<String, dynamic>)['access_token']
              as String?;

      if (token == null || token.isEmpty) {
        throw Exception('Token login tidak tersedia.');
      }

      await _saveCredentials();

      try {
        await http.post(
          Uri.parse('$supabaseUrl/rest/v1/user_activities'),
          headers: {
            'apikey': supabaseAnonKey,
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
          body: jsonEncode({
            'email': cleanEmail,
            'action': 'ADMIN_LOGIN',
            'details': 'Administrator masuk ke panel dashboard',
          }),
        );
      } catch (_) {}

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminDashboard(token: token)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navyBg,
      body: Stack(
        children: [
          // 1. Ornamen Mandala Kanan Atas
          Positioned(
            top: 0,
            right: 0,
            width: 360,
            height: 360,
            child: IgnorePointer(
              child: CustomPaint(
                painter: MandalaOrnamentPainter(
                  scale: 1.1,
                  isDark: true,
                  origin: OrnamentOrigin.topRight,
                ),
              ),
            ),
          ),

          // 2. Ornamen Mandala Kiri Bawah
          Positioned(
            bottom: 0,
            left: 0,
            width: 320,
            height: 320,
            child: IgnorePointer(
              child: CustomPaint(
                painter: MandalaOrnamentPainter(
                  scale: 0.95,
                  isDark: true,
                  origin: OrnamentOrigin.bottomLeft,
                ),
              ),
            ),
          ),

          // 3. Aksen Corak Bunga Batik Floating
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: FloatingBatikAccentPainter(isDark: true),
              ),
            ),
          ),

          // 4. Soft Glow di Belakang Kartu
          Center(
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _amberPrimary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 5. Kartu Login di Tengah Layar (Landscape / Memanjang)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscape = constraints.maxWidth >= 760;
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isLandscape ? 820 : 440,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _navyCard,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _navyBorder, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 36,
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: _amberPrimary.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isLandscape ? 40 : 28,
                          vertical: isLandscape ? 36 : 32,
                        ),
                        child: isLandscape
                            ? _buildLandscapeContent()
                            : _buildPortraitContent(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kolom Kiri: Branding & Logo
              Expanded(flex: 4, child: _buildBrandingSide()),

              // Garis Pembatas Vertikal Halus
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 8,
                ),
                child: Container(width: 1, color: _navyBorder),
              ),

              // Kolom Kanan: Form Input
              Expanded(flex: 5, child: _buildFormSide()),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Â© 2026 Tim Proyek PML MAMPIR',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingSide() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1 Logo MAMPIR
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: _navySurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _amberPrimary, width: 2),
            boxShadow: [
              BoxShadow(
                color: _amberPrimary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Transform.scale(
              scale: 1.35,
              alignment: const Alignment(0, -0.04),
              child: Image.asset(
                'assets/images/app_icon.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.travel_explore_rounded,
                  size: 42,
                  color: _amberPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'MAMPIR',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _amberPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _amberPrimary.withValues(alpha: 0.3)),
          ),
          child: const Text(
            'PORTAL ADMINISTRATOR',
            style: TextStyle(
              color: _amberPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Masuk untuk mengelola data\ndan sistem MAMPIR',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSide() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF7F1D1D).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFCA5A5),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Input Email
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Email Administrator',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            hintText: 'admin@mampir.id',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: _amberPrimary,
              size: 20,
            ),
            filled: true,
            fillColor: _navyInput,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _navyBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _navyBorder),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: _amberPrimary, width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Input Password
        TextField(
          controller: password,
          obscureText: obscurePassword,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onSubmitted: (_) => loading ? null : login(),
          decoration: InputDecoration(
            labelText: 'Kata Sandi',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            hintText: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: _amberPrimary,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white54,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => obscurePassword = !obscurePassword),
            ),
            filled: true,
            fillColor: _navyInput,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _navyBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _navyBorder),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: _amberPrimary, width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Checkbox Ingat Saya
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: rememberMe,
                activeColor: _amberPrimary,
                checkColor: _navyBg,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (val) {
                  setState(() => rememberMe = val ?? false);
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => rememberMe = !rememberMe),
              child: Text(
                'Ingat saya di perangkat ini',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Tombol Masuk
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: loading ? null : login,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amberPrimary,
              foregroundColor: _navyBg,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _navyBg,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Masuk ke Dashboard',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBrandingSide(),
        const SizedBox(height: 24),
        _buildFormSide(),
        const SizedBox(height: 24),
        Text(
          'Â© 2026 Tim Proyek PML MAMPIR',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.token});
  final String token;
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedNavIndex = 0; // 0 = Katalog Tempat, 1 = Aktivitas & Akun
  int userCount = 0;
  List<Map<String, dynamic>> places = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> preferences = [];
  bool loading = true;
  String? error;

  final TextEditingController searchController = TextEditingController();
  String selectedZone = 'Semua Wilayah';

  static const List<String> zones = [
    'Semua Wilayah',
    'Purwokerto Kota',
    'Baturraden',
    'Purwokerto Utara (Unsoed)',
    'Sokaraja',
    'Purwokerto Timur & Sumbang',
    'Purwokerto Barat & Selatan',
  ];

  Map<String, String> get headers => {
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer ${widget.token}',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  static String _getZoneKeyword(String zone) {
    final l = zone.toLowerCase();
    if (l.contains('baturraden')) return 'baturraden';
    if (l.contains('sokaraja')) return 'sokaraja';
    if (l.contains('utara') || l.contains('unsoed')) return 'utara';
    if (l.contains('timur') || l.contains('sumbang')) return 'timur';
    if (l.contains('barat')) return 'barat';
    if (l.contains('selatan')) return 'selatan';
    return 'purwokerto';
  }

  List<Map<String, dynamic>> get filteredPlaces {
    return places.where((place) {
      if (selectedZone != 'Semua Wilayah') {
        final city = (place['city'] as String? ?? '').toLowerCase();
        final addr = (place['address'] as String? ?? '').toLowerCase();
        final kw = _getZoneKeyword(selectedZone);
        if (!city.contains(kw) && !addr.contains(kw)) {
          return false;
        }
      }
      final query = searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final name = (place['name'] as String? ?? '').toLowerCase();
        final cat = (place['category'] as String? ?? '').toLowerCase();
        final addr = (place['address'] as String? ?? '').toLowerCase();
        if (!name.contains(query) &&
            !cat.contains(query) &&
            !addr.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  double get _averageRating {
    if (places.isEmpty) return 0;
    return places.fold<double>(
          0,
          (sum, place) => sum + ((place['rating'] as num?)?.toDouble() ?? 0),
        ) /
        places.length;
  }

  double get _averageBudget {
    if (places.isEmpty) return 0;
    return places.fold<double>(
          0,
          (sum, place) =>
              sum +
              ((place['avg_price'] as num?)?.toDouble() ??
                  ((place['min_price'] as num?)?.toDouble() ?? 0)),
        ) /
        places.length;
  }

  Future<void> loadPlaces() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/places?select=*&order=name.asc'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil katalog tempat.');
      }
      setState(
        () => places = (jsonDecode(response.body) as List<dynamic>)
            .cast<Map<String, dynamic>>(),
      );
      final results = await Future.wait([
        http.get(
          Uri.parse(
            '$supabaseUrl/rest/v1/categories?select=*&is_active=eq.true&order=sort_order,name',
          ),
          headers: headers,
        ),
        http.get(
          Uri.parse(
            '$supabaseUrl/rest/v1/preferences?select=*&is_active=eq.true&order=sort_order,name',
          ),
          headers: headers,
        ),
      ]);
      if (results[0].statusCode == 200) {
        categories = (jsonDecode(results[0].body) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
      if (results[1].statusCode == 200) {
        preferences = (jsonDecode(results[1].body) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> savePlace(Map<String, dynamic> place) async {
    final editableFields = <String, dynamic>{
      'name': place['name'],
      'address': place['address'],
      'city': place['city'],
      'description': place['description'],
      'image_url': place['image_url'],
      'open_hours': place['open_hours'],
      'min_price': place['min_price'],
      'max_price': place['max_price'],
      'avg_price': place['avg_price'],
      'category': place['category'],
      'facilities': place['facilities'],
      'menu_highlights': place['menu_highlights'] ?? const [],
      'latitude': place['latitude'],
      'longitude': place['longitude'],
    };
    final response = await http.patch(
      Uri.parse('$supabaseUrl/rest/v1/places?id=eq.${place['id']}'),
      headers: headers,
      body: jsonEncode({...place, 'override_fields': editableFields}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal menyimpan perubahan.');
    }
    final category = categories.where(
      (item) => item['name'] == place['category'],
    );
    if (category.isNotEmpty) {
      final categoryResponse = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/place_categories?on_conflict=place_id'),
        headers: {...headers, 'Prefer': 'resolution=merge-duplicates'},
        body: jsonEncode({
          'place_id': place['id'],
          'category_id': category.first['id'],
        }),
      );
      if (categoryResponse.statusCode < 200 ||
          categoryResponse.statusCode >= 300) {
        throw Exception('Gagal menyimpan kategori tempat.');
      }
    }
    final deletePreferences = await http.delete(
      Uri.parse(
        '$supabaseUrl/rest/v1/place_preferences?place_id=eq.${place['id']}',
      ),
      headers: headers,
    );
    if (deletePreferences.statusCode < 200 ||
        deletePreferences.statusCode >= 300) {
      throw Exception('Gagal memperbarui preferensi tempat.');
    }
    final selectedPreferences = preferences
        .where(
          (item) => (place['facilities'] as List<dynamic>? ?? const [])
              .contains(item['name']),
        )
        .map((item) => {'place_id': place['id'], 'preference_id': item['id']})
        .toList();
    if (selectedPreferences.isNotEmpty) {
      final preferenceResponse = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/place_preferences'),
        headers: headers,
        body: jsonEncode(selectedPreferences),
      );
      if (preferenceResponse.statusCode < 200 ||
          preferenceResponse.statusCode >= 300) {
        throw Exception('Gagal menyimpan preferensi tempat.');
      }
    }
    await loadPlaces();
  }

  Future<void> syncGoogle() async {
    final response = await http.post(
      Uri.parse('$supabaseUrl/functions/v1/sync-places'),
      headers: headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Sinkronisasi gagal (${response.statusCode}). Pastikan Edge Function sync-places sudah aktif.',
      );
    }

    await loadPlaces();
  }

  Future<void> manageLookupValues({
    required String table,
    required String title,
    required List<Map<String, dynamic>> values,
  }) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Kelola $title'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: values
                    .map(
                      (value) => InputChip(
                        label: Text('${value['name']}'),
                        onDeleted: () async {
                          await http.patch(
                            Uri.parse(
                              '$supabaseUrl/rest/v1/$table?id=eq.${value['id']}',
                            ),
                            headers: headers,
                            body: jsonEncode({'is_active': false}),
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          await loadPlaces();
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Tambah $title',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;
                      await http.post(
                        Uri.parse('$supabaseUrl/rest/v1/$table'),
                        headers: headers,
                        body: jsonEncode({'name': name}),
                      );
                      controller.clear();
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      await loadPlaces();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> addPlace(Map<String, dynamic> place) async {
    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/places'),
      headers: headers,
      body: jsonEncode(place),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gagal menambahkan tempat (${response.statusCode}): ${response.body}',
      );
    }
    await loadPlaces();
  }

  Future<void> deletePlace(Map<String, dynamic> place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus Tempat'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${place['name']}" dari katalog? '
          'Tindakan ini akan menghapus data dari sistem database Supabase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$supabaseUrl/rest/v1/places?id=eq.${place['id']}'),
        headers: headers,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Gagal menghapus tempat (${response.statusCode}).');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tempat "${place['name']}" berhasil dihapus.'),
          ),
        );
      }
      await loadPlaces();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> showStats() async {
    final response = await http.get(
      Uri.parse(
        '$supabaseUrl/rest/v1/analytics_events?select=event_name,created_at&limit=1000',
      ),
      headers: headers,
    );
    if (!mounted) return;
    final eventCount = response.statusCode == 200
        ? (jsonDecode(response.body) as List<dynamic>).length
        : 0;

    final avgRating = _averageRating;
    final avgBudget = _averageBudget;

    // Hitung sebaran tempat per 7 zona wilayah Purwokerto
    final zoneCounts = <String, int>{};
    for (final z in zones.where((z) => z != 'Semua Wilayah')) {
      final kw = _getZoneKeyword(z);
      final count = places.where((p) {
        final c = (p['city'] as String? ?? '').toLowerCase();
        final a = (p['address'] as String? ?? '').toLowerCase();
        return c.contains(kw) || a.contains(kw);
      }).length;
      zoneCounts[z] = count;
    }

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics_rounded, color: Color(0xffd99b25)),
            SizedBox(width: 10),
            Text('Statistik Kuliner Purwokerto (WADM-1)'),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Total Tempat',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${places.length}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text(
                              'Rating Rata-rata',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${avgRating.toStringAsFixed(1)} â˜…',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text(
                              'Rata-rata Budget',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${avgBudget.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffd99b25),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Distribusi Sebaran Tempat per 7 Zona Wilayah:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...zoneCounts.entries.map((e) {
                  final pct = places.isNotEmpty
                      ? (e.value / places.length * 100).toStringAsFixed(1)
                      : '0';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '${e.value} tempat ($pct%)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24),
                Text(
                  'Event analitik tercatat: $eventCount interaksi',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadPlaces();
    fetchUserCount();
  }

  Future<void> fetchUserCount() async {
    try {
      final r = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/admin_user_list?select=id'),
        headers: headers,
      );
      if (r.statusCode == 200 && mounted) {
        final list = jsonDecode(r.body) as List<dynamic>;
        setState(() => userCount = list.length);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navyBg = isDark ? const Color(0xFF0D1326) : const Color(0xFFF8FAFC);
    final navyCard = isDark ? const Color(0xFF162035) : Colors.white;
    final navySurface = isDark
        ? const Color(0xFF1A233A)
        : const Color(0xFFF1F5F9);
    final navyInput = isDark
        ? const Color(0xFF131B30)
        : const Color(0xFFF1F5F9);
    final navyBorder = isDark
        ? const Color(0xFF263353)
        : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF475569);
    final textMuted = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF94A3B8);
    const amberPrimary = Color(0xFFD99B25);

    return Scaffold(
      backgroundColor: navyBg,
      body: Row(
        children: [
          // 1. Sidebar Navigasi di Sebelah Kiri
          _buildSidebar(
            context,
            isDark,
            navyInput,
            navySurface,
            navyBorder,
            amberPrimary,
            textPrimary,
            textSecondary,
            textMuted,
          ),

          // 2. Area Konten Utama Dashboard di Kanan
          Expanded(
            child: Stack(
              children: [
                // Ornamen Mandala Kanan Atas
                Positioned(
                  top: 0,
                  right: 0,
                  width: 380,
                  height: 380,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: MandalaOrnamentPainter(
                        scale: 1.1,
                        isDark: isDark,
                        origin: OrnamentOrigin.topRight,
                      ),
                    ),
                  ),
                ),

                // Ornamen Mandala Kiri Bawah
                Positioned(
                  bottom: 0,
                  left: 0,
                  width: 340,
                  height: 340,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: MandalaOrnamentPainter(
                        scale: 0.95,
                        isDark: isDark,
                        origin: OrnamentOrigin.bottomLeft,
                      ),
                    ),
                  ),
                ),

                // Aksen Corak Bunga Batik Floating
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: FloatingBatikAccentPainter(isDark: isDark),
                    ),
                  ),
                ),

                // Konten Utama Dashboard
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : error != null
                        ? Center(child: Text(error!))
                        : _selectedNavIndex == 1
                        ? UserActivityPage(
                            token: widget.token,
                            supabaseUrl: supabaseUrl,
                            supabaseAnonKey: supabaseAnonKey,
                            onUserCountChanged: (count) {
                              if (mounted) {
                                setState(() => userCount = count);
                              }
                            },
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Bar Header Konten
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Katalog Tempat Kuliner',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: textPrimary,
                                              letterSpacing: -0.5,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Menampilkan ${filteredPlaces.length} dari ${places.length} data rekomendasi kuliner & wisata di Banyumas',
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  FilledButton.icon(
                                    onPressed: () async {
                                      final newPlace = await showAddPlaceDialog(
                                        context,
                                        categories: categories,
                                        preferences: preferences,
                                      );
                                      if (newPlace != null) {
                                        try {
                                          await addPlace(newPlace);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Tempat baru berhasil ditambahkan ke Supabase!',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('$e'),
                                                backgroundColor:
                                                    Colors.redAccent,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: amberPrimary,
                                      foregroundColor: navyBg,
                                      elevation: 2,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Tambah Tempat Baru (WADM-3)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Filter Bar
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: searchController,
                                      style: TextStyle(color: textPrimary),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Cari tempat berdasarkan nama, kategori, atau alamat (WADM-2)...',
                                        hintStyle: TextStyle(color: textMuted),
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          color: amberPrimary,
                                        ),
                                        suffixIcon:
                                            searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: Icon(
                                                  Icons.clear,
                                                  color: textSecondary,
                                                ),
                                                onPressed: () => setState(
                                                  () =>
                                                      searchController.clear(),
                                                ),
                                              )
                                            : null,
                                        filled: true,
                                        fillColor: navyInput,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: navyBorder,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: navyBorder,
                                          ),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(10),
                                          ),
                                          borderSide: BorderSide(
                                            color: amberPrimary,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: selectedZone,
                                      dropdownColor: navyCard,
                                      style: TextStyle(color: textPrimary),
                                      decoration: InputDecoration(
                                        labelText:
                                            'Filter 7 Zona Wilayah (WADM-2)',
                                        labelStyle: TextStyle(
                                          color: textSecondary,
                                        ),
                                        filled: true,
                                        fillColor: navyInput,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: navyBorder,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: navyBorder,
                                          ),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(10),
                                          ),
                                          borderSide: BorderSide(
                                            color: amberPrimary,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                      ),
                                      items: zones
                                          .map(
                                            (z) => DropdownMenuItem(
                                              value: z,
                                              child: Text(
                                                z,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) => setState(
                                        () => selectedZone =
                                            val ?? 'Semua Wilayah',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Card List Tempat
                              Expanded(
                                child: filteredPlaces.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.search_off_rounded,
                                              size: 52,
                                              color: textMuted,
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              'Tidak ada tempat kuliner yang sesuai',
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Coba sesuaikan kata kunci pencarian atau ubah filter zona wilayah.',
                                              style: TextStyle(
                                                color: textMuted,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: filteredPlaces.length,
                                        separatorBuilder: (_, index) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          final place = filteredPlaces[index];
                                          final imageUrl =
                                              (place['image_url'] as String? ??
                                                      '')
                                                  .trim();
                                          final category =
                                              place['category'] as String? ??
                                              'Cafe';
                                          final city =
                                              place['city'] as String? ??
                                              'Purwokerto';
                                          final rating =
                                              place['rating']?.toString() ??
                                              '4.5';
                                          final minP =
                                              place['min_price']?.toString() ??
                                              '0';
                                          final maxP =
                                              place['max_price']?.toString() ??
                                              '0';
                                          final hours =
                                              place['open_hours'] as String? ??
                                              '';
                                          final menuCount =
                                              parseMenuHighlights(
                                                place['menu_highlights'],
                                              ).length;

                                          return Container(
                                            decoration: BoxDecoration(
                                              color: navyCard,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: navyBorder,
                                                width: 1.2,
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(14),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                // Thumbnail Image
                                                Container(
                                                  width: 76,
                                                  height: 76,
                                                  decoration: BoxDecoration(
                                                    color: navyInput,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color: navyBorder,
                                                    ),
                                                  ),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: imageUrl.isNotEmpty
                                                      ? buildSmartImage(
                                                          imageUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (
                                                                context,
                                                                error,
                                                                stackTrace,
                                                              ) => Center(
                                                                child: Icon(
                                                                  category ==
                                                                          'Warkop'
                                                                      ? Icons
                                                                            .coffee_rounded
                                                                      : category ==
                                                                            'Restoran'
                                                                      ? Icons
                                                                            .restaurant_rounded
                                                                      : Icons
                                                                            .local_cafe_rounded,
                                                                  color:
                                                                      amberPrimary,
                                                                  size: 30,
                                                                ),
                                                              ),
                                                        )
                                                      : Center(
                                                          child: Icon(
                                                            category == 'Warkop'
                                                                ? Icons
                                                                      .coffee_rounded
                                                                : category ==
                                                                      'Restoran'
                                                                ? Icons
                                                                      .restaurant_rounded
                                                                : Icons
                                                                      .local_cafe_rounded,
                                                            color: amberPrimary,
                                                            size: 30,
                                                          ),
                                                        ),
                                                ),
                                                const SizedBox(width: 16),

                                                // Information details
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      // Top row: Name + Category Pill + Zone Pill
                                                      Row(
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              '${place['name'] ?? '-'}',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color:
                                                                    textPrimary,
                                                                letterSpacing:
                                                                    0.2,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 3,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: amberPrimary
                                                                  .withValues(
                                                                    alpha:
                                                                        isDark
                                                                        ? 0.15
                                                                        : 0.12,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6,
                                                                  ),
                                                              border: Border.all(
                                                                color: amberPrimary
                                                                    .withValues(
                                                                      alpha:
                                                                          isDark
                                                                          ? 0.35
                                                                          : 0.45,
                                                                    ),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              category,
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: isDark
                                                                    ? amberPrimary
                                                                    : const Color(
                                                                        0xFFB45309,
                                                                      ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 3,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: isDark
                                                                  ? const Color(
                                                                      0xFF1E2E4E,
                                                                    )
                                                                  : const Color(
                                                                      0xFFE0F2FE,
                                                                    ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6,
                                                                  ),
                                                              border: Border.all(
                                                                color: isDark
                                                                    ? const Color(
                                                                        0xFF2C4372,
                                                                      )
                                                                    : const Color(
                                                                        0xFFBAE6FD,
                                                                      ),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              city,
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: isDark
                                                                    ? const Color(
                                                                        0xFF90CDF4,
                                                                      )
                                                                    : const Color(
                                                                        0xFF0284C7,
                                                                      ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),

                                                      // Address row
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .location_on_outlined,
                                                            size: 14,
                                                            color: textMuted,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              '${place['address'] ?? '-'}',
                                                              style: TextStyle(
                                                                fontSize: 12.5,
                                                                color:
                                                                    textSecondary,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),

                                                      // Meta row: Budget, Rating, Open Hours
                                                      Wrap(
                                                        spacing: 12,
                                                        runSpacing: 4,
                                                        crossAxisAlignment:
                                                            WrapCrossAlignment
                                                                .center,
                                                        children: [
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .payments_outlined,
                                                                size: 14,
                                                                color: Color(
                                                                  0xFF34D399,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                'Rp $minP - Rp $maxP',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Color(
                                                                    0xFF34D399,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .star_rounded,
                                                                size: 16,
                                                                color: Color(
                                                                  0xFFFBBF24,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 2,
                                                              ),
                                                              Text(
                                                                '$rating â˜…',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color: Color(
                                                                    0xFFFBBF24,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          if (hours.isNotEmpty)
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .access_time_rounded,
                                                                  size: 13,
                                                                  color:
                                                                      textMuted,
                                                                ),
                                                                const SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Text(
                                                                  hours,
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        textSecondary,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .restaurant_menu_rounded,
                                                                size: 13,
                                                                color: menuCount > 0
                                                                    ? const Color(
                                                                        0xFFD99B25,
                                                                      )
                                                                    : textMuted,
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                '$menuCount Menu',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      menuCount >
                                                                          0
                                                                      ? FontWeight
                                                                            .w600
                                                                      : FontWeight
                                                                            .normal,
                                                                  color:
                                                                      menuCount >
                                                                          0
                                                                      ? const Color(
                                                                          0xFFD99B25,
                                                                        )
                                                                      : textMuted,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 16),

                                                // Action Buttons
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    FilledButton.tonalIcon(
                                                      style: FilledButton.styleFrom(
                                                        backgroundColor: isDark
                                                            ? const Color(
                                                                0xFF1E2D4A,
                                                              )
                                                            : const Color(
                                                                0xFFF1F5F9,
                                                              ),
                                                        foregroundColor:
                                                            textPrimary,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 14,
                                                              vertical: 10,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          side: BorderSide(
                                                            color: isDark
                                                                ? const Color(
                                                                    0xFF2F4470,
                                                                  )
                                                                : const Color(
                                                                    0xFFCBD5E1,
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        final edited =
                                                            await showPlaceEditor(
                                                              context,
                                                              place,
                                                              categories:
                                                                  categories,
                                                              preferences:
                                                                  preferences,
                                                            );
                                                        if (edited == null) {
                                                          return;
                                                        }
                                                        try {
                                                          await savePlace(
                                                            edited,
                                                          );
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Tempat "${edited['name']}" berhasil diperbarui.',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        } catch (e) {
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  '$e',
                                                                ),
                                                                backgroundColor:
                                                                    Colors
                                                                        .redAccent,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                      icon: const Icon(
                                                        Icons.edit_rounded,
                                                        size: 16,
                                                        color: amberPrimary,
                                                      ),
                                                      label: const Text(
                                                        'Edit',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons
                                                            .delete_outline_rounded,
                                                        color: Colors.redAccent,
                                                        size: 20,
                                                      ),
                                                      tooltip:
                                                          'Hapus Tempat (WADM-5)',
                                                      onPressed: () =>
                                                          deletePlace(place),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    bool isDark,
    Color navyInput,
    Color navySurface,
    Color navyBorder,
    Color amberPrimary,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    return Container(
      width: 265,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(right: BorderSide(color: navyBorder, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Logo & App Title di Header Sidebar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: navySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: amberPrimary, width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: amberPrimary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Transform.scale(
                      scale: 1.35,
                      alignment: const Alignment(0, -0.04),
                      child: Image.asset(
                        'assets/images/app_icon.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.travel_explore_rounded,
                          size: 22,
                          color: amberPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MAMPIR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: amberPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ADMIN DASHBOARD',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: amberPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Online Supabase
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF131D33)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: navyBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Supabase Online',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2A44)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${places.length} Tempat â€¢ $userCount Akun',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: navyBorder),

          // 2. Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              children: [
                _buildSidebarSectionTitle('NAVIGASI UTAMA', textMuted),
                _buildSidebarItem(
                  icon: Icons.storefront_rounded,
                  label: 'Katalog Tempat',
                  isActive: _selectedNavIndex == 0,
                  onTap: () {
                    setState(() => _selectedNavIndex = 0);
                  },
                  isDark: isDark,
                  amberPrimary: amberPrimary,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (_selectedNavIndex == 0 ? amberPrimary : textMuted)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${filteredPlaces.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _selectedNavIndex == 0
                            ? amberPrimary
                            : textMuted,
                      ),
                    ),
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.manage_accounts_rounded,
                  label: 'Aktivitas & Akun',
                  isActive: _selectedNavIndex == 1,
                  onTap: () {
                    setState(() => _selectedNavIndex = 1);
                    fetchUserCount();
                  },
                  isDark: isDark,
                  amberPrimary: amberPrimary,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (_selectedNavIndex == 1 ? amberPrimary : textMuted)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$userCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _selectedNavIndex == 1
                            ? amberPrimary
                            : textMuted,
                      ),
                    ),
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.analytics_rounded,
                  label: 'Statistik Kuliner (WADM-1)',
                  onTap: showStats,
                  isDark: isDark,
                  amberPrimary: amberPrimary,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 14),
                _buildSidebarSectionTitle('MANAJEMEN DATA', textMuted),
                _buildSidebarItem(
                  icon: Icons.category_rounded,
                  label: 'Kelola Kategori',
                  onTap: () => manageLookupValues(
                    table: 'categories',
                    title: 'kategori',
                    values: categories,
                  ),
                  isDark: isDark,
                  amberPrimary: amberPrimary,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _buildSidebarItem(
                  icon: Icons.tune_rounded,
                  label: 'Preferensi & Fasilitas',
                  onTap: () => manageLookupValues(
                    table: 'preferences',
                    title: 'preferensi/fasilitas',
                    values: preferences,
                  ),
                  isDark: isDark,
                  amberPrimary: amberPrimary,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 14),
                _buildSidebarSectionTitle('AKSI & SINKRONISASI', textMuted),
                _buildSidebarItem(
                  icon: Icons.cloud_sync_rounded,
                  label: 'Sinkron Google API',
                  onTap: () async {
                    try {
                      await syncGoogle();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  isDark: isDark,
                  amberPrimary: amberPrimary,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _buildSidebarItem(
                  icon: Icons.refresh_rounded,
                  label: 'Muat Ulang Data',
                  onTap: () {
                    loadPlaces();
                    fetchUserCount();
                  },
                  isDark: isDark,
                  amberPrimary: amberPrimary,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 14),
                _buildSidebarSectionTitle('TEMA TAMPILAN', textMuted),
                const AdminThemeToggleWidget(),
              ],
            ),
          ),

          // 3. User Profile & Logout
          Divider(height: 1, color: navyBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile pill
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF131D33)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: navyBorder),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: amberPrimary.withValues(alpha: 0.25),
                        child: Text(
                          'AD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: amberPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administrator',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'admin@mampir.id',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _handleLogout(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Keluar Sesi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionTitle(String title, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color amberPrimary,
    required Color textPrimary,
    required Color textSecondary,
    bool isActive = false,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive
            ? amberPrimary.withValues(alpha: isDark ? 0.15 : 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(
                color: amberPrimary.withValues(alpha: isDark ? 0.35 : 0.45),
              )
            : null,
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          icon,
          size: 20,
          color: isActive ? amberPrimary : textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            color: isActive
                ? (isDark ? Colors.white : const Color(0xFFB45309))
                : textSecondary,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sesi Admin MAMPIR?',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      Navigator.of(this.context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      );
    }
  }
}

