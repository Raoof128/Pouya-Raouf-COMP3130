import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/features/map/data/datasources/location_source.dart';
import 'package:mq_navigation/features/map/data/repositories/map_repository_impl.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/domain/entities/nav_instruction.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';

void main() {
  group('MapController', () {
    final building = Building.fromJson({
      'id': 'LIB',
      'name': 'Waranara Library',
      'location': {'lat': -33.7756994, 'lng': 151.1131306},
      'entranceLocation': {'lat': -33.7754, 'lng': 151.11325},
      'category': 'academic',
    });
    final secondBuilding = Building.fromJson({
      'id': '18WW',
      'name': '18 Wally\'s Walk',
      'location': {'lat': -33.7739781, 'lng': 151.1126116},
      'entranceLocation': {'lat': -33.77388, 'lng': 151.11275},
      'category': 'services',
    });

    test(
      'defaults to campus renderer and preserves selection when switching',
      () async {
        final repository = _FakeMapRepository(buildings: [building]);
        final container = ProviderContainer(
          overrides: [mapRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        final initialState = await container.read(mapControllerProvider.future);
        expect(initialState.renderer, MapRendererType.campus);

        final notifier = container.read(mapControllerProvider.notifier);
        notifier.selectBuilding(building);
        notifier.setRenderer(MapRendererType.google);

        final state = container.read(mapControllerProvider).value!;
        expect(state.renderer, MapRendererType.google);
        expect(state.selectedBuilding, building);
      },
    );

    test('passes active renderer through route loading', () async {
      final repository = _FakeMapRepository(buildings: [building]);
      final container = ProviderContainer(
        overrides: [mapRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(mapControllerProvider.future);
      final notifier = container.read(mapControllerProvider.notifier);

      notifier.selectBuilding(building);
      notifier.setRenderer(MapRendererType.google);
      await notifier.loadRoute();

      expect(repository.lastRenderer, MapRendererType.google);
      // loadRoute() no longer auto-starts navigation; explicit startNavigation() required.
      expect(
        container.read(mapControllerProvider).value!.isNavigating,
        isFalse,
      );

      notifier.startNavigation();
      expect(container.read(mapControllerProvider).value!.isNavigating, isTrue);
    });

    test('ignores stale route responses after destination changes', () async {
      final repository = _FakeMapRepository(
        buildings: [building, secondBuilding],
      );
      final completer = Completer<MapRoute>();
      repository.pendingRouteCompleter = completer;

      final container = ProviderContainer(
        overrides: [mapRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(mapControllerProvider.future);
      final notifier = container.read(mapControllerProvider.notifier);

      notifier.selectBuilding(building);
      final loadRouteFuture = notifier.loadRoute();

      notifier.selectBuilding(secondBuilding);
      completer.complete(
        MapRoute(
          travelMode: TravelMode.walk,
          distanceMeters: 220,
          durationSeconds: 180,
          encodedPolyline: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
          instructions: const [
            NavInstruction(text: 'Head north', distanceMeters: 80),
          ],
        ),
      );
      await loadRouteFuture;

      final state = container.read(mapControllerProvider).value!;
      expect(state.selectedBuilding, secondBuilding);
      expect(state.route, isNull);
      expect(state.isLoadingRoute, isFalse);
      expect(state.isNavigating, isFalse);
    });

    test(
      'surfaces permission errors when route loading has no location',
      () async {
        final repository = _FakeMapRepository(
          buildings: [building],
          permissionState: LocationPermissionState.denied,
          currentLocation: null,
        );
        final container = ProviderContainer(
          overrides: [mapRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        await container.read(mapControllerProvider.future);
        final notifier = container.read(mapControllerProvider.notifier);

        notifier.selectBuilding(building);
        await notifier.loadRoute();

        final state = container.read(mapControllerProvider).value!;
        expect(state.error, MapStateError.locationPermissionRequired);
        expect(state.isLoadingRoute, isFalse);
        expect(state.route, isNull);
      },
    );

    test(
      'marks arrival and stops navigation when user reaches destination',
      () async {
        final locationStream = StreamController<LocationSample>.broadcast();
        addTearDown(locationStream.close);
        final repository = _FakeMapRepository(
          buildings: [building],
          locationStream: locationStream.stream,
        );
        final container = ProviderContainer(
          overrides: [mapRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        await container.read(mapControllerProvider.future);
        final notifier = container.read(mapControllerProvider.notifier);

        notifier.selectBuilding(building);
        await notifier.loadRoute();
        notifier.startNavigation();

        locationStream.add(
          const LocationSample(
            latitude: -33.7754,
            longitude: 151.11325,
            accuracy: 5,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final state = container.read(mapControllerProvider).value!;
        expect(state.hasArrived, isTrue);
        expect(state.isNavigating, isFalse);
      },
    );

    test('recalculates when navigation goes sufficiently off route', () async {
      final locationStream = StreamController<LocationSample>.broadcast();
      addTearDown(locationStream.close);
      final repository = _FakeMapRepository(
        buildings: [building],
        locationStream: locationStream.stream,
      );
      final container = ProviderContainer(
        overrides: [mapRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(mapControllerProvider.future);
      final notifier = container.read(mapControllerProvider.notifier);

      notifier.selectBuilding(building);
      await notifier.loadRoute();
      notifier.startNavigation();
      final initialRouteCalls = repository.routeCallCount;

      locationStream.add(
        const LocationSample(
          latitude: -33.7700,
          longitude: 151.1200,
          accuracy: 5,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.routeCallCount, greaterThan(initialRouteCalls));
    });
  });

  group('MapState', () {
    test('default activeOverlayIds is empty', () {
      const state = MapState(buildings: [], searchResults: []);
      expect(state.activeOverlayIds, isEmpty);
    });

    test('copyWith preserves activeOverlayIds', () {
      const state = MapState(
        buildings: [],
        searchResults: [],
        activeOverlayIds: {'parking', 'accessibility'},
      );
      final updated = state.copyWith(searchQuery: 'test');
      expect(updated.activeOverlayIds, {'parking', 'accessibility'});
    });

    test('copyWith can update activeOverlayIds', () {
      const state = MapState(buildings: [], searchResults: []);
      final updated = state.copyWith(activeOverlayIds: {'parking'});
      expect(updated.activeOverlayIds, {'parking'});
    });
  });
}

class _FakeMapRepository implements MapRepository {
  _FakeMapRepository({
    required this.buildings,
    this.permissionState = LocationPermissionState.granted,
    this.currentLocation = const LocationSample(
      latitude: -33.77388,
      longitude: 151.11275,
      accuracy: 8,
    ),
    Stream<LocationSample>? locationStream,
  }) : _locationStream = locationStream ?? const Stream<LocationSample>.empty();

  final List<Building> buildings;
  final LocationPermissionState permissionState;
  final LocationSample? currentLocation;
  final Stream<LocationSample> _locationStream;
  MapRendererType? lastRenderer;
  Completer<MapRoute>? pendingRouteCompleter;
  int routeCallCount = 0;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}

  @override
  Future<LocationPermissionState> ensureLocationPermission() async {
    return permissionState;
  }

  @override
  Future<List<Building>> getBuildings({bool forceRefresh = false}) async {
    return buildings;
  }

  @override
  Future<LocationSample?> getCurrentLocation() async {
    return currentLocation;
  }

  @override
  Future<MapRoute> getRoute({
    required MapRendererType renderer,
    required LocationSample origin,
    required Building destination,
    required TravelMode travelMode,
  }) async {
    routeCallCount += 1;
    lastRenderer = renderer;
    final pending = pendingRouteCompleter;
    if (pending != null) {
      pendingRouteCompleter = null;
      return pending.future;
    }
    return MapRoute(
      travelMode: travelMode,
      distanceMeters: 220,
      durationSeconds: 180,
      encodedPolyline: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
      instructions: const [
        NavInstruction(text: 'Head north', distanceMeters: 80),
      ],
    );
  }

  @override
  Stream<LocationSample> watchLocation() => _locationStream;
}
