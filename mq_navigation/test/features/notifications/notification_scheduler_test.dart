import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/notifications/data/datasources/local_notifications_service.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';
import 'package:mq_navigation/features/notifications/domain/entities/notification_preferences.dart';
import 'package:mq_navigation/features/notifications/domain/services/notification_scheduler.dart';
import 'package:mq_navigation/shared/models/academic_models.dart';

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
    test('builds stable reminder ids and times for academic items', () {
      final scheduler = NotificationScheduler(LocalNotificationsService());
      final now = DateTime(2026, 3, 11, 8);

      final requests = scheduler.buildRequests(
        deadlines: [
          DeadlineItem(
            id: 'deadline-1',
            unitCode: 'COMP3130',
            title: 'Migration report',
            dueDate: now.add(const Duration(days: 3)),
          ),
          DeadlineItem(
            id: 'exam-1',
            unitCode: 'COMP3130',
            title: 'Final exam',
            dueDate: now.add(const Duration(days: 5, hours: 2)),
            type: AcademicItemType.exam,
          ),
        ],
        events: [
          AcademicEvent(
            id: 'event-1',
            title: 'Study Jam',
            startAt: now.add(const Duration(days: 1, hours: 4)),
          ),
        ],
        preferences: NotificationPreference.defaults(),
        now: now,
      );

      final deadlineRequest = requests.firstWhere(
        (request) => request.type == NotificationType.deadline,
      );
      final examRequest = requests.firstWhere(
        (request) => request.type == NotificationType.exam,
      );
      final eventRequest = requests.firstWhere(
        (request) => request.type == NotificationType.event,
      );
      final studyRequest = requests.firstWhere(
        (request) => request.type == NotificationType.studyPrompt,
      );

      expect(deadlineRequest.stableId, 'deadline_deadline-1');
      expect(deadlineRequest.scheduledFor, now.add(const Duration(days: 2)));
      expect(examRequest.stableId, 'exam_exam-1');
      expect(
        examRequest.scheduledFor,
        now.add(const Duration(days: 5, hours: 1)),
      );
      expect(eventRequest.stableId, 'event_event-1');
      expect(
        eventRequest.scheduledFor,
        now.add(const Duration(days: 1, hours: 3, minutes: 30)),
      );
      expect(studyRequest.stableId, 'study_prompt_daily');
      expect(studyRequest.repeatsDaily, isTrue);
      expect(studyRequest.scheduledFor, DateTime(2026, 3, 11, 9));
    });
  });
}
