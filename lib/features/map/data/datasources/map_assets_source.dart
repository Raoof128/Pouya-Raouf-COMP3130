import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/map/domain/entities/campus_overlay_meta.dart';

class MapAssetsException implements Exception {
  const MapAssetsException(this.message);
  final String message;

  @override
  String toString() => 'MapAssetsException: $message';
}

class MapAssetsSource {
  const MapAssetsSource();

  static const _campusOverlayMetaPath = 'assets/data/campus_overlay_meta.json';

  Future<CampusOverlayMeta> loadCampusOverlayMeta() async {
    try {
      final raw = await rootBundle.loadString(_campusOverlayMetaPath);
      if (raw.isEmpty) {
        throw const MapAssetsException('Campus overlay meta file is empty');
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CampusOverlayMeta.fromJson(json);
    } catch (e, stack) {
      AppLogger.error('Failed to load campus overlay meta', e, stack);
      throw MapAssetsException('Failed to load campus overlay meta: $e');
    }
  }
}

final mapAssetsSourceProvider = Provider<MapAssetsSource>((ref) {
  return const MapAssetsSource();
});
