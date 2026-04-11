import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
    required this.onDelete,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Semantics(
      label: '${notification.title}, ${notification.body}',
      child: MqCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: notification.isRead
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.primaryContainer,
              child: Icon(_iconFor(notification.type)),
            ),
            const SizedBox(width: MqSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat(
                          'EEE d MMM • h:mm a',
                        ).format(notification.createdAt),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: MqSpacing.space2),
                  Text(notification.body, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: MqSpacing.space2),
                  Wrap(
                    spacing: MqSpacing.space2,
                    children: [
                      if (!notification.isRead)
                        TextButton(
                          onPressed: onMarkRead,
                          child: Text(l10n.markAsRead),
                        ),
                      TextButton(onPressed: onDelete, child: Text(l10n.delete)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(NotificationType type) {
    return switch (type) {
      NotificationType.deadline => Icons.assignment_late_outlined,
      NotificationType.exam => Icons.school_outlined,
      NotificationType.event => Icons.event_outlined,
      NotificationType.announcement => Icons.campaign_outlined,
      NotificationType.system => Icons.security_outlined,
      NotificationType.studyPrompt => Icons.menu_book_outlined,
    };
  }
}
