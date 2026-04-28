import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'web_maps_key_stub.dart'
    if (dart.library.js_interop) 'web_maps_key.dart';
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/geo_utils.dart';
import 'package:mq_navigation/features/map/presentation/widgets/google/desktop_map_fallback_view.dart';
import 'package:mq_navigation/features/map/presentation/widgets/map_view_helpers.dart';

/// The native `google_maps_flutter` renderer.
///
/// Uses the Google Maps SDK to provide an alternative top-down vector map.
/// Manages its own internal `GoogleMapController` for programmatic camera
/// animations (like fitting route bounds or following the user's location)
/// while maintaining parity with the visual state of [CampusMapView].
class GoogleMapView extends StatefulWidget {
  const GoogleMapView({
    super.key,
    required this.searchResults,
    required this.searchQuery,
    required this.selectedBuilding,
    required this.route,
    required this.currentLocation,
    required this.locationCenterRequestToken,
    required this.isNavigating,
    required this.onSelectBuilding,
  });

  final List<Building> searchResults;
  final String searchQuery;
  final Building? selectedBuilding;
  final MapRoute? route;
  final LocationSample? currentLocation;
  final int locationCenterRequestToken;
  final bool isNavigating;
  final ValueChanged<Building> onSelectBuilding;

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> {
  GoogleMapController? _controller;
  bool _hasFitRouteBounds = false;

  @override
  void dispose() {
    if (!kIsWeb) {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.locationCenterRequestToken !=
        oldWidget.locationCenterRequestToken) {
      final location = widget.currentLocation;
      if (_controller != null && location != null) {
        _focusLocation(location);
      }
      return;
    }

    // Follow user during active navigation
    if (widget.isNavigating) {
      final newLocation = widget.currentLocation;
      final oldLocation = oldWidget.currentLocation;
      if (_controller != null &&
          newLocation != null &&
          (oldLocation == null ||
              newLocation.latitude != oldLocation.latitude ||
              newLocation.longitude != oldLocation.longitude)) {
        unawaited(
          _controller!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(newLocation.latitude, newLocation.longitude),
            ),
          ),
        );
        return;
      }
    }

    // Focus on newly selected building
    if (widget.selectedBuilding != null &&
        widget.selectedBuilding?.id != oldWidget.selectedBuilding?.id) {
      _hasFitRouteBounds = false;
      _focusBuilding(widget.selectedBuilding!);
      return;
    }

    // Fit route bounds when route first appears
    if (widget.route != null &&
        oldWidget.route == null &&
        !_hasFitRouteBounds) {
      _fitRouteBounds();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    // google_maps_flutter only supports Android, iOS, and Web.
    // On desktop platforms (macOS, Linux, Windows) show a fallback.
    final isGoogleMapsSupported =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (!isGoogleMapsSupported) {
      // On desktop platforms use flutter_map with OSM tiles as a fallback
      // so the "Google Maps" toggle still shows a real interactive map.
      return DesktopMapFallbackView(
        searchResults: widget.searchResults,
        searchQuery: widget.searchQuery,
        selectedBuilding: widget.selectedBuilding,
        route: widget.route,
        currentLocation: widget.currentLocation,
        locationCenterRequestToken: widget.locationCenterRequestToken,
        isNavigating: widget.isNavigating,
        onSelectBuilding: widget.onSelectBuilding,
      );
    }

    // On web, the Maps JS API key comes from google_maps_config.js (HTML-side).
    // On native, it comes from --dart-define via EnvConfig.
    // In both cases, fall back to the OSM renderer instead of crashing.
    final hasKey = kIsWeb
        ? hasWebGoogleMapsApiKey()
        : EnvConfig.hasGoogleMapsApiKey;
    if (!hasKey) {
      return DesktopMapFallbackView(
        searchResults: widget.searchResults,
        searchQuery: widget.searchQuery,
        selectedBuilding: widget.selectedBuilding,
        route: widget.route,
        currentLocation: widget.currentLocation,
        locationCenterRequestToken: widget.locationCenterRequestToken,
        isNavigating: widget.isNavigating,
        onSelectBuilding: widget.onSelectBuilding,
      );
    }

    final visibleBuildings = resolveVisibleBuildings(
      searchResults: widget.searchResults,
      searchQuery: widget.searchQuery,
      selectedBuilding: widget.selectedBuilding,
    );

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(-33.7738, 151.1130),
        zoom: 15.5,
      ),
      onMapCreated: (controller) {
        _controller = controller;
        _syncCameraToState();
      },
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      myLocationEnabled: widget.currentLocation != null,
      myLocationButtonEnabled: false,
      markers: {
        for (final building in visibleBuildings)
          if (resolveBuildingGeographicTarget(building) case final target?)
            Marker(
              markerId: MarkerId(building.id),
              position: LatLng(target.latitude, target.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                widget.selectedBuilding?.id == building.id
                    ? BitmapDescriptor.hueRed
                    : BitmapDescriptor.hueAzure,
              ),
              alpha: widget.selectedBuilding?.id == building.id ? 1.0 : 0.6,
              zIndexInt: widget.selectedBuilding?.id == building.id ? 1 : 0,
              infoWindow: InfoWindow(
                title: building.name,
                snippet: building.code,
              ),
              onTap: () => widget.onSelectBuilding(building),
            ),
        // Origin dot: green marker at route start
        if (widget.route != null)
          if (resolveRoutePoints(widget.route!).firstOrNull case final origin?)
            Marker(
              markerId: const MarkerId('route_origin'),
              position: LatLng(origin.latitude, origin.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              alpha: 0.85,
              zIndexInt: 0,
            ),
      },
      polylines: _buildPolylines(),
    );
  }

  Set<Polyline> _buildPolylines() {
    if (widget.route == null) {
      return const <Polyline>{};
    }

    final allPoints = resolveRoutePoints(widget.route!);
    if (allPoints.isEmpty) {
      return const <Polyline>{};
    }

    final isWalking = widget.route!.travelMode == TravelMode.walk;
    final routeColor = _colorFor(widget.route!.travelMode);
    final polylines = <Polyline>{};

    // During navigation: split into walked (dimmed) + remaining (colored)
    if (widget.isNavigating && widget.currentLocation != null) {
      final splitIdx = findClosestPointIndex(
        allPoints,
        widget.currentLocation!,
      );

      if (splitIdx > 0) {
        final walkedPoints = allPoints.sublist(0, splitIdx + 1);
        polylines.add(
          Polyline(
            polylineId: const PolylineId('walked'),
            points: walkedPoints
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList(),
            width: 5,
            color: const Color(0xFF94a3b8),
          ),
        );
      }

      final remainingPoints = splitIdx > 0
          ? allPoints.sublist(splitIdx)
          : allPoints;
      polylines.add(
        Polyline(
          polylineId: const PolylineId('remaining'),
          points: remainingPoints
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList(),
          width: 5,
          color: routeColor,
          patterns: isWalking
              ? [PatternItem.dash(20), PatternItem.gap(10)]
              : const [],
        ),
      );
    } else {
      // Not navigating: single route polyline
      polylines.add(
        Polyline(
          polylineId: const PolylineId('shared_route'),
          points: allPoints
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList(),
          width: 5,
          color: routeColor,
          patterns: isWalking
              ? [PatternItem.dash(20), PatternItem.gap(10)]
              : const [],
        ),
      );
    }

    return polylines;
  }

  void _syncCameraToState() {
    final selectedBuilding = widget.selectedBuilding;
    if (selectedBuilding != null) {
      _focusBuilding(selectedBuilding, animate: false);
      return;
    }

    final currentLocation = widget.currentLocation;
    if (currentLocation != null) {
      _focusLocation(currentLocation, animate: false);
    }
  }

  void _focusBuilding(Building building, {bool animate = true}) {
    final target = resolveBuildingGeographicTarget(building);
    if (_controller == null || target == null) {
      return;
    }

    final update = CameraUpdate.newLatLngZoom(
      LatLng(target.latitude, target.longitude),
      17,
    );
    if (animate) {
      unawaited(_controller!.animateCamera(update));
      return;
    }

    unawaited(_controller!.moveCamera(update));
  }

  void _focusLocation(LocationSample location, {bool animate = true}) {
    if (_controller == null) {
      return;
    }

    final update = CameraUpdate.newLatLng(
      LatLng(location.latitude, location.longitude),
    );
    if (animate) {
      unawaited(_controller!.animateCamera(update));
      return;
    }

    unawaited(_controller!.moveCamera(update));
  }

  void _fitRouteBounds() {
    if (_controller == null || widget.route == null) {
      return;
    }
    final points = resolveRoutePoints(widget.route!);
    if (points.isEmpty) {
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    if (widget.currentLocation != null) {
      final loc = widget.currentLocation!;
      if (loc.latitude < minLat) minLat = loc.latitude;
      if (loc.latitude > maxLat) maxLat = loc.latitude;
      if (loc.longitude < minLng) minLng = loc.longitude;
      if (loc.longitude > maxLng) maxLng = loc.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _hasFitRouteBounds = true;
    unawaited(
      _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80)),
    );
  }

  Color _colorFor(TravelMode travelMode) {
    return switch (travelMode) {
      TravelMode.walk => const Color(0xFF4285F4),
      TravelMode.drive => const Color(0xFF6C757D),
      TravelMode.bike => const Color(0xFF2E8B57),
      TravelMode.transit => const Color(0xFFF57C00),
    };
  }
}
