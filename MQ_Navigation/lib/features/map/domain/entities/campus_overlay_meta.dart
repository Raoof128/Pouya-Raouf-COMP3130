import 'dart:math' as math;

import 'package:flutter/foundation.dart';

@immutable
class CampusOverlayMeta {
  const CampusOverlayMeta({
    required this.imageAsset,
    required this.width,
    required this.height,
    required this.pixelBounds,
    required this.buildingPixelOffsetX,
    required this.gpsNorth,
    required this.gpsSouth,
    required this.gpsEast,
    required this.gpsWest,
    required this.initialFitPadding,
    required this.minZoomOffset,
    required this.maxZoom,
    this.gpsProjection,
  });

  final String imageAsset;
  final double width;
  final double height;
  final CampusPixelBounds pixelBounds;
  final double buildingPixelOffsetX;
  final double gpsNorth;
  final double gpsSouth;
  final double gpsEast;
  final double gpsWest;
  final double initialFitPadding;
  final double minZoomOffset;
  final double maxZoom;
  final CampusGpsProjection? gpsProjection;

  double get pixelWidth => pixelBounds.east - pixelBounds.west;

  double get pixelHeight => pixelBounds.north - pixelBounds.south;

  double get mapCoordinateScale =>
      math.max(1, math.max(pixelWidth / 170, pixelHeight / 85));

  double get mapSouth => 0;

  double get mapWest => 0;

  double get mapNorth => pixelHeight / mapCoordinateScale;

  double get mapEast => pixelWidth / mapCoordinateScale;

  double get centerLatitude => (mapNorth + mapSouth) / 2;

  double get centerLongitude => (mapEast + mapWest) / 2;

  double pixelXToMapLongitude(double x) {
    return (x - pixelBounds.west) / mapCoordinateScale;
  }

  double pixelYToMapLatitude(double y) {
    return (pixelBounds.north - y) / mapCoordinateScale;
  }

  double mapLongitudeToPixelX(double longitude) {
    return pixelBounds.west + (longitude * mapCoordinateScale);
  }

  double mapLatitudeToPixelY(double latitude) {
    return pixelBounds.north - (latitude * mapCoordinateScale);
  }

  factory CampusOverlayMeta.fromJson(Map<String, dynamic> json) {
    final gpsBounds = json['gpsBounds'] as Map<String, dynamic>? ?? const {};
    final pixelBounds =
        json['pixelBounds'] as Map<String, dynamic>? ??
        <String, dynamic>{
          'south': 0,
          'west': 0,
          'north': (json['height'] as num).toDouble(),
          'east': (json['width'] as num).toDouble(),
        };

    return CampusOverlayMeta(
      imageAsset: json['imageAsset'] as String,
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      pixelBounds: CampusPixelBounds.fromJson(pixelBounds),
      buildingPixelOffsetX:
          (json['buildingPixelOffsetX'] as num?)?.toDouble() ??
          (json['pixelOffsetX'] as num?)?.toDouble() ??
          0,
      gpsNorth: (gpsBounds['north'] as num).toDouble(),
      gpsSouth: (gpsBounds['south'] as num).toDouble(),
      gpsEast: (gpsBounds['east'] as num).toDouble(),
      gpsWest: (gpsBounds['west'] as num).toDouble(),
      initialFitPadding: (json['initialFitPadding'] as num?)?.toDouble() ?? 20,
      minZoomOffset: (json['minZoomOffset'] as num?)?.toDouble() ?? 1.5,
      maxZoom: (json['maxZoom'] as num?)?.toDouble() ?? 3,
      gpsProjection: switch (json['gpsProjection']) {
        final Map<String, dynamic> projectionJson =>
          CampusGpsProjection.fromJson(projectionJson),
        _ => null,
      },
    );
  }
}

@immutable
class CampusPixelBounds {
  const CampusPixelBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  factory CampusPixelBounds.fromJson(Map<String, dynamic> json) {
    return CampusPixelBounds(
      south: (json['south'] as num).toDouble(),
      west: (json['west'] as num).toDouble(),
      north: (json['north'] as num).toDouble(),
      east: (json['east'] as num).toDouble(),
    );
  }
}

@immutable
class CampusGpsProjection {
  const CampusGpsProjection({required this.method, this.affine});

  final String method;
  final CampusAffineProjection? affine;

  factory CampusGpsProjection.fromJson(Map<String, dynamic> json) {
    return CampusGpsProjection(
      method: (json['method'] as String?) ?? 'bounds_linear',
      affine: switch (json['affine']) {
        final Map<String, dynamic> affineJson =>
          CampusAffineProjection.fromJson(affineJson),
        _ => null,
      },
    );
  }
}

@immutable
class CampusAffineProjection {
  const CampusAffineProjection({
    required this.x,
    required this.y,
    required this.normalization,
  });

  final List<double> x;
  final List<double> y;
  final CampusAffineNormalization normalization;

  factory CampusAffineProjection.fromJson(Map<String, dynamic> json) {
    return CampusAffineProjection(
      x: (json['x'] as List<dynamic>)
          .cast<num>()
          .map((v) => v.toDouble())
          .toList(growable: false),
      y: (json['y'] as List<dynamic>)
          .cast<num>()
          .map((v) => v.toDouble())
          .toList(growable: false),
      normalization: CampusAffineNormalization.fromJson(
        json['normalization'] as Map<String, dynamic>,
      ),
    );
  }
}

@immutable
class CampusAffineNormalization {
  const CampusAffineNormalization({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  factory CampusAffineNormalization.fromJson(Map<String, dynamic> json) {
    return CampusAffineNormalization(
      minLat: (json['minLat'] as num).toDouble(),
      maxLat: (json['maxLat'] as num).toDouble(),
      minLng: (json['minLng'] as num).toDouble(),
      maxLng: (json['maxLng'] as num).toDouble(),
    );
  }
}
