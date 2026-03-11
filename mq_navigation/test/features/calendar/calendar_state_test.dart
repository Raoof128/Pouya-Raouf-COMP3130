import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:mq_navigation/shared/models/academic_models.dart';

void main() {
  group('CalendarState', () {
    test('filters day entries to the focused date', () {
      final focusedDate = DateTime(2026, 3, 11, 10);
      final state = CalendarState(
        viewMode: CalendarViewMode.day,
        focusedDate: focusedDate,
        units: const [],
        deadlines: [
          DeadlineItem(
            id: 'a',
            unitCode: 'COMP1010',
            title: 'Assignment',
            dueDate: DateTime(2026, 3, 11, 18),
          ),
        ],
        events: [
          AcademicEvent(
            id: 'b',
            title: 'Seminar',
            startAt: DateTime(2026, 3, 12, 9),
          ),
        ],
        todos: const [],
        gamification: const GamificationProfile(),
      );

      expect(state.focusedDayEntries, hasLength(1));
      expect(state.focusedDayEntries.first.title, 'Assignment');
    });

    test('respects unit filters for deadline-derived entries', () {
      final state = CalendarState(
        viewMode: CalendarViewMode.agenda,
        focusedDate: DateTime(2026, 3, 11),
        units: const [],
        deadlines: [
          DeadlineItem(
            id: 'keep',
            unitId: 'unit-a',
            unitCode: 'COMP1010',
            title: 'Assignment',
            dueDate: DateTime(2026, 3, 11, 18),
          ),
          DeadlineItem(
            id: 'drop',
            unitId: 'unit-b',
            unitCode: 'STAT1170',
            title: 'Quiz',
            dueDate: DateTime(2026, 3, 12, 9),
          ),
        ],
        events: const [],
        todos: const [],
        gamification: const GamificationProfile(),
        selectedUnitIds: const {'unit-a'},
      );

      expect(state.entries, hasLength(1));
      expect(state.entries.first.id, 'keep');
    });

    test('excludes undated and out-of-range todos from the timeline', () {
      final state = CalendarState(
        viewMode: CalendarViewMode.agenda,
        focusedDate: DateTime(2026, 3, 11),
        units: const [],
        deadlines: const [],
        events: const [],
        todos: [
          TodoItem(
            id: 'visible',
            title: 'Visible',
            dueDate: DateTime(2026, 3, 13, 9),
          ),
          const TodoItem(id: 'undated', title: 'Undated'),
          TodoItem(
            id: 'outside-range',
            title: 'Outside',
            dueDate: DateTime(2026, 4, 1, 9),
          ),
        ],
        gamification: const GamificationProfile(),
      );

      expect(state.entries, hasLength(1));
      expect(state.entries.single.id, 'visible');
    });
  });
}
