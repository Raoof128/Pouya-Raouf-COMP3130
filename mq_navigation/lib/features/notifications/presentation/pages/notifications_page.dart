import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/features/notifications/data/datasources/fcm_service.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';
import 'package:mq_navigation/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:mq_navigation/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_app_bar.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';

/// Screen displaying the user's notification inbox and preference toggles.
///
/// Handles missing permissions by offering a prominent "Enable Notifications"
/// prompt at the top of the feed. Interacts with [NotificationsController]
/// to manage read states and clear items.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.watch(notificationsControllerProvider);
    final notifications = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: MqAppBar(
        title: l10n.notifications,
        actions: [
          IconButton(
            tooltip: l10n.markAllRead,
            onPressed: () => ref
                .read(notificationsControllerProvider.notifier)
                .markAllRead(),
            icon: const Icon(Icons.done_all_outlined),
          ),
        ],
      ),
      body: controller.when(
        data: (state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.permissionStatus !=
                      NotificationPermissionStatus.granted &&
                  state.permissionStatus !=
                      NotificationPermissionStatus.provisional)
                MqCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.enablePushNotificationsDesc,
                        style: context.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.pushNotificationsDesc),
                      const SizedBox(height: 12),
                      MqButton(
                        label: l10n.enableNotifications,
                        isExpanded: false,
                        onPressed: () => ref
                            .read(notificationsControllerProvider.notifier)
                            .requestPermissions(),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _PreferenceSection(state: state),
              const SizedBox(height: 16),
              notifications.when(
                data: (items) {
                  if (items.isEmpty) {
                    return MqCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.noNotificationsYet,
                            style: context.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(l10n.noNotificationsYetDesc),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsetsDirectional.only(
                              bottom: 12,
                            ),
                            child: NotificationTile(
                              notification: item,
                              onTap: () =>
                                  _openNotification(context, ref, item),
                              onMarkRead: () => ref
                                  .read(
                                    notificationsControllerProvider.notifier,
                                  )
                                  .markRead(item.id),
                              onDelete: () => ref
                                  .read(
                                    notificationsControllerProvider.notifier,
                                  )
                                  .deleteNotification(item.id),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                error: (error, _) => MqCard(child: Text(error.toString())),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        },
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    await ref
        .read(notificationsControllerProvider.notifier)
        .markRead(notification.id);
    if (notification.link != null && context.mounted) {
      context.go(notification.link!);
    }
  }
}

class _PreferenceSection extends ConsumerWidget {
  const _PreferenceSection({required this.state});

  final NotificationsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notificationsControllerProvider.notifier);

    return MqCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.notificationPreferences,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          // Only show types that have corresponding features in the app.
          for (final type in const [
            NotificationType.announcement,
            NotificationType.system,
          ])
            SwitchListTile.adaptive(
              value: state.preferenceFor(type).enabled,
              contentPadding: EdgeInsets.zero,
              title: Text(_labelFor(context, type)),
              onChanged: (value) => notifier.updatePreference(type, value),
            ),
        ],
      ),
    );
  }

  String _labelFor(BuildContext context, NotificationType type) {
    final l10n = AppLocalizations.of(context)!;
    return switch (type) {
      NotificationType.deadline => l10n.deadlineReminders,
      NotificationType.exam => l10n.examReminders,
      NotificationType.event => l10n.eventReminders,
      NotificationType.announcement => l10n.announcements,
      NotificationType.system => l10n.systemAlerts,
      NotificationType.studyPrompt => l10n.studyPromptLabel,
    };
  }
}
