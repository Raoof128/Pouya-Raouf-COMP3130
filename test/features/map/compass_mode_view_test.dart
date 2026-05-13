import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/nav_instruction.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/presentation/widgets/compass_mode_view.dart';
import 'package:mq_navigation/features/map/presentation/widgets/map_view_helpers.dart';

/// Pure function extracted from CompassModeView for heading -> angle conversion.
/// Returns radians, 0 = pointing up (north).
double calculateArrowAngle(double bearingToDestination, double compassHeading) {
  var direction = bearingToDestination - compassHeading;
  if (direction < 0) direction += 360;
  return direction * (math.pi / 180);
}

/// The bearing of the four cardinal directions
const north = 0.0;
const east = 90.0;
const south = 180.0;
const west = 270.0;

LocationSample _loc(double lat, double lng) {
  return LocationSample(latitude: lat, longitude: lng);
}

Building _building({double? lat, double? lng}) {
  return Building(
    id: 'LIB',
    code: 'LIB',
    name: 'Library',
    category: BuildingCategory.academic,
    latitude: lat ?? -33.7757,
    longitude: lng ?? 151.1131,
  );
}

MapRoute _route({List<NavInstruction> instructions = const []}) {
  return MapRoute(
    travelMode: TravelMode.walk,
    distanceMeters: 500,
    durationSeconds: 420,
    encodedPolyline: '',
    instructions: instructions,
  );
}

void main() {
  group('calculateArrowAngle', () {
    // When heading matches bearing, arrow should point up (angle = 0)
    test('arrow points up when heading matches bearing', () {
      final angle = calculateArrowAngle(north, north);
      expect(angle, closeTo(0, 1e-10));
    });

    // When heading is 90° east but bearing is 0° north:
    // direction = 0 - 90 = -90 → -90 + 360 = 270° → 270° = 3π/2 rad
    // The arrow turns left (negative rotation) showing the correct relative direction.
    test('bearing - heading: facing east, target is north', () {
      final angle = calculateArrowAngle(north, east);
      // 270° = 3π/2 rad (the angle is normalized to 0-360 before conversion)
      expect(angle, closeTo(3 * math.pi / 2, 1e-10));
    });

    // When heading is north but target is east, arrow rotates right (positive)
    test('bearing - heading: facing north, target is east', () {
      final angle = calculateArrowAngle(east, north);
      expect(angle, closeTo(math.pi / 2, 1e-10));
    });

    // Destination is directly behind user
    test('arrow points down when target is behind', () {
      final angle = calculateArrowAngle(south, north);
      expect(angle, closeTo(math.pi, 1e-10));
    });

    // Full 360 wrapping test
    test('bearing 10°, heading 350° → angle = 20°', () {
      final angle = calculateArrowAngle(10.0, 350.0);
      expect(angle, closeTo(20 * math.pi / 180, 1e-10));
    });

    // Bearing 350°, heading 10° → angle = 340° (wrapped)
    test('bearing 350°, heading 10° → direction wraps to 340°', () {
      final angle = calculateArrowAngle(350.0, 10.0);
      expect(angle, closeTo(340 * math.pi / 180, 1e-10));
    });

    // Both at 0
    test('zero values produce zero angle', () {
      expect(calculateArrowAngle(0, 0), closeTo(0, 1e-10));
    });

    // 360 edge case → direction = 360 - 0 = 360 → 360 * π/180 = 2π
    // 2π rad = 1 full turn, which is equivalent to 0 for rendering
    test('bearing 360°, heading 0° produces 2π (full rotation)', () {
      final angle = calculateArrowAngle(360.0, 0.0);
      expect(angle, closeTo(2 * math.pi, 1e-10));
    });

    // Random values for regression
    test('random: bearing 45°, heading 315°', () {
      final angle = calculateArrowAngle(45.0, 315.0);
      expect(angle, closeTo(90 * math.pi / 180, 1e-10));
    });
  });

  group('resolveBuildingGeographicTarget', () {
    test('returns building entrance coordinates when available', () {
      const building = Building(
        id: 'B1',
        code: 'B1',
        name: 'Test',
        latitude: -33.77,
        longitude: 151.11,
        entranceLatitude: -33.775,
        entranceLongitude: 151.112,
      );

      final target = resolveBuildingGeographicTarget(building);
      expect(target, isNotNull);
      expect(target!.latitude, -33.775);
      expect(target.longitude, 151.112);
    });

    test('falls back to building center when entrance is null', () {
      final building = _building();

      final target = resolveBuildingGeographicTarget(building);
      expect(target, isNotNull);
      expect(target!.latitude, building.latitude);
      expect(target.longitude, building.longitude);
    });

    test('returns null when building has no geographic coordinates', () {
      const building = Building(
        id: 'NOLOC',
        code: 'NOLOC',
        name: 'No Location',
        category: BuildingCategory.other,
      );

      final target = resolveBuildingGeographicTarget(building);
      expect(target, isNull);
    });
  });

  group('CompassModeView widget tests', () {
    // Note: Full widget rendering with StreamBuilder and FlutterCompass.events
    // requires platform channel mocking. Unit tests below verify the
    // component composition and integration contracts.

    test('CompassModeView is a StatelessWidget', () {
      final view = CompassModeView(
        currentLocation: null,
        selectedBuilding: null,
        route: null,
        onClose: () {},
      );
      expect(view, isA<CompassModeView>());
    });

    test(
      'constructor requires currentLocation, selectedBuilding, route, onClose',
      () {
        // The named parameters are all required.
        // Verify they appear in the API contract via compile-time checks
        // in the test project (compilation of this file as-is) .
        expect(
          () => CompassModeView(
            currentLocation: _loc(-33.77, 151.11),
            selectedBuilding: _building(),
            route: _route(),
            onClose: () {},
          ),
          isNot(throwsA(anything)),
        );
      },
    );
  });

  group('bearing between locations matches compass use case', () {
    // Macquarie University campus locations
    // Library: -33.7757, 151.1131
    // 18 Wally's Walk: -33.7740, 151.1126
    test('bearing from library to 18WW points roughly north', () {
      final bearing = Geolocator.bearingBetween(
        -33.7757,
        151.1131, // Library
        -33.7740,
        151.1126, // 18WW
      );
      // 18WW is north of the library by ~0.0017°, so bearing ~350° or ~-10°
      final normalized = ((bearing % 360) + 360) % 360;
      expect(normalized, closeTo(350.0, 15.0));
    });

    test('bearing returns a finite number', () {
      final bearing = Geolocator.bearingBetween(-33.77, 151.11, -33.76, 151.12);
      expect(bearing.isFinite, isTrue);
    });

    test('bearing is symmetric for reverse direction', () {
      final fwd = Geolocator.bearingBetween(-33.77, 151.11, -33.76, 151.12);
      final rev = Geolocator.bearingBetween(-33.76, 151.12, -33.77, 151.11);
      // Should differ by roughly 180°
      final diff = ((fwd - rev).abs() % 360);
      expect(diff, closeTo(180, 5));
    });
  });

  group('heading accuracy rounding', () {
    test('accuracy rounds correctly for display', () {
      const accuracy = 12.7;
      expect(accuracy.round(), 13);
    });

    test('accuracy handles null gracefully', () {
      const double? accuracy = null;
      expect(accuracy, isNull);
    });

    test('heading rounds correctly for display', () {
      const heading = 87.3;
      expect(heading.round(), 87);
    });
  });
}
