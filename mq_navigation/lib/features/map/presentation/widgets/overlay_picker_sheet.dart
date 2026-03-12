import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/data/datasources/overlay_registry.dart';
import 'package:mq_navigation/features/map/domain/entities/map_overlay.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';

/// Bottom sheet that lets users toggle campus overlay layers
/// (parking, water, accessibility, permits).
class OverlayPickerSheet extends ConsumerWidget {
  const OverlayPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final activeIds =
        ref.watch(mapControllerProvider).value?.activeOverlayIds ?? const {};
    final controller = ref.read(mapControllerProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          MqSpacing.space4,
          MqSpacing.space2,
          MqSpacing.space4,
          MqSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsetsDirectional.only(
                  bottom: MqSpacing.space3,
                ),
                decoration: BoxDecoration(
                  color: isDark ? MqColors.charcoal600 : MqColors.sand300,
                  borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: MqSpacing.space1,
                bottom: MqSpacing.space3,
              ),
              child: Text(
                l10n.mapLayers,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: MqSpacing.space1,
                bottom: MqSpacing.space4,
              ),
              child: Text(
                l10n.mapLayersDesc,
                style: context.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? MqColors.contentSecondaryDark
                      : MqColors.contentSecondary,
                ),
              ),
            ),

            // Overlay toggles
            ...OverlayRegistry.overlays.map(
              (overlay) => _OverlayToggleRow(
                overlay: overlay,
                label: _resolveLabel(l10n, overlay.id),
                description: _resolveDescription(l10n, overlay.id),
                isActive: activeIds.contains(overlay.id),
                onToggle: () => controller.toggleOverlay(overlay.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _resolveLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      'parking' => l10n.overlayParking,
      'drinking_water' => l10n.overlayWater,
      'accessibility' => l10n.overlayAccessibility,
      'special_permits' => l10n.overlayPermits,
      _ => id,
    };
  }

  static String _resolveDescription(AppLocalizations l10n, String id) {
    return switch (id) {
      'parking' => l10n.overlayParkingDesc,
      'drinking_water' => l10n.overlayWaterDesc,
      'accessibility' => l10n.overlayAccessibilityDesc,
      'special_permits' => l10n.overlayPermitsDesc,
      _ => '',
    };
  }
}

class _OverlayToggleRow extends StatelessWidget {
  const _OverlayToggleRow({
    required this.overlay,
    required this.label,
    required this.description,
    required this.isActive,
    required this.onToggle,
  });

  final MapOverlay overlay;
  final String label;
  final String description;
  final bool isActive;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final overlayColor =
        overlay.color ?? (isDark ? MqColors.sand400 : MqColors.charcoal700);

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: MqSpacing.minTapTarget),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: MqSpacing.space1,
            vertical: MqSpacing.space2,
          ),
          child: Row(
            children: [
              // Colored indicator circle
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: overlayColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: MqSpacing.space3),

              // Label and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: MqSpacing.space1),
                    Text(
                      description,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? MqColors.contentSecondaryDark
                            : MqColors.contentTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MqSpacing.space2),

              // Toggle switch
              Switch.adaptive(
                value: isActive,
                onChanged: (_) => onToggle(),
                activeTrackColor: overlayColor.withValues(alpha: 0.5),
                activeThumbColor: overlayColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
