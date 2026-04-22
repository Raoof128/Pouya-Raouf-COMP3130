import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/notifications/data/datasources/local_notifications_service.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';
import 'package:mq_navigation/features/notifications/domain/entities/notification_preferences.dart';
import 'package:mq_navigation/features/notifications/domain/entities/reminder_request.dart';
import 'package:mq_navigation/shared/models/user_preferences.dart';

/// Handles scheduling and unscheduling of local push notifications.
///
/// Currently, this only schedules the daily "Study prompt" based on
/// user preferences. It calculates the next valid trigger time and cancels
/// any stale reminders that no longer match the user's preference.
class NotificationScheduler {
  NotificationScheduler(this._localNotificationsService);

  final LocalNotificationsService _localNotificationsService;

  Future<void> syncReminders({
    required List<NotificationPreference> preferences,
    UserPreferences? userPreferences,
    String? studyPromptTitle,
    String? studyPromptBody,
    DateTime? now,
  }) async {
    final requests = buildRequests(
      preferences: preferences,
      userPreferences: userPreferences,
      studyPromptTitle: studyPromptTitle,
      studyPromptBody: studyPromptBody,
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
    required List<NotificationPreference> preferences,
    UserPreferences? userPreferences,
    String? studyPromptTitle,
    String? studyPromptBody,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final preferenceByType = <NotificationType, NotificationPreference>{
      for (final preference in preferences) preference.type: preference,
    };
    final requests = <ReminderRequest>[];

    final studyPreference = preferenceByType[NotificationType.studyPrompt];
    if (studyPreference?.enabled == true) {
      var scheduledFor = DateTime(
        current.year,
        current.month,
        current.day,
        studyPreference!.scheduledHour,
        studyPreference.scheduledMinute,
      );

      // Apply Quiet Hours Check
      if (userPreferences?.quietHoursEnabled == true) {
        scheduledFor = _applyQuietHours(
          scheduledFor,
          userPreferences!.quietHoursStart,
          userPreferences.quietHoursEnd,
        );
      }

      if (!scheduledFor.isAfter(current)) {
        scheduledFor = scheduledFor.add(const Duration(days: 1));
        // Re-check quiet hours for the next day
        if (userPreferences?.quietHoursEnabled == true) {
          scheduledFor = _applyQuietHours(
            scheduledFor,
            userPreferences!.quietHoursStart,
            userPreferences.quietHoursEnd,
          );
        }
      }

      requests.add(
        ReminderRequest(
          notificationId: _localNotificationsService.notificationIdForStableId(
            'study_prompt_daily',
          ),
          stableId: 'study_prompt_daily',
          type: NotificationType.studyPrompt,
          title: studyPromptTitle ?? 'Study prompt',
          body:
              studyPromptBody ??
              'Review your next deadline and plan one focused study block.',
          scheduledFor: scheduledFor,
          link: '/home',
          repeatsDaily: true,
        ),
      );
    }

    AppLogger.debug('Prepared notification reminders', requests.length);
    return requests;
  }

  DateTime _applyQuietHours(DateTime time, String startStr, String endStr) {
    try {
      final startParts = startStr.split(':');
      final endParts = endStr.split(':');
      if (startParts.length != 2 || endParts.length != 2) return time;

      final startH = int.parse(startParts[0]);
      final startM = int.parse(startParts[1]);
      final endH = int.parse(endParts[0]);
      final endM = int.parse(endParts[1]);

      final start = DateTime(time.year, time.month, time.day, startH, startM);
      final end = DateTime(time.year, time.month, time.day, endH, endM);

      // If end is before start, it means quiet hours span across midnight
      final spansMidnight = end.isBefore(start);
      if (spansMidnight) {
        if (time.isAfter(start) || time.isBefore(end)) {
          // Inside quiet hours across midnight
          // Move to the end time on the current or next day
          return time.isBefore(end) ? end : end.add(const Duration(days: 1));
        }
      } else {
        if (time.isAfter(start) && time.isBefore(end)) {
          // Inside quiet hours on same day
          return end;
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to parse quiet hours', e);
    }
    return time;
  }
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(ref.watch(localNotificationsServiceProvider));
});
