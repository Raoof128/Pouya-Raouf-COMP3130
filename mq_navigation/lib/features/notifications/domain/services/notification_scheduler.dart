import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/notifications/data/datasources/local_notifications_service.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';
import 'package:mq_navigation/features/notifications/domain/entities/notification_preferences.dart';
import 'package:mq_navigation/features/notifications/domain/entities/reminder_request.dart';
import 'package:mq_navigation/shared/models/academic_models.dart';

class NotificationScheduler {
  NotificationScheduler(this._localNotificationsService);

  final LocalNotificationsService _localNotificationsService;

  Future<void> syncAcademicItems({
    required List<DeadlineItem> deadlines,
    required List<AcademicEvent> events,
    required List<NotificationPreference> preferences,
    DateTime? now,
  }) async {
    final requests = buildRequests(
      deadlines: deadlines,
      events: events,
      preferences: preferences,
      now: now,
    );
    await _localNotificationsService.cancelManagedNotificationsExcept(
      requests.map((item) => item.notificationId).toSet(),
    );
    for (final request in requests) {
      await _localNotificationsService.scheduleReminder(request);
    }
  }

  List<ReminderRequest> buildRequests({
    required List<DeadlineItem> deadlines,
    required List<AcademicEvent> events,
    required List<NotificationPreference> preferences,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final preferenceByType = <NotificationType, NotificationPreference>{
      for (final preference in preferences) preference.type: preference,
    };
    final requests = <ReminderRequest>[];

    for (final item in deadlines) {
      if (item.id == null || item.completed || !item.notificationEnabled) {
        continue;
      }

      if (item.isExam) {
        final preference = preferenceByType[NotificationType.exam];
        if (preference?.enabled == true) {
          final scheduledFor = item.dueDate.subtract(const Duration(hours: 1));
          if (scheduledFor.isAfter(current)) {
            requests.add(
              ReminderRequest(
                notificationId: _localNotificationsService
                    .notificationIdForStableId('exam_${item.id}'),
                stableId: 'exam_${item.id}',
                type: NotificationType.exam,
                title: item.title,
                body: '${item.unitCode} exam in 1 hour',
                scheduledFor: scheduledFor,
                link: '/detail/exam/${item.id}',
              ),
            );
          }
        }
      } else {
        final preference = preferenceByType[NotificationType.deadline];
        if (preference?.enabled == true) {
          final scheduledFor = item.dueDate.subtract(const Duration(hours: 24));
          if (scheduledFor.isAfter(current)) {
            requests.add(
              ReminderRequest(
                notificationId: _localNotificationsService
                    .notificationIdForStableId('deadline_${item.id}'),
                stableId: 'deadline_${item.id}',
                type: NotificationType.deadline,
                title: item.title,
                body: '${item.unitCode} deadline due in 24 hours',
                scheduledFor: scheduledFor,
                link: '/detail/deadline/${item.id}',
              ),
            );
          }
        }
      }
    }

    final eventPreference = preferenceByType[NotificationType.event];
    if (eventPreference?.enabled == true) {
      for (final item in events) {
        if (item.id == null || !item.notificationEnabled) {
          continue;
        }
        final scheduledFor = item.startAt.subtract(const Duration(minutes: 30));
        if (scheduledFor.isAfter(current)) {
          requests.add(
            ReminderRequest(
              notificationId: _localNotificationsService
                  .notificationIdForStableId('event_${item.id}'),
              stableId: 'event_${item.id}',
              type: NotificationType.event,
              title: item.title,
              body: 'Event starts in 30 minutes',
              scheduledFor: scheduledFor,
              link: '/detail/event/${item.id}',
            ),
          );
        }
      }
    }

    final studyPreference = preferenceByType[NotificationType.studyPrompt];
    if (studyPreference?.enabled == true) {
      var scheduledFor = DateTime(
        current.year,
        current.month,
        current.day,
        studyPreference!.scheduledHour,
        studyPreference.scheduledMinute,
      );
      if (!scheduledFor.isAfter(current)) {
        scheduledFor = scheduledFor.add(const Duration(days: 1));
      }
      requests.add(
        ReminderRequest(
          notificationId: _localNotificationsService.notificationIdForStableId(
            'study_prompt_daily',
          ),
          stableId: 'study_prompt_daily',
          type: NotificationType.studyPrompt,
          title: 'Study prompt',
          body: 'Review your next deadline and plan one focused study block.',
          scheduledFor: scheduledFor,
          link: '/home',
          repeatsDaily: true,
        ),
      );
    }

    AppLogger.debug('Prepared notification reminders', requests.length);
    return requests;
  }
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(ref.watch(localNotificationsServiceProvider));
});
