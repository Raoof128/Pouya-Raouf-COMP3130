import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_animations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/nav_instruction.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';

/// Floating bottom sheet displaying routing instructions and status.
///
/// Reacts dynamically to state changes during active navigation (e.g., showing
/// the next immediate turn, updating distance/ETA, or displaying the arrival
/// celebration card).
class RoutePanel extends StatefulWidget {
  const RoutePanel({
    super.key,
    required this.selectedBuilding,
    required this.route,
    required this.travelMode,
    required this.supportedTravelModes,
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
  final List<TravelMode> supportedTravelModes;
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
    final isDark = context.isDarkMode;

    if (widget.selectedBuilding == null) {
      return const SizedBox.shrink();
    }

    // Arrival celebration
    if (widget.hasArrived) {
      return _ArrivalCard(
        buildingName: widget.selectedBuilding?.name ?? '',
        arrivedLabel: l10n.youveArrived,
        doneLabel: l10n.done,
        onDismiss: widget.onDismissArrival,
        isDark: isDark,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: MqSpacing.space3,
          sigmaY: MqSpacing.space3,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? MqColors.charcoal800.withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : MqColors.charcoal800.withValues(alpha: 0.06),
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: MqColors.charcoal800.withValues(
                  alpha: isDark ? 0.30 : 0.10,
                ),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(MqSpacing.space6),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : MqColors.black12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: MqSpacing.space6),

                // Building name + close button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.selectedBuilding!.name,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : MqColors.contentPrimary,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: MqSpacing.space1),
                          Row(
                            children: [
                              Flexible(
                                child: Text.rich(
                                  TextSpan(
                                    text: '${l10n.buildingCode}: ',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: isDark
                                              ? Colors.white
                                              : MqColors.contentTertiary,
                                        ),
                                    children: [
                                      TextSpan(
                                        text: widget.selectedBuilding!.code,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : MqColors.contentPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.selectedBuilding!.category !=
                                  BuildingCategory.other) ...[
                                const SizedBox(width: MqSpacing.space2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: MqSpacing.space3,
                                    vertical: MqSpacing.space1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: MqColors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                      MqSpacing.radiusFull,
                                    ),
                                  ),
                                  child: Text(
                                    widget.selectedBuilding!.category.name
                                        .toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: MqColors.red,
                                          letterSpacing: 1.2,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: MqSpacing.iconMd,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : MqColors.contentTertiary,
                      ),
                      tooltip: l10n.clear,
                      onPressed: widget.isNavigating
                          ? widget.onStopNavigation
                          : widget.onClearSelection,
                    ),
                  ],
                ),

                // Route info row (when route is loaded)
                if (widget.route != null) ...[
                  const SizedBox(height: MqSpacing.space4),
                  _RouteInfoRow(
                    route: widget.route!,
                    l10n: l10n,
                    isDark: isDark,
                  ),
                ],

                // Travel mode selector (hidden during navigation)
                if (!widget.isNavigating) ...[
                  const SizedBox(height: MqSpacing.space4),
                  _TravelModePills(
                    supportedTravelModes: widget.supportedTravelModes,
                    travelMode: widget.travelMode,
                    isDark: isDark,
                    l10n: l10n,
                    onChanged: widget.onTravelModeChanged,
                  ),
                ],

                // Next instruction (during navigation)
                if (widget.isNavigating &&
                    widget.route != null &&
                    widget.route!.instructions.isNotEmpty) ...[
                  const SizedBox(height: MqSpacing.space4),
                  _NextInstructionCard(
                    instruction: widget.route!.instructions.first,
                    isDark: isDark,
                  ),
                ],

                // Expandable steps
                if (widget.route != null &&
                    widget.route!.instructions.isNotEmpty) ...[
                  const SizedBox(height: MqSpacing.space2),
                  _ExpandableStepList(
                    instructions: widget.route!.instructions,
                    isNavigating: widget.isNavigating,
                    isExpanded: _stepsExpanded,
                    isDark: isDark,
                    onToggle: () =>
                        setState(() => _stepsExpanded = !_stepsExpanded),
                  ),
                ],

                const SizedBox(height: MqSpacing.space4),

                // Action buttons
                if (widget.route != null) ...[
                  if (widget.isNavigating)
                    _GlassOutlinedButton(
                      label: l10n.stopNavigation,
                      isDark: isDark,
                      onPressed: widget.onStopNavigation,
                    )
                  else ...[
                    _BrandActionButton(
                      label: l10n.walkingDirections,
                      icon: Icons.double_arrow_rounded,
                      onPressed: widget.onStartNavigation,
                    ),
                    const SizedBox(height: MqSpacing.space2),
                    Row(
                      children: [
                        Expanded(
                          child: _GlassOutlinedButton(
                            label: l10n.clear,
                            isDark: isDark,
                            onPressed: widget.onClearRoute,
                          ),
                        ),
                        if (widget.selectedBuilding != null) ...[
                          const SizedBox(width: MqSpacing.space2),
                          _GlassCircleAction(
                            icon: Icons.streetview,
                            tooltip: l10n.openStreetView,
                            isDark: isDark,
                            onPressed: widget.onOpenStreetView,
                          ),
                        ],
                        const SizedBox(width: MqSpacing.space2),
                        _GlassCircleAction(
                          icon: Icons.open_in_new,
                          tooltip: l10n.openInGoogleMaps,
                          isDark: isDark,
                          onPressed: widget.onOpenInGoogleMaps,
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  // No route yet — show "Get Directions" button
                  _BrandActionButton(
                    label: widget.isLoading
                        ? l10n.loadingRoute
                        : _directionsLabel(l10n),
                    icon: Icons.double_arrow_rounded,
                    isLoading: widget.isLoading,
                    onPressed: widget.selectedBuilding == null
                        ? null
                        : () => widget.onLoadRoute(),
                  ),
                ],
              ],
            ),
          ),
        ),
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

// ── Route info row (duration + distance) ───────────────────

class _RouteInfoRow extends StatelessWidget {
  const _RouteInfoRow({
    required this.route,
    required this.l10n,
    required this.isDark,
  });

  final MapRoute route;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final duration = _fmtDuration(route.durationSeconds, l10n);
    final distance = _fmtDistance(route.distanceMeters, l10n);

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 18,
          color: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : MqColors.contentTertiary,
        ),
        const SizedBox(width: MqSpacing.space2),
        Text(
          duration,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : MqColors.contentPrimary,
          ),
        ),
        const SizedBox(width: MqSpacing.space6),
        Icon(
          Icons.navigation_outlined,
          size: 18,
          color: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : MqColors.contentTertiary,
        ),
        const SizedBox(width: MqSpacing.space2),
        Text(
          distance,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : MqColors.contentPrimary,
          ),
        ),
        const Spacer(),
        Text(
          '${l10n.eta} ${DateFormat('h:mm a').format(route.arrivalAt)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white : MqColors.contentTertiary,
          ),
        ),
      ],
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

// ── Travel mode pills ──────────────────────────────────────

class _TravelModePills extends StatelessWidget {
  const _TravelModePills({
    required this.travelMode,
    required this.supportedTravelModes,
    required this.isDark,
    required this.l10n,
    required this.onChanged,
  });

  final TravelMode travelMode;
  final List<TravelMode> supportedTravelModes;
  final bool isDark;
  final AppLocalizations l10n;
  final ValueChanged<TravelMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: supportedTravelModes.map((mode) {
          final isSelected = mode == travelMode;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: MqSpacing.space2),
            child: Semantics(
              button: true,
              selected: isSelected,
              child: GestureDetector(
                onTap: () => onChanged(mode),
                child: AnimatedContainer(
                  duration: MqAnimations.normal,
                  constraints: const BoxConstraints(
                    minHeight: MqSpacing.minTapTarget,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: MqSpacing.space4,
                    vertical: MqSpacing.space2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? MqColors.red.withValues(alpha: 0.15)
                        : isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : MqColors.charcoal800.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
                    border: Border.all(
                      color: isSelected
                          ? MqColors.red.withValues(alpha: 0.4)
                          : isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : MqColors.charcoal800.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconFor(mode),
                        size: MqSpacing.iconSm,
                        color: isSelected
                            ? MqColors.red
                            : isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : MqColors.contentTertiary,
                      ),
                      const SizedBox(width: MqSpacing.space2),
                      Text(
                        _labelFor(mode),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? MqColors.red
                              : isDark
                              ? Colors.white
                              : MqColors.contentSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconFor(TravelMode mode) {
    return switch (mode) {
      TravelMode.walk => Icons.directions_walk,
      TravelMode.drive => Icons.directions_car,
      TravelMode.bike => Icons.directions_bike,
      TravelMode.transit => Icons.directions_transit,
    };
  }

  String _labelFor(TravelMode mode) {
    return switch (mode) {
      TravelMode.walk => l10n.walk,
      TravelMode.drive => l10n.drive,
      TravelMode.bike => l10n.bike,
      TravelMode.transit => l10n.transit,
    };
  }
}

// ── Next instruction card (during navigation) ──────────────

class _NextInstructionCard extends StatelessWidget {
  const _NextInstructionCard({required this.instruction, required this.isDark});

  final NavInstruction instruction;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MqSpacing.space3,
        vertical: MqSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? MqColors.navInstructionBgDark
            : MqColors.navInstructionBgLight,
        borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
        border: Border.all(
          color: isDark
              ? MqColors.navInstructionBorderDark
              : MqColors.navInstructionBorderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            instruction.text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : MqColors.navInstructionTextLight,
            ),
          ),
          if (instruction.distanceMeters > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: Text(
                instruction.distanceMeters >= 1000
                    ? '${(instruction.distanceMeters / 1000).toStringAsFixed(1)} ${l10n.routeKilometersShort}'
                    : '${instruction.distanceMeters} ${l10n.routeMetersShort}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? Colors.white
                      : MqColors.navInstructionSubtextLight,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Expandable step list ───────────────────────────────────

class _ExpandableStepList extends StatelessWidget {
  const _ExpandableStepList({
    required this.instructions,
    required this.isNavigating,
    required this.isExpanded,
    required this.isDark,
    required this.onToggle,
  });

  final List<NavInstruction> instructions;
  final bool isNavigating;
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
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
                      color: isDark ? Colors.white : MqColors.contentSecondary,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
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
                              ? MqColors.navInstructionBgDark
                              : MqColors.navInstructionBgLight,
                          borderRadius: BorderRadius.circular(
                            MqSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: isDark
                                ? MqColors.navInstructionBorderDark
                                : MqColors.navInstructionBorderLight,
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
                              ? Colors.white.withValues(alpha: 0.08)
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
                                      ? '${(step.distanceMeters / 1000).toStringAsFixed(1)} ${l10n.routeKilometersShort}'
                                      : '${step.distanceMeters} ${l10n.routeMetersShort}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: isDark
                                            ? Colors.white
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

// ── Action buttons ─────────────────────────────────────────

/// Full-width brand-red action button matching the reference design.
class _BrandActionButton extends StatelessWidget {
  const _BrandActionButton({
    required this.label,
    this.icon,
    this.isLoading = false,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: effectiveOnPressed == null
            ? MqColors.red.withValues(alpha: 0.5)
            : MqColors.red,
        borderRadius: BorderRadius.circular(MqSpacing.radiusLg),
        elevation: effectiveOnPressed == null ? 0 : 4,
        shadowColor: MqColors.red.withValues(alpha: 0.3),
        child: InkWell(
          onTap: effectiveOnPressed,
          borderRadius: BorderRadius.circular(MqSpacing.radiusLg),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: MqSpacing.minTapTarget + 8,
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 22),
                        const SizedBox(width: MqSpacing.space2),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Outlined button with glass-like appearance.
class _GlassOutlinedButton extends StatelessWidget {
  const _GlassOutlinedButton({
    required this.label,
    required this.isDark,
    required this.onPressed,
  });

  final String label;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: MqSpacing.minTapTarget,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: MqSpacing.space3,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : MqColors.black12,
              ),
              borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : MqColors.contentSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small circular action icon (street view, google maps link).
class _GlassCircleAction extends StatelessWidget {
  const _GlassCircleAction({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: MqSpacing.minTapTarget,
              minHeight: MqSpacing.minTapTarget,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : MqColors.black12,
              ),
              borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
            ),
            child: Icon(
              icon,
              size: MqSpacing.iconMd,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : MqColors.contentSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Arrival celebration ────────────────────────────────────

class _ArrivalCard extends StatelessWidget {
  const _ArrivalCard({
    required this.buildingName,
    required this.arrivedLabel,
    required this.doneLabel,
    required this.onDismiss,
    required this.isDark,
  });

  final String buildingName;
  final String arrivedLabel;
  final String doneLabel;
  final VoidCallback onDismiss;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: MqSpacing.space3,
          sigmaY: MqSpacing.space3,
        ),
        child: Container(
          padding: const EdgeInsets.all(MqSpacing.space6),
          decoration: BoxDecoration(
            color: isDark
                ? MqColors.arrivalBgDark.withValues(alpha: 0.94)
                : MqColors.arrivalBgLight.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
            border: Border.all(
              color: isDark
                  ? MqColors.arrivalBorderDark
                  : MqColors.arrivalBorderLight,
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: MqColors.charcoal800.withValues(
                  alpha: isDark ? 0.30 : 0.10,
                ),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 40,
                color: isDark
                    ? MqColors.arrivalIconDark
                    : MqColors.arrivalIconLight,
              ),
              const SizedBox(height: MqSpacing.space3),
              Text(
                arrivedLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : MqColors.arrivalTextLight,
                ),
              ),
              if (buildingName.isNotEmpty) ...[
                const SizedBox(height: MqSpacing.space1),
                Text(
                  buildingName,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : MqColors.arrivalSubtextLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: MqSpacing.space4),
              _BrandActionButton(label: doneLabel, onPressed: onDismiss),
            ],
          ),
        ),
      ),
    );
  }
}
