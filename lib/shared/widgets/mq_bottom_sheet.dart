import 'package:flutter/material.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';

/// A styled bottom sheet container that follows the MQ design system.
///
/// Handles handle-bar rendering, consistent padding, and background
/// colors for both light and dark modes.
class MqBottomSheet extends StatelessWidget {
  const MqBottomSheet({super.key, required this.child, this.showHandle = true});

  final Widget child;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? MqColors.charcoal850 : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MqSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHandle)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: MqSpacing.space3,
                ),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.white.withAlpha(26)
                        : MqColors.black.withAlpha(26),
                    borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                MqSpacing.space5,
                MqSpacing.space4,
                MqSpacing.space5,
                MqSpacing.space6,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
