import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/map/data/datasources/location_source.dart';
import 'package:mq_navigation/features/map/data/repositories/map_repository_impl.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/building_search.dart';
import 'package:mq_navigation/features/map/domain/services/geo_utils.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:url_launcher/url_launcher.dart';

enum MapStateError {
  routeUnavailable,
  locationServicesDisabled,
  locationPermissionBlocked,
  locationPermissionRequired,
  locationUnsupported,
  locationUnavailable,
}

@immutable
class MapState {
  const MapState({
    required this.buildings,
    required this.searchResults,
    this.selectedBuilding,
    this.currentLocation,
    this.route,
    this.searchQuery = '',
    this.renderer = MapRendererType.campus,
    this.travelMode = TravelMode.walk,
    this.permissionState = LocationPermissionState.denied,
    this.isNavigating = false,
    this.isLoadingRoute = false,
    this.hasArrived = false,
    this.activeOverlayIds = const {},
    this.error,
  });

  final MapRendererType renderer;
  final List<Building> buildings;
  final List<Building> searchResults;
  final Building? selectedBuilding;
  final LocationSample? currentLocation;
  final MapRoute? route;
  final String searchQuery;
  final TravelMode travelMode;
  final LocationPermissionState permissionState;
  final bool isNavigating;
  final bool isLoadingRoute;
  final bool hasArrived;
  final Set<String> activeOverlayIds;
  final MapStateError? error;

  MapState copyWith({
    MapRendererType? renderer,
    List<Building>? buildings,
    List<Building>? searchResults,
    Building? selectedBuilding,
    bool clearSelectedBuilding = false,
    LocationSample? currentLocation,
    bool clearCurrentLocation = false,
    MapRoute? route,
    bool clearRoute = false,
    String? searchQuery,
    TravelMode? travelMode,
    LocationPermissionState? permissionState,
    bool? isNavigating,
    bool? isLoadingRoute,
    bool? hasArrived,
    Set<String>? activeOverlayIds,
    MapStateError? error,
    bool clearError = false,
  }) {
    return MapState(
      renderer: renderer ?? this.renderer,
      buildings: buildings ?? this.buildings,
      searchResults: searchResults ?? this.searchResults,
      selectedBuilding: clearSelectedBuilding
          ? null
          : selectedBuilding ?? this.selectedBuilding,
      currentLocation: clearCurrentLocation
          ? null
          : currentLocation ?? this.currentLocation,
      route: clearRoute ? null : route ?? this.route,
      searchQuery: searchQuery ?? this.searchQuery,
      travelMode: travelMode ?? this.travelMode,
      permissionState: permissionState ?? this.permissionState,
      isNavigating: isNavigating ?? this.isNavigating,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      hasArrived: hasArrived ?? this.hasArrived,
      activeOverlayIds: activeOverlayIds ?? this.activeOverlayIds,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MapState &&
        other.renderer == renderer &&
        listEquals(other.buildings, buildings) &&
        listEquals(other.searchResults, searchResults) &&
        other.selectedBuilding == selectedBuilding &&
        other.currentLocation == currentLocation &&
        other.route == route &&
        other.searchQuery == searchQuery &&
        other.travelMode == travelMode &&
        other.permissionState == permissionState &&
        other.isNavigating == isNavigating &&
        other.isLoadingRoute == isLoadingRoute &&
        other.hasArrived == hasArrived &&
        setEquals(other.activeOverlayIds, activeOverlayIds) &&
        other.error == error;
  }

  @override
  int get hashCode {
    return renderer.hashCode ^
        buildings.hashCode ^
        searchResults.hashCode ^
        selectedBuilding.hashCode ^
        currentLocation.hashCode ^
        route.hashCode ^
        searchQuery.hashCode ^
        travelMode.hashCode ^
        permissionState.hashCode ^
        isNavigating.hashCode ^
        isLoadingRoute.hashCode ^
        hasArrived.hashCode ^
        activeOverlayIds.hashCode ^
        error.hashCode;
  }
}

final mapControllerProvider = AsyncNotifierProvider<MapController, MapState>(
  MapController.new,
);

/// Central state controller for the Map feature.
///
/// This controller bridges the presentation layer and the map repository.
/// It holds the unified state for both map renderers (Google and Campus),
/// managing building selection, search results, routing, and live navigation.
///
/// It uses a versioning system (`_routeRequestVersion`) to drop stale async
/// route responses if the user changes their selection or renderer mid-flight.
class MapController extends AsyncNotifier<MapState> {
  static const _defaultVisibleBuildings = 15;
  static const _arrivalThresholdMetres = 30.0;
  static const _recalcThresholdMetres = 80.0;
  static const _offRouteThresholdMetres = 50.0;

  StreamSubscription<LocationSample>? _locationSubscription;
  int _routeRequestVersion = 0;
  LocationSample? _lastRouteFetchLocation;

  @override
  Future<MapState> build() async {
    ref.onDispose(() => _locationSubscription?.cancel());
    final buildings = await ref.read(mapRepositoryProvider).getBuildings();

    // Load defaults from user preferences
    final prefs = await ref.watch(settingsControllerProvider.future);

    return MapState(
      renderer: prefs.defaultRenderer,
      buildings: buildings,
      searchResults: searchCampusBuildings(
        buildings,
        '',
      ).take(_defaultVisibleBuildings).toList(),
      travelMode: prefs.defaultTravelMode,
      permissionState: LocationPermissionState.denied,
    );
  }

  void updateSearchQuery(String query) {
    final current = state.value;
    if (current == null) {
      return;
    }

    final normalized = normalizeMapSearch(query);
    final rankedBuildings = searchCampusBuildings(
      current.buildings,
      normalized,
    );
    // When a query is present, drop non-matches (score == 0). `searchCampusBuildings`
    // is a ranker, not a filter — it returns every building sorted by score — so
    // category chips like "library" or "parking" would otherwise show all 153
    // buildings regardless of match.
    final searchResults = normalized.isEmpty
        ? rankedBuildings.take(_defaultVisibleBuildings).toList()
        : rankedBuildings
              .where((b) => scoreBuildingMatch(b, normalized) > 0)
              .toList();

    final exactMatch = searchResults.where((building) {
      return isStrongCampusMatch(building, normalized);
    }).toList();
    final shouldAutoSelect =
        exactMatch.length == 1 && searchResults.length == 1;
    final nextSelectedBuilding = shouldAutoSelect ? exactMatch.first : null;
    final selectionChanged =
        nextSelectedBuilding?.id != current.selectedBuilding?.id;

    if (selectionChanged) {
      _invalidateRouteRequest();
    }

    state = AsyncData(
      current.copyWith(
        searchQuery: query,
        searchResults: searchResults,
        // Only auto-select when there is exactly one strong match
        // (e.g. user typed an exact building name/id).
        // Category searches like "food" or "parking" should NOT auto-select
        // — they show all matching buildings as markers instead.
        selectedBuilding: nextSelectedBuilding,
        clearSelectedBuilding: !shouldAutoSelect,
        clearRoute: selectionChanged && current.route != null,
        isNavigating: selectionChanged ? false : current.isNavigating,
        isLoadingRoute: selectionChanged ? false : current.isLoadingRoute,
        clearError: true,
      ),
    );
  }

  void selectBuilding(Building building) {
    final current = state.value;
    if (current == null) {
      return;
    }
    _invalidateRouteRequest();
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _lastRouteFetchLocation = null;
    state = AsyncData(
      current.copyWith(
        selectedBuilding: building,
        clearRoute: true,
        isNavigating: false,
        hasArrived: false,
        isLoadingRoute: false,
        clearError: true,
      ),
    );
  }

  void selectBuildingById(String buildingId) {
    final current = state.value;
    if (current == null) {
      return;
    }
    final building = current.buildings
        .where((item) => item.id == buildingId)
        .firstOrNull;
    if (building != null) {
      selectBuilding(building);
    }
  }

  Future<void> loadRoute() async {
    final current = state.value;
    if (current?.selectedBuilding == null) {
      return;
    }
    final requestId = _beginRouteRequest();
    final selectedBuildingId = current!.selectedBuilding!.id;
    final renderer = current.renderer;
    final travelMode = current.travelMode;

    state = AsyncData(current.copyWith(isLoadingRoute: true, clearError: true));

    final permissionState = await ref
        .read(mapRepositoryProvider)
        .ensureLocationPermission();

    // Get location — may be real GPS or campus-center fallback.
    final location = await ref.read(mapRepositoryProvider).getCurrentLocation();
    if (!_isRouteRequestCurrent(
      requestId,
      selectedBuildingId: selectedBuildingId,
      renderer: renderer,
      travelMode: travelMode,
    )) {
      return;
    }
    if (location == null) {
      final latest = state.value;
      if (latest == null) {
        return;
      }
      state = AsyncData(
        latest.copyWith(
          permissionState: permissionState,
          isLoadingRoute: false,
          error: _errorForPermission(permissionState),
        ),
      );
      return;
    }

    try {
      final route = await ref
          .read(mapRepositoryProvider)
          .getRoute(
            renderer: current.renderer,
            origin: location,
            destination: current.selectedBuilding!,
            travelMode: current.travelMode,
          );
      if (!_isRouteRequestCurrent(
        requestId,
        selectedBuildingId: selectedBuildingId,
        renderer: renderer,
        travelMode: travelMode,
      )) {
        return;
      }
      final latest = state.value;
      if (latest == null) {
        return;
      }
      _lastRouteFetchLocation = location;
      await _startLocationTracking();
      state = AsyncData(
        latest.copyWith(
          currentLocation: location,
          permissionState: permissionState,
          route: route,
          isLoadingRoute: false,
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load route', error, stackTrace);
      if (!_isRouteRequestCurrent(
        requestId,
        selectedBuildingId: selectedBuildingId,
        renderer: renderer,
        travelMode: travelMode,
      )) {
        return;
      }
      final latest = state.value;
      if (latest == null) {
        return;
      }
      state = AsyncData(
        latest.copyWith(
          currentLocation: location,
          permissionState: permissionState,
          isLoadingRoute: false,
          error: MapStateError.routeUnavailable,
        ),
      );
    }
  }

  /// 18 Wally's Walk entrance — used when real GPS is unavailable.
  static const _campusFallback = LocationSample(
    latitude: -33.77388,
    longitude: 151.11275,
    accuracy: 100,
  );

  /// Centers the map on the user's current GPS location.
  ///
  /// Requests location permissions if needed. Falls back to a default campus
  /// coordinate if GPS is unavailable so the map always has a valid center.
  Future<void> centerOnCurrentLocation() async {
    final current = state.value;
    if (current == null) {
      return;
    }
    final permissionState = await ref
        .read(mapRepositoryProvider)
        .ensureLocationPermission();
    final location = await ref.read(mapRepositoryProvider).getCurrentLocation();
    // Always provide a location — fall back to campus center on emulators /
    // when permissions are denied so the button never feels broken.
    final effectiveLocation = location ?? _campusFallback;
    state = AsyncData(
      current.copyWith(
        currentLocation: effectiveLocation,
        permissionState: permissionState,
        clearError: true,
      ),
    );
  }

  /// Changes the current travel mode (walk, drive, bike, transit) and
  /// requests a new route if one is currently active.
  Future<void> setTravelMode(TravelMode travelMode) async {
    final current = state.value;
    if (current == null) {
      return;
    }
    _invalidateRouteRequest();
    state = AsyncData(
      current.copyWith(
        travelMode: travelMode,
        isLoadingRoute: false,
        isNavigating: false,
        hasArrived: false,
      ),
    );
    if (current.selectedBuilding != null && current.route != null) {
      await loadRoute();
    }
  }

  /// Updates the active map renderer (Campus vs Google).
  ///
  /// Clears the existing route because the route polyline points are specific
  /// to the renderer's coordinate system. If a building is selected, it
  /// automatically requests a new route for the new renderer.
  void setRenderer(MapRendererType renderer) {
    final current = state.value;
    if (current == null || current.renderer == renderer) {
      return;
    }
    _invalidateRouteRequest();

    state = AsyncData(
      current.copyWith(
        renderer: renderer,
        clearRoute: true,
        isLoadingRoute: false,
        isNavigating: false,
        hasArrived: false,
        clearError: true,
      ),
    );

    if (current.selectedBuilding != null && current.route != null) {
      unawaited(loadRoute());
    }
  }

  /// Clears the active route and ends any active navigation session.
  void clearRoute() {
    final current = state.value;
    if (current == null) {
      return;
    }
    _invalidateRouteRequest();
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _lastRouteFetchLocation = null;
    state = AsyncData(
      current.copyWith(
        clearRoute: true,
        isNavigating: false,
        hasArrived: false,
        isLoadingRoute: false,
        clearError: true,
      ),
    );
  }

  /// Fully resets the map: clears selected building, route, and search query.
  void clearSelection() {
    final current = state.value;
    if (current == null) {
      return;
    }
    _invalidateRouteRequest();
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _lastRouteFetchLocation = null;
    state = AsyncData(
      current.copyWith(
        clearSelectedBuilding: true,
        clearRoute: true,
        searchQuery: '',
        searchResults: searchCampusBuildings(
          current.buildings,
          '',
        ).take(_defaultVisibleBuildings).toList(),
        isNavigating: false,
        hasArrived: false,
        isLoadingRoute: false,
        clearError: true,
      ),
    );
  }

  void startNavigation() {
    final current = state.value;
    if (current == null || current.route == null) {
      return;
    }
    state = AsyncData(
      current.copyWith(isNavigating: true, hasArrived: false, clearError: true),
    );
  }

  void stopNavigation() {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(current.copyWith(isNavigating: false, clearError: true));
  }

  void toggleOverlay(String id) {
    final current = state.value;
    if (current == null) {
      return;
    }
    final ids = Set<String>.of(current.activeOverlayIds);
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    state = AsyncData(current.copyWith(activeOverlayIds: ids));
  }

  void clearOverlays() {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(current.copyWith(activeOverlayIds: const {}));
  }

  void dismissArrival() {
    clearSelection();
  }

  Future<void> openStreetView() async {
    final building = state.value?.selectedBuilding;
    if (building == null) return;
    final lat = building.routingLatitude ?? building.latitude;
    final lng = building.routingLongitude ?? building.longitude;
    if (lat == null || lng == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/@$lat,$lng,3a,75y,0h,90t/data=!3m4!1e1!3m2!1s!2e0',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> openInGoogleMaps() async {
    final current = state.value;
    if (current == null) {
      return;
    }
    final destination = current.selectedBuilding;
    if (destination == null) {
      return;
    }
    final destLat = destination.routingLatitude;
    final destLng = destination.routingLongitude;
    if (destLat == null || destLng == null) {
      return;
    }

    final origin = current.currentLocation;
    final modeStr = switch (current.travelMode) {
      TravelMode.walk => 'walking',
      TravelMode.drive => 'driving',
      TravelMode.bike => 'bicycling',
      TravelMode.transit => 'transit',
    };

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '${origin != null ? '&origin=${origin.latitude},${origin.longitude}' : ''}'
      '&destination=$destLat,$destLng'
      '&travelmode=$modeStr',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> openLocationSettings() {
    return ref.read(mapRepositoryProvider).openLocationSettings();
  }

  Future<void> openAppSettings() {
    return ref.read(mapRepositoryProvider).openAppSettings();
  }

  Future<void> _startLocationTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = ref
        .read(mapRepositoryProvider)
        .watchLocation()
        .listen(
          (location) {
            final current = state.value;
            if (current == null) {
              return;
            }
            state = AsyncData(current.copyWith(currentLocation: location));

            final updated = state.value;
            if (updated != null &&
                updated.isNavigating &&
                updated.selectedBuilding != null) {
              _checkNavigationState(location);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            AppLogger.warning('Location stream error', error, stackTrace);
          },
        );
  }

  void _checkNavigationState(LocationSample location) {
    final current = state.value;
    if (current == null || !current.isNavigating) {
      return;
    }
    final destination = current.selectedBuilding;
    if (destination == null) {
      return;
    }
    final destLat = destination.routingLatitude;
    final destLng = destination.routingLongitude;
    if (destLat == null || destLng == null) {
      return;
    }

    final distToDestination = haversineMetres(
      lat1: location.latitude,
      lng1: location.longitude,
      lat2: destLat,
      lng2: destLng,
    );

    // Arrival detection
    if (distToDestination <= _arrivalThresholdMetres) {
      _locationSubscription?.cancel();
      _locationSubscription = null;
      state = AsyncData(
        current.copyWith(
          currentLocation: location,
          isNavigating: false,
          hasArrived: true,
        ),
      );
      return;
    }

    // Off-route detection + route recalculation
    final lastFetch = _lastRouteFetchLocation;
    if (lastFetch == null) {
      return;
    }
    final distFromLastFetch = haversineMetres(
      lat1: location.latitude,
      lng1: location.longitude,
      lat2: lastFetch.latitude,
      lng2: lastFetch.longitude,
    );

    var isOffRoute = false;
    if (current.route != null && distFromLastFetch > _offRouteThresholdMetres) {
      if (distToDestination > current.route!.distanceMeters * 1.5) {
        isOffRoute = true;
      }
    }

    if (distFromLastFetch > _recalcThresholdMetres || isOffRoute) {
      unawaited(loadRoute());
    }
  }

  int _beginRouteRequest() {
    _routeRequestVersion += 1;
    return _routeRequestVersion;
  }

  void _invalidateRouteRequest() {
    _routeRequestVersion += 1;
  }

  bool _isRouteRequestCurrent(
    int requestId, {
    required String selectedBuildingId,
    required MapRendererType renderer,
    required TravelMode travelMode,
  }) {
    final current = state.value;
    return current != null &&
        _routeRequestVersion == requestId &&
        current.selectedBuilding?.id == selectedBuildingId &&
        current.renderer == renderer &&
        current.travelMode == travelMode;
  }

  MapStateError _errorForPermission(LocationPermissionState state) {
    return switch (state) {
      LocationPermissionState.servicesDisabled =>
        MapStateError.locationServicesDisabled,
      LocationPermissionState.deniedForever =>
        MapStateError.locationPermissionBlocked,
      LocationPermissionState.denied =>
        MapStateError.locationPermissionRequired,
      LocationPermissionState.unsupported => MapStateError.locationUnsupported,
      LocationPermissionState.granted => MapStateError.locationUnavailable,
    };
  }
}
