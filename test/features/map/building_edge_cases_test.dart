import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';

void main() {
  group('Building.fromJson', () {
    test('handles missing optional fields correctly', () {
      // Arrange
      final json = {'id': 'TEST', 'name': 'Test Building'};

      // Act
      final building = Building.fromJson(json);

      // Assert
      expect(building.id, 'TEST');
      expect(building.name, 'Test Building');
      expect(building.category, BuildingCategory.other);
      expect(building.latitude, isNull);
      expect(building.wheelchair, isFalse);
    });

    test('handles invalid category by falling back to other', () {
      // Arrange
      final json = {
        'id': 'TEST',
        'name': 'Test Building',
        'category': 'not-a-real-category',
      };

      // Act
      final building = Building.fromJson(json);

      // Assert
      expect(building.category, BuildingCategory.other);
    });

    test('correctly maps various coordinate formats', () {
      // Arrange
      final formats = [
        {'id': 'B1', 'name': 'B1', 'latitude': -33.1, 'longitude': 151.1},
        {
          'id': 'B2',
          'name': 'B2',
          'location': {'lat': -33.2, 'lng': 151.2},
        },
        {
          'id': 'B3',
          'name': 'B3',
          'entranceLocation': {'lat': -33.3, 'lng': 151.3},
        },
      ];

      // Act & Assert
      final b1 = Building.fromJson(formats[0]);
      expect(b1.latitude, -33.1);

      final b2 = Building.fromJson(formats[1]);
      expect(b2.latitude, -33.2);

      final b3 = Building.fromJson(formats[2]);
      expect(b3.entranceLatitude, -33.3);
    });

    test('handles numeric types correctly (int vs double)', () {
      // Arrange
      final json = {
        'id': 'TEST',
        'name': 'Test',
        'latitude': -33, // int
        'levels': 5.0, // double
      };

      // Act
      final building = Building.fromJson(json);

      // Assert
      expect(building.latitude, -33.0);
      expect(building.levels, 5);
    });
  });

  group('Building.matchesQuery', () {
    const building = Building(
      id: 'LIB',
      code: 'LIB',
      name: 'Library',
      aliases: ['Waranara'],
      tags: ['books'],
    );

    test('matches by id, code, or name', () {
      expect(building.matchesQuery('LIB'), isTrue);
      expect(building.matchesQuery('Library'), isTrue);
    });

    test('matches by aliases or tags', () {
      expect(building.matchesQuery('Waranara'), isTrue);
      expect(building.matchesQuery('books'), isTrue);
    });

    test('is case-insensitive', () {
      expect(building.matchesQuery('lib'), isTrue);
      expect(building.matchesQuery('LIBRARY'), isTrue);
    });

    test('returns false for non-matching queries', () {
      expect(building.matchesQuery('engineering'), isFalse);
    });
  });
}
