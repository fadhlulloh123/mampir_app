import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ============================================================
/// APP THEME & PALET WARNA — MAMPIR APP
/// ============================================================
/// Mengikuti desain mockup Dark Navy & Gold-Orange:
/// - Background Utama: #0D1326 / #111827
/// - Surface & Card: #1A233A / #1E293B
/// - Border halus: #263353
/// - Aksen Utama: Gradasi #FFB74D ke #F57C00 (#FFC107 - #E65100)
/// - Teks Utama: #FFFFFF
/// - Teks Sekunder: #94A3B8 / #CBD5E1
/// ============================================================
class AppTheme {
  // Warna Pokok
  static const Color scaffoldBg = Color(0xFF0D1326);
  static const Color surfaceNavy = Color(0xFF1A233A);
  static const Color cardNavy = Color(0xFF162035);
  static const Color searchNavy = Color(0xFF131B30);
  static const Color borderNavy = Color(0xFF263353);

  // Aksen Gradasi Emas-Oranye
  static const Color gold = Color(0xFFFFB74D);
  static const Color goldLight = Color(0xFFFFC107);
  static const Color orange = Color(0xFFF57C00);
  static const Color orangeDeep = Color(0xFFE65100);

  // Teks
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradasi tombol utama & ikon
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gold, orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [goldLight, orangeDeep],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient subtleNavyGradient = LinearGradient(
    colors: [Color(0xFF131D36), Color(0xFF0D1326)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: orange,
      colorScheme: const ColorScheme.dark(
        primary: orange,
        secondary: gold,
        surface: surfaceNavy,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceNavy,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderNavy, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceNavy,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: searchNavy,
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderNavy),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderNavy),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
      ),
    );
  }
}

/// Ornamen Mandala / Batik halus yang digambar pada latar belakang header
class MandalaOrnamentPainter extends CustomPainter {
  final Color color;
  final double scale;

  MandalaOrnamentPainter({
    this.color = const Color(0xFFFFB74D),
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width, 0); // Di pojok kanan atas
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const int petals = 12;
    final maxRadius = size.width * 0.75 * scale;

    // Lingkaran konsentris
    for (double r = 40; r <= maxRadius; r += 32) {
      canvas.drawCircle(center, r, paint);
    }

    // Pola kelopak mandala
    for (int i = 0; i < petals; i++) {
      final angle = (i * 2 * math.pi) / petals;
      final x = center.dx + math.cos(angle) * (maxRadius * 0.6);
      final y = center.dy + math.sin(angle) * (maxRadius * 0.6);

      canvas.drawCircle(Offset(x, y), 24, paint);

      // Garis radial berujung halus
      final rx = center.dx + math.cos(angle) * maxRadius;
      final ry = center.dy + math.sin(angle) * maxRadius;
      canvas.drawLine(center, Offset(rx, ry), paint);
    }

    // Ornamen pojok kiri atas
    final leftCenter = const Offset(0, 0);
    final leftMax = size.width * 0.45 * scale;
    for (double r = 30; r <= leftMax; r += 28) {
      canvas.drawCircle(leftCenter, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MandalaOrnamentPainter oldDelegate) => false;
}
