import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/geo_utils.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';

/// Renders the route polyline on the campus map.
///
/// When navigating, the traversed portion is drawn in grey while the
/// remaining portion keeps the travel-mode colour.
class CampusMapRouteLayer extends ConsumerWidget {
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

  static const Color _traversedColor = MqColors.slate400;
  static const double _strokeWidth = 5.0;
  static const double _highContrastStrokeWidth = 8.0;
  static const double _borderWidth = 2.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (routePoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final highContrast =
        ref.watch(settingsControllerProvider).value?.highContrastMap ?? false;

    return PolylineLayer(
      polylines: _buildCampusPolylines(
        routePoints,
        rawRoutePoints,
        highContrast,
      ),
    );
  }

  List<Polyline> _buildCampusPolylines(
    List<latlong.LatLng> mapPoints,
    List<LocationSample> rawPoints,
    bool highContrast,
  ) {
    final routeColor = _colorFor(route.travelMode, highContrast);
    final isWalking = route.travelMode == TravelMode.walk;
    final strokeWidth = highContrast ? _highContrastStrokeWidth : _strokeWidth;

    StrokePattern pattern = isWalking
        ? StrokePattern.dashed(segments: const [12, 8])
        : const StrokePattern.solid();

    if (highContrast && !isWalking) {
      // For high contrast non-walking, use a more distinct solid style
      pattern = const StrokePattern.solid();
    } else if (highContrast && isWalking) {
      // For high contrast walking, use thicker dashes
      pattern = StrokePattern.dashed(segments: const [16, 10]);
    }

    final borderColor = highContrast
        ? Colors.black.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.45);

    // If not navigating or no location, return single full polyline
    if (!isNavigating || currentLocation == null || rawPoints.length <= 1) {
      return [
        Polyline(
          points: mapPoints,
          strokeWidth: strokeWidth,
          color: routeColor,
          borderStrokeWidth: _borderWidth,
          borderColor: borderColor,
          pattern: pattern,
        ),
      ];
    }

    final splitIdx = findClosestPointIndex(rawPoints, currentLocation!);
    final polylines = <Polyline>[];

    // Traversed segment (Grey)
    if (splitIdx > 0) {
      polylines.add(
        Polyline(
          points: mapPoints.sublist(0, splitIdx + 1),
          strokeWidth: strokeWidth,
          color: highContrast ? MqColors.slate600 : _traversedColor,
          borderStrokeWidth: _borderWidth,
          borderColor: highContrast
              ? Colors.black.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.25),
          pattern: pattern,
        ),
      );
    }

    // Remaining segment (Colored)
    final remaining = splitIdx > 0 ? mapPoints.sublist(splitIdx) : mapPoints;
    if (remaining.isNotEmpty) {
      polylines.add(
        Polyline(
          points: remaining,
          strokeWidth: strokeWidth,
          color: routeColor,
          borderStrokeWidth: _borderWidth,
          borderColor: borderColor,
          pattern: pattern,
        ),
      );
    }

    return polylines;
  }

  static Color _colorFor(TravelMode travelMode, bool highContrast) {
    if (highContrast) {
      return switch (travelMode) {
        TravelMode.walk => Colors.yellowAccent,
        TravelMode.drive => Colors.white,
        TravelMode.bike => Colors.cyanAccent,
        TravelMode.transit => Colors.orangeAccent,
      };
    }
    return switch (travelMode) {
      TravelMode.walk => MqColors.red,
      TravelMode.drive => MqColors.charcoal600,
      TravelMode.bike => MqColors.success,
      TravelMode.transit => MqColors.warning,
    };
  }
}
