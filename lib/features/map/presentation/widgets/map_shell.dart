import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/shared/widgets/glass_pane.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/presentation/widgets/map_mode_toggle.dart';

/// Scaffold overlay for the map screen.
///
/// Wraps the underlying map renderer in a `Stack` to provide floating glass-styled
/// UI components like the search bar, mode toggle, error banners, and the
/// interactive bottom footer (routing panel or search results).
class MapShell extends StatelessWidget {
  const MapShell({
    super.key,
    required this.mapView,
    required this.renderer,
    required this.onRendererChanged,
    required this.onCenterOnLocation,
    required this.onOpenSearch,
    this.onOpenOverlayPicker,
    this.banner,
    this.footer,
    this.filterChips,
  });

  final Widget mapView;
  final MapRendererType renderer;
  final ValueChanged<MapRendererType> onRendererChanged;
  final VoidCallback onCenterOnLocation;
  final VoidCallback onOpenSearch;
  final VoidCallback? onOpenOverlayPicker;
  final Widget? banner;
  final Widget? footer;
  final Widget? filterChips;

  /// Vertical gap kept between the floating controls and the top edge of the
  /// footer panel so neither element overlaps the other.
  static const double _footerClearance = 80;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerWidget = banner;
    final footerWidget = footer;

    return Stack(
      children: [
        // ── Full-bleed map ─────────────────────────────────
        Positioned.fill(child: mapView),

        // ── Top overlay: search bar + renderer toggle ──────
        Positioned(
          top: safeTop + MqSpacing.space4,
          left: MqSpacing.space4,
          right: MqSpacing.space4,
          child: Column(
            children: [
              // Glass search bar
              Semantics(
                button: true,
                label: l10n.searchBuildingsPlaceholder,
                child: GestureDetector(
                  onTap: onOpenSearch,
                  child: _GlassPane(
                    isDark: isDark,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: MqSpacing.space4,
                        vertical: MqSpacing.space4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.4),
                            size: 20,
                          ),
                          const SizedBox(width: MqSpacing.space3),
                          Expanded(
                            child: Text(
                              l10n.searchBuildingsPlaceholder,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Category filter chips — available in both renderers so students
              // can re-filter the map without going back to the home screen.
              if (filterChips != null) ...[
                const SizedBox(height: MqSpacing.space3),
                filterChips!,
              ],

              const SizedBox(height: MqSpacing.space3),

              // Renderer toggle (centered)
              Center(
                child: MapModeToggle(
                  value: renderer,
                  onChanged: onRendererChanged,
                ),
              ),

              // Error banner
              if (bannerWidget != null) ...[
                const SizedBox(height: MqSpacing.space3),
                bannerWidget,
              ],
            ],
          ),
        ),

        // ── Footer panel (route panel / building list) ─────
        if (footerWidget != null)
          Positioned(
            bottom: safeBottom,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                MqSpacing.space4,
                0,
                MqSpacing.space4,
                MqSpacing.space4,
              ),
              child: footerWidget,
            ),
          ),

        // ── Layers button — bottom-left ────────────────────
        if (renderer == MapRendererType.campus && onOpenOverlayPicker != null)
          PositionedDirectional(
            start: MqSpacing.space4,
            bottom:
                safeBottom +
                (footerWidget != null ? _footerClearance : MqSpacing.space4),
            child: _GlassIconButton(
              isDark: isDark,
              icon: Icons.layers_outlined,
              tooltip: l10n.mapLayers,
              onPressed: onOpenOverlayPicker!,
            ),
          ),

        // ── Location button — bottom-right ─────────────────
        PositionedDirectional(
          end: MqSpacing.space4,
          bottom:
              safeBottom +
              (footerWidget != null ? _footerClearance : MqSpacing.space4),
          child: _BrandCircleButton(
            icon: Icons.my_location,
            tooltip: l10n.centerOnLocation,
            onPressed: onCenterOnLocation,
          ),
        ),
      ],
    );
  }
}

// ── Shared glass-effect components ──────────────────────────

/// Private alias for internal use.
class _GlassPane extends GlassPane {
  const _GlassPane({required super.isDark, required super.child});
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.isDark,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final bool isDark;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: isDark
              ? MqColors.charcoal850.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.8),
          shape: CircleBorder(
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: isDark ? Colors.white : Colors.black87),
            tooltip: tooltip,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

class _BrandCircleButton extends StatelessWidget {
  const _BrandCircleButton({
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
      color: MqColors.vividRed,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: MqColors.vividRed.withValues(alpha: 0.4),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
