import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/features/map/domain/entities/campus_overlay_meta.dart';

class MapAssetsSource {
  const MapAssetsSource();

  static const _campusOverlayMetaPath = 'assets/data/campus_overlay_meta.json';

  Future<CampusOverlayMeta> loadCampusOverlayMeta() async {
    final raw = await rootBundle.loadString(_campusOverlayMetaPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return CampusOverlayMeta.fromJson(json);
  }
}

final mapAssetsSourceProvider = Provider<MapAssetsSource>((ref) {
  return const MapAssetsSource();
});
