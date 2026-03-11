import 'package:flutter/material.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';

/// Standard MQ-styled buttons.
enum MqButtonVariant { filled, outlined, text }

class MqButton extends StatelessWidget {
  const MqButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MqButtonVariant.filled,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final MqButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final spinnerColor = variant == MqButtonVariant.filled
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: spinnerColor,
            ),
          )
        : Text(label);

    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget button;
    switch (variant) {
      case MqButtonVariant.filled:
        button = icon != null
            ? FilledButton.icon(
                onPressed: effectiveOnPressed,
                icon: Icon(icon),
                label: child,
              )
            : FilledButton(onPressed: effectiveOnPressed, child: child);
      case MqButtonVariant.outlined:
        button = icon != null
            ? OutlinedButton.icon(
                onPressed: effectiveOnPressed,
                icon: Icon(icon),
                label: child,
              )
            : OutlinedButton(onPressed: effectiveOnPressed, child: child);
      case MqButtonVariant.text:
        button = icon != null
            ? TextButton.icon(
                onPressed: effectiveOnPressed,
                icon: Icon(icon),
                label: child,
              )
            : TextButton(onPressed: effectiveOnPressed, child: child);
    }

    if (isExpanded) {
      return SizedBox(
        width: double.infinity,
        height: MqSpacing.minTapTarget,
        child: button,
      );
    }
    return button;
  }
}
