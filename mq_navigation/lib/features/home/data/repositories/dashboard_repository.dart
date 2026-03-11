import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/features/calendar/data/repositories/calendar_repository.dart';
import 'package:mq_navigation/shared/models/academic_models.dart';

abstract interface class DashboardRepository {
  Future<DashboardSnapshot> loadDashboard();
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final calendarRepository = ref.watch(calendarRepositoryProvider);
  return SupabaseDashboardRepository(calendarRepository);
});

class SupabaseDashboardRepository implements DashboardRepository {
  const SupabaseDashboardRepository(this._calendarRepository);

  final CalendarRepository _calendarRepository;

  @override
  Future<DashboardSnapshot> loadDashboard() async {
    final now = DateTime.now();
    final bundle = await _calendarRepository.fetchBundle(
      rangeStart: now.subtract(const Duration(days: 7)),
      rangeEnd: now.add(const Duration(days: 21)),
    );

    final upcomingDeadlines = [...bundle.deadlines]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final upcomingEvents = [...bundle.events]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final todos = [...bundle.todos]
      ..sort((a, b) {
        final left = a.dueDate ?? now.add(const Duration(days: 365));
        final right = b.dueDate ?? now.add(const Duration(days: 365));
        return left.compareTo(right);
      });

    return DashboardSnapshot(
      units: bundle.units,
      deadlines: upcomingDeadlines,
      events: upcomingEvents,
      todos: todos,
      gamification: bundle.gamification,
      stress: StressSnapshot.fromData(
        deadlines: upcomingDeadlines,
        todos: todos,
        upcomingEvents: upcomingEvents.take(5).toList(),
      ),
    );
  }
}
