import 'dart:math';

import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';

/// Calculates the shortest distance over the earth's surface between two points.
///
/// Used extensively in navigation to detect arrival, off-route deviations,
/// and splitting walked vs remaining route segments.
///
/// **Performance Note**: This involves trigonometric functions (sin, cos, atan2, sqrt).
/// Avoid calling this in tight loops on the UI thread for large datasets.
double haversineMetres({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const r = 6371000.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  final sinLat = sin(dLat / 2);
  final sinLng = sin(dLng / 2);
  final h =
      sinLat * sinLat +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sinLng * sinLng;
  return r * 2 * atan2(sqrt(h), sqrt(1 - h));
}

double _toRadians(double degrees) => degrees * pi / 180;

/// Bearing from point 1 toward point 2 in degrees clockwise from north `[0, 360)`.
double bearingDegreesBetween({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  final phi1 = _toRadians(lat1);
  final phi2 = _toRadians(lat2);
  final dLng = _toRadians(lng2 - lng1);
  final y = sin(dLng) * cos(phi2);
  final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLng);
  final radians = atan2(y, x);
  final degreesOut = radians * 180 / pi;
  return (degreesOut + 360) % 360;
}

/// Returns the index of the point in [points] closest to [location].
///
/// **Complexity**: O(N).
/// **Performance Warning**: Iterates through all points. Use with caution on large lists
/// inside `build()` methods. Consider memoization or running in an isolate for
/// lists > 1000 items.
int findClosestPointIndex(
  List<LocationSample> points,
  LocationSample location,
) {
  var closestIdx = 0;
  var minDist = double.infinity;
  for (var i = 0; i < points.length; i++) {
    final dist = haversineMetres(
      lat1: location.latitude,
      lng1: location.longitude,
      lat2: points[i].latitude,
      lng2: points[i].longitude,
    );
    if (dist < minDist) {
      minDist = dist;
      closestIdx = i;
    }
  }
  return closestIdx;
}
