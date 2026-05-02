import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/transit/domain/entities/transit_stop.dart';
import 'package:mq_navigation/features/transit/presentation/providers/tfnsw_provider.dart';

void main() {
  group('dedupeTransitStops', () {
    test(
      'collapses parent station + platform variants into one cleaner entry',
      () {
        // Real-world example from the screenshot bug report.
        final stops = [
          const TransitStop(id: 'G276288', name: 'Tallawong Station, Implexa Pde'),
          const TransitStop(id: '2155384', name: 'Tallawong Station'),
        ];

        final result = dedupeTransitStops(stops);

        expect(result, hasLength(1));
        expect(
          result.single.name,
          'Tallawong Station',
          reason: 'Shortest name (the cleaner parent-station form) wins',
        );
      },
    );

    test('preserves distinct stations', () {
      final stops = [
        const TransitStop(id: '1', name: 'Tallawong Station'),
        const TransitStop(id: '2', name: 'Macquarie University Station'),
        const TransitStop(id: '3', name: 'Chatswood Station'),
      ];
      final result = dedupeTransitStops(stops);
      expect(result, hasLength(3));
    });

    test('keeps the shortest name when multiple platforms appear', () {
      final stops = [
        const TransitStop(id: '1', name: 'Town Hall Station, Platform 1'),
        const TransitStop(id: '2', name: 'Town Hall Station, Platform 2'),
        const TransitStop(id: '3', name: 'Town Hall Station'),
      ];
      final result = dedupeTransitStops(stops);
      expect(result, hasLength(1));
      expect(result.single.name, 'Town Hall Station');
    });

    test('case-insensitive matching', () {
      final stops = [
        const TransitStop(id: '1', name: 'TALLAWONG STATION'),
        const TransitStop(id: '2', name: 'tallawong station'),
      ];
      final result = dedupeTransitStops(stops);
      expect(result, hasLength(1));
    });

    test('ignores entries with empty names after normalisation', () {
      final stops = [
        const TransitStop(id: '1', name: '  ,foo'),
        const TransitStop(id: '2', name: 'Real Station'),
      ];
      final result = dedupeTransitStops(stops);
      expect(result, hasLength(1));
      expect(result.single.name, 'Real Station');
    });

    test('empty input returns empty list', () {
      expect(dedupeTransitStops(const []), isEmpty);
    });
  });
}
