import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';

class RoutePanel extends StatelessWidget {
  const RoutePanel({
    super.key,
    required this.selectedBuilding,
    required this.route,
    required this.travelMode,
    required this.isLoading,
    required this.onLoadRoute,
    required this.onClearRoute,
    required this.onTravelModeChanged,
  });

  final Building? selectedBuilding;
  final MapRoute? route;
  final TravelMode travelMode;
  final bool isLoading;
  final Future<void> Function() onLoadRoute;
  final VoidCallback onClearRoute;
  final ValueChanged<TravelMode> onTravelModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final arrivalAt = route == null
        ? null
        : DateTime.now().add(Duration(seconds: route!.durationSeconds));

    return MqCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<TravelMode>(
            segments: [
              ButtonSegment(value: TravelMode.walk, label: Text(l10n.walk)),
              ButtonSegment(value: TravelMode.drive, label: Text(l10n.drive)),
              ButtonSegment(value: TravelMode.bike, label: Text(l10n.bike)),
              ButtonSegment(
                value: TravelMode.transit,
                label: Text(l10n.transit),
              ),
            ],
            selected: <TravelMode>{travelMode},
            onSelectionChanged: (selection) {
              onTravelModeChanged(selection.first);
            },
          ),
          const SizedBox(height: 16),
          if (selectedBuilding != null)
            Text(
              selectedBuilding!.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          if (route != null) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.eta}: ${DateFormat('h:mm a').format(arrivalAt!)} · ${_distanceLabel(route!.distanceMeters, l10n)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...route!.instructions
                .take(3)
                .map(
                  (instruction) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• ${instruction.text}'),
                  ),
                ),
            const SizedBox(height: 12),
            MqButton(
              label: l10n.clear,
              variant: MqButtonVariant.outlined,
              onPressed: onClearRoute,
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              selectedBuilding == null ? l10n.routeReady : l10n.loadingRoute,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            MqButton(
              label: isLoading ? l10n.loadingRoute : l10n.walkingDirections,
              isLoading: isLoading,
              onPressed: selectedBuilding == null ? null : onLoadRoute,
            ),
          ],
        ],
      ),
    );
  }

  String _distanceLabel(int distanceMeters, AppLocalizations l10n) {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} ${l10n.routeKilometersShort}';
    }
    return '$distanceMeters ${l10n.routeMetersShort}';
  }
}
