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
    final affine = meta.gpsProjection?.affine;
    if (affine != null && affine.x.length == 3 && affine.y.length == 3) {
      final minLat = affine.normalization.minLat;
      final maxLat = affine.normalization.maxLat;
      final minLng = affine.normalization.minLng;
      final maxLng = affine.normalization.maxLng;
      final normLng = (longitude - minLng) / (maxLng - minLng);
      final normLat = (latitude - minLat) / (maxLat - minLat);

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

    final xNorm = (longitude - meta.gpsWest) / (meta.gpsEast - meta.gpsWest);
    final yNorm = (meta.gpsNorth - latitude) / (meta.gpsNorth - meta.gpsSouth);

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
