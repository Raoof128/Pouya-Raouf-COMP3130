import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/map/data/datasources/places_search_source.dart';

void main() {
  group('PlaceSuggestion', () {
    test('creates from constructor', () {
      const suggestion = PlaceSuggestion(
        placeId: 'abc123',
        description: 'Macquarie University, Sydney',
      );
      expect(suggestion.placeId, 'abc123');
      expect(suggestion.description, 'Macquarie University, Sydney');
    });
  });

  group('PlacesSearchSource', () {
    test('returns empty list for short queries', () async {
      final source = PlacesSearchSource();
      final results = await source.search('a');
      expect(results, isEmpty);
    });

    test('returns empty list for empty queries', () async {
      final source = PlacesSearchSource();
      final results = await source.search('');
      expect(results, isEmpty);
    });

    test('returns empty list for whitespace-only queries', () async {
      final source = PlacesSearchSource();
      final results = await source.search('   ');
      expect(results, isEmpty);
    });
  });
}
