import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/features/map/data/datasources/location_source.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';
import 'package:mq_navigation/features/map/presentation/widgets/building_search_sheet.dart';
import 'package:mq_navigation/features/map/presentation/widgets/campus_map_view.dart';
import 'package:mq_navigation/features/map/presentation/widgets/route_panel.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_app_bar.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key, this.initialBuildingId});

  final String? initialBuildingId;

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final buildingId = widget.initialBuildingId;
    if (buildingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mapControllerProvider.notifier).selectBuildingById(buildingId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(mapControllerProvider);

    return Scaffold(
      appBar: MqAppBar(
        title: l10n.map,
        actions: [
          IconButton(
            tooltip: l10n.searchBuildingsPlaceholder,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const BuildingSearchSheet(),
            ),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: state.when(
        data: (mapState) {
          final controller = ref.read(mapControllerProvider.notifier);
          final permissionState = mapState.permissionState;
          final isPermissionBlocked =
              permissionState == LocationPermissionState.denied ||
              permissionState == LocationPermissionState.deniedForever ||
              permissionState == LocationPermissionState.servicesDisabled;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (mapState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MqCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _errorTitle(l10n, mapState.error!),
                            style: context.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(_errorMessage(l10n, mapState.error!)),
                          if (isPermissionBlocked) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: [
                                MqButton(
                                  label: l10n.centerOnLocation,
                                  isExpanded: false,
                                  onPressed: () =>
                                      controller.centerOnCurrentLocation(),
                                ),
                                MqButton(
                                  label: l10n.settings,
                                  variant: MqButtonVariant.outlined,
                                  isExpanded: false,
                                  onPressed:
                                      permissionState ==
                                          LocationPermissionState
                                              .servicesDisabled
                                      ? () => controller.openLocationSettings()
                                      : () => controller.openAppSettings(),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: CampusMapView(
                    buildings: mapState.buildings,
                    selectedBuilding: mapState.selectedBuilding,
                    route: mapState.route,
                    currentLocation: mapState.currentLocation,
                    onSelectBuilding: controller.selectBuilding,
                  ),
                ),
                const SizedBox(height: 16),
                RoutePanel(
                  selectedBuilding: mapState.selectedBuilding,
                  route: mapState.route,
                  travelMode: mapState.travelMode,
                  isLoading: mapState.isLoadingRoute,
                  onLoadRoute: () => _ensureLocationAndLoadRoute(context),
                  onClearRoute: controller.clearRoute,
                  onTravelModeChanged: controller.setTravelMode,
                ),
              ],
            ),
          );
        },
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => Center(child: Text(l10n.loadingBuildings)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ensureLocationAndLoadRoute(context, onlyCenter: true),
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Future<void> _ensureLocationAndLoadRoute(
    BuildContext context, {
    bool onlyCenter = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.map, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.walkingDirectionsDesc),
              const SizedBox(height: 16),
              MqButton(
                label: l10n.centerOnLocation,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
    );

    if (proceed != true || !context.mounted) {
      return;
    }

    if (onlyCenter) {
      await ref.read(mapControllerProvider.notifier).centerOnCurrentLocation();
    } else {
      await ref.read(mapControllerProvider.notifier).loadRoute();
    }
  }

  String _errorTitle(AppLocalizations l10n, MapStateError error) {
    return switch (error) {
      MapStateError.outsideCampus => l10n.locationOutsideCampusTitle,
      MapStateError.routeUnavailable => l10n.routeUnavailable,
      MapStateError.locationServicesDisabled ||
      MapStateError.locationPermissionBlocked ||
      MapStateError.locationPermissionRequired ||
      MapStateError.locationUnsupported ||
      MapStateError.locationUnavailable => l10n.map,
    };
  }

  String _errorMessage(AppLocalizations l10n, MapStateError error) {
    return switch (error) {
      MapStateError.outsideCampus => l10n.locationOutsideCampusMessage,
      MapStateError.routeUnavailable => l10n.noRouteAvailable,
      MapStateError.locationServicesDisabled => l10n.locationServicesDisabled,
      MapStateError.locationPermissionBlocked => l10n.locationPermissionBlocked,
      MapStateError.locationPermissionRequired =>
        l10n.locationPermissionRequired,
      MapStateError.locationUnsupported => l10n.locationUnsupported,
      MapStateError.locationUnavailable => l10n.locationUnavailable,
    };
  }
}
