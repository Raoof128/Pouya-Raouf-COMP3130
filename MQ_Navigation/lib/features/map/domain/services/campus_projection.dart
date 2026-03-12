import 'package:latlong2/latlong.dart';
import 'package:mq_navigation/features/map/domain/entities/campus_overlay_meta.dart';
import 'package:mq_navigation/features/map/domain/entities/campus_point.dart';

abstract interface class CampusProjection {
  CampusOverlayMeta get meta;

  CampusPoint gpsToPixel({required double latitude, required double longitude});

  LatLng gpsToMapPoint({required double latitude, required double longitude});

  LatLng pixelToMapPoint(CampusPoint point);

  LatLng buildingPixelToMapPoint(CampusPoint point);

  CampusPoint mapPointToPixel(LatLng point);
}
