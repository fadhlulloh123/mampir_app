import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_preference_screen.dart';
import 'services/preference_service.dart';
import 'theme/app_theme.dart';

/// ============================================================
/// MAIN.DART — ENTRY POINT APLIKASI MAMPIR
/// ============================================================
/// MAMPIR: Makan, Ampir, Pilih, dan Rekomendasi
/// Kuliner & Nongkrong • Kota Purwokerto & Sekitarnya (Baturraden, Sokaraja)
/// ============================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MampirApp());
}

class MampirApp extends StatelessWidget {
  const MampirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAMPIR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

/// ============================================================
/// SPLASH SCREEN — SESUAI SPESIFIKASI #3 & splash screen.jpeg
/// ============================================================
/// - Background Deep Navy #0D1326
/// - Fade-in animasi halus 2.5 detik
/// - Cek is_first_launch via PreferenceService:
///   * True  -> OnboardingPreferenceScreen
///   * False -> HomeScreen
/// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final PreferenceService _prefService = PreferenceService();

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
    _startTimerAndRoute();
  }

  Future<void> _startTimerAndRoute() async {
    // Jalankan timer 2.5 detik
    await Future.delayed(const Duration(milliseconds: 2500));

    final isFirst = await _prefService.isFirstLaunch();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, anim, secondAnim) =>
            isFirst ? const OnboardingPreferenceScreen() : const HomeScreen(),
        transitionsBuilder: (context, anim, secondAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Stack(
        children: [
          // Subtle mandala ornamentation on top right & bottom left
          Positioned(
            top: 0,
            right: 0,
            width: 300,
            height: 300,
            child: CustomPaint(
              painter: MandalaOrnamentPainter(scale: 1.0),
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Splash Logo Gambar (dari splash screen.jpeg)
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: 320,
                          maxHeight: 320,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/splash_logo.jpeg',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/images/app_icon.jpeg',
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, st) => const Icon(
                                Icons.restaurant_menu_rounded,
                                size: 100,
                                color: AppTheme.orange,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
