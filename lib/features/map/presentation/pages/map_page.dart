import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/data/datasources/location_source.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';
import 'package:mq_navigation/features/map/presentation/widgets/building_search_sheet.dart';
import 'package:mq_navigation/features/map/presentation/widgets/campus/campus_map_view.dart';
import 'package:mq_navigation/features/map/presentation/widgets/google/google_map_view.dart';
import 'package:mq_navigation/features/map/presentation/widgets/map_shell.dart';
import 'package:mq_navigation/features/map/presentation/widgets/overlay_picker_sheet.dart';
import 'package:mq_navigation/features/map/presentation/widgets/route_panel.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';

/// Main screen for the campus map feature.
///
/// Serves as the orchestration layer that watches [MapController] and passes
/// its unified state down to the active renderer ([CampusMapView] or
/// [GoogleMapView]). Also manages bottom sheets for search and overlays.
class MapPage extends ConsumerStatefulWidget {
  const MapPage({
    super.key,
    this.initialBuildingId,
    this.initialSearchQuery,
    this.meetLat,
    this.meetLng,
  });

  final String? initialBuildingId;
  final String? initialSearchQuery;
  final double? meetLat;
  final double? meetLng;

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  void _openSearchSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BuildingSearchSheet(),
    );
  }

  void _openOverlayPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? MqColors.charcoal850
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MqSpacing.radiusXl),
        ),
      ),
      builder: (_) => const OverlayPickerSheet(),
    );
  }

  @override
  void initState() {
    super.initState();
    final buildingId = widget.initialBuildingId;
    final meetLat = widget.meetLat;
    final meetLng = widget.meetLng;
    final searchQuery = widget.initialSearchQuery;
    if (meetLat != null && meetLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(mapControllerProvider.notifier)
            .selectMeetPoint(latitude: meetLat, longitude: meetLng);
      });
    } else if (buildingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mapControllerProvider.notifier).selectBuildingById(buildingId);
      });
    } else if (searchQuery != null && searchQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mapControllerProvider.notifier).updateSearchQuery(searchQuery);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(mapControllerProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      body: state.when(
        data: (mapState) {
          final controller = ref.read(mapControllerProvider.notifier);
          final permissionState = mapState.permissionState;
          final isPermissionBlocked =
              permissionState == LocationPermissionState.denied ||
              permissionState == LocationPermissionState.deniedForever ||
              permissionState == LocationPermissionState.servicesDisabled;

          // Category browse mode: search active, multiple results, nothing selected.
          final isCategoryBrowse =
              mapState.searchQuery.trim().isNotEmpty &&
              mapState.selectedBuilding == null &&
              mapState.searchResults.length > 1;

          final mapView = switch (mapState.renderer) {
            MapRendererType.campus => CampusMapView(
              searchResults: mapState.searchResults,
              searchQuery: mapState.searchQuery,
              selectedBuilding: mapState.selectedBuilding,
              route: mapState.route,
              currentLocation: mapState.currentLocation,
              locationCenterRequestToken: mapState.locationCenterRequestToken,
              isNavigating: mapState.isNavigating,
              onSelectBuilding: controller.selectBuilding,
              activeOverlayIds: mapState.activeOverlayIds,
            ),
            MapRendererType.google => GoogleMapView(
              searchResults: mapState.searchResults,
              searchQuery: mapState.searchQuery,
              selectedBuilding: mapState.selectedBuilding,
              route: mapState.route,
              currentLocation: mapState.currentLocation,
              locationCenterRequestToken: mapState.locationCenterRequestToken,
              isNavigating: mapState.isNavigating,
              onSelectBuilding: controller.selectBuilding,
            ),
          };

          return MapShell(
            mapView: mapView,
            renderer: mapState.renderer,
            onRendererChanged: controller.setRenderer,
            onCenterOnLocation: controller.centerOnCurrentLocation,
            onOpenSearch: _openSearchSheet,
            onOpenOverlayPicker: _openOverlayPicker,
            filterChips: _CategoryFilterChips(
              activeQuery: mapState.searchQuery,
              onSelect: controller.updateSearchQuery,
            ),
            banner: mapState.error == null
                ? null
                : _MapErrorBanner(
                    title: _errorTitle(l10n, mapState.error!),
                    message: _errorMessage(l10n, mapState.error!),
                    isPermissionBlocked: isPermissionBlocked,
                    onCenterOnLocation: controller.centerOnCurrentLocation,
                    onOpenSettings:
                        permissionState ==
                            LocationPermissionState.servicesDisabled
                        ? controller.openLocationSettings
                        : controller.openAppSettings,
                  ),
            footer: isCategoryBrowse
                ? _CategoryBuildingList(
                    buildings: mapState.searchResults,
                    searchQuery: mapState.searchQuery,
                    onSelectBuilding: controller.selectBuilding,
                    onClear: controller.clearSelection,
                  )
                : mapState.selectedBuilding != null
                ? RoutePanel(
                    selectedBuilding: mapState.selectedBuilding,
                    route: mapState.route,
                    travelMode: mapState.travelMode,
                    supportedTravelModes:
                        mapState.renderer == MapRendererType.campus
                        ? const [TravelMode.walk]
                        : TravelMode.values,
                    isLoading: mapState.isLoadingRoute,
                    isNavigating: mapState.isNavigating,
                    hasArrived: mapState.hasArrived,
                    onLoadRoute: controller.loadRoute,
                    onClearRoute: controller.clearRoute,
                    onClearSelection: controller.clearSelection,
                    onTravelModeChanged: controller.setTravelMode,
                    onStartNavigation: controller.startNavigation,
                    onStopNavigation: controller.stopNavigation,
                    onDismissArrival: controller.dismissArrival,
                    onOpenInGoogleMaps: controller.openInGoogleMaps,
                    onOpenStreetView: controller.openStreetView,
                  )
                : null,
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
                  color: isDark ? MqColors.sand400 : MqColors.contentTertiary,
                ),
              ),
            ],
          ),
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

class _MapErrorBanner extends StatelessWidget {
  const _MapErrorBanner({
    required this.title,
    required this.message,
    required this.isPermissionBlocked,
    required this.onCenterOnLocation,
    required this.onOpenSettings,
  });

  final String title;
  final String message;
  final bool isPermissionBlocked;
  final Future<void> Function() onCenterOnLocation;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(MqSpacing.space4),
      decoration: BoxDecoration(
        color: isDark
            ? MqColors.error.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(MqSpacing.radiusLg),
        border: Border.all(
          color: MqColors.error.withValues(alpha: isDark ? 0.34 : 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
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
                  title,
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
            message,
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
              runSpacing: MqSpacing.space2,
              children: [
                MqButton(
                  label: l10n.centerOnLocation,
                  isExpanded: false,
                  onPressed: () => onCenterOnLocation(),
                ),
                MqButton(
                  label: l10n.settings,
                  variant: MqButtonVariant.outlined,
                  isExpanded: false,
                  onPressed: () => onOpenSettings(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Glass-styled scrollable list of buildings for category browse mode.
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

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    final validBuildings = buildings
        .where((b) => b.latitude != null && b.longitude != null)
        .toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(MqSpacing.radiusXl),
        bottom: Radius.circular(MqSpacing.radiusXl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: MqSpacing.space3,
          sigmaY: MqSpacing.space3,
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            color: isDark
                ? MqColors.charcoal850.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(MqSpacing.radiusXl),
              bottom: Radius.circular(MqSpacing.radiusXl),
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: MqSpacing.space3,
                ),
                child: Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              // Header
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
                        '${_capitalize(searchQuery.trim())} (${validBuildings.length})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : MqColors.contentPrimary,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : MqColors.contentTertiary,
                      ),
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
                        color: MqColors.vividRed,
                        size: 20,
                      ),
                      title: Text(
                        building.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white
                              : MqColors.contentPrimary,
                        ),
                      ),
                      subtitle: building.address != null
                          ? Text(
                              building.address!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : MqColors.charcoal600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : MqColors.charcoal600,
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
        ),
      ),
    );
  }
}

/// Horizontal row of campus category chips shown under the map search bar.
///
/// Tapping a chip seeds the map's search query; tapping the active chip clears
/// it. Matches the category shortcuts on the home screen so students can
/// re-filter without leaving the map.
class _CategoryFilterChips extends StatelessWidget {
  const _CategoryFilterChips({
    required this.activeQuery,
    required this.onSelect,
  });

  final String activeQuery;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final normalizedActive = activeQuery.trim().toLowerCase();
    // Transport intentionally absent — surfaced via Home's Metro Countdown
    // card, so a duplicate Map filter chip would only add noise.
    final categories = <({IconData icon, String label, String query})>[
      (icon: Icons.restaurant, label: l10n.food, query: 'food'),
      (icon: Icons.local_parking, label: l10n.parking, query: 'parking'),
      (icon: Icons.menu_book, label: l10n.mapCategoryLibrary, query: 'library'),
      (icon: Icons.school, label: l10n.home_studentServices, query: 'student'),
      (icon: Icons.support_agent, label: l10n.services, query: 'services'),
    ];

    return SizedBox(
      height: MqSpacing.minTapTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: MqSpacing.space2),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = normalizedActive == category.query;
          return _CategoryChip(
            icon: category.icon,
            label: category.label,
            isActive: isActive,
            isDark: isDark,
            onTap: () => onSelect(isActive ? '' : category.query),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeBg = MqColors.vividRed;
    final inactiveBg = isDark
        ? MqColors.charcoal850.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.9);
    const activeFg = Colors.white;
    final inactiveFg = isDark ? Colors.white : MqColors.contentPrimary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: isActive ? activeBg : inactiveBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
            side: BorderSide(
              color: isActive
                  ? activeBg
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: MqSpacing.space3,
                vertical: MqSpacing.space2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: isActive ? activeFg : inactiveFg),
                  const SizedBox(width: MqSpacing.space2),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isActive ? activeFg : inactiveFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
