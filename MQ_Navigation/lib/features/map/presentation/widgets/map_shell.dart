import 'package:flutter/material.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/presentation/widgets/map_action_stack.dart';
import 'package:mq_navigation/features/map/presentation/widgets/map_mode_toggle.dart';

class MapShell extends StatelessWidget {
  const MapShell({
    super.key,
    required this.mapView,
    required this.renderer,
    required this.onRendererChanged,
    required this.onCenterOnLocation,
    required this.onOpenSearch,
    this.banner,
    this.footer,
  });

  final Widget mapView;
  final MapRendererType renderer;
  final ValueChanged<MapRendererType> onRendererChanged;
  final VoidCallback onCenterOnLocation;
  final VoidCallback onOpenSearch;
  final Widget? banner;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bannerWidget = banner;
    final footerWidget = footer;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
                  child: mapView,
                ),
              ),
              PositionedDirectional(
                top: MqSpacing.space3,
                start: MqSpacing.space4,
                end: MqSpacing.space4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: MapActionStack(
                        children: [
                          MapModeToggle(
                            value: renderer,
                            onChanged: onRendererChanged,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _MapIconButton(
                                icon: Icons.search,
                                tooltip: l10n.searchBuildingsPlaceholder,
                                onPressed: onOpenSearch,
                              ),
                              const SizedBox(width: MqSpacing.space2),
                              _MapIconButton(
                                icon: Icons.my_location,
                                tooltip: l10n.centerOnLocation,
                                onPressed: onCenterOnLocation,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (bannerWidget != null) ...[
                      const SizedBox(height: MqSpacing.space3),
                      bannerWidget,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        ...(footerWidget != null ? <Widget>[footerWidget] : const <Widget>[]),
      ],
    );
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? MqColors.charcoal850.withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.96),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(MqSpacing.radiusLg),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
