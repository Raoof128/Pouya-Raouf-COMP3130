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
import 'package:shared_preferences/shared_preferences.dart';
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
  static const _travelModeKey = 'travelMode';

  StreamSubscription<LocationSample>? _locationSubscription;
  int _routeRequestVersion = 0;
  LocationSample? _lastRouteFetchLocation;

  @override
  Future<MapState> build() async {
    ref.onDispose(() => _locationSubscription?.cancel());
    final buildings = await ref.read(mapRepositoryProvider).getBuildings();
    final savedMode = await _loadTravelMode();
    return MapState(
      renderer: MapRendererType.campus,
      buildings: buildings,
      searchResults: searchCampusBuildings(
        buildings,
        '',
      ).take(_defaultVisibleBuildings).toList(),
      travelMode: savedMode,
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
    final searchResults = normalized.isEmpty
        ? rankedBuildings.take(_defaultVisibleBuildings).toList()
        : rankedBuildings;

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
    unawaited(_saveTravelMode(travelMode));
    if (current.selectedBuilding != null && current.route != null) {
      await loadRoute();
    }
  }

  void setRenderer(MapRendererType renderer) {
    final current = state.value;
    if (current == null || current.renderer == renderer) {
      return;
    }
    _invalidateRouteRequest();

    state = AsyncData(
      current.copyWith(
        renderer: renderer,
        isLoadingRoute: false,
        clearError: true,
      ),
    );
  }

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

  static Future<TravelMode> _loadTravelMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_travelModeKey);
      return TravelMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => TravelMode.walk,
      );
    } catch (_) {
      return TravelMode.walk;
    }
  }

  static Future<void> _saveTravelMode(TravelMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_travelModeKey, mode.name);
    } catch (_) {
      // Ignore — preference persistence is best-effort.
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
