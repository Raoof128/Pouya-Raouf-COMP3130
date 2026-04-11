import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/notifications/data/datasources/local_notifications_service.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';
import 'package:mq_navigation/features/notifications/domain/entities/notification_preferences.dart';
import 'package:mq_navigation/features/notifications/domain/services/notification_scheduler.dart';

void main() {
  group('NotificationPreference.normalized', () {
    test('fills missing preference rows with defaults', () {
      final normalized = NotificationPreference.normalized([
        const NotificationPreference(
          type: NotificationType.system,
          enabled: false,
        ),
      ]);

      expect(normalized, hasLength(NotificationType.values.length));
      expect(
        normalized
            .firstWhere(
              (preference) => preference.type == NotificationType.system,
            )
            .enabled,
        isFalse,
      );
      expect(
        normalized
            .firstWhere(
              (preference) => preference.type == NotificationType.deadline,
            )
            .enabled,
        isTrue,
      );
    });
  });

  group('NotificationScheduler', () {
    test('builds study prompt reminder', () {
      final scheduler = NotificationScheduler(LocalNotificationsService());
      final now = DateTime(2026, 3, 11, 8);

      final requests = scheduler.buildRequests(
        preferences: NotificationPreference.defaults(),
        now: now,
      );

      expect(requests, hasLength(1));
      final studyRequest = requests.first;
      expect(studyRequest.stableId, 'study_prompt_daily');
      expect(studyRequest.repeatsDaily, isTrue);
      expect(studyRequest.scheduledFor, DateTime(2026, 3, 11, 9));
    });

    test('returns empty when study prompt is disabled', () {
      final scheduler = NotificationScheduler(LocalNotificationsService());
      final now = DateTime(2026, 3, 11, 8);

      final preferences = NotificationPreference.defaults()
          .map(
            (p) => p.type == NotificationType.studyPrompt
                ? const NotificationPreference(
                    type: NotificationType.studyPrompt,
                    enabled: false,
                  )
                : p,
          )
          .toList();

      final requests = scheduler.buildRequests(
        preferences: preferences,
        now: now,
      );

      expect(requests, isEmpty);
    });
  });
}
