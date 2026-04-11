import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/campus_projection.dart';

/// Renders the current-location dot, GPS accuracy circle, and route origin dot.
class CampusMapLocationLayer extends StatelessWidget {
  const CampusMapLocationLayer({
    super.key,
    required this.currentLocation,
    required this.projection,
    required this.route,
    required this.routePoints,
  });

  final LocationSample? currentLocation;
  final CampusProjection projection;
  final MapRoute? route;
  final List<latlong.LatLng> routePoints;

  /// Maximum accuracy-circle size in map coordinate units to keep the UI
  /// readable when GPS accuracy is very low.
  static const double _maxAccuracyMapUnits = 200;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];
    final meta = projection.meta;

    // ── Accuracy circle ───────────────────────────────────────
    if (currentLocation case final loc?) {
      final accuracyMetres = loc.accuracy;
      if (accuracyMetres != null && accuracyMetres > 0) {
        // Convert GPS accuracy (metres) to pixel distance.
        // 1 degree longitude ≈ 111,320m × cos(latitude) at MQ's latitude.
        final cosLat = math.cos(loc.latitude * math.pi / 180);
        final gpsLongitudeSpanMetres =
            (meta.gpsEast - meta.gpsWest) * 111320 * cosLat;
        final accuracyPixels =
            accuracyMetres * (meta.pixelWidth / gpsLongitudeSpanMetres);
        final accuracyMapUnits = math.min(
          accuracyPixels / meta.mapCoordinateScale,
          _maxAccuracyMapUnits,
        );
        final diameter = accuracyMapUnits * 2;

        markers.add(
          Marker(
            point: projection.gpsToMapPoint(
              latitude: loc.latitude,
              longitude: loc.longitude,
            ),
            width: diameter,
            height: diameter,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MqColors.mapUserLocation.withValues(alpha: 0.12),
                border: Border.all(
                  color: MqColors.mapUserLocation.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
        );
      }

      // ── User location dot ─────────────────────────────────
      markers.add(
        Marker(
          point: projection.gpsToMapPoint(
            latitude: loc.latitude,
            longitude: loc.longitude,
          ),
          width: 28,
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MqColors.mapUserLocation,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: MqColors.mapUserLocation.withValues(alpha: 0.4),
                  blurRadius: 14,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Origin dot (first point of route polyline) ──────────
    if (route != null && routePoints.isNotEmpty) {
      markers.add(
        Marker(
          point: routePoints.first,
          width: 18,
          height: 18,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2E8B57),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E8B57).withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (markers.isEmpty) {
      return const SizedBox.shrink();
    }

    return MarkerLayer(markers: markers);
  }
}
