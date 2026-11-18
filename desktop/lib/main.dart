import 'dart:convert';

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
      ),
      useMaterial3: true,
    ),
    home: const AdminLoginPage(),
  );
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
        body: jsonEncode({
          'email': cleanEmail,
          'password': cleanPassword,
        }),
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

  static const Color _amberPrimary = Color(0xFFD99B25);
  static const Color _amberDark = Color(0xFFB57D18);
  static const Color _darkSurface = Color(0xFF131316);
  static const Color _darkInput = Color(0xFF24242C);
  static const Color _brandDark = Color(0xFF1E1303);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkSurface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildBrandingPanel(),
                ),
                Expanded(
                  flex: 6,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: _buildLoginForm(context),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildCompactBrandingBanner(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _buildLoginForm(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF2B039),
            _amberPrimary,
            _amberDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -80,
            bottom: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/app_icon.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF231805),
                        child: const Icon(
                          Icons.travel_explore_rounded,
                          color: Color(0xFFF3B43F),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'MAMPIR',
                        style: TextStyle(
                          color: _brandDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'PORTAL ADMINISTRASI',
                        style: TextStyle(
                          color: Color(0xFF4A3410),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: _brandDark,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/app_icon.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.travel_explore_rounded,
                          color: Color(0xFFF3B43F),
                          size: 46,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Kelola Informasi,\nRute, & Komunitas.',
                    style: TextStyle(
                      color: _brandDark,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Pusat kendali operasional platform MAMPIR untuk kurasi destinasi kuliner dan wisata, moderasi ulasan, serta sinkronisasi data tempat secara real-time.',
                    style: TextStyle(
                      color: const Color(0xFF2E1C05).withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildBrandingFeatureItem(
                    Icons.map_rounded,
                    'Manajemen Tempat & Rute Wisata',
                  ),
                  const SizedBox(height: 12),
                  _buildBrandingFeatureItem(
                    Icons.category_rounded,
                    'Kelola Kategori & Ulasan Komunitas',
                  ),
                  const SizedBox(height: 12),
                  _buildBrandingFeatureItem(
                    Icons.sync_rounded,
                    'Sinkronisasi Google API & Supabase',
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _brandDark,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mampir Admin Suite • Proyek PML 2026',
                    style: TextStyle(
                      color: const Color(0xFF2E1C05).withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingFeatureItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _brandDark.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _brandDark.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _brandDark),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: _brandDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBrandingBanner() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_amberPrimary, _amberDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _brandDark,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/app_icon.jpeg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.travel_explore_rounded,
                color: Color(0xFFF3B43F),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'MAMPIR ADMIN',
                style: TextStyle(
                  color: _brandDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Portal Manajemen Administrator',
                style: TextStyle(
                  color: Color(0xFF382307),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _amberPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _amberPrimary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.shield_rounded, size: 14, color: _amberPrimary),
              SizedBox(width: 6),
              Text(
                'Akses Terbatas Admin',
                style: TextStyle(
                  color: _amberPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Selamat Datang Kembali 👋',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Silakan masukkan kredensial administrator Anda untuk mengelola data sistem MAMPIR.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7F1D1D).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFCA5A5),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        const Text(
          'Email Administrator',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'admin@mampir.id',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Colors.white54,
              size: 20,
            ),
            filled: true,
            fillColor: _darkInput,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: _amberPrimary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Kata Sandi',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: password,
          obscureText: obscurePassword,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onSubmitted: (_) => loading ? null : login(),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white54,
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
            fillColor: _darkInput,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: _amberPrimary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: rememberMe,
                activeColor: _amberPrimary,
                checkColor: _brandDark,
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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: loading ? null : login,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amberPrimary,
              foregroundColor: _brandDark,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _brandDark,
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
        const SizedBox(height: 32),
        Center(
          child: Text(
            '© 2026 Tim Proyek PML MAMPIR. Hak Cipta Dilindungi.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
            ),
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
        if (!name.contains(query) && !cat.contains(query) && !addr.contains(query)) {
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
      throw Exception('Gagal menambahkan tempat (${response.statusCode}): ${response.body}');
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
          SnackBar(content: Text('Tempat "${place['name']}" berhasil dihapus.')),
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
                            const Text('Total Tempat', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('${places.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Rating Rata-rata', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('${avgRating.toStringAsFixed(1)} ★', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Rata-rata Budget', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('Rp ${avgBudget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xffd99b25))),
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
                  final pct = places.isNotEmpty ? (e.value / places.length * 100).toStringAsFixed(1) : '0';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13))),
                        Text('${e.value} tempat ($pct%)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('MAMPIR Admin Dashboard'),
      actions: [
        FilledButton.tonalIcon(
          onPressed: () async {
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
          icon: const Icon(Icons.sync),
          label: const Text('Sinkron Google'),
        ),
        IconButton(
          onPressed: () => manageLookupValues(
            table: 'categories',
            title: 'kategori',
            values: categories,
          ),
          icon: const Icon(Icons.category_outlined),
          tooltip: 'Kelola kategori',
        ),
        IconButton(
          onPressed: () => manageLookupValues(
            table: 'preferences',
            title: 'preferensi/fasilitas',
            values: preferences,
          ),
          icon: const Icon(Icons.tune),
          tooltip: 'Kelola preferensi',
        ),
        IconButton(
          onPressed: showStats,
          icon: const Icon(Icons.analytics_outlined),
          tooltip: 'Statistik',
        ),
        IconButton(
          onPressed: loadPlaces,
          icon: const Icon(Icons.refresh),
          tooltip: 'Muat ulang',
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Center(child: Text('Data tersinkron Supabase')),
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Katalog tempat (${filteredPlaces.length} dari ${places.length})',
                      style: Theme.of(context).textTheme.headlineSmall,
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
                                  content: Text('Tempat baru berhasil ditambahkan ke Supabase!'),
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
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Tempat Baru (WADM-3)'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari tempat berdasarkan nama, kategori, atau alamat (WADM-2)...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => setState(() => searchController.clear()),
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedZone,
                        decoration: InputDecoration(
                          labelText: 'Filter 7 Zona Wilayah (WADM-2)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: zones
                            .map((z) => DropdownMenuItem(value: z, child: Text(z, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) => setState(() => selectedZone = val ?? 'Semua Wilayah'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    child: filteredPlaces.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Tidak ada tempat kuliner yang sesuai dengan pencarian atau filter zona.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredPlaces.length,
                            separatorBuilder: (_, index) => const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final place = filteredPlaces[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Icon(
                                    place['category'] == 'Warkop'
                                        ? Icons.coffee_rounded
                                        : place['category'] == 'Restoran'
                                            ? Icons.restaurant_rounded
                                            : Icons.local_cafe_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      '${place['name'] ?? '-'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${place['category'] ?? 'Cafe'} • ${place['city'] ?? 'Purwokerto'}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  '${place['address'] ?? '-'}\nBudget: Rp ${place['min_price'] ?? 0} - Rp ${place['max_price'] ?? 0} • Rating: ${place['rating'] ?? '-'} ★',
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FilledButton.tonal(
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
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(SnackBar(content: Text('$e')));
                                          }
                                        }
                                      },
                                      child: const Text('Edit'),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      tooltip: 'Hapus Tempat (WADM-5)',
                                      onPressed: () => deletePlace(place),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    ),
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
  final facilities = TextEditingController(
    text: ((source['facilities'] as List<dynamic>?) ?? const []).join(', '),
  );
  var selectedCategory =
      '${source['category'] ?? categories.firstOrNull?['name'] ?? ''}';
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Edit tempat'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Alamat'),
              ),
              TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              TextField(
                controller: image,
                decoration: const InputDecoration(labelText: 'URL gambar'),
              ),
              TextField(
                controller: openHours,
                decoration: const InputDecoration(labelText: 'Jam buka'),
              ),
              DropdownButtonFormField<String>(
                initialValue:
                    categories.any((item) => item['name'] == selectedCategory)
                    ? selectedCategory
                    : null,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: categories
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: '${item['name']}',
                        child: Text('${item['name']}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    selectedCategory = value ?? selectedCategory,
              ),
              TextField(
                controller: facilities,
                decoration: const InputDecoration(
                  labelText: 'Preferensi/fasilitas (pisahkan koma)',
                  hintText: 'WiFi, Colokan, AC, Parkir',
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latitude,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: longitude,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minPrice,
                      decoration: const InputDecoration(
                        labelText: 'Budget minimum',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxPrice,
                      decoration: const InputDecoration(
                        labelText: 'Budget maksimum',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            ...source,
            'name': name.text.trim(),
            'address': address.text.trim(),
            'description': description.text.trim(),
            'image_url': image.text.trim(),
            'open_hours': openHours.text.trim(),
            'category': selectedCategory,
            'facilities': facilities.text
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList(),
            'latitude': double.tryParse(latitude.text) ?? source['latitude'],
            'longitude': double.tryParse(longitude.text) ?? source['longitude'],
            'min_price': int.tryParse(minPrice.text) ?? source['min_price'],
            'max_price': int.tryParse(maxPrice.text) ?? source['max_price'],
            'avg_price': ((int.tryParse(minPrice.text) ?? (source['min_price'] ?? 0)) +
                    (int.tryParse(maxPrice.text) ?? (source['max_price'] ?? 0))) ~/ 2,
          }),
          child: const Text('Simpan'),
        ),
      ],
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
  final image = TextEditingController(text: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80');
  final openHours = TextEditingController(text: '09.00 - 22.00 WIB');
  final minPrice = TextEditingController(text: '15000');
  final maxPrice = TextEditingController(text: '40000');
  final latitude = TextEditingController(text: '-7.4244');
  final longitude = TextEditingController(text: '109.2302');
  final facilities = TextEditingController(text: 'WiFi, Colokan, Parkir');

  var selectedCategory = categories.firstOrNull?['name']?.toString() ?? 'Cafe';
  var selectedCity = 'Purwokerto Kota';

  final availableZones = [
    'Purwokerto Kota',
    'Baturraden',
    'Purwokerto Utara (Unsoed)',
    'Sokaraja',
    'Purwokerto Timur & Sumbang',
    'Purwokerto Barat & Selatan',
  ];

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setModalState) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_location_alt_rounded, color: Color(0xffd99b25)),
            SizedBox(width: 10),
            Text('Tambah Tempat Baru (WADM-3)'),
          ],
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nama Tempat *',
                    hintText: 'Contoh: Kopi Roemah Baturraden',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(labelText: 'Kategori *'),
                        items: (categories.isNotEmpty ? categories : [{'name': 'Cafe'}, {'name': 'Warkop'}, {'name': 'Restoran'}])
                            .map((item) => DropdownMenuItem<String>(
                                  value: '${item['name']}',
                                  child: Text('${item['name']}'),
                                ))
                            .toList(),
                        onChanged: (val) => setModalState(() => selectedCategory = val ?? selectedCategory),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCity,
                        decoration: const InputDecoration(labelText: 'Zona Wilayah *'),
                        items: availableZones
                            .map((z) => DropdownMenuItem(value: z, child: Text(z, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) => setModalState(() => selectedCity = val ?? selectedCity),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: address,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Lengkap *',
                    hintText: 'Jl. Raya Purwokerto No. 12',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latitude,
                        decoration: const InputDecoration(
                          labelText: 'Latitude (-7.6 s/d -7.2) *',
                          hintText: '-7.4244',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: longitude,
                        decoration: const InputDecoration(
                          labelText: 'Longitude (109.0 s/d 109.5) *',
                          hintText: '109.2302',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPrice,
                        decoration: const InputDecoration(labelText: 'Harga Min (Rp)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxPrice,
                        decoration: const InputDecoration(labelText: 'Harga Max (Rp)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: openHours,
                  decoration: const InputDecoration(labelText: 'Jam Operasional'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: image,
                  decoration: const InputDecoration(labelText: 'URL Gambar'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Deskripsi Singkat'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: facilities,
                  decoration: const InputDecoration(
                    labelText: 'Fasilitas (pisahkan dengan koma)',
                    hintText: 'WiFi, Colokan, AC, Parkir',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final n = name.text.trim();
              final addr = address.text.trim();
              final lat = double.tryParse(latitude.text.trim());
              final lng = double.tryParse(longitude.text.trim());
              final min = int.tryParse(minPrice.text.trim()) ?? 0;
              final max = int.tryParse(maxPrice.text.trim()) ?? 0;

              if (n.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama tempat wajib diisi.'), backgroundColor: Colors.redAccent),
                );
                return;
              }
              if (addr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alamat tempat wajib diisi.'), backgroundColor: Colors.redAccent),
                );
                return;
              }
              if (lat == null || lat < -7.6 || lat > -7.2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Latitude tidak valid untuk wilayah Purwokerto/Banyumas (-7.6 s/d -7.2).'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }
              if (lng == null || lng < 109.0 || lng > 109.5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Longitude tidak valid untuk wilayah Purwokerto/Banyumas (109.0 s/d 109.5).'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              final facList = facilities.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

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
            child: const Text('Simpan Tempat'),
          ),
        ],
      ),
    ),
  );
}
