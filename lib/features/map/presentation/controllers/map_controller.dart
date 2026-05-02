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
import 'package:mq_navigation/features/map/presentation/widgets/map_view_helpers.dart';
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
    this.locationCenterRequestToken = 0,
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
  final int locationCenterRequestToken;
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
    int? locationCenterRequestToken,
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
      locationCenterRequestToken:
          locationCenterRequestToken ?? this.locationCenterRequestToken,
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
        other.locationCenterRequestToken == locationCenterRequestToken &&
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
        locationCenterRequestToken.hashCode ^
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
  static const _offRouteThresholdMetres = 50.0;

  TravelMode _normalizeTravelModeForRenderer(
    MapRendererType renderer,
    TravelMode mode,
  ) {
    if (renderer == MapRendererType.campus && mode != TravelMode.walk) {
      return TravelMode.walk;
    }
    return mode;
  }

  StreamSubscription<LocationSample>? _locationSubscription;
  int _routeRequestVersion = 0;
  LocationSample? _lastRouteFetchLocation;
  DateTime? _lastNavDiagnosticsAt;

  @override
  Future<MapState> build() async {
    ref.onDispose(() => _locationSubscription?.cancel());
    final buildings = await ref.read(mapRepositoryProvider).getBuildings();

    // Load defaults from user preferences (read once so we don't rebuild on unrelated setting changes)
    final prefs = await ref.read(settingsControllerProvider.future);

    // Listen to settings changes to update map renderer/travel mode dynamically
    // without destroying the entire map state (selected building, route, etc).
    ref.listen(settingsControllerProvider, (previous, next) {
      final nextPrefs = next.value;
      final currentMapState = state.value;
      if (nextPrefs == null || currentMapState == null) return;

      var updatedState = currentMapState;
      var changed = false;

      if (currentMapState.renderer != nextPrefs.defaultRenderer) {
        final normalizedTravelMode = _normalizeTravelModeForRenderer(
          nextPrefs.defaultRenderer,
          currentMapState.travelMode,
        );
        _invalidateRouteRequest();
        updatedState = updatedState.copyWith(
          renderer: nextPrefs.defaultRenderer,
          travelMode: normalizedTravelMode,
          clearRoute: true,
          isLoadingRoute: false,
          isNavigating: false,
          hasArrived: false,
          clearError: true,
        );
        changed = true;
      }

      if (currentMapState.travelMode != nextPrefs.defaultTravelMode) {
        final normalizedTravelMode = _normalizeTravelModeForRenderer(
          currentMapState.renderer,
          nextPrefs.defaultTravelMode,
        );
        _invalidateRouteRequest();
        updatedState = updatedState.copyWith(
          travelMode: normalizedTravelMode,
          isLoadingRoute: false,
          isNavigating: false,
          hasArrived: false,
        );
        changed = true;
      }

      if (changed) {
        state = AsyncData(updatedState);
        if (updatedState.selectedBuilding != null &&
            currentMapState.route != null) {
          unawaited(loadRoute());
        }
      }
    });

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

  Future<void> selectMeetPoint({
    required double latitude,
    required double longitude,
  }) async {
    final current = state.value;
    if (current == null) {
      return;
    }

    final meetPoint = Building(
      code: '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
      id: 'meet_${latitude}_$longitude',
      latitude: latitude,
      longitude: longitude,
      name: '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
    );

    selectBuilding(meetPoint);
    await loadRoute();
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

  /// Centers the map on the user's current GPS location.
  ///
  /// Requests location permissions if needed. If GPS legitimately fails
  /// (no permission, no fix, no last-known), surfaces the appropriate
  /// permission/unavailable banner instead of silently snapping to a
  /// campus-centre fallback that would look like a wrong real location
  /// to the user.
  Future<void> centerOnCurrentLocation() async {
    if (state.value == null) {
      return;
    }
    final permissionState = await ref
        .read(mapRepositoryProvider)
        .ensureLocationPermission();
    final location = await ref.read(mapRepositoryProvider).getCurrentLocation();
    final latest = state.value;
    if (latest == null) {
      return;
    }
    if (location == null) {
      // No real fix available — show a banner so the user understands why
      // the dot didn't move, and offer the existing settings/permission
      // recovery actions.
      state = AsyncData(
        latest.copyWith(
          permissionState: permissionState,
          error: _errorForPermission(permissionState),
        ),
      );
      return;
    }
    state = AsyncData(
      latest.copyWith(
        currentLocation: location,
        locationCenterRequestToken: latest.locationCenterRequestToken + 1,
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
    final normalizedMode = _normalizeTravelModeForRenderer(
      current.renderer,
      travelMode,
    );
    _invalidateRouteRequest();
    state = AsyncData(
      current.copyWith(
        travelMode: normalizedMode,
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

    final normalizedTravelMode = _normalizeTravelModeForRenderer(
      renderer,
      current.travelMode,
    );
    state = AsyncData(
      current.copyWith(
        renderer: renderer,
        travelMode: normalizedTravelMode,
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

  /// Closes the category-browse panel entirely.
  ///
  /// Used by the **X button on the category list footer** — distinct
  /// from `clearSelection` which is the focused-back-to-list affordance.
  /// This method always performs a full reset: clears selection, route,
  /// search query, and rehydrates the default visible-buildings set.
  /// After this, the user lands on the empty/default map state.
  void clearCategoryBrowse() {
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

  /// Closes the currently-focused destination.
  ///
  /// **Contextual semantics**:
  ///   * If a search/category query is active, this returns the user
  ///     to the **category browse state** — selected building cleared,
  ///     route cleared, but the query and its result list are preserved
  ///     so the markers and the list footer reappear automatically.
  ///   * If there is no active query, this is a full reset — the map
  ///     drops back to its idle empty state.
  ///
  /// This means the close-X on `RoutePanel` *just works* whether the
  /// user got there via direct search, via a category chip, or via a
  /// deep-link — the right "back" destination is inferred from state.
  void clearSelection() {
    final current = state.value;
    if (current == null) {
      return;
    }
    _invalidateRouteRequest();
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _lastRouteFetchLocation = null;

    final hasActiveQuery = current.searchQuery.trim().isNotEmpty;
    if (hasActiveQuery) {
      // Preserve query + results so the category list footer and
      // multi-marker browse state reappear automatically.
      state = AsyncData(
        current.copyWith(
          clearSelectedBuilding: true,
          clearRoute: true,
          isNavigating: false,
          hasArrived: false,
          isLoadingRoute: false,
          clearError: true,
        ),
      );
      return;
    }

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
    AppLogger.info('Navigation started', {
      'destination': current.selectedBuilding?.id,
      'renderer': current.renderer.name,
      'travelMode': current.travelMode.name,
    });
    state = AsyncData(
      current.copyWith(isNavigating: true, hasArrived: false, clearError: true),
    );
  }

  void stopNavigation() {
    final current = state.value;
    if (current == null) {
      return;
    }
    AppLogger.info('Navigation stopped', {
      'destination': current.selectedBuilding?.id,
    });
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
      AppLogger.info('Navigation arrived', {
        'destination': destination.id,
        'distanceToDestinationMetres': distToDestination.toStringAsFixed(1),
      });
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
      final routePoints = resolveRoutePoints(current.route!);
      if (routePoints.isNotEmpty) {
        final closestIdx = findClosestPointIndex(routePoints, location);
        final closestPoint = routePoints[closestIdx];
        final distToRoute = haversineMetres(
          lat1: location.latitude,
          lng1: location.longitude,
          lat2: closestPoint.latitude,
          lng2: closestPoint.longitude,
        );
        if (distToRoute > _offRouteThresholdMetres) {
          isOffRoute = true;
        }
      }
    }

    _logNavigationDiagnostics(
      location: location,
      distFromLastFetch: distFromLastFetch,
      distToDestination: distToDestination,
      isOffRoute: isOffRoute,
      routeDistanceMeters: current.route?.distanceMeters,
    );

    if (isOffRoute) {
      AppLogger.info('Navigation route recalculation triggered', {
        'distFromLastFetchMetres': distFromLastFetch.toStringAsFixed(1),
        'distToDestinationMetres': distToDestination.toStringAsFixed(1),
        'isOffRoute': isOffRoute,
      });
      unawaited(loadRoute());
    }
  }

  void _logNavigationDiagnostics({
    required LocationSample location,
    required double distFromLastFetch,
    required double distToDestination,
    required bool isOffRoute,
    required int? routeDistanceMeters,
  }) {
    final now = DateTime.now();
    final last = _lastNavDiagnosticsAt;
    if (last != null && now.difference(last) < const Duration(seconds: 5)) {
      return;
    }
    _lastNavDiagnosticsAt = now;
    AppLogger.debug('Navigation diagnostics', {
      'accuracyMetres': location.accuracy?.toStringAsFixed(1),
      'distFromLastFetchMetres': distFromLastFetch.toStringAsFixed(1),
      'distToDestinationMetres': distToDestination.toStringAsFixed(1),
      'isOffRoute': isOffRoute,
      'routeDistanceMeters': routeDistanceMeters,
    });
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
