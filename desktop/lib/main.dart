import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://vdqdithxujxvzyybjtpn.supabase.co',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkcWRpdGh4dWp4dnp5eWJqdHBuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMyMzA2NTIsImV4cCI6MjEwODgwNjY1Mn0.7zE0gLxh0a2DNzdVcRfTj3EZDaqXWZ09kL5gcXTETXY',
);

void main() => runApp(const AdminApp());

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MAMPIR Admin',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffd99b25),
        brightness: Brightness.dark,
        surface: const Color(0xFF162035),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1326),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF162035),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF263353), width: 1.5),
        ),
        elevation: 16,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF131B30),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF263353)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF263353)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFFD99B25), width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF131B30),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF162035),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF263353), width: 1),
        ),
      ),
      useMaterial3: true,
    ),
    home: const AdminLoginPage(),
  );
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
          '© 2026 Tim Proyek PML MAMPIR',
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
            hintText: '••••••••',
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
          '© 2026 Tim Proyek PML MAMPIR',
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
                              '${avgRating.toStringAsFixed(1)} ★',
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
  }

  @override
  Widget build(BuildContext context) {
    const navyBg = Color(0xFF0D1326);
    const navyCard = Color(0xFF162035);
    const navySurface = Color(0xFF1A233A);
    const navyInput = Color(0xFF131B30);
    const navyBorder = Color(0xFF263353);
    const amberPrimary = Color(0xFFD99B25);

    return Scaffold(
      backgroundColor: navyBg,
      body: Row(
        children: [
          // 1. Sidebar Navigasi di Sebelah Kiri
          _buildSidebar(context, navyInput, navySurface, navyBorder, amberPrimary),

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
                        isDark: true,
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
                        isDark: true,
                        origin: OrnamentOrigin.bottomLeft,
                      ),
                    ),
                  ),
                ),

                // Aksen Corak Bunga Batik Floating
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: FloatingBatikAccentPainter(isDark: true),
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
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Bar Header Konten
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Katalog Tempat Kuliner',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: -0.5,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Menampilkan ${filteredPlaces.length} dari ${places.length} data rekomendasi kuliner & wisata di Banyumas',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.65),
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
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Tempat baru berhasil ditambahkan ke Supabase!',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('$e'),
                                                backgroundColor: Colors.redAccent,
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
                                    icon: const Icon(Icons.add_rounded, size: 20),
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
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Cari tempat berdasarkan nama, kategori, atau alamat (WADM-2)...',
                                        hintStyle: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.35),
                                        ),
                                        prefixIcon: const Icon(Icons.search, color: amberPrimary),
                                        suffixIcon: searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear, color: Colors.white70),
                                                onPressed: () =>
                                                    setState(() => searchController.clear()),
                                              )
                                            : null,
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
                                        contentPadding: const EdgeInsets.symmetric(
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
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Filter 7 Zona Wilayah (WADM-2)',
                                        labelStyle: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
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
                                        contentPadding: const EdgeInsets.symmetric(
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
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) => setState(
                                        () => selectedZone = val ?? 'Semua Wilayah',
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
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.search_off_rounded,
                                              size: 52,
                                              color: Colors.white30,
                                            ),
                                            const SizedBox(height: 14),
                                            const Text(
                                              'Tidak ada tempat kuliner yang sesuai',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Coba sesuaikan kata kunci pencarian atau ubah filter zona wilayah.',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.45),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: filteredPlaces.length,
                                        separatorBuilder: (_, index) => const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          final place = filteredPlaces[index];
                                          final imageUrl = (place['image_url'] as String? ?? '').trim();
                                          final category = place['category'] as String? ?? 'Cafe';
                                          final city = place['city'] as String? ?? 'Purwokerto';
                                          final rating = place['rating']?.toString() ?? '4.5';
                                          final minP = place['min_price']?.toString() ?? '0';
                                          final maxP = place['max_price']?.toString() ?? '0';
                                          final hours = place['open_hours'] as String? ?? '';

                                          return Container(
                                            decoration: BoxDecoration(
                                              color: navyCard,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: navyBorder, width: 1.2),
                                            ),
                                            padding: const EdgeInsets.all(14),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                // Thumbnail Image
                                                Container(
                                                  width: 76,
                                                  height: 76,
                                                  decoration: BoxDecoration(
                                                    color: navyInput,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: navyBorder),
                                                  ),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: imageUrl.isNotEmpty
                                                      ? Image.network(
                                                          imageUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) => Center(
                                                            child: Icon(
                                                              category == 'Warkop'
                                                                  ? Icons.coffee_rounded
                                                                  : category == 'Restoran'
                                                                      ? Icons.restaurant_rounded
                                                                      : Icons.local_cafe_rounded,
                                                              color: amberPrimary,
                                                              size: 30,
                                                            ),
                                                          ),
                                                        )
                                                      : Center(
                                                          child: Icon(
                                                            category == 'Warkop'
                                                                ? Icons.coffee_rounded
                                                                : category == 'Restoran'
                                                                    ? Icons.restaurant_rounded
                                                                    : Icons.local_cafe_rounded,
                                                            color: amberPrimary,
                                                            size: 30,
                                                          ),
                                                        ),
                                                ),
                                                const SizedBox(width: 16),

                                                // Information details
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      // Top row: Name + Category Pill + Zone Pill
                                                      Row(
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              '${place['name'] ?? '-'}',
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.w800,
                                                                color: Colors.white,
                                                                letterSpacing: 0.2,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 3,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: amberPrimary.withValues(alpha: 0.15),
                                                              borderRadius: BorderRadius.circular(6),
                                                              border: Border.all(
                                                                color: amberPrimary.withValues(alpha: 0.35),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              category,
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w700,
                                                                color: amberPrimary,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 3,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFF1E2E4E),
                                                              borderRadius: BorderRadius.circular(6),
                                                              border: Border.all(color: const Color(0xFF2C4372)),
                                                            ),
                                                            child: Text(
                                                              city,
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w600,
                                                                color: Color(0xFF90CDF4),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),

                                                      // Address row
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.location_on_outlined,
                                                            size: 14,
                                                            color: Colors.white54,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Expanded(
                                                            child: Text(
                                                              '${place['address'] ?? '-'}',
                                                              style: TextStyle(
                                                                fontSize: 12.5,
                                                                color: Colors.white.withValues(alpha: 0.7),
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),

                                                      // Meta row: Budget, Rating, Open Hours
                                                      Wrap(
                                                        spacing: 12,
                                                        runSpacing: 4,
                                                        crossAxisAlignment: WrapCrossAlignment.center,
                                                        children: [
                                                          Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              const Icon(
                                                                Icons.payments_outlined,
                                                                size: 14,
                                                                color: Color(0xFF34D399),
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                'Rp $minP - Rp $maxP',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Color(0xFF34D399),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              const Icon(
                                                                Icons.star_rounded,
                                                                size: 16,
                                                                color: Color(0xFFFBBF24),
                                                              ),
                                                              const SizedBox(width: 2),
                                                              Text(
                                                                '$rating ★',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w700,
                                                                  color: Color(0xFFFBBF24),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          if (hours.isNotEmpty)
                                                            Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                const Icon(
                                                                  Icons.access_time_rounded,
                                                                  size: 13,
                                                                  color: Colors.white54,
                                                                ),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  hours,
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    color: Colors.white.withValues(alpha: 0.6),
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
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    FilledButton.tonalIcon(
                                                      style: FilledButton.styleFrom(
                                                        backgroundColor: const Color(0xFF1E2D4A),
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 10,
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                          side: const BorderSide(color: Color(0xFF2F4470)),
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        final edited = await showPlaceEditor(
                                                          context,
                                                          place,
                                                          categories: categories,
                                                          preferences: preferences,
                                                        );
                                                        if (edited == null) return;
                                                        try {
                                                          await savePlace(edited);
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Tempat "${edited['name']}" berhasil diperbarui.',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        } catch (e) {
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text('$e'),
                                                                backgroundColor: Colors.redAccent,
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
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete_outline_rounded,
                                                        color: Colors.redAccent,
                                                        size: 20,
                                                      ),
                                                      tooltip: 'Hapus Tempat (WADM-5)',
                                                      onPressed: () => deletePlace(place),
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
    Color navyInput,
    Color navySurface,
    Color navyBorder,
    Color amberPrimary,
  ) {
    return Container(
      width: 265,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          right: BorderSide(color: Color(0xFF1E293B), width: 1.5),
        ),
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
                    const Text(
                      'MAMPIR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                color: const Color(0xFF131D33),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E2C48)),
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
                  const Text(
                    'Supabase Online',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2A44),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${places.length} Data',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFF1E293B)),

          // 2. Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              children: [
                _buildSidebarSectionTitle('NAVIGASI UTAMA'),
                _buildSidebarItem(
                  icon: Icons.storefront_rounded,
                  label: 'Katalog Tempat',
                  isActive: true,
                  onTap: () {},
                  amberPrimary: amberPrimary,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: amberPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${filteredPlaces.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: amberPrimary,
                      ),
                    ),
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.analytics_rounded,
                  label: 'Statistik Kuliner (WADM-1)',
                  onTap: showStats,
                  amberPrimary: amberPrimary,
                ),
                const SizedBox(height: 14),
                _buildSidebarSectionTitle('MANAJEMEN DATA'),
                _buildSidebarItem(
                  icon: Icons.category_rounded,
                  label: 'Kelola Kategori',
                  onTap: () => manageLookupValues(
                    table: 'categories',
                    title: 'kategori',
                    values: categories,
                  ),
                  amberPrimary: amberPrimary,
                ),
                _buildSidebarItem(
                  icon: Icons.tune_rounded,
                  label: 'Preferensi & Fasilitas',
                  onTap: () => manageLookupValues(
                    table: 'preferences',
                    title: 'preferensi/fasilitas',
                    values: preferences,
                  ),
                  amberPrimary: amberPrimary,
                ),
                const SizedBox(height: 14),
                _buildSidebarSectionTitle('AKSI & SINKRONISASI'),
                _buildSidebarItem(
                  icon: Icons.cloud_sync_rounded,
                  label: 'Sinkron Google API',
                  onTap: () async {
                    try {
                      await syncGoogle();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      }
                    }
                  },
                  amberPrimary: amberPrimary,
                ),
                _buildSidebarItem(
                  icon: Icons.refresh_rounded,
                  label: 'Muat Ulang Data',
                  onTap: loadPlaces,
                  amberPrimary: amberPrimary,
                ),
              ],
            ),
          ),

          // 3. User Profile & Logout
          const Divider(height: 1, color: Color(0xFF1E293B)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile pill
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131D33),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E2C48)),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administrator',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'admin@mampir.id',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.white54,
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
                        Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
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

  Widget _buildSidebarSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white.withValues(alpha: 0.35),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color amberPrimary,
    bool isActive = false,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? amberPrimary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(color: amberPrimary.withValues(alpha: 0.35))
            : null,
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          icon,
          size: 20,
          color: isActive ? amberPrimary : Colors.white70,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            color: isActive ? Colors.white : Colors.white70,
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
        content: const Text('Apakah Anda yakin ingin keluar dari sesi Admin MAMPIR?'),
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

Widget _buildDialogSectionHeader(String title, IconData icon, Color amberPrimary) {
  return Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 16, color: amberPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: amberPrimary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Divider(color: Color(0xFF263353), height: 1),
        ),
      ],
    ),
  );
}

Widget _buildDialogCard(Widget child, Color navyInput, Color navyBorder) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: navyInput.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: navyBorder, width: 1.2),
    ),
    child: child,
  );
}

Future<Map<String, dynamic>?> showPlaceEditor(
  BuildContext context,
  Map<String, dynamic> source, {
  required List<Map<String, dynamic>> categories,
  required List<Map<String, dynamic>> preferences,
}) {
  final name = TextEditingController(text: '${source['name'] ?? ''}');
  final description = TextEditingController(
    text: '${source['description'] ?? ''}',
  );
  final address = TextEditingController(text: '${source['address'] ?? ''}');
  final image = TextEditingController(text: '${source['image_url'] ?? ''}');
  final openHours = TextEditingController(
    text: '${source['open_hours'] ?? ''}',
  );
  final minPrice = TextEditingController(text: '${source['min_price'] ?? 0}');
  final maxPrice = TextEditingController(text: '${source['max_price'] ?? 0}');
  final latitude = TextEditingController(text: '${source['latitude'] ?? ''}');
  final longitude = TextEditingController(text: '${source['longitude'] ?? ''}');

  const availableZones = [
    'Purwokerto Kota',
    'Baturraden',
    'Purwokerto Utara (Unsoed)',
    'Sokaraja',
    'Purwokerto Timur & Sumbang',
    'Purwokerto Barat & Selatan',
  ];

  var selectedCategory = '${source['category'] ?? (categories.firstOrNull?['name'] ?? 'Cafe')}';
  var selectedCity = '${source['city'] ?? 'Purwokerto Kota'}';
  if (!availableZones.contains(selectedCity)) {
    selectedCity = availableZones.first;
  }

  // Preferensi / Fasilitas
  final initialFacilities = ((source['facilities'] as List<dynamic>?) ?? const [])
      .map((e) => e.toString().trim())
      .where((e) => e.isNotEmpty)
      .toSet();
  final Set<String> selectedFacilities = Set.from(initialFacilities);
  final standardPrefNames = preferences.map((p) => p['name']?.toString() ?? '').toSet();
  final customList = initialFacilities.where((f) => !standardPrefNames.contains(f)).toList();
  final customFacilities = TextEditingController(text: customList.join(', '));

  const amberPrimary = Color(0xFFD99B25);
  const navyCard = Color(0xFF162035);
  const navyBorder = Color(0xFF263353);
  const navyInput = Color(0xFF131B30);

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final currentCategory = categories.any((item) => item['name'] == selectedCategory)
            ? selectedCategory
            : (categories.firstOrNull?['name']?.toString());

        return AlertDialog(
          backgroundColor: navyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: navyBorder, width: 1.5),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: amberPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: amberPrimary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.edit_location_alt_rounded,
                  color: amberPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Tempat Kuliner',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Perbarui rincian informasi tempat, koordinat peta & fasilitas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(dialogCtx),
              ),
            ],
          ),
          content: SizedBox(
            width: 780,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(dialogCtx).height * 0.82,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: INFORMASI UTAMA & KATEGORI
                    _buildDialogSectionHeader('INFORMASI UTAMA & KATEGORI', Icons.storefront_rounded, amberPrimary),
                    _buildDialogCard(
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: name,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Tempat Kuliner *',
                                    hintText: 'Contoh: Cafe & Resto Banyumas',
                                    prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  initialValue: currentCategory,
                                  dropdownColor: navyCard,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Kategori Tempat *',
                                    prefixIcon: Icon(Icons.category_rounded, size: 20),
                                  ),
                                  items: categories
                                      .map(
                                        (item) => DropdownMenuItem<String>(
                                          value: '${item['name']}',
                                          child: Text('${item['name']}'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setModalState(
                                    () => selectedCategory = value ?? selectedCategory,
                                  ),
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
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Zona Wilayah Banyumas *',
                                    prefixIcon: Icon(Icons.map_rounded, size: 20),
                                  ),
                                  items: availableZones
                                      .map(
                                        (z) => DropdownMenuItem(
                                          value: z,
                                          child: Text(z, overflow: TextOverflow.ellipsis),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) => setModalState(
                                    () => selectedCity = val ?? selectedCity,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: openHours,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Jam Operasional',
                                    hintText: '09.00 - 22.00 WIB',
                                    prefixIcon: Icon(Icons.access_time_rounded, size: 20),
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

                    // SECTION 2: LOKASI & KOORDINAT GPS
                    _buildDialogSectionHeader('LOKASI & KOORDINAT GPS', Icons.location_on_outlined, amberPrimary),
                    _buildDialogCard(
                      Column(
                        children: [
                          TextField(
                            controller: address,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Alamat Lengkap Tempat *',
                              hintText: 'Jl. Jend. Sudirman No. 10, Purwokerto',
                              prefixIcon: Icon(Icons.place_rounded, size: 20),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: latitude,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Latitude GPS (-7.6 s/d -7.2)',
                                    hintText: 'Contoh: -7.4246',
                                    prefixIcon: Icon(Icons.my_location_rounded, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: longitude,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Longitude GPS (109.0 s/d 109.5)',
                                    hintText: 'Contoh: 109.2315',
                                    prefixIcon: Icon(Icons.explore_rounded, size: 20),
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

                    // SECTION 3: BUDGET & PREFERENSI FASILITAS
                    _buildDialogSectionHeader('RENTANG BUDGET & FASILITAS', Icons.payments_outlined, amberPrimary),
                    _buildDialogCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: minPrice,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Budget Minimum (Rp)',
                                    hintText: 'Contoh: 15000',
                                    prefixIcon: Icon(Icons.payments_outlined, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: maxPrice,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Budget Maksimum (Rp)',
                                    hintText: 'Contoh: 50000',
                                    prefixIcon: Icon(Icons.payments_rounded, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Pilih Fasilitas & Preferensi (Klik untuk aktifkan):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: preferences.map((pref) {
                              final pName = '${pref['name']}';
                              final isSelected = selectedFacilities.contains(pName);
                              return FilterChip(
                                label: Text(
                                  pName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                ),
                                selected: isSelected,
                                backgroundColor: navyInput,
                                selectedColor: amberPrimary.withValues(alpha: 0.25),
                                checkmarkColor: amberPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected ? amberPrimary : navyBorder,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                onSelected: (sel) {
                                  setModalState(() {
                                    if (sel) {
                                      selectedFacilities.add(pName);
                                    } else {
                                      selectedFacilities.remove(pName);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: customFacilities,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Fasilitas Tambahan Lainnya (Opsional)',
                              hintText: 'Contoh: Photobooth, Musholla (pisahkan koma)',
                              prefixIcon: Icon(Icons.playlist_add_rounded, size: 20),
                            ),
                          ),
                        ],
                      ),
                      navyInput,
                      navyBorder,
                    ),

                    // SECTION 4: MEDIA BANNER & DESKRIPSI
                    _buildDialogSectionHeader('MEDIA BANNER & DESKRIPSI', Icons.image_outlined, amberPrimary),
                    _buildDialogCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: image,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'URL Gambar Banner Tempat',
                              hintText: 'https://images.unsplash.com/...',
                              prefixIcon: Icon(Icons.link_rounded, size: 20),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                          const SizedBox(height: 12),
                          // Live Image Banner Preview
                          Container(
                            height: 135,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: navyInput,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: navyBorder),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: image.text.trim().isNotEmpty
                                ? Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Image.network(
                                          image.text.trim(),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.broken_image_rounded, color: Colors.white38),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Pratinjau gambar gagal dimuat (URL tidak valid)',
                                                  style: TextStyle(color: Colors.white38, fontSize: 12),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.65),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.visibility_rounded, size: 12, color: amberPrimary),
                                              SizedBox(width: 4),
                                              Text(
                                                'Pratinjau Banner',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
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
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: Colors.white.withValues(alpha: 0.3),
                                          size: 28,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Masukkan URL gambar di atas untuk melihat pratinjau banner',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.4),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: description,
                            maxLines: 3,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Deskripsi Singkat Tempat',
                              hintText: 'Deskripsikan daya tarik, suasana, atau menu unggulan tempat...',
                              prefixIcon: Icon(Icons.description_outlined, size: 20),
                            ),
                          ),
                        ],
                      ),
                      navyInput,
                      navyBorder,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: navyBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal', style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: amberPrimary,
                foregroundColor: const Color(0xFF0D1326),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                final n = name.text.trim();
                final addr = address.text.trim();
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

                final customExtras = customFacilities.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty);
                final combinedFacilities = {...selectedFacilities, ...customExtras}.toList();

                final min = int.tryParse(minPrice.text) ?? (source['min_price'] ?? 0);
                final max = int.tryParse(maxPrice.text) ?? (source['max_price'] ?? 0);

                Navigator.pop(dialogCtx, {
                  ...source,
                  'name': n,
                  'address': addr,
                  'city': selectedCity,
                  'description': description.text.trim(),
                  'image_url': image.text.trim(),
                  'open_hours': openHours.text.trim(),
                  'category': selectedCategory,
                  'facilities': combinedFacilities,
                  'latitude': double.tryParse(latitude.text) ?? source['latitude'],
                  'longitude': double.tryParse(longitude.text) ?? source['longitude'],
                  'min_price': min,
                  'max_price': max,
                  'avg_price': (min + max) ~/ 2,
                });
              },
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text(
                'Simpan Perubahan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ),
  );
}

Future<Map<String, dynamic>?> showAddPlaceDialog(
  BuildContext context, {
  required List<Map<String, dynamic>> categories,
  required List<Map<String, dynamic>> preferences,
}) {
  final name = TextEditingController();
  final address = TextEditingController();
  final description = TextEditingController();
  final image = TextEditingController(
    text:
        'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80',
  );
  final openHours = TextEditingController(text: '09.00 - 22.00 WIB');
  final minPrice = TextEditingController(text: '15000');
  final maxPrice = TextEditingController(text: '40000');
  final latitude = TextEditingController(text: '-7.4244');
  final longitude = TextEditingController(text: '109.2302');
  final customFacilities = TextEditingController();

  var selectedCategory = categories.firstOrNull?['name']?.toString() ?? 'Cafe';
  var selectedCity = 'Purwokerto Kota';

  const availableZones = [
    'Purwokerto Kota',
    'Baturraden',
    'Purwokerto Utara (Unsoed)',
    'Sokaraja',
    'Purwokerto Timur & Sumbang',
    'Purwokerto Barat & Selatan',
  ];

  final Set<String> selectedFacilities = {'WiFi', 'Colokan', 'Parkir'};

  const amberPrimary = Color(0xFFD99B25);
  const navyCard = Color(0xFF162035);
  const navyBorder = Color(0xFF263353);
  const navyInput = Color(0xFF131B30);

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final currentCategory = categories.any((item) => item['name'] == selectedCategory)
            ? selectedCategory
            : (categories.firstOrNull?['name']?.toString() ?? 'Cafe');

        return AlertDialog(
          backgroundColor: navyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: navyBorder, width: 1.5),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: amberPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: amberPrimary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.add_location_alt_rounded,
                  color: amberPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tambah Tempat Baru (WADM-3)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Daftarkan tempat kuliner atau wisata baru ke database Supabase',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(dialogCtx),
              ),
            ],
          ),
          content: SizedBox(
            width: 780,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(dialogCtx).height * 0.82,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: INFORMASI UTAMA & KATEGORI
                    _buildDialogSectionHeader('INFORMASI UTAMA & KATEGORI', Icons.storefront_rounded, amberPrimary),
                    _buildDialogCard(
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: name,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Tempat Kuliner *',
                                    hintText: 'Contoh: Kopi Roemah Baturraden',
                                    prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  initialValue: currentCategory,
                                  dropdownColor: navyCard,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Kategori Tempat *',
                                    prefixIcon: Icon(Icons.category_rounded, size: 20),
                                  ),
                                  items: (categories.isNotEmpty
                                          ? categories
                                          : [
                                              {'name': 'Cafe'},
                                              {'name': 'Warkop'},
                                              {'name': 'Restoran'},
                                            ])
                                      .map(
                                        (item) => DropdownMenuItem<String>(
                                          value: '${item['name']}',
                                          child: Text('${item['name']}'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) => setModalState(
                                    () => selectedCategory = val ?? selectedCategory,
                                  ),
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
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Zona Wilayah Banyumas *',
                                    prefixIcon: Icon(Icons.map_rounded, size: 20),
                                  ),
                                  items: availableZones
                                      .map(
                                        (z) => DropdownMenuItem(
                                          value: z,
                                          child: Text(z, overflow: TextOverflow.ellipsis),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) => setModalState(
                                    () => selectedCity = val ?? selectedCity,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: openHours,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Jam Operasional',
                                    hintText: '09.00 - 22.00 WIB',
                                    prefixIcon: Icon(Icons.access_time_rounded, size: 20),
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

                    // SECTION 2: LOKASI & KOORDINAT GPS
                    _buildDialogSectionHeader('LOKASI & KOORDINAT GPS', Icons.location_on_outlined, amberPrimary),
                    _buildDialogCard(
                      Column(
                        children: [
                          TextField(
                            controller: address,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Alamat Lengkap Tempat *',
                              hintText: 'Jl. Raya Purwokerto No. 12',
                              prefixIcon: Icon(Icons.place_rounded, size: 20),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: latitude,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Latitude GPS (-7.6 s/d -7.2) *',
                                    hintText: '-7.4244',
                                    prefixIcon: Icon(Icons.my_location_rounded, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: longitude,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Longitude GPS (109.0 s/d 109.5) *',
                                    hintText: '109.2302',
                                    prefixIcon: Icon(Icons.explore_rounded, size: 20),
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

                    // SECTION 3: BUDGET & PREFERENSI FASILITAS
                    _buildDialogSectionHeader('RENTANG BUDGET & FASILITAS', Icons.payments_outlined, amberPrimary),
                    _buildDialogCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: minPrice,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Budget Minimum (Rp)',
                                    hintText: '15000',
                                    prefixIcon: Icon(Icons.payments_outlined, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: maxPrice,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Budget Maksimum (Rp)',
                                    hintText: '40000',
                                    prefixIcon: Icon(Icons.payments_rounded, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Pilih Fasilitas & Preferensi (Klik untuk aktifkan):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: preferences.map((pref) {
                              final pName = '${pref['name']}';
                              final isSelected = selectedFacilities.contains(pName);
                              return FilterChip(
                                label: Text(
                                  pName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                ),
                                selected: isSelected,
                                backgroundColor: navyInput,
                                selectedColor: amberPrimary.withValues(alpha: 0.25),
                                checkmarkColor: amberPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected ? amberPrimary : navyBorder,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                onSelected: (sel) {
                                  setModalState(() {
                                    if (sel) {
                                      selectedFacilities.add(pName);
                                    } else {
                                      selectedFacilities.remove(pName);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: customFacilities,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Fasilitas Tambahan Lainnya (Opsional)',
                              hintText: 'Contoh: Outdoor, Lesehan, Live Musik (pisahkan koma)',
                              prefixIcon: Icon(Icons.playlist_add_rounded, size: 20),
                            ),
                          ),
                        ],
                      ),
                      navyInput,
                      navyBorder,
                    ),

                    // SECTION 4: MEDIA BANNER & DESKRIPSI
                    _buildDialogSectionHeader('MEDIA BANNER & DESKRIPSI', Icons.image_outlined, amberPrimary),
                    _buildDialogCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: image,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'URL Gambar Banner Tempat',
                              hintText: 'https://images.unsplash.com/...',
                              prefixIcon: Icon(Icons.link_rounded, size: 20),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                          const SizedBox(height: 12),
                          // Live Image Banner Preview
                          Container(
                            height: 135,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: navyInput,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: navyBorder),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: image.text.trim().isNotEmpty
                                ? Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Image.network(
                                          image.text.trim(),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.broken_image_rounded, color: Colors.white38),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Pratinjau gambar gagal dimuat (URL tidak valid)',
                                                  style: TextStyle(color: Colors.white38, fontSize: 12),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.65),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.visibility_rounded, size: 12, color: amberPrimary),
                                              SizedBox(width: 4),
                                              Text(
                                                'Pratinjau Banner',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
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
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: Colors.white.withValues(alpha: 0.3),
                                          size: 28,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Masukkan URL gambar di atas untuk melihat pratinjau banner',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.4),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: description,
                            maxLines: 3,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Deskripsi Singkat Tempat',
                              hintText: 'Deskripsikan konsep, keunikan, atau menu favorit tempat...',
                              prefixIcon: Icon(Icons.description_outlined, size: 20),
                            ),
                          ),
                        ],
                      ),
                      navyInput,
                      navyBorder,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: navyBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal', style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: amberPrimary,
                foregroundColor: const Color(0xFF0D1326),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                final facList = {...selectedFacilities, ...customExtras}.toList();

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
                  'menu_highlights': <Map<String, dynamic>>[],
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
