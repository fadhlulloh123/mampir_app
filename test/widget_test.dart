import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mampir_app/main.dart';
import 'package:mampir_app/services/api_service.dart';
import 'package:mampir_app/services/recommendation_service.dart';

void main() {
  testWidgets('MAMPIR app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const MampirApp());
    // Verify the app renders without crashing
    expect(find.byType(MaterialApp), findsOneWidget);

    // Fast-forward past the splash timer
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 500));
  });

  test('ApiService returns 25 authentic places for Purwokerto & Sekitarnya', () async {
    final apiService = ApiService();
    final places = await apiService.fetchPlaces();

    expect(places.length, equals(25));

    // Verify places include key regions like Purwokerto Kota, Baturraden, Sokaraja, Unsoed
    final cities = places.map((p) => p.city).toSet();
    expect(cities.contains('Purwokerto Kota'), isTrue);
    expect(cities.contains('Baturraden'), isTrue);
    expect(cities.contains('Sokaraja'), isTrue);
    expect(cities.contains('Purwokerto Utara (Unsoed)'), isTrue);
    expect(cities.contains('Purwokerto Timur & Sumbang'), isTrue);
    expect(cities.contains('Purwokerto Barat & Selatan'), isTrue);

    // Verify all latitudes are in Purwokerto - Baturraden region (~ -7.31 to -7.47)
    for (final p in places) {
      expect(p.latitude, inInclusiveRange(-7.50, -7.25));
      expect(p.longitude, inInclusiveRange(109.15, 109.35));
    }
  });

  test('RecommendationService filters Purwokerto sub-regions accurately', () async {
    final apiService = ApiService();
    final places = await apiService.fetchPlaces();

    // Test Baturraden recommendations
    final btrRecs = RecommendationService.getRecommendations(
      allPlaces: places,
      userBudget: 50000,
      selectedRegion: 'Baturraden',
    );
    expect(btrRecs.isNotEmpty, isTrue);
    expect(btrRecs.any((r) => r.place.city.contains('Baturraden')), isTrue);

    // Test Sokaraja recommendations
    final skrRecs = RecommendationService.getRecommendations(
      allPlaces: places,
      userBudget: 50000,
      selectedRegion: 'Sokaraja',
    );
    expect(skrRecs.isNotEmpty, isTrue);
    expect(skrRecs.any((r) => r.place.city.contains('Sokaraja')), isTrue);
  });
}
