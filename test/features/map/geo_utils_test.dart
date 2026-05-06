import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/geo_utils.dart';

void main() {
  group('haversineMetres', () {
    test('calculates distance between two known points accurately', () {
      // Arrange
      const lat1 = -33.77388; // 18 Wally's Walk
      const lng1 = 151.11275;
      const lat2 = -33.7756994; // Library
      const lng2 = 151.1131306;

      // Act
      final distance = haversineMetres(
        lat1: lat1,
        lng1: lng1,
        lat2: lat2,
        lng2: lng2,
      );

      // Assert
      // Expected distance is ~205m according to common mapping tools.
      expect(distance, closeTo(205.0, 5.0));
    });

    test('returns zero for the same point', () {
      // Act
      final distance = haversineMetres(
        lat1: -33.77388,
        lng1: 151.11275,
        lat2: -33.77388,
        lng2: 151.11275,
      );

      // Assert
      expect(distance, 0.0);
    });

    test('handles zero coordinates correctly', () {
      // Act
      final distance = haversineMetres(
        lat1: 0.0,
        lng1: 0.0,
        lat2: 0.1,
        lng2: 0.1,
      );

      // Assert
      expect(distance, isPositive);
    });

    test('handles extreme coordinates (poles)', () {
      // Act
      final distance = haversineMetres(
        lat1: 90.0,
        lng1: 0.0,
        lat2: -90.0,
        lng2: 0.0,
      );

      // Assert
      // Distance from North Pole to South Pole is ~20,015km.
      expect(distance, closeTo(20015000.0, 50000.0));
    });
  });

  group('bearingDegreesBetween', () {
    test('returns ~0° when travelling north along a meridian', () {
      final bearing = bearingDegreesBetween(
        lat1: -33.77,
        lng1: 151.11,
        lat2: -33.76,
        lng2: 151.11,
      );
      expect(bearing, closeTo(0.0, 1.0));
    });

    test('returns ~90° when travelling east along a parallel', () {
      final bearing = bearingDegreesBetween(
        lat1: -33.77,
        lng1: 151.11,
        lat2: -33.77,
        lng2: 151.12,
      );
      expect(bearing, closeTo(90.0, 1.0));
    });
  });

  group('findClosestPointIndex', () {
    test('finds the correct index when multiple points exist', () {
      // Arrange
      const target = LocationSample(latitude: -33.774, longitude: 151.112);
      const points = [
        LocationSample(latitude: -33.770, longitude: 151.110),
        LocationSample(latitude: -33.7741, longitude: 151.1121), // Closest
        LocationSample(latitude: -33.780, longitude: 151.120),
      ];

      // Act
      final index = findClosestPointIndex(points, target);

      // Assert
      expect(index, 1);
    });

    test('returns zero index for a single point list', () {
      // Arrange
      const target = LocationSample(latitude: -33.774, longitude: 151.112);
      const points = [LocationSample(latitude: -33.770, longitude: 151.110)];

      // Act
      final index = findClosestPointIndex(points, target);

      // Assert
      expect(index, 0);
    });
  });
}
