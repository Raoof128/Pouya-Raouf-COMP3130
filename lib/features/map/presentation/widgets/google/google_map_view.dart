import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/geo_utils.dart';
import 'package:mq_navigation/features/map/presentation/widgets/google/desktop_map_fallback_view.dart';
import 'package:mq_navigation/features/map/presentation/widgets/map_view_helpers.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'web_maps_key_stub.dart'
    if (dart.library.js_interop) 'web_maps_key.dart';

/// The native `google_maps_flutter` renderer.
///
/// Uses the Google Maps SDK to provide an alternative top-down vector map.
/// Manages its own internal `GoogleMapController` for programmatic camera
/// animations (like fitting route bounds or following the user's location)
/// while maintaining parity with the visual state of [CampusMapView].
class GoogleMapView extends ConsumerStatefulWidget {
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
  ConsumerState<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends ConsumerState<GoogleMapView> {
  GoogleMapController? _controller;
  bool _hasFitRouteBounds = false;
  DateTime? _lastNavigationCameraUpdateAt;
  LocationSample? _lastNavigationCameraLocation;

  bool _trafficEnabled = false;
  MapType _mapType = MapType.normal;

  /// Camera zoom used when the user presses the "locate me" button.
  /// Must be high enough that pressing the button while already centred
  /// on the same lat/lng still produces a visible camera change — the
  /// previous implementation called `newLatLng` (no zoom) which silently
  /// no-ops when the target hasn't moved.
  static const double _locateZoom = 17;

  /// Camera zoom held during active navigation. Tighter than the
  /// locate-me zoom so the user feels they are following the route.
  static const double _navigationFollowZoom = 18;
  static const Duration _navigationCameraMinInterval = Duration(
    milliseconds: 900,
  );
  static const double _navigationCameraMinMoveMetres = 3;

  /// Mirrors [MapShell] reserved band above safe inset + route panel estimate.
  static const double _bottomControlsReservedHeight = 80;
  static const double _routePanelEstimateHeight = 210;

  static const int _strokeWidthPx = 5;
  static const int _highContrastStrokeWidthPx = 8;
  static const double _navigationTiltDegrees = 32;

  @override
  void dispose() {
    if (!kIsWeb) {
      _controller?.dispose();
    }
    super.dispose();
  }

  double _routeFitPadding(MediaQueryData mq) {
    final pad = mq.padding;
    const overlayTop = 110.0;
    final verticalTop = pad.top + overlayTop;
    final verticalBottom =
        pad.bottom + _bottomControlsReservedHeight + _routePanelEstimateHeight;
    final horizontal = max(pad.left, pad.right) + 20;
    return max(80.0, max(horizontal, max(verticalTop, verticalBottom)));
  }

  Set<Marker> _buildingMarkers() {
    final visible = resolveVisibleBuildings(
      searchResults: widget.searchResults,
      searchQuery: widget.searchQuery,
      selectedBuilding: widget.selectedBuilding,
    );
    return {
      for (final building in visible)
        if (resolveBuildingGeographicTarget(building) case final target?)
          Marker(
            markerId: MarkerId(building.id),
            position: LatLng(target.latitude, target.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            alpha: widget.selectedBuilding?.id == building.id ? 1.0 : 0.85,
            zIndexInt: widget.selectedBuilding?.id == building.id ? 1 : 0,
            infoWindow: InfoWindow(
              title: building.name,
              snippet: building.code,
            ),
            onTap: () => widget.onSelectBuilding(building),
          ),
    };
  }

  Set<Marker> _routeMarkers() {
    final route = widget.route;
    if (route == null) {
      return const {};
    }
    final points = resolveRoutePoints(route);
    if (points.isEmpty) {
      return const {};
    }
    final origin = points.first;
    final destination = points.last;
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('route_origin'),
        position: LatLng(origin.latitude, origin.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        alpha: 0.85,
        zIndexInt: 0,
      ),
    };
    if (points.length > 1 &&
        (origin.latitude != destination.latitude ||
            origin.longitude != destination.longitude)) {
      markers.add(
        Marker(
          markerId: const MarkerId('route_destination'),
          position: LatLng(destination.latitude, destination.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          alpha: 0.95,
          zIndexInt: 1,
          infoWindow: InfoWindow(title: widget.selectedBuilding?.name ?? ''),
        ),
      );
    }
    return markers;
  }

  int _bearingLookaheadIndex(
    List<LocationSample> points,
    LocationSample current,
    int closestIdx,
  ) {
    const minMetres = 12.0;
    for (var i = closestIdx + 1; i < points.length; i++) {
      final d = haversineMetres(
        lat1: current.latitude,
        lng1: current.longitude,
        lat2: points[i].latitude,
        lng2: points[i].longitude,
      );
      if (d >= minMetres) {
        return i;
      }
    }
    return closestIdx < points.length - 1 ? closestIdx + 1 : closestIdx;
  }

  void _animateNavigationCamera(
    LocationSample location,
    List<LocationSample> points,
  ) {
    final ctrl = _controller;
    if (ctrl == null || points.length < 2) {
      return;
    }
    final closestIdx = findClosestPointIndex(points, location);
    final targetIdx = _bearingLookaheadIndex(points, location, closestIdx);
    final targetPoint = points[targetIdx];
    final bearing = bearingDegreesBetween(
      lat1: location.latitude,
      lng1: location.longitude,
      lat2: targetPoint.latitude,
      lng2: targetPoint.longitude,
    );

    unawaited(
      ctrl.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(location.latitude, location.longitude),
            zoom: _navigationFollowZoom,
            bearing: bearing,
            tilt: _navigationTiltDegrees,
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant GoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.locationCenterRequestToken !=
        oldWidget.locationCenterRequestToken) {
      final location = widget.currentLocation;
      if (_controller != null && location != null) {
        unawaited(
          _controller!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(location.latitude, location.longitude),
                zoom: _locateZoom,
                bearing: 0,
                tilt: 0,
              ),
            ),
          ),
        );
      }
      return;
    }

    if (widget.isNavigating) {
      final newLocation = widget.currentLocation;
      final oldLocation = oldWidget.currentLocation;
      final justStartedNavigating =
          widget.isNavigating && !oldWidget.isNavigating;
      final movedSinceLastTick =
          newLocation != null &&
          (oldLocation == null ||
              newLocation.latitude != oldLocation.latitude ||
              newLocation.longitude != oldLocation.longitude);
      final routePoints = widget.route != null
          ? resolveRoutePoints(widget.route!)
          : const <LocationSample>[];

      if (_controller != null &&
          newLocation != null &&
          routePoints.length >= 2 &&
          (justStartedNavigating || movedSinceLastTick) &&
          _shouldFollowNavigationCamera(
            location: newLocation,
            force: justStartedNavigating,
          )) {
        _animateNavigationCamera(newLocation, routePoints);
        _lastNavigationCameraUpdateAt = DateTime.now();
        _lastNavigationCameraLocation = newLocation;
        return;
      }
    } else if (oldWidget.isNavigating && !widget.isNavigating) {
      _lastNavigationCameraUpdateAt = null;
      _lastNavigationCameraLocation = null;
    }

    if (widget.selectedBuilding != null &&
        widget.selectedBuilding?.id != oldWidget.selectedBuilding?.id) {
      _hasFitRouteBounds = false;
      _focusBuilding(widget.selectedBuilding!);
      return;
    }

    if (widget.route != null &&
        oldWidget.route == null &&
        !_hasFitRouteBounds) {
      _fitRouteBounds();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGoogleMapsSupported =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (!isGoogleMapsSupported) {
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

    final highContrast =
        ref.watch(settingsControllerProvider).value?.highContrastMap ?? false;
    final mq = MediaQuery.of(context);
    final l10n = AppLocalizations.of(context)!;

    final routeMarkers = _routeMarkers();
    final allMarkers = <Marker>{..._buildingMarkers(), ...routeMarkers};

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(-33.77388, 151.11275),
            zoom: 15.5,
          ),
          mapType: _mapType,
          trafficEnabled: _trafficEnabled,
          onMapCreated: (controller) {
            _controller = controller;
            _syncCameraToState();
          },
          webCameraControlPosition: WebCameraControlPosition.rightCenter,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          myLocationEnabled: widget.currentLocation != null,
          myLocationButtonEnabled: false,
          indoorViewEnabled: false,
          buildingsEnabled: false,
          markers: allMarkers,
          polylines: _buildPolylines(highContrast),
        ),
        PositionedDirectional(
          top: mq.padding.top + 168,
          end: MqSpacing.space4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Semantics(
                toggled: _trafficEnabled,
                label: l10n.googleMapTrafficLayer,
                button: true,
                child: FilterChip(
                  label: Text(l10n.googleMapTrafficLayer),
                  selected: _trafficEnabled,
                  onSelected: (v) => setState(() => _trafficEnabled = v),
                  avatar: Icon(
                    Icons.traffic,
                    size: 18,
                    color: _trafficEnabled ? Colors.white : MqColors.red,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              PopupMenuButton<MapType>(
                tooltip: l10n.googleMapChooseMapType,
                icon: const Icon(Icons.layers_outlined),
                onSelected: (mode) => setState(() => _mapType = mode),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: MapType.normal,
                    child: Text(l10n.googleMapTypeNormal),
                  ),
                  PopupMenuItem(
                    value: MapType.satellite,
                    child: Text(l10n.googleMapTypeSatellite),
                  ),
                  PopupMenuItem(
                    value: MapType.hybrid,
                    child: Text(l10n.googleMapTypeHybrid),
                  ),
                  PopupMenuItem(
                    value: MapType.terrain,
                    child: Text(l10n.googleMapTypeTerrain),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Set<Polyline> _buildPolylines(bool highContrast) {
    if (widget.route == null) {
      return const <Polyline>{};
    }

    final allPoints = resolveRoutePoints(widget.route!);
    if (allPoints.isEmpty) {
      return const <Polyline>{};
    }

    final isWalking = widget.route!.travelMode == TravelMode.walk;
    final routeColor = _polylineColorFor(
      widget.route!.travelMode,
      highContrast,
    );
    final walkedColor = highContrast ? MqColors.slate600 : MqColors.slate400;
    final strokeWidthPx = highContrast
        ? _highContrastStrokeWidthPx
        : _strokeWidthPx;
    final polylines = <Polyline>{};

    List<PatternItem> dashPattern() {
      if (!isWalking) {
        return const [];
      }
      if (highContrast) {
        return [PatternItem.dash(16), PatternItem.gap(10)];
      }
      return [PatternItem.dash(20), PatternItem.gap(10)];
    }

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
            width: strokeWidthPx,
            color: walkedColor,
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
          width: strokeWidthPx,
          color: routeColor,
          patterns: dashPattern(),
        ),
      );
    } else {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('shared_route'),
          points: allPoints
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList(),
          width: strokeWidthPx,
          color: routeColor,
          patterns: dashPattern(),
        ),
      );
    }

    return polylines;
  }

  Color _polylineColorFor(TravelMode travelMode, bool highContrast) {
    if (highContrast) {
      return switch (travelMode) {
        TravelMode.walk => Colors.yellowAccent,
        TravelMode.drive => Colors.white,
        TravelMode.bike => Colors.cyanAccent,
        TravelMode.transit => Colors.orangeAccent,
      };
    }
    return switch (travelMode) {
      TravelMode.walk => MqColors.mapRouteActive,
      TravelMode.drive => MqColors.charcoal600,
      TravelMode.bike => MqColors.success,
      TravelMode.transit => MqColors.warning,
    };
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

    final update = CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(location.latitude, location.longitude),
        zoom: _locateZoom,
        bearing: 0,
        tilt: 0,
      ),
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
    final pad = _routeFitPadding(MediaQuery.of(context));
    unawaited(
      _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, pad)),
    );
  }

  bool _shouldFollowNavigationCamera({
    required LocationSample location,
    required bool force,
  }) {
    if (force) {
      return true;
    }
    final now = DateTime.now();
    final lastAt = _lastNavigationCameraUpdateAt;
    if (lastAt != null &&
        now.difference(lastAt) < _navigationCameraMinInterval) {
      return false;
    }
    final lastLocation = _lastNavigationCameraLocation;
    if (lastLocation == null) {
      return true;
    }
    final movedMetres = haversineMetres(
      lat1: lastLocation.latitude,
      lng1: lastLocation.longitude,
      lat2: location.latitude,
      lng2: location.longitude,
    );
    return movedMetres >= _navigationCameraMinMoveMetres;
  }
}
