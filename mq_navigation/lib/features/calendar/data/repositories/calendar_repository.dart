import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/core/error/app_exception.dart' as app_error;
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/shared/models/academic_models.dart';

abstract interface class CalendarRepository {
  Future<AcademicBundle> fetchBundle({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  });

  Future<DeadlineItem?> fetchDeadlineById(String id);
  Future<DeadlineItem> saveDeadline(DeadlineItem item);
  Future<void> deleteDeadline(String id);
  Future<AcademicEvent?> fetchEventById(String id);
  Future<AcademicEvent> saveEvent(AcademicEvent item);
  Future<void> deleteEvent(String id);
  Future<TodoItem> saveTodo(TodoItem item);
  Future<void> deleteTodo(String id);
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return SupabaseCalendarRepository(Supabase.instance.client);
});

class SupabaseCalendarRepository implements CalendarRepository {
  const SupabaseCalendarRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AcademicBundle> fetchBundle({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final userId = _requireUserId();
    try {
      final unitsFuture = _client.from('units').select().eq('user_id', userId);
      final deadlinesFuture = _client
          .from('deadlines')
          .select()
          .eq('user_id', userId)
          .order('due_date');
      final eventsFuture = _client
          .from('events')
          .select()
          .eq('user_id', userId)
          .order('start_at');
      final todosFuture = _client
          .from('todos')
          .select()
          .eq('user_id', userId)
          .order('due_date');
      final gamificationFuture = _client
          .from('gamification_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      final responses = await Future.wait<dynamic>([
        unitsFuture,
        deadlinesFuture,
        eventsFuture,
        todosFuture,
        gamificationFuture,
      ]);

      final units =
          (responses[0] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .where((row) => row['deleted_at'] == null)
              .map(UnitSummary.fromJson)
              .toList()
            ..sort((a, b) => a.code.compareTo(b.code));

      final deadlines = (responses[1] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((row) => row['deleted_at'] == null)
          .map(DeadlineItem.fromJson)
          .toList();

      final events = (responses[2] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where(
            (row) => row['deleted_at'] == null && row['is_deleted'] != true,
          )
          .map(AcademicEvent.fromJson)
          .toList();

      final todos = (responses[3] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((row) => row['deleted_at'] == null)
          .map(TodoItem.fromJson)
          .toList();

      final gamificationJson = responses[4];
      final gamification = gamificationJson == null
          ? const GamificationProfile()
          : GamificationProfile.fromJson(
              Map<String, dynamic>.from(gamificationJson as Map),
            );

      return AcademicBundle(
        units: units,
        deadlines: deadlines
            .where(
              (item) =>
                  !item.dueDate.isBefore(
                    rangeStart.subtract(const Duration(days: 2)),
                  ) &&
                  !item.dueDate.isAfter(rangeEnd.add(const Duration(days: 2))),
            )
            .toList(),
        events: events
            .where(
              (item) =>
                  !item.startAt.isBefore(
                    rangeStart.subtract(const Duration(days: 2)),
                  ) &&
                  !item.startAt.isAfter(rangeEnd.add(const Duration(days: 2))),
            )
            .toList(),
        todos: todos,
        gamification: gamification,
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to fetch calendar bundle', error, stackTrace);
      throw app_error.ServerException(
        'Unable to load calendar data.',
        cause: error,
      );
    }
  }

  @override
  Future<DeadlineItem?> fetchDeadlineById(String id) async {
    final userId = _requireUserId();
    try {
      final response = await _client
          .from('deadlines')
          .select()
          .eq('user_id', userId)
          .eq('id', id)
          .maybeSingle();
      if (response == null || response['deleted_at'] != null) {
        return null;
      }
      return DeadlineItem.fromJson(Map<String, dynamic>.from(response));
    } catch (error, stackTrace) {
      AppLogger.error('Failed to fetch deadline', error, stackTrace);
      throw app_error.ServerException(
        'Unable to load the deadline.',
        cause: error,
      );
    }
  }

  @override
  Future<DeadlineItem> saveDeadline(DeadlineItem item) async {
    final userId = _requireUserId();
    try {
      final response = await _client
          .from('deadlines')
          .upsert(item.toUpsertJson(userId))
          .select()
          .single();
      return DeadlineItem.fromJson(Map<String, dynamic>.from(response));
    } catch (error, stackTrace) {
      AppLogger.error('Failed to save deadline', error, stackTrace);
      throw app_error.ServerException(
        'Unable to save the deadline.',
        cause: error,
      );
    }
  }

  @override
  Future<void> deleteDeadline(String id) async {
    try {
      await _client.from('deadlines').delete().eq('id', id);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to delete deadline', error, stackTrace);
      throw app_error.ServerException(
        'Unable to delete the deadline.',
        cause: error,
      );
    }
  }

  @override
  Future<AcademicEvent?> fetchEventById(String id) async {
    final userId = _requireUserId();
    try {
      final response = await _client
          .from('events')
          .select()
          .eq('user_id', userId)
          .eq('id', id)
          .maybeSingle();
      if (response == null ||
          response['deleted_at'] != null ||
          response['is_deleted'] == true) {
        return null;
      }
      return AcademicEvent.fromJson(Map<String, dynamic>.from(response));
    } catch (error, stackTrace) {
      AppLogger.error('Failed to fetch event', error, stackTrace);
      throw app_error.ServerException(
        'Unable to load the event.',
        cause: error,
      );
    }
  }

  @override
  Future<AcademicEvent> saveEvent(AcademicEvent item) async {
    final userId = _requireUserId();
    try {
      final response = await _client
          .from('events')
          .upsert(item.toUpsertJson(userId))
          .select()
          .single();
      return AcademicEvent.fromJson(Map<String, dynamic>.from(response));
    } catch (error, stackTrace) {
      AppLogger.error('Failed to save event', error, stackTrace);
      throw app_error.ServerException(
        'Unable to save the event.',
        cause: error,
      );
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    try {
      await _client.from('events').delete().eq('id', id);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to delete event', error, stackTrace);
      throw app_error.ServerException(
        'Unable to delete the event.',
        cause: error,
      );
    }
  }

  @override
  Future<TodoItem> saveTodo(TodoItem item) async {
    final userId = _requireUserId();
    try {
      final response = await _client
          .from('todos')
          .upsert(item.toUpsertJson(userId))
          .select()
          .single();
      return TodoItem.fromJson(Map<String, dynamic>.from(response));
    } catch (error, stackTrace) {
      AppLogger.error('Failed to save todo', error, stackTrace);
      throw app_error.ServerException(
        'Unable to save the to-do item.',
        cause: error,
      );
    }
  }

  @override
  Future<void> deleteTodo(String id) async {
    try {
      await _client.from('todos').delete().eq('id', id);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to delete todo', error, stackTrace);
      throw app_error.ServerException(
        'Unable to delete the to-do item.',
        cause: error,
      );
    }
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const app_error.AuthException(
        'You must be signed in to access calendar data.',
      );
    }
    return userId;
  }
}
