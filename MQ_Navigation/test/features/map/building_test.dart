import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';

void main() {
  group('Building', () {
    final sampleJson = {
      'id': '18WW',
      'name': '18 Wally\'s Walk (Central Hub)',
      'description': 'Central services hub',
      'address': '18 Wally\'s Walk',
      'category': 'services',
      'location': {'lat': -33.7739781, 'lng': 151.1126116},
      'entranceLocation': {'lat': -33.77388, 'lng': 151.11275},
      'googlePlaceId': 'ChIJx123',
      'levels': 4,
      'wheelchair': true,
      'tags': ['services', 'administration', 'study'],
      'aliases': ['Central Hub', 'Wally\'s Walk'],
      'gridRef': 'N16',
    };

    test('fromJson parses all fields correctly', () {
      final building = Building.fromJson(sampleJson);
      expect(building.id, '18WW');
      expect(building.name, contains('Central Hub'));
      expect(building.description, 'Central services hub');
      expect(building.address, '18 Wally\'s Walk');
      expect(building.category, BuildingCategory.services);
      expect(building.latitude, -33.7739781);
      expect(building.longitude, 151.1126116);
      expect(building.entranceLatitude, -33.77388);
      expect(building.entranceLongitude, 151.11275);
      expect(building.googlePlaceId, 'ChIJx123');
      expect(building.levels, 4);
      expect(building.wheelchair, isTrue);
      expect(building.tags, hasLength(3));
      expect(building.aliases, hasLength(2));
      expect(building.gridRef, 'N16');
    });

    test('fromJson handles missing optional fields', () {
      final building = Building.fromJson({
        'id': 'TEST',
        'name': 'Test Building',
      });
      expect(building.id, 'TEST');
      expect(building.name, 'Test Building');
      expect(building.description, isNull);
      expect(building.latitude, isNull);
      expect(building.longitude, isNull);
      expect(building.category, BuildingCategory.other);
      expect(building.wheelchair, isFalse);
      expect(building.tags, isEmpty);
      expect(building.aliases, isEmpty);
    });

    test('toJson round-trips correctly', () {
      final building = Building.fromJson(sampleJson);
      final json = building.toJson();
      expect(json['id'], '18WW');
      expect(json['category'], 'services');
      expect((json['location'] as Map)['lat'], -33.7739781);
      expect((json['entranceLocation'] as Map)['lat'], -33.77388);
    });

    test('routingLatitude prefers entrance over building center', () {
      final building = Building.fromJson(sampleJson);
      expect(building.routingLatitude, -33.77388);
      expect(building.routingLongitude, 151.11275);
    });

    test('routingLatitude falls back to center when no entrance', () {
      final building = Building.fromJson({
        'id': 'X',
        'name': 'X',
        'location': {'lat': -33.77, 'lng': 151.11},
      });
      expect(building.routingLatitude, -33.77);
    });

    test('matchesQuery matches building code', () {
      final building = Building.fromJson(sampleJson);
      expect(building.matchesQuery('18WW'), isTrue);
      expect(building.matchesQuery('18ww'), isTrue);
    });

    test('matchesQuery matches name', () {
      final building = Building.fromJson(sampleJson);
      expect(building.matchesQuery('Central Hub'), isTrue);
      expect(building.matchesQuery('wally'), isTrue);
    });

    test('matchesQuery matches alias', () {
      final building = Building.fromJson(sampleJson);
      expect(building.matchesQuery('Central Hub'), isTrue);
    });

    test('matchesQuery matches tag', () {
      final building = Building.fromJson(sampleJson);
      expect(building.matchesQuery('administration'), isTrue);
    });

    test('matchesQuery returns false for non-match', () {
      final building = Building.fromJson(sampleJson);
      expect(building.matchesQuery('xyz_nonexistent'), isFalse);
    });
  });

  group('BuildingCategory', () {
    test('fromString parses known categories', () {
      expect(
        BuildingCategory.fromString('academic'),
        BuildingCategory.academic,
      );
      expect(
        BuildingCategory.fromString('services'),
        BuildingCategory.services,
      );
      expect(BuildingCategory.fromString('health'), BuildingCategory.health);
      expect(BuildingCategory.fromString('food'), BuildingCategory.food);
      expect(BuildingCategory.fromString('sports'), BuildingCategory.sports);
    });

    test('fromString defaults to other for unknown', () {
      expect(BuildingCategory.fromString('unknown'), BuildingCategory.other);
      expect(BuildingCategory.fromString(''), BuildingCategory.other);
    });
  });
}
