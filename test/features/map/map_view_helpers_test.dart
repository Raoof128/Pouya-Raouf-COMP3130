import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/presentation/widgets/map_view_helpers.dart';

Building _b({required String id, bool geo = true}) {
  return Building(
    id: id,
    code: id,
    name: 'Building $id',
    description: null,
    address: null,
    category: BuildingCategory.other,
    latitude: geo ? -33.7738 : null,
    longitude: geo ? 151.1126 : null,
    entranceLatitude: null,
    entranceLongitude: null,
    googlePlaceId: null,
    aliases: const [],
    tags: const [],
    searchTokens: const [],
    gridRef: null,
    levels: null,
    wheelchair: false,
    campusX: null,
    campusY: null,
  );
}

void main() {
  group('resolveVisibleBuildings', () {
    final a = _b(id: 'A');
    final b = _b(id: 'B');
    final c = _b(id: 'C');

    test('idle state — no query, no selection — returns nothing', () {
      final result = resolveVisibleBuildings(
        searchResults: [a, b, c],
        searchQuery: '',
        selectedBuilding: null,
      );
      expect(result, isEmpty);
    });

    test(
      'category browse — query active, no selection — shows all matches',
      () {
        final result = resolveVisibleBuildings(
          searchResults: [a, b, c],
          searchQuery: 'student services',
          selectedBuilding: null,
        );
        expect(result, [a, b, c]);
      },
    );

    test(
      'focused state — selection set — returns ONLY the selected building',
      () {
        // Critical regression fix: previously this returned [b, a, c]
        // when query was active AND selection was set, which surfaced
        // every category match alongside the focused destination.
        final result = resolveVisibleBuildings(
          searchResults: [a, b, c],
          searchQuery: 'student services',
          selectedBuilding: b,
        );
        expect(result, [b]);
      },
    );

    test(
      'focused state — selection set, no query — still returns just selected',
      () {
        final result = resolveVisibleBuildings(
          searchResults: const [],
          searchQuery: '',
          selectedBuilding: b,
        );
        expect(result, [b]);
      },
    );

    test('skips buildings without coordinates from category results', () {
      final noGeo = _b(id: 'D', geo: false);
      final result = resolveVisibleBuildings(
        searchResults: [a, noGeo, c],
        searchQuery: 'food',
        selectedBuilding: null,
      );
      expect(result, [a, c], reason: 'noGeo dropped — cannot be placed on map');
    });

    test('focused selection without coordinates returns empty list', () {
      final noGeo = _b(id: 'D', geo: false);
      final result = resolveVisibleBuildings(
        searchResults: const [],
        searchQuery: '',
        selectedBuilding: noGeo,
      );
      expect(result, isEmpty);
    });
  });
}
