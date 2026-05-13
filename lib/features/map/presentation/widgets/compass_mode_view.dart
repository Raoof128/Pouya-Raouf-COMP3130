import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/presentation/widgets/map_view_helpers.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';

class CompassModeView extends StatelessWidget {
  const CompassModeView({
    super.key,
    required this.currentLocation,
    required this.selectedBuilding,
    required this.route,
    required this.onClose,
  });

  final LocationSample? currentLocation;
  final Building? selectedBuilding;
  final MapRoute? route;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    if (currentLocation == null || selectedBuilding == null) {
      return Scaffold(
        backgroundColor: isDark ? MqColors.charcoal900 : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white : MqColors.charcoal900,
            ),
            onPressed: onClose,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final target = resolveBuildingGeographicTarget(selectedBuilding!);
    final bearingToDestination = target != null
        ? Geolocator.bearingBetween(
            currentLocation!.latitude,
            currentLocation!.longitude,
            target.latitude,
            target.longitude,
          )
        : 0.0;

    return Scaffold(
      backgroundColor: isDark ? MqColors.charcoal900 : MqColors.sand100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white : MqColors.charcoal900,
          ),
          onPressed: onClose,
        ),
        title: Text(
          l10n.compassMode,
          style: TextStyle(
            color: isDark ? Colors.white : MqColors.charcoal900,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(context, isDark, l10n, bearingToDestination),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
    double bearingToDestination,
  ) {
    final stream = FlutterCompass.events;
    if (stream == null) {
      return _buildNoSensorState(context, isDark, l10n);
    }

    return StreamBuilder<CompassEvent>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(context, isDark, l10n);
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final compassHeading = snapshot.data!.heading;
        final headingAccuracy = snapshot.data!.accuracy;

        if (compassHeading == null) {
          return _buildNoSensorState(context, isDark, l10n);
        }

        var direction = bearingToDestination - compassHeading;
        if (direction < 0) direction += 360;
        final angle = direction * (math.pi / 180);

        return SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeadingBar(
                  context, isDark, l10n, compassHeading, headingAccuracy),
              _buildRouteInfo(context, isDark, l10n),
              _buildCompassRadar(context, isDark, angle),
              _buildLandmarkHints(context, isDark, l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeadingBar(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
    double heading,
    double? accuracy,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MqSpacing.space6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MqSpacing.space4,
              vertical: MqSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: isDark ? MqColors.charcoal800 : Colors.white,
              borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.explore,
                  size: MqSpacing.iconMd,
                  color: MqColors.red,
                ),
                const SizedBox(width: MqSpacing.space2),
                Text(
                  l10n.compassHeading(heading.round().toString()),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : MqColors.charcoal900,
                  ),
                ),
                if (accuracy != null) ...[
                  const SizedBox(width: MqSpacing.space2),
                  Text(
                    l10n.compassAccuracy(accuracy.round().toString()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : MqColors.contentTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassRadar(BuildContext context, bool isDark, double angle) {
    return Expanded(
      child: Center(
        child: AnimatedRotation(
          turns: angle / (2 * math.pi),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? MqColors.charcoal800 : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: MqColors.charcoal800.withValues(
                    alpha: isDark ? 0.30 : 0.10,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 16,
                  child: Text(
                    'N',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MqColors.red,
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.navigation,
                    size: 100,
                    color: MqColors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfo(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    if (route == null) return const SizedBox.shrink();

    final distanceStr = route!.distanceMeters >= 1000
        ? '${(route!.distanceMeters / 1000).toStringAsFixed(1)} ${l10n.routeKilometersShort}'
        : '${route!.distanceMeters} ${l10n.routeMetersShort}';

    final minutes = (route!.durationSeconds / 60).ceil().clamp(1, 999999);
    final durationStr = minutes < 60
        ? l10n.durationMinutes(minutes)
        : l10n.durationHoursMinutes(minutes ~/ 60, minutes % 60);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MqSpacing.space6),
      child: Container(
        padding: const EdgeInsets.all(MqSpacing.space4),
        decoration: BoxDecoration(
          color: isDark ? MqColors.charcoal800 : Colors.white,
          borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: MqColors.charcoal800.withValues(
                alpha: isDark ? 0.30 : 0.05,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildInfoItem(context, Icons.directions_walk, durationStr, isDark),
            Container(
              width: 1,
              height: 40,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : MqColors.charcoal800.withValues(alpha: 0.1),
            ),
            _buildInfoItem(context, Icons.straighten, distanceStr, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String text,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28,
          color: isDark ? Colors.white : MqColors.charcoal900,
        ),
        const SizedBox(height: MqSpacing.space2),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : MqColors.charcoal900,
          ),
        ),
      ],
    );
  }

  Widget _buildLandmarkHints(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    if (route == null || route!.instructions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(MqSpacing.space6),
        child: Text(
          selectedBuilding?.name ?? '',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : MqColors.charcoal900,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final instruction = route!.instructions.first;

    return Padding(
      padding: const EdgeInsets.all(MqSpacing.space6),
      child: Container(
        padding: const EdgeInsets.all(MqSpacing.space5),
        decoration: BoxDecoration(
          color: isDark ? MqColors.charcoal800 : Colors.white,
          borderRadius: BorderRadius.circular(MqSpacing.radiusLg),
        ),
        child: Column(
          children: [
            Text(
              l10n.compassNextHint,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: MqColors.red,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: MqSpacing.space3),
            Text(
              instruction.text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.white : MqColors.charcoal900,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off,
            size: 64,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : MqColors.contentTertiary,
          ),
          const SizedBox(height: MqSpacing.space4),
          Text(
            l10n.compassError,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white : MqColors.charcoal900,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MqSpacing.space2),
          Text(
            l10n.compassCalibrate,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : MqColors.contentTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MqSpacing.space6),
          FilledButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.compassRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSensorState(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sensors_off,
            size: 64,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : MqColors.contentTertiary,
          ),
          const SizedBox(height: MqSpacing.space4),
          Text(
            l10n.compassNoSensor,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white : MqColors.charcoal900,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MqSpacing.space2),
          Text(
            l10n.compassCalibrate,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : MqColors.contentTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MqSpacing.space6),
          FilledButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.compassRetry),
          ),
        ],
      ),
    );
  }
}
