import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/map/data/datasources/overlay_registry.dart';

void main() {
  group('OverlayRegistry', () {
    test('contains exactly 4 overlays', () {
      expect(OverlayRegistry.overlays, hasLength(4));
    });

    test('each overlay has a unique non-empty ID', () {
      final ids = OverlayRegistry.overlays.map((o) => o.id).toSet();
      expect(ids, hasLength(4));
      for (final id in ids) {
        expect(id, isNotEmpty);
      }
    });

    test('each overlay references an asset path', () {
      for (final overlay in OverlayRegistry.overlays) {
        expect(overlay.imageAsset, startsWith('assets/maps/'));
        expect(overlay.imageAsset, endsWith('.png'));
      }
    });

    test('overlay IDs match expected set', () {
      final ids = OverlayRegistry.overlays.map((o) => o.id).toSet();
      expect(
        ids,
        containsAll([
          'parking',
          'drinking_water',
          'accessibility',
          'special_permits',
        ]),
      );
    });

    test('each overlay has a label and description', () {
      for (final overlay in OverlayRegistry.overlays) {
        expect(overlay.label, isNotEmpty);
        expect(overlay.description, isNotEmpty);
      }
    });
  });
}
