import 'package:flutter/material.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';

class SafetyActionCard extends StatelessWidget {
  const SafetyActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.isDestructive = false,
    this.isActive = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isActive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MqSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(MqSpacing.space4),
          decoration: BoxDecoration(
            color: isDestructive
                ? (isDark
                      ? MqColors.red.withValues(alpha: 0.15)
                      : MqColors.red.withValues(alpha: 0.08))
                : (isDark ? MqColors.charcoal800 : Colors.white),
            borderRadius: BorderRadius.circular(MqSpacing.radiusLg),
            border: Border.all(
              color: isDestructive
                  ? MqColors.red.withValues(alpha: 0.3)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : MqColors.charcoal800.withValues(alpha: 0.06)),
              width: 0.6,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? MqColors.red.withValues(alpha: 0.2)
                      : (isActive
                            ? MqColors.red.withValues(alpha: 0.15)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : MqColors.red.withValues(alpha: 0.08))),
                  borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
                ),
                child: Icon(
                  icon,
                  color: isDestructive || isActive
                      ? MqColors.red
                      : (isDark ? Colors.white : MqColors.charcoal900),
                  size: 24,
                ),
              ),
              const SizedBox(width: MqSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive
                            ? MqColors.red
                            : (isDark ? Colors.white : MqColors.charcoal900),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : MqColors.contentTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MqSpacing.space3,
                    vertical: MqSpacing.space1,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : MqColors.sand100,
                    borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
                  ),
                  child: Text(
                    value!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : MqColors.charcoal900,
                    ),
                  ),
                ),
              ?trailing,
              if (onTap != null && trailing == null)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : MqColors.contentTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
