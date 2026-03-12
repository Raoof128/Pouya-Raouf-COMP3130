import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/map/domain/entities/map_overlay.dart';

void main() {
  group('MapOverlay', () {
    test('creates with required fields', () {
      const overlay = MapOverlay(
        id: 'test',
        label: 'Test Overlay',
        description: 'A test overlay',
        imageAsset: 'assets/maps/test.png',
      );
      expect(overlay.id, 'test');
      expect(overlay.label, 'Test Overlay');
      expect(overlay.description, 'A test overlay');
      expect(overlay.imageAsset, 'assets/maps/test.png');
      expect(overlay.opacity, 0.95); // default
      expect(overlay.color, isNull); // default
    });

    test('supports custom opacity', () {
      const overlay = MapOverlay(
        id: 'test',
        label: 'Test',
        description: 'Test',
        imageAsset: 'assets/test.png',
        opacity: 0.5,
      );
      expect(overlay.opacity, 0.5);
    });
  });
}
