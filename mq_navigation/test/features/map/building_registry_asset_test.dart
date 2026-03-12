import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/campus_overlay_meta.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled building registry mirrors the audited web dataset', () async {
    final raw = await rootBundle.loadString('assets/data/buildings.json');
    final data = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Building.fromJson)
        .toList();

    expect(data.length, greaterThanOrEqualTo(100));

    final byId = <String, Building>{
      for (final building in data) building.id: building,
    };

    for (final buildingId in const [
      'LIB',
      '18WW',
      '1CC',
      'MUSE',
      '14SCO',
      '12WW',
    ]) {
      final building = byId[buildingId];
      expect(building, isNotNull);
      expect(building!.entranceLatitude, isNotNull);
      expect(building.entranceLongitude, isNotNull);
      expect(building.googlePlaceId, isNotNull);
      expect(building.campusX, isNotNull);
      expect(building.campusY, isNotNull);
    }
  });

  test(
    'bundled campus overlay metadata matches the shared web export',
    () async {
      final raw = await rootBundle.loadString(
        'assets/data/campus_overlay_meta.json',
      );
      final meta = CampusOverlayMeta.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );

      expect(meta.imageAsset, 'assets/maps/mq-campus.png');
      expect(meta.width, greaterThan(4000));
      expect(meta.height, greaterThan(3000));
      expect(meta.pixelBounds.north, meta.height);
      expect(meta.pixelBounds.east, meta.width);
      expect(meta.buildingPixelOffsetX, greaterThan(0));
      expect(meta.mapNorth, lessThanOrEqualTo(85));
      expect(meta.mapEast, lessThanOrEqualTo(170));
      expect(meta.gpsProjection?.method, 'gcp_affine');
      expect(meta.gpsProjection?.affine, isNotNull);
    },
  );
}
