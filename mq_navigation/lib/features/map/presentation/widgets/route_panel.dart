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

    return MqCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<TravelMode>(
              segments: [
                ButtonSegment(
                  value: TravelMode.walk,
                  label: FittedBox(child: Text(l10n.walk)),
                  icon: const Icon(Icons.directions_walk, size: 18),
                ),
                ButtonSegment(
                  value: TravelMode.drive,
                  label: FittedBox(child: Text(l10n.drive)),
                  icon: const Icon(Icons.directions_car, size: 18),
                ),
                ButtonSegment(
                  value: TravelMode.bike,
                  label: FittedBox(child: Text(l10n.bike)),
                  icon: const Icon(Icons.directions_bike, size: 18),
                ),
                ButtonSegment(
                  value: TravelMode.transit,
                  label: FittedBox(child: Text(l10n.transit)),
                  icon: const Icon(Icons.directions_transit, size: 18),
                ),
              ],
              selected: <TravelMode>{travelMode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                onTravelModeChanged(selection.first);
              },
            ),
          ),
          const SizedBox(height: 16),
          if (selectedBuilding != null)
            Text(
              selectedBuilding!.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          if (route != null) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.eta}: ${DateFormat('h:mm a').format(route!.arrivalAt)} · ${_distanceLabel(route!.distanceMeters, l10n)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...route!.instructions
                .take(3)
                .map(
                  (instruction) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${instruction.text}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
              selectedBuilding == null
                  ? l10n.routeReady
                  : l10n.loadingRoute,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            MqButton(
              label: isLoading
                  ? l10n.loadingRoute
                  : _directionsLabel(l10n),
              isLoading: isLoading,
              onPressed: selectedBuilding == null ? null : onLoadRoute,
            ),
          ],
        ],
      ),
    );
  }

  String _directionsLabel(AppLocalizations l10n) {
    return switch (travelMode) {
      TravelMode.walk => l10n.walkingDirections,
      TravelMode.drive => l10n.drive,
      TravelMode.bike => l10n.bike,
      TravelMode.transit => l10n.transit,
    };
  }

  String _distanceLabel(int distanceMeters, AppLocalizations l10n) {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} ${l10n.routeKilometersShort}';
    }
    return '$distanceMeters ${l10n.routeMetersShort}';
  }
}
