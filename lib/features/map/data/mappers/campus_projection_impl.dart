import 'package:latlong2/latlong.dart';
import 'package:mq_navigation/features/map/domain/entities/campus_overlay_meta.dart';
import 'package:mq_navigation/features/map/domain/entities/campus_point.dart';
import 'package:mq_navigation/features/map/domain/services/campus_projection.dart';

class CampusProjectionImpl implements CampusProjection {
  const CampusProjectionImpl(this.meta);

  @override
  final CampusOverlayMeta meta;

  @override
  CampusPoint gpsToPixel({
    required double latitude,
    required double longitude,
  }) {
    // 1. Try Affine Projection (High Accuracy)
    final affine = meta.gpsProjection?.affine;
    if (affine != null && affine.x.length == 3 && affine.y.length == 3) {
      final norm = affine.normalization;
      // Avoid division by zero in normalization
      final latRange = norm.maxLat - norm.minLat;
      final lngRange = norm.maxLng - norm.minLng;

      if (latRange != 0 && lngRange != 0) {
        final normLng = (longitude - norm.minLng) / lngRange;
        final normLat = (latitude - norm.minLat) / latRange;

        final x = affine.x[0] + affine.x[1] * normLng + affine.x[2] * normLat;
        final y = affine.y[0] + affine.y[1] * normLng + affine.y[2] * normLat;

        return CampusPoint(
          x: x
              .roundToDouble()
              .clamp(meta.pixelBounds.west, meta.pixelBounds.east)
              .toDouble(),
          y: y
              .roundToDouble()
              .clamp(meta.pixelBounds.south, meta.pixelBounds.north)
              .toDouble(),
        );
      }
    }

    // 2. Fallback to Linear Bounds Interpolation
    final latSpan = meta.gpsNorth - meta.gpsSouth;
    final lngSpan = meta.gpsEast - meta.gpsWest;

    // Safety check for zero-span (invalid metadata)
    if (latSpan == 0 || lngSpan == 0) {
      return CampusPoint(x: meta.pixelBounds.west, y: meta.pixelBounds.south);
    }

    final xNorm = (longitude - meta.gpsWest) / lngSpan;
    final yNorm = (meta.gpsNorth - latitude) / latSpan;

    return CampusPoint(
      x: (meta.pixelBounds.west + (xNorm * meta.pixelWidth))
          .clamp(meta.pixelBounds.west, meta.pixelBounds.east)
          .toDouble(),
      y: (meta.pixelBounds.south + (yNorm * meta.pixelHeight))
          .clamp(meta.pixelBounds.south, meta.pixelBounds.north)
          .toDouble(),
    );
  }

  @override
  LatLng gpsToMapPoint({required double latitude, required double longitude}) {
    return pixelToMapPoint(
      gpsToPixel(latitude: latitude, longitude: longitude),
    );
  }

  @override
  LatLng pixelToMapPoint(CampusPoint point) {
    return LatLng(
      meta.pixelYToMapLatitude(point.y),
      meta.pixelXToMapLongitude(point.x),
    );
  }

  @override
  LatLng buildingPixelToMapPoint(CampusPoint point) {
    return LatLng(
      meta.pixelYToMapLatitude(point.y),
      meta.pixelXToMapLongitude(point.x + meta.buildingPixelOffsetX),
    );
  }

  @override
  CampusPoint mapPointToPixel(LatLng point) {
    return CampusPoint(
      x: meta
          .mapLongitudeToPixelX(point.longitude)
          .clamp(meta.pixelBounds.west, meta.pixelBounds.east)
          .toDouble(),
      y: meta
          .mapLatitudeToPixelY(point.latitude)
          .clamp(meta.pixelBounds.south, meta.pixelBounds.north)
          .toDouble(),
    );
  }
}
