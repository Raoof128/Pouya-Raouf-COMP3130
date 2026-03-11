import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/shared/models/academic_models.dart';

void main() {
  group('StressSnapshot', () {
    test('elevates score for overdue and urgent work', () {
      final now = DateTime.now();
      final snapshot = StressSnapshot.fromData(
        deadlines: [
          DeadlineItem(
            unitCode: 'COMP1010',
            title: 'Assignment',
            dueDate: now.subtract(const Duration(hours: 2)),
          ),
          DeadlineItem(
            unitCode: 'COMP1020',
            title: 'Quiz',
            dueDate: now.add(const Duration(days: 1)),
          ),
        ],
        todos: [
          TodoItem(
            title: 'Revise lecture',
            priority: 'high',
            dueDate: now.subtract(const Duration(hours: 3)),
          ),
        ],
        upcomingEvents: [
          AcademicEvent(
            title: 'Study group',
            startAt: now.add(const Duration(hours: 2)),
          ),
        ],
      );

      expect(snapshot.score, greaterThan(40));
      expect(snapshot.label, anyOf('Busy', 'Critical'));
    });
  });

  group('GamificationProfile', () {
    test('derives level and progress from xp', () {
      const profile = GamificationProfile(xp: 620, streakDays: 7);

      expect(profile.level, 3);
      expect(profile.xpIntoLevel, 120);
      expect(profile.progressToNextLevel, closeTo(0.48, 0.001));
    });
  });

  group('AcademicEvent', () {
    test('preserves source public event ids for feed imports', () {
      final event = AcademicEvent(
        id: 'event-1',
        sourcePublicEventId: 'public-event-7',
        title: 'Orientation',
        startAt: DateTime.utc(2026, 3, 12, 9),
        endAt: DateTime.utc(2026, 3, 12, 11),
        category: 'featured',
      );

      final json = event.toUpsertJson('user-1');
      final roundTrip = AcademicEvent.fromJson({
        ...json,
        'id': 'event-1',
        'source_public_event_id': 'public-event-7',
      });

      expect(json['source_public_event_id'], 'public-event-7');
      expect(roundTrip.sourcePublicEventId, 'public-event-7');
      expect(roundTrip.isImportedFromFeed, isTrue);
    });
  });
}
