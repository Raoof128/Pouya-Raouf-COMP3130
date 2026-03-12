import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/data/datasources/location_source.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';
import 'package:mq_navigation/features/map/presentation/widgets/building_search_sheet.dart';
import 'package:mq_navigation/features/map/presentation/widgets/campus_map_view.dart';
import 'package:mq_navigation/features/map/presentation/widgets/route_panel.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_app_bar.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key, this.initialBuildingId, this.initialSearchQuery});

  final String? initialBuildingId;
  final String? initialSearchQuery;

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  @override
  void initState() {
    super.initState();
    final buildingId = widget.initialBuildingId;
    final searchQuery = widget.initialSearchQuery;
    if (buildingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mapControllerProvider.notifier).selectBuildingById(buildingId);
      });
    } else if (searchQuery != null && searchQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(mapControllerProvider.notifier)
            .updateSearchQuery(searchQuery);
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
            padding: const EdgeInsetsDirectional.only(end: MqSpacing.space1),
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

          // Determine if we're in category browse mode:
          // search is active, multiple results, no specific building selected.
          final isCategoryBrowse = mapState.searchQuery.trim().length >= 2 &&
              mapState.selectedBuilding == null &&
              mapState.searchResults.length > 1;

          return Column(
            children: [
              // ── Error banner ──
              if (mapState.error != null)
                Container(
                  margin: const EdgeInsetsDirectional.fromSTEB(
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
                child: CampusMapView(
                  searchResults: mapState.searchResults,
                  searchQuery: mapState.searchQuery,
                  selectedBuilding: mapState.selectedBuilding,
                  route: mapState.route,
                  currentLocation: mapState.currentLocation,
                  onSelectBuilding: controller.selectBuilding,
                ),
              ),

              // ── Bottom panel: category list OR route panel ──
              if (isCategoryBrowse)
                _CategoryBuildingList(
                  buildings: mapState.searchResults,
                  searchQuery: mapState.searchQuery,
                  onSelectBuilding: controller.selectBuilding,
                  onClear: controller.clearSelection,
                )
              else
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
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
                    onLoadRoute: controller.loadRoute,
                    onClearRoute: controller.clearRoute,
                    onClearSelection: controller.clearSelection,
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
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.centerOnLocation,
        onPressed: () =>
            ref.read(mapControllerProvider.notifier).centerOnCurrentLocation(),
        backgroundColor: MqColors.red,
        foregroundColor: Colors.white,
        child: Icon(
          Icons.my_location,
          semanticLabel: l10n.centerOnLocation,
        ),
      ),
    );
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

/// Scrollable list of buildings shown when browsing a category (e.g., "Food").
class _CategoryBuildingList extends StatelessWidget {
  const _CategoryBuildingList({
    required this.buildings,
    required this.searchQuery,
    required this.onSelectBuilding,
    required this.onClear,
  });

  final List<Building> buildings;
  final String searchQuery;
  final ValueChanged<Building> onSelectBuilding;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    // Only show buildings with valid coordinates.
    final validBuildings =
        buildings.where((b) => b.latitude != null && b.longitude != null).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: isDark ? MqColors.charcoal850 : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MqSpacing.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with title and close button
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              MqSpacing.space4,
              MqSpacing.space3,
              MqSpacing.space2,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${searchQuery[0].toUpperCase()}${searchQuery.substring(1)} (${validBuildings.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: l10n.clear,
                  onPressed: onClear,
                ),
              ],
            ),
          ),

          // Building list
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsetsDirectional.fromSTEB(
                MqSpacing.space2,
                0,
                MqSpacing.space2,
                MqSpacing.space3,
              ),
              itemCount: validBuildings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                final building = validBuildings[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.location_on,
                    color: MqColors.red,
                    size: 20,
                  ),
                  title: Text(
                    building.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: building.address != null
                      ? Text(
                          building.address!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? MqColors.slate500
                                : MqColors.charcoal600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: const Icon(
                    Icons.chevron_right,
                    size: 20,
                  ),
                  onTap: () => onSelectBuilding(building),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
