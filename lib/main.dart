import 'package:flutter/material.dart';
import 'services/preference_service.dart';
import 'screens/onboarding_preference_screen.dart';
import 'screens/home_screen.dart';

/// ============================================================
/// MAIN.DART — ENTRY POINT APLIKASI MAMPIR
/// ============================================================
/// Aplikasi MAMPIR: Makan, Ampir, Pilih, dan Rekomendasi
/// Tempat Makan & Nongkrong se-BARLINGMASCAKEB
///
/// Fitur Utama:
/// 1. Rekomendasi tempat berdasarkan budget & selera
/// 2. Peta interaktif OpenStreetMap
/// 3. Bookmark tempat favorit/langganan
/// 4. Usulkan tempat baru (HTTP POST ke Web Service)
/// ============================================================
void main() {
  runApp(const MampirApp());
}

class MampirApp extends StatelessWidget {
  const MampirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAMPIR',
      debugShowCheckedModeBanner: false,

      // ======================== TEMA MATERIAL 3 ========================
      // Warna sesuai PRD: Terracotta/Warm Orange, Deep Teal, Soft Cream
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35), // Terracotta / Warm Orange
          primary: const Color(0xFFFF6B35),
          secondary: const Color(0xFF004E64), // Deep Teal
          surface: const Color(0xFFF8F9FA), // Soft Cream
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto', // Fallback, clean & modern
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFFFF6B35),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFF6B35),
          foregroundColor: Colors.white,
        ),
        chipTheme: ChipThemeData(
          selectedColor: const Color(0xFFFF6B35).withValues(alpha: 0.2),
        ),
      ),

      // ======================== ROUTING ========================
      // Cek apakah user sudah pernah onboarding.
      // Jika belum → tampilkan OnboardingPreferenceScreen
      // Jika sudah → langsung ke HomeScreen
      home: const _AppEntry(),
    );
  }
}

/// Widget pembantu untuk mengecek status onboarding secara async.
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  final _prefService = PreferenceService();
  bool? _isOnboarded;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final onboarded = await _prefService.isOnboarded();
    if (mounted) {
      setState(() => _isOnboarded = onboarded);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading sementara cek status onboarding
    if (_isOnboarded == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Arahkan ke screen yang sesuai
    if (_isOnboarded!) {
      return const HomeScreen();
    } else {
      return const OnboardingPreferenceScreen();
    }
  }
}
