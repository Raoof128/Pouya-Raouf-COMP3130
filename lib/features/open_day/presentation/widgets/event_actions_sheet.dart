import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/data/datasources/building_registry_source.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';
import 'package:mq_navigation/features/open_day/domain/entities/open_day_data.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_bottom_sheet.dart';

/// Bottom sheet shown when the user taps the direction icon on an event.
///
/// Two actions, both routing **through the in-app Navigation tab** —
/// they differ only in which renderer the user lands inside:
///   1. **View in Campus Map** → Navigation tab + Campus Map renderer,
///      single-marker focused state on the venue.
///   2. **Navigate with Google Maps** → Navigation tab + Google Maps
///      renderer, single-marker focused state on the venue. The
///      embedded Google Maps view supports gesture-based zoom/pan and
///      uses the user's current location for spatial context, while
///      keeping the user *inside* MQ Navigation rather than booting
///      out to the OS-level Maps app.
///
/// Implementation note: both actions perform two side effects in
/// sequence — `mapController.setRenderer(...)` then
/// `goNamed(buildingDetail, …)`. The order matters: setting the
/// renderer first means the destination page builds in the right mode
/// from frame zero (no flash of the wrong renderer).
class EventActionsSheet extends ConsumerWidget {
  const EventActionsSheet({super.key, required this.event});

  final OpenDayEvent event;

  static Future<void> show(BuildContext context, OpenDayEvent event) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EventActionsSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dark = context.isDarkMode;
    final buildingsAsync = ref.watch(buildingRegistryProvider);
    final building = _resolveBuilding(buildingsAsync.value, event.buildingCode);
    final hasResolvedBuilding = event.buildingCode != null && building != null;

    return MqBottomSheet(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: MqSpacing.space2,
          vertical: MqSpacing.space2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: MqSpacing.space2,
                vertical: MqSpacing.space1,
              ),
              child: Text(
                event.venueName,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : MqColors.contentPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                MqSpacing.space2,
                0,
                MqSpacing.space2,
                MqSpacing.space2,
              ),
              child: Text(
                event.title,
                style: context.textTheme.bodySmall?.copyWith(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.72)
                      : MqColors.contentSecondary,
                ),
              ),
            ),
            // Both actions are gated on a resolved building — without
            // a known buildingCode there's nothing to focus, so the
            // sheet never offers a broken action.
            if (hasResolvedBuilding) ...[
              Semantics(
                button: true,
                label: l10n.openDay_viewInCampusMapSemantic(event.venueName),
                child: ListTile(
                  leading: Icon(
                    Icons.location_on_rounded,
                    color: dark ? MqColors.brightRed : MqColors.red,
                  ),
                  title: Text(
                    l10n.openDay_viewInCampusMap,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(l10n.openDay_openInsideMqNav),
                  onTap: () => _routeToMap(
                    context,
                    ref,
                    renderer: MapRendererType.campus,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: l10n.openDay_navigateWithGoogleSemantic(event.venueName),
                child: ListTile(
                  leading: Icon(
                    Icons.navigation_rounded,
                    color: dark
                        ? Colors.white.withValues(alpha: 0.85)
                        : MqColors.contentPrimary,
                  ),
                  title: Text(
                    l10n.openDay_navigateWithGoogle,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(l10n.openDay_openGoogleMapsInsideNav),
                  onTap: () => _routeToMap(
                    context,
                    ref,
                    renderer: MapRendererType.google,
                  ),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsetsDirectional.all(MqSpacing.space4),
                child: Text(l10n.openDay_noMappableVenue),
              ),
          ],
        ),
      ),
    );
  }

  /// Routes the user to the in-app Navigation tab with the given
  /// renderer active and the venue selected as the single focused
  /// destination.
  ///
  /// Why both side effects rather than just navigating: the renderer
  /// state lives on `mapControllerProvider` and persists across route
  /// transitions, so setting it *before* `goNamed` ensures `MapPage`
  /// rebuilds in the right mode immediately rather than briefly
  /// flashing the user's previous default renderer.
  void _routeToMap(
    BuildContext context,
    WidgetRef ref, {
    required MapRendererType renderer,
  }) {
    Navigator.pop(context);
    ref.read(mapControllerProvider.notifier).setRenderer(renderer);
    // `/map/building/:id` lives inside the Map shell branch, so
    // GoRouter switches into the Map tab *and* `MapPage._initState`
    // reads `initialBuildingId` and calls `selectBuildingById` —
    // landing the user in single-focused-marker state automatically.
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!context.mounted) return;
      context.goNamed(
        RouteNames.buildingDetail,
        pathParameters: {'buildingId': event.buildingCode!},
      );
    });
  }

  Building? _resolveBuilding(List<Building>? buildings, String? code) {
    if (buildings == null || code == null) return null;
    final upper = code.toUpperCase();
    for (final b in buildings) {
      if (b.code.toUpperCase() == upper || b.id.toUpperCase() == upper) {
        return b;
      }
    }
    return null;
  }
}
