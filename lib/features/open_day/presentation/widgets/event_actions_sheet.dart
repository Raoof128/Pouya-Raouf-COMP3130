import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/data/datasources/building_registry_source.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/open_day/domain/entities/open_day_data.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom sheet shown when the user taps the direction icon on an event.
///
/// Two actions, deliberately distinct:
///   1. "View in Campus Map" — pushes the in-app campus map and focuses
///      the event's building. The user stays inside MQ Navigation.
///   2. "Navigate with Google Maps" — opens an external Google Maps URL
///      for actual turn-by-turn navigation. The user leaves the app.
///
/// The sheet keeps the in-app option visually primary, since on-campus
/// users typically don't need turn-by-turn — they need *spatial context*.
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
    final dark = context.isDarkMode;
    final buildingsAsync = ref.watch(buildingRegistryProvider);
    final building = _resolveBuilding(buildingsAsync.value, event.buildingCode);

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
                  color: dark
                      ? MqColors.contentPrimaryDark
                      : MqColors.contentPrimary,
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
            // Primary: View in Campus Map. Hidden gracefully if the
            // building isn't in the registry (so the sheet never offers
            // a broken action).
            if (event.buildingCode != null && building != null)
              ListTile(
                leading: const Icon(
                  Icons.location_on_rounded,
                  color: MqColors.vividRed,
                ),
                title: Text(
                  'View in Campus Map',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text('Open inside MQ Navigation'),
                onTap: () {
                  Navigator.pop(context);
                  context.goNamed(
                    RouteNames.buildingDetail,
                    pathParameters: {'buildingId': event.buildingCode!},
                  );
                },
              ),
            ListTile(
              leading: Icon(
                Icons.navigation_rounded,
                color: dark
                    ? Colors.white.withValues(alpha: 0.85)
                    : MqColors.contentPrimary,
              ),
              title: Text(
                'Navigate with Google Maps',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Open external turn-by-turn directions'),
              onTap: () async {
                Navigator.pop(context);
                await _openInGoogleMaps(building, event);
              },
            ),
          ],
        ),
      ),
    );
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

  /// Opens Google Maps with the best available signal:
  ///   1. Exact lat/lng from `buildings.json` if we have it.
  ///   2. Otherwise, a search query built from venue name + "Macquarie
  ///      University" so Google can resolve it heuristically.
  Future<void> _openInGoogleMaps(Building? b, OpenDayEvent e) async {
    final Uri uri;
    if (b != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${b.latitude},${b.longitude}',
      );
    } else {
      final q = Uri.encodeQueryComponent('${e.venueName} Macquarie University');
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
