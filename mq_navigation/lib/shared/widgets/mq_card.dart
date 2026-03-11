import 'package:flutter/material.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';

/// Standard MQ-styled card with consistent padding and shape.
class MqCard extends StatelessWidget {
  const MqCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(MqSpacing.space4),
      child: child,
    );

    if (onTap != null) {
      return Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          child: content,
        ),
      );
    }

    return Card(child: content);
  }
}
