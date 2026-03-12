import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/map/data/datasources/location_source.dart';
import 'package:mq_navigation/features/map/data/repositories/map_repository_impl.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/map_mode.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';

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
    this.mode = MapMode.campus,
    this.travelMode = TravelMode.walk,
    this.permissionState = LocationPermissionState.denied,
    this.isLoadingRoute = false,
    this.error,
  });

  final List<Building> buildings;
  final List<Building> searchResults;
  final Building? selectedBuilding;
  final LocationSample? currentLocation;
  final MapRoute? route;
  final String searchQuery;
  final MapMode mode;
  final TravelMode travelMode;
  final LocationPermissionState permissionState;
  final bool isLoadingRoute;
  final MapStateError? error;

  MapState copyWith({
    List<Building>? buildings,
    List<Building>? searchResults,
    Building? selectedBuilding,
    bool clearSelectedBuilding = false,
    LocationSample? currentLocation,
    bool clearCurrentLocation = false,
    MapRoute? route,
    bool clearRoute = false,
    String? searchQuery,
    MapMode? mode,
    TravelMode? travelMode,
    LocationPermissionState? permissionState,
    bool? isLoadingRoute,
    MapStateError? error,
    bool clearError = false,
  }) {
    return MapState(
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
      mode: mode ?? this.mode,
      travelMode: travelMode ?? this.travelMode,
      permissionState: permissionState ?? this.permissionState,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final mapControllerProvider = AsyncNotifierProvider<MapController, MapState>(
  MapController.new,
);

class MapController extends AsyncNotifier<MapState> {
  StreamSubscription<LocationSample>? _locationSubscription;

  @override
  Future<MapState> build() async {
    ref.onDispose(() => _locationSubscription?.cancel());
    final buildings = await ref.read(mapRepositoryProvider).getBuildings();
    return MapState(
      buildings: buildings,
      searchResults: buildings.take(12).toList(),
      permissionState: LocationPermissionState.denied,
    );
  }

  void updateSearchQuery(String query) {
    final current = state.value;
    if (current == null) {
      return;
    }

    final normalized = query.trim().toLowerCase();
    final searchResults =
        normalized.length < 2
              ? current.buildings.take(12).toList()
              : current.buildings
                    .where((building) => building.matchesQuery(normalized))
                    .toList()
          ..sort((left, right) {
            final leftStrong = _isStrongMatch(left, normalized);
            final rightStrong = _isStrongMatch(right, normalized);
            if (leftStrong != rightStrong) {
              return rightStrong ? 1 : -1;
            }
            return left.name.compareTo(right.name);
          });

    final exactMatch = searchResults.where((building) {
      return _isStrongMatch(building, normalized);
    }).toList();

    state = AsyncData(
      current.copyWith(
        searchQuery: query,
        searchResults: searchResults,
        // Only auto-select when there is exactly one strong match
        // (e.g. user typed an exact building name/id).
        // Category searches like "food" or "parking" should NOT auto-select
        // — they show all matching buildings as markers instead.
        selectedBuilding: exactMatch.length == 1 && searchResults.length == 1
            ? exactMatch.first
            : null,
        clearSelectedBuilding: !(exactMatch.length == 1 && searchResults.length == 1),
        clearError: true,
      ),
    );
  }

  void selectBuilding(Building building) {
    final current = state.value;
    if (current == null) {
      return;
    }
    // Clear route and stop tracking when selecting a new building during navigation.
    if (current.mode == MapMode.navigation) {
      _locationSubscription?.cancel();
      _locationSubscription = null;
    }
    state = AsyncData(
      current.copyWith(
        selectedBuilding: building,
        mode: MapMode.campus,
        clearRoute: current.mode == MapMode.navigation,
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

    state = AsyncData(
      current!.copyWith(isLoadingRoute: true, clearError: true),
    );

    final permissionState = await ref
        .read(mapRepositoryProvider)
        .ensureLocationPermission();

    // Get location — may be real GPS or campus-center fallback.
    final location = await ref.read(mapRepositoryProvider).getCurrentLocation();
    if (location == null) {
      state = AsyncData(
        current.copyWith(
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
            origin: location,
            destination: current.selectedBuilding!,
            travelMode: current.travelMode,
          );
      await _startLocationTracking();
      state = AsyncData(
        current.copyWith(
          currentLocation: location,
          permissionState: permissionState,
          route: route,
          mode: MapMode.navigation,
          isLoadingRoute: false,
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load route', error, stackTrace);
      state = AsyncData(
        current.copyWith(
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
    state = AsyncData(current.copyWith(travelMode: travelMode));
    if (current.selectedBuilding != null) {
      await loadRoute();
    }
  }

  void clearRoute() {
    final current = state.value;
    if (current == null) {
      return;
    }
    _locationSubscription?.cancel();
    _locationSubscription = null;
    state = AsyncData(
      current.copyWith(
        clearRoute: true,
        mode: MapMode.campus,
        clearError: true,
      ),
    );
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
          },
          onError: (Object error, StackTrace stackTrace) {
            AppLogger.warning('Location stream error', error, stackTrace);
          },
        );
  }


  bool _isStrongMatch(Building building, String query) {
    final normalized = query.trim().toLowerCase();
    return building.id.toLowerCase() == normalized ||
        building.name.toLowerCase() == normalized ||
        building.aliases.any((alias) => alias.toLowerCase() == normalized);
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
