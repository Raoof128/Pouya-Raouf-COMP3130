import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';

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
    }
  });
}
