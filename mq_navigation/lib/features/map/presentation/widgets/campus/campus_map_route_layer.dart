import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/geo_utils.dart';

/// Renders the route polyline on the campus map.
///
/// When navigating, the traversed portion is drawn in grey while the
/// remaining portion keeps the travel-mode colour.
class CampusMapRouteLayer extends StatelessWidget {
  const CampusMapRouteLayer({
    super.key,
    required this.route,
    required this.routePoints,
    required this.rawRoutePoints,
    required this.isNavigating,
    required this.currentLocation,
  });

  final MapRoute route;
  final List<latlong.LatLng> routePoints;
  final List<LocationSample> rawRoutePoints;
  final bool isNavigating;
  final LocationSample? currentLocation;

  @override
  Widget build(BuildContext context) {
    if (routePoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return PolylineLayer(
      polylines: _buildCampusPolylines(routePoints, rawRoutePoints),
    );
  }

  List<Polyline> _buildCampusPolylines(
    List<latlong.LatLng> mapPoints,
    List<LocationSample> rawPoints,
  ) {
    final routeColor = _colorFor(route.travelMode);
    final isWalking = route.travelMode == TravelMode.walk;
    final StrokePattern pattern = isWalking
        ? StrokePattern.dashed(segments: const [12, 8])
        : const StrokePattern.solid();
    final polylines = <Polyline>[];

    if (isNavigating && currentLocation != null && rawPoints.length > 1) {
      final splitIdx = findClosestPointIndex(rawPoints, currentLocation!);

      if (splitIdx > 0) {
        polylines.add(
          Polyline(
            points: mapPoints.sublist(0, splitIdx + 1),
            strokeWidth: 5,
            color: const Color(0xFF94a3b8),
            borderStrokeWidth: 2,
            borderColor: Colors.white.withValues(alpha: 0.25),
            pattern: pattern,
          ),
        );
      }

      final remaining = splitIdx > 0 ? mapPoints.sublist(splitIdx) : mapPoints;
      polylines.add(
        Polyline(
          points: remaining,
          strokeWidth: 5,
          color: routeColor,
          borderStrokeWidth: 2,
          borderColor: Colors.white.withValues(alpha: 0.45),
          pattern: pattern,
        ),
      );
    } else {
      polylines.add(
        Polyline(
          points: mapPoints,
          strokeWidth: 5,
          color: routeColor,
          borderStrokeWidth: 2,
          borderColor: Colors.white.withValues(alpha: 0.45),
          pattern: pattern,
        ),
      );
    }

    return polylines;
  }

  static Color _colorFor(TravelMode travelMode) {
    return switch (travelMode) {
      TravelMode.walk => MqColors.red,
      TravelMode.drive => const Color(0xFF6C757D),
      TravelMode.bike => const Color(0xFF2E8B57),
      TravelMode.transit => const Color(0xFFF57C00),
    };
  }
}
