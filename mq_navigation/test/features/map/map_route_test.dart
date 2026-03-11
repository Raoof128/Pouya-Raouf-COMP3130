import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';

void main() {
  group('MapRoute', () {
    test('parses Google Routes payloads into route instructions', () {
      final route = MapRoute.fromJson({
        'routes': [
          {
            'distanceMeters': 1450,
            'duration': '480s',
            'polyline': {'encodedPolyline': 'abc123'},
            'legs': [
              {
                'steps': [
                  {
                    'distanceMeters': 100,
                    'navigationInstruction': {'instructions': 'Head north'},
                  },
                  {
                    'distanceMeters': 20,
                    'navigationInstruction': {'instructions': 'Turn right'},
                  },
                ],
              },
            ],
          },
        ],
      }, TravelMode.walk);

      expect(route.travelMode, TravelMode.walk);
      expect(route.distanceMeters, 1450);
      expect(route.durationSeconds, 480);
      expect(route.encodedPolyline, 'abc123');
      expect(route.instructions, hasLength(2));
      expect(route.instructions.first.text, 'Head north');
    });
  });
}
