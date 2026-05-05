import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';

/// Frosted-glass container matching the MQ reference web design.
///
/// Uses backdrop blur + semi-transparent background for the
/// characteristic frosted-glass overlay look. Reusable across
/// any feature that needs glass-effect containers.
class GlassPane extends StatelessWidget {
  const GlassPane({
    super.key,
    required this.isDark,
    required this.child,
    this.borderRadius = MqSpacing.radiusXl,
  });

  final bool isDark;
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? MqColors.charcoal850.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : MqColors.black.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
