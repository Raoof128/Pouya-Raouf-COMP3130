import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/services/building_search.dart';

void main() {
  final buildings = [
    Building.fromJson({
      'id': 'LIB',
      'code': 'LIB',
      'name': 'Waranara Library',
      'aliases': ['mq library'],
      'searchTokens': ['library'],
      'tags': ['study'],
      'gridRef': 'Q17',
      'latitude': -33.7756994,
      'longitude': 151.1131306,
    }),
    Building.fromJson({
      'id': '18WW',
      'code': '18WW',
      'name': '18 Wally\'s Walk (Central Hub)',
      'aliases': ['service connect'],
      'searchTokens': ['central hub'],
      'tags': ['services'],
      'latitude': -33.7739781,
      'longitude': 151.1126116,
    }),
    Building.fromJson({
      'id': '1CC',
      'code': '1CC',
      'name': 'Campus Commons',
      'tags': ['food'],
      'latitude': -33.773,
      'longitude': 151.112,
    }),
  ];

  group('searchCampusBuildings', () {
    test('returns the web-style default ordering for empty search', () {
      final results = searchCampusBuildings(buildings, '');
      expect(results.map((building) => building.id), ['18WW', '1CC', 'LIB']);
    });

    test('prefers exact id matches over everything else', () {
      final results = searchCampusBuildings(buildings, 'LIB');
      expect(results.first.id, 'LIB');
    });

    test('prefers exact alias and search token matches after exact id', () {
      final results = searchCampusBuildings(buildings, 'service connect');
      expect(results.first.id, '18WW');
    });

    test('keeps non-matches in the result set but sorts them last', () {
      final results = searchCampusBuildings(buildings, 'study');
      expect(results.first.id, 'LIB');
      expect(results, hasLength(3));
    });
  });
}
