import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/nav_instruction.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';

class RoutePanel extends StatefulWidget {
  const RoutePanel({
    super.key,
    required this.selectedBuilding,
    required this.route,
    required this.travelMode,
    required this.isLoading,
    required this.isNavigating,
    required this.hasArrived,
    required this.onLoadRoute,
    required this.onClearRoute,
    required this.onClearSelection,
    required this.onTravelModeChanged,
    required this.onStartNavigation,
    required this.onStopNavigation,
    required this.onDismissArrival,
    required this.onOpenInGoogleMaps,
    required this.onOpenStreetView,
  });

  final Building? selectedBuilding;
  final MapRoute? route;
  final TravelMode travelMode;
  final bool isLoading;
  final bool isNavigating;
  final bool hasArrived;
  final Future<void> Function() onLoadRoute;
  final VoidCallback onClearRoute;
  final VoidCallback onClearSelection;
  final ValueChanged<TravelMode> onTravelModeChanged;
  final VoidCallback onStartNavigation;
  final VoidCallback onStopNavigation;
  final VoidCallback onDismissArrival;
  final VoidCallback onOpenInGoogleMaps;
  final VoidCallback onOpenStreetView;

  @override
  State<RoutePanel> createState() => _RoutePanelState();
}

class _RoutePanelState extends State<RoutePanel> {
  bool _stepsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Arrival celebration
    if (widget.hasArrived) {
      return _ArrivalCard(
        buildingName: widget.selectedBuilding?.name ?? '',
        arrivedLabel: l10n.youveArrived,
        doneLabel: l10n.done,
        onDismiss: widget.onDismissArrival,
      );
    }

    return MqCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Travel mode selector — hidden during active navigation
          if (!widget.isNavigating)
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
                selected: <TravelMode>{widget.travelMode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  widget.onTravelModeChanged(selection.first);
                },
              ),
            ),
          if (!widget.isNavigating) const SizedBox(height: 16),

          // Building name + close
          if (widget.selectedBuilding != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.selectedBuilding!.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: l10n.clear,
                  onPressed: widget.isNavigating
                      ? widget.onStopNavigation
                      : widget.onClearSelection,
                ),
              ],
            ),

          // Route loaded
          if (widget.route != null) ...[
            const SizedBox(height: MqSpacing.space2),

            // Next instruction highlight during navigation
            if (widget.isNavigating && widget.route!.instructions.isNotEmpty)
              _NextInstructionCard(
                instruction: widget.route!.instructions.first,
              ),

            // Route summary bar
            _RouteSummaryBar(route: widget.route!, l10n: l10n),

            // Expandable step list
            if (widget.route!.instructions.isNotEmpty) ...[
              const SizedBox(height: MqSpacing.space2),
              _ExpandableStepList(
                instructions: widget.route!.instructions,
                isNavigating: widget.isNavigating,
                isExpanded: _stepsExpanded,
                onToggle: () =>
                    setState(() => _stepsExpanded = !_stepsExpanded),
              ),
            ],

            const SizedBox(height: MqSpacing.space3),

            // Action buttons
            if (widget.isNavigating)
              MqButton(
                label: l10n.clear,
                variant: MqButtonVariant.outlined,
                onPressed: widget.onStopNavigation,
              )
            else ...[
              MqButton(
                label: l10n.walkingDirections,
                onPressed: widget.onStartNavigation,
              ),
              const SizedBox(height: MqSpacing.space2),
              Row(
                children: [
                  Expanded(
                    child: MqButton(
                      label: l10n.clear,
                      variant: MqButtonVariant.outlined,
                      onPressed: widget.onClearRoute,
                    ),
                  ),
                  if (widget.selectedBuilding != null) ...[
                    const SizedBox(width: MqSpacing.space2),
                    Semantics(
                      button: true,
                      label: l10n.openStreetView,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onOpenStreetView,
                          borderRadius: BorderRadius.circular(
                            MqSpacing.radiusMd,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: MqSpacing.minTapTarget,
                              minHeight: MqSpacing.minTapTarget,
                            ),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: MqSpacing.space3,
                              vertical: MqSpacing.space3,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: context.isDarkMode
                                    ? MqColors.charcoal700
                                    : MqColors.charcoal600.withValues(
                                        alpha: 0.3,
                                      ),
                              ),
                              borderRadius: BorderRadius.circular(
                                MqSpacing.radiusMd,
                              ),
                            ),
                            child: const Icon(Icons.streetview, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: MqSpacing.space2),
                  Semantics(
                    button: true,
                    label: l10n.openInGoogleMaps,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onOpenInGoogleMaps,
                        borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MqSpacing.space3,
                            vertical: MqSpacing.space3,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: context.isDarkMode
                                  ? MqColors.charcoal700
                                  : MqColors.charcoal600.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(
                              MqSpacing.radiusMd,
                            ),
                          ),
                          child: const Icon(Icons.open_in_new, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ]
          // No route yet
          else ...[
            const SizedBox(height: MqSpacing.space2),
            Text(
              widget.isLoading ? l10n.loadingRoute : l10n.routeReady,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: MqSpacing.space3),
            MqButton(
              label: widget.isLoading
                  ? l10n.loadingRoute
                  : _directionsLabel(l10n),
              isLoading: widget.isLoading,
              onPressed: widget.selectedBuilding == null
                  ? null
                  : widget.onLoadRoute,
            ),
          ],
        ],
      ),
    );
  }

  String _directionsLabel(AppLocalizations l10n) {
    return switch (widget.travelMode) {
      TravelMode.walk => l10n.walkingDirections,
      TravelMode.drive => l10n.drive,
      TravelMode.bike => l10n.bike,
      TravelMode.transit => l10n.transit,
    };
  }
}

class _RouteSummaryBar extends StatelessWidget {
  const _RouteSummaryBar({required this.route, required this.l10n});

  final MapRoute route;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final duration = _fmtDuration(route.durationSeconds, l10n);
    final eta = DateFormat('h:mm a').format(route.arrivalAt);
    final distance = _fmtDistance(route.distanceMeters, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MqSpacing.space3,
        vertical: MqSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: isDark ? MqColors.charcoal800 : MqColors.sand100,
        borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                duration,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '${l10n.eta} $eta',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? MqColors.contentSecondaryDark
                      : MqColors.contentTertiary,
                ),
              ),
            ],
          ),
          Text(
            distance,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? MqColors.contentSecondaryDark
                  : MqColors.charcoal600,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDuration(int totalSeconds, AppLocalizations l10n) {
    final m = (totalSeconds / 60).ceil().clamp(1, 999999);
    return m < 60
        ? l10n.durationMinutes(m)
        : l10n.durationHoursMinutes(m ~/ 60, m % 60);
  }

  static String _fmtDistance(int meters, AppLocalizations l10n) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} ${l10n.routeKilometersShort}';
    }
    return '$meters ${l10n.routeMetersShort}';
  }
}

class _NextInstructionCard extends StatelessWidget {
  const _NextInstructionCard({required this.instruction});

  final NavInstruction instruction;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: MqSpacing.space2),
      padding: const EdgeInsets.symmetric(
        horizontal: MqSpacing.space3,
        vertical: MqSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a3a5c) : const Color(0xFFe8f0fe),
        borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
        border: Border.all(
          color: isDark ? const Color(0xFF3b6fa0) : const Color(0xFFc2d9f7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            instruction.text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF8ab4f8) : const Color(0xFF1a73e8),
            ),
          ),
          if (instruction.distanceMeters > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: Text(
                instruction.distanceMeters >= 1000
                    ? '${(instruction.distanceMeters / 1000).toStringAsFixed(1)} km'
                    : '${instruction.distanceMeters} m',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? const Color(0xFF6ea8f0)
                      : const Color(0xFF4285f4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpandableStepList extends StatelessWidget {
  const _ExpandableStepList({
    required this.instructions,
    required this.isNavigating,
    required this.isExpanded,
    required this.onToggle,
  });

  final List<NavInstruction> instructions;
  final bool isNavigating;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: MqSpacing.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: MqSpacing.space1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.stepsCount(instructions.length),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? MqColors.contentSecondaryDark
                          : MqColors.contentSecondary,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: isDark
                        ? MqColors.contentSecondaryDark
                        : MqColors.contentSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: instructions.length,
              itemBuilder: (context, index) {
                final step = instructions[index];
                final isFirst = index == 0 && isNavigating;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MqSpacing.space2,
                    vertical: MqSpacing.space2,
                  ),
                  decoration: isFirst
                      ? BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1a3a5c)
                              : const Color(0xFFe8f0fe),
                          borderRadius: BorderRadius.circular(
                            MqSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF3b6fa0)
                                : const Color(0xFFc2d9f7),
                          ),
                        )
                      : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? MqColors.charcoal800
                              : MqColors.sand100,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: MqSpacing.space2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.text,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (step.distanceMeters > 0)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  top: 2,
                                ),
                                child: Text(
                                  step.distanceMeters >= 1000
                                      ? '${(step.distanceMeters / 1000).toStringAsFixed(1)} km'
                                      : '${step.distanceMeters} m',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: isDark
                                            ? MqColors.contentSecondaryDark
                                            : MqColors.contentTertiary,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ArrivalCard extends StatelessWidget {
  const _ArrivalCard({
    required this.buildingName,
    required this.arrivedLabel,
    required this.doneLabel,
    required this.onDismiss,
  });

  final String buildingName;
  final String arrivedLabel;
  final String doneLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsetsDirectional.only(top: MqSpacing.space3),
      padding: const EdgeInsets.all(MqSpacing.space4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF052e16) : const Color(0xFFf0fdf4),
        borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
        border: Border.all(
          color: isDark ? const Color(0xFF166534) : const Color(0xFFbbf7d0),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 36,
            color: isDark ? const Color(0xFF4ade80) : const Color(0xFF16a34a),
          ),
          const SizedBox(height: MqSpacing.space2),
          Text(
            arrivedLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFbbf7d0) : const Color(0xFF166534),
            ),
          ),
          if (buildingName.isNotEmpty) ...[
            const SizedBox(height: MqSpacing.space1),
            Text(
              buildingName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? const Color(0xFF86efac)
                    : const Color(0xFF15803d),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: MqSpacing.space3),
          MqButton(label: doneLabel, onPressed: onDismiss),
        ],
      ),
    );
  }
}
