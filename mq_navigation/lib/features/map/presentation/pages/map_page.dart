import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/data/datasources/location_source.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';
import 'package:mq_navigation/features/map/presentation/widgets/building_search_sheet.dart';
import 'package:mq_navigation/features/map/presentation/widgets/campus_map_view.dart';
import 'package:mq_navigation/features/map/presentation/widgets/route_panel.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_app_bar.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';

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
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: MqAppBar(
        title: l10n.map,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: MqSpacing.space1),
            child: IconButton(
              tooltip: l10n.searchBuildingsPlaceholder,
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const BuildingSearchSheet(),
              ),
              icon: Container(
                padding: const EdgeInsets.all(MqSpacing.space2),
                decoration: BoxDecoration(
                  color: isDark
                      ? MqColors.charcoal800
                      : MqColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.search,
                  size: 20,
                  color: isDark ? MqColors.contentPrimaryDark : MqColors.red,
                ),
              ),
            ),
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

          return Column(
            children: [
              // ── Error banner ──
              if (mapState.error != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(
                    MqSpacing.space4,
                    MqSpacing.space2,
                    MqSpacing.space4,
                    0,
                  ),
                  padding: const EdgeInsets.all(MqSpacing.space4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? MqColors.error.withValues(alpha: 0.12)
                        : MqColors.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(MqSpacing.radiusLg),
                    border: Border.all(
                      color: MqColors.error.withValues(
                        alpha: isDark ? 0.3 : 0.15,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: MqColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: MqSpacing.space2),
                          Expanded(
                            child: Text(
                              _errorTitle(l10n, mapState.error!),
                              style: context.textTheme.titleSmall?.copyWith(
                                color: MqColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MqSpacing.space2),
                      Text(
                        _errorMessage(l10n, mapState.error!),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? MqColors.contentSecondaryDark
                              : MqColors.contentSecondary,
                        ),
                      ),
                      if (isPermissionBlocked) ...[
                        const SizedBox(height: MqSpacing.space3),
                        Wrap(
                          spacing: MqSpacing.space2,
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
                              onPressed: permissionState ==
                                      LocationPermissionState.servicesDisabled
                                  ? () => controller.openLocationSettings()
                                  : () => controller.openAppSettings(),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

              // ── Map view ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    MqSpacing.space4,
                    MqSpacing.space3,
                    MqSpacing.space4,
                    0,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(MqSpacing.radiusLg),
                    child: CampusMapView(
                      buildings: mapState.buildings,
                      selectedBuilding: mapState.selectedBuilding,
                      route: mapState.route,
                      currentLocation: mapState.currentLocation,
                      onSelectBuilding: controller.selectBuilding,
                    ),
                  ),
                ),
              ),

              // ── Route panel ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MqSpacing.space4,
                  MqSpacing.space3,
                  MqSpacing.space4,
                  MqSpacing.space4,
                ),
                child: RoutePanel(
                  selectedBuilding: mapState.selectedBuilding,
                  route: mapState.route,
                  travelMode: mapState.travelMode,
                  isLoading: mapState.isLoadingRoute,
                  onLoadRoute: () => _ensureLocationAndLoadRoute(context),
                  onClearRoute: controller.clearRoute,
                  onTravelModeChanged: controller.setTravelMode,
                ),
              ),
            ],
          );
        },
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(MqSpacing.space8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: MqColors.error.withValues(alpha: 0.7),
                ),
                const SizedBox(height: MqSpacing.space4),
                Text(
                  error.toString(),
                  style: context.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: MqColors.red),
              const SizedBox(height: MqSpacing.space4),
              Text(
                l10n.loadingBuildings,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? MqColors.sand400
                      : MqColors.contentTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: MqColors.red.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () =>
              _ensureLocationAndLoadRoute(context, onlyCenter: true),
          backgroundColor: MqColors.red,
          foregroundColor: Colors.white,
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }

  Future<void> _ensureLocationAndLoadRoute(
    BuildContext context, {
    bool onlyCenter = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;

    final proceed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? MqColors.charcoal800 : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(MqSpacing.radiusXl),
            ),
          ),
          padding: const EdgeInsets.all(MqSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? MqColors.charcoal600 : MqColors.sand300,
                    borderRadius:
                        BorderRadius.circular(MqSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: MqSpacing.space5),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(MqSpacing.space2),
                    decoration: BoxDecoration(
                      color: MqColors.red.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(MqSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: MqColors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: MqSpacing.space3),
                  Text(
                    l10n.map,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MqSpacing.space3),
              Text(
                l10n.walkingDirectionsDesc,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? MqColors.sand400
                      : MqColors.contentTertiary,
                ),
              ),
              const SizedBox(height: MqSpacing.space5),
              MqButton(
                label: l10n.centerOnLocation,
                icon: Icons.navigation,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: MqSpacing.space2),
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
