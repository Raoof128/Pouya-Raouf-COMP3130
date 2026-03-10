import 'package:flutter/material.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';

/// Shows a standard MQ-styled modal bottom sheet with a drag handle.
Future<T?> showMqBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isDismissible = true,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: isScrollControlled,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(MqSpacing.radiusLg),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: MqSpacing.space3),
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: MqSpacing.space4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MqSpacing.space4,
                  ),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
              const SizedBox(height: MqSpacing.space4),
              child,
              const SizedBox(height: MqSpacing.space4),
            ],
          ),
        ),
      );
    },
  );
}
