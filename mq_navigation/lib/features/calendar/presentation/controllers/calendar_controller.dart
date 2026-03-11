import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/calendar/data/repositories/calendar_repository.dart';
import 'package:mq_navigation/shared/models/academic_models.dart';

@immutable
class CalendarState {
  const CalendarState({
    required this.viewMode,
    required this.focusedDate,
    required this.units,
    required this.deadlines,
    required this.events,
    required this.todos,
    required this.gamification,
    this.selectedUnitIds = const <String>{},
    this.includeCompletedItems = true,
  });

  final CalendarViewMode viewMode;
  final DateTime focusedDate;
  final List<UnitSummary> units;
  final List<DeadlineItem> deadlines;
  final List<AcademicEvent> events;
  final List<TodoItem> todos;
  final GamificationProfile gamification;
  final Set<String> selectedUnitIds;
  final bool includeCompletedItems;

  CalendarState copyWith({
    CalendarViewMode? viewMode,
    DateTime? focusedDate,
    List<UnitSummary>? units,
    List<DeadlineItem>? deadlines,
    List<AcademicEvent>? events,
    List<TodoItem>? todos,
    GamificationProfile? gamification,
    Set<String>? selectedUnitIds,
    bool? includeCompletedItems,
  }) {
    return CalendarState(
      viewMode: viewMode ?? this.viewMode,
      focusedDate: focusedDate ?? this.focusedDate,
      units: units ?? this.units,
      deadlines: deadlines ?? this.deadlines,
      events: events ?? this.events,
      todos: todos ?? this.todos,
      gamification: gamification ?? this.gamification,
      selectedUnitIds: selectedUnitIds ?? this.selectedUnitIds,
      includeCompletedItems:
          includeCompletedItems ?? this.includeCompletedItems,
    );
  }

  DateTime get weekStart {
    final weekday = focusedDate.weekday;
    return DateTime(
      focusedDate.year,
      focusedDate.month,
      focusedDate.day,
    ).subtract(Duration(days: weekday - 1));
  }

  DateTime get weekEnd => weekStart.add(const Duration(days: 6, hours: 23));

  DateTime get weekEndExclusive => weekStart.add(const Duration(days: 7));

  List<CalendarEntry> get entries {
    bool isVisible(DateTime value) =>
        !value.isBefore(weekStart) && value.isBefore(weekEndExclusive);

    final entries = <CalendarEntry>[
      ...deadlines
          .where((item) => _matchesUnit(item.unitId))
          .where((item) => isVisible(item.dueDate))
          .map(CalendarEntry.fromDeadline),
      ...events
          .where((item) => isVisible(item.startAt))
          .map(CalendarEntry.fromEvent),
      ...todos
          .where((item) => item.dueDate != null)
          .where((item) => includeCompletedItems || !item.completed)
          .where((item) => isVisible(item.dueDate!))
          .map(CalendarEntry.fromTodo),
    ]..sort((a, b) => a.startAt.compareTo(b.startAt));
    return entries;
  }

  List<CalendarEntry> get focusedDayEntries {
    final start = DateTime(
      focusedDate.year,
      focusedDate.month,
      focusedDate.day,
    );
    final end = start.add(const Duration(days: 1));
    return entries.where((entry) {
      return !entry.startAt.isBefore(start) && entry.startAt.isBefore(end);
    }).toList();
  }

  List<CalendarEntry> entriesForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return entries.where((entry) {
      return !entry.startAt.isBefore(start) && entry.startAt.isBefore(end);
    }).toList();
  }

  bool _matchesUnit(String? unitId) {
    if (selectedUnitIds.isEmpty) {
      return true;
    }
    return unitId != null && selectedUnitIds.contains(unitId);
  }
}

final calendarControllerProvider =
    AsyncNotifierProvider<CalendarController, CalendarState>(
      CalendarController.new,
    );

class CalendarController extends AsyncNotifier<CalendarState> {
  @override
  Future<CalendarState> build() async {
    return _loadState(
      focusedDate: DateTime.now(),
      viewMode: CalendarViewMode.agenda,
    );
  }

  Future<void> refresh() async {
    final current = state.value;
    state = const AsyncLoading();
    state = AsyncData(
      await _loadState(
        focusedDate: current?.focusedDate ?? DateTime.now(),
        viewMode: current?.viewMode ?? CalendarViewMode.agenda,
        selectedUnitIds: current?.selectedUnitIds ?? const <String>{},
        includeCompletedItems: current?.includeCompletedItems ?? true,
      ),
    );
  }

  void setViewMode(CalendarViewMode viewMode) {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(current.copyWith(viewMode: viewMode));
  }

  Future<void> setFocusedDate(DateTime focusedDate) async {
    final current = state.value;
    state = const AsyncLoading();
    state = AsyncData(
      await _loadState(
        focusedDate: focusedDate,
        viewMode: current?.viewMode ?? CalendarViewMode.agenda,
        selectedUnitIds: current?.selectedUnitIds ?? const <String>{},
        includeCompletedItems: current?.includeCompletedItems ?? true,
      ),
    );
  }

  void toggleUnit(String unitId) {
    final current = state.value;
    if (current == null) {
      return;
    }
    final nextSelection = <String>{...current.selectedUnitIds};
    if (!nextSelection.add(unitId)) {
      nextSelection.remove(unitId);
    }
    state = AsyncData(current.copyWith(selectedUnitIds: nextSelection));
  }

  void toggleIncludeCompletedItems(bool value) {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(current.copyWith(includeCompletedItems: value));
  }

  Future<String?> saveDeadline(DeadlineItem item) async {
    return _mutate(() async {
      await ref.read(calendarRepositoryProvider).saveDeadline(item);
      await refresh();
    });
  }

  Future<String?> deleteDeadline(String id) async {
    return _mutate(() async {
      await ref.read(calendarRepositoryProvider).deleteDeadline(id);
      await refresh();
    });
  }

  Future<String?> saveEvent(AcademicEvent item) async {
    return _mutate(() async {
      await ref.read(calendarRepositoryProvider).saveEvent(item);
      await refresh();
    });
  }

  Future<String?> deleteEvent(String id) async {
    return _mutate(() async {
      await ref.read(calendarRepositoryProvider).deleteEvent(id);
      await refresh();
    });
  }

  Future<String?> saveTodo(TodoItem item) async {
    return _mutate(() async {
      await ref.read(calendarRepositoryProvider).saveTodo(item);
      await refresh();
    });
  }

  Future<String?> deleteTodo(String id) async {
    return _mutate(() async {
      await ref.read(calendarRepositoryProvider).deleteTodo(id);
      await refresh();
    });
  }

  Future<CalendarState> _loadState({
    required DateTime focusedDate,
    required CalendarViewMode viewMode,
    Set<String> selectedUnitIds = const <String>{},
    bool includeCompletedItems = true,
  }) async {
    final weekStart = DateTime(
      focusedDate.year,
      focusedDate.month,
      focusedDate.day,
    ).subtract(Duration(days: focusedDate.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23));
    final bundle = await ref
        .read(calendarRepositoryProvider)
        .fetchBundle(rangeStart: weekStart, rangeEnd: weekEnd);
    return CalendarState(
      viewMode: viewMode,
      focusedDate: focusedDate,
      units: bundle.units,
      deadlines: bundle.deadlines,
      events: bundle.events,
      todos: bundle.todos,
      gamification: bundle.gamification,
      selectedUnitIds: selectedUnitIds,
      includeCompletedItems: includeCompletedItems,
    );
  }

  Future<String?> _mutate(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } catch (error, stackTrace) {
      AppLogger.error('Calendar mutation failed', error, stackTrace);
      return 'We could not save that change. Please try again.';
    }
  }
}
