import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_animations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';

class MapModeToggle extends StatelessWidget {
  const MapModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final MapRendererType value;
  final ValueChanged<MapRendererType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(MqSpacing.space1),
          decoration: BoxDecoration(
            color: isDark
                ? MqColors.charcoal850.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PillSegment(
                label: l10n.campusMap,
                isSelected: value == MapRendererType.campus,
                isDark: isDark,
                onTap: () => onChanged(MapRendererType.campus),
              ),
              _PillSegment(
                label: l10n.googleMaps,
                isSelected: value == MapRendererType.google,
                isDark: isDark,
                onTap: () => onChanged(MapRendererType.google),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillSegment extends StatelessWidget {
  const _PillSegment({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: MqAnimations.normal,
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(minHeight: MqSpacing.minTapTarget),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: MqSpacing.space6,
            vertical: MqSpacing.space2,
          ),
          decoration: BoxDecoration(
            color: isSelected ? MqColors.vividRed : Colors.transparent,
            borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
