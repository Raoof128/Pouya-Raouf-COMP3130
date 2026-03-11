import 'package:flutter/foundation.dart';

enum AcademicItemType { deadline, exam, event, todo }

enum CalendarViewMode { agenda, day, week }

@immutable
class UnitSummary {
  const UnitSummary({
    required this.id,
    required this.code,
    required this.name,
    required this.colorHex,
    this.description,
    this.locationName,
    this.notificationEnabled = true,
  });

  final String id;
  final String code;
  final String name;
  final String colorHex;
  final String? description;
  final String? locationName;
  final bool notificationEnabled;

  factory UnitSummary.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    String? locationName;
    if (location is Map<String, dynamic>) {
      locationName =
          _stringOrNull(location['building']) ??
          _stringOrNull(location['name']) ??
          _stringOrNull(location['room']);
    }

    return UnitSummary(
      id: json['id'] as String,
      code: (json['code'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      colorHex: (_stringOrNull(json['color']) ?? '#A6192E').toUpperCase(),
      description: _stringOrNull(json['description']),
      locationName: locationName,
      notificationEnabled: _boolOrDefault(json['notification_enabled']),
    );
  }
}

@immutable
class DeadlineItem {
  const DeadlineItem({
    this.id,
    this.unitId,
    required this.unitCode,
    required this.title,
    this.description,
    this.type = AcademicItemType.deadline,
    required this.dueDate,
    this.priority = 'medium',
    this.building,
    this.room,
    this.colorHex,
    this.completed = false,
    this.notificationEnabled = true,
  });

  final String? id;
  final String? unitId;
  final String unitCode;
  final String title;
  final String? description;
  final AcademicItemType type;
  final DateTime dueDate;
  final String priority;
  final String? building;
  final String? room;
  final String? colorHex;
  final bool completed;
  final bool notificationEnabled;

  bool get isExam => type == AcademicItemType.exam;
  bool get isOverdue => !completed && dueDate.isBefore(DateTime.now());

  DeadlineItem copyWith({
    String? id,
    String? unitId,
    String? unitCode,
    String? title,
    String? description,
    AcademicItemType? type,
    DateTime? dueDate,
    String? priority,
    String? building,
    String? room,
    String? colorHex,
    bool? completed,
    bool? notificationEnabled,
  }) {
    return DeadlineItem(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      unitCode: unitCode ?? this.unitCode,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      building: building ?? this.building,
      room: room ?? this.room,
      colorHex: colorHex ?? this.colorHex,
      completed: completed ?? this.completed,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }

  factory DeadlineItem.fromJson(Map<String, dynamic> json) {
    final typeValue = (_stringOrNull(json['type']) ?? 'assignment')
        .toLowerCase();
    return DeadlineItem(
      id: _stringOrNull(json['id']),
      unitId: _stringOrNull(json['unit_id']),
      unitCode: (_stringOrNull(json['unit_code']) ?? 'GEN').toUpperCase(),
      title: (json['title'] as String?) ?? '',
      description: _stringOrNull(json['description']),
      type: typeValue == 'exam'
          ? AcademicItemType.exam
          : AcademicItemType.deadline,
      dueDate: _dateTimeFromJson(json['due_date']) ?? DateTime.now(),
      priority: (_stringOrNull(json['priority']) ?? 'medium').toLowerCase(),
      building: _stringOrNull(json['building']),
      room: _stringOrNull(json['room']),
      colorHex: _stringOrNull(json['color']),
      completed: _boolOrDefault(json['completed'], defaultValue: false),
      notificationEnabled: _boolOrDefault(json['notification_enabled']),
    );
  }

  Map<String, dynamic> toUpsertJson(String userId) {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'user_id': userId,
      'unit_id': unitId,
      'unit_code': unitCode,
      'title': title.trim(),
      'description': _stringOrNull(description),
      'type': isExam ? 'exam' : 'assignment',
      'due_date': dueDate.toIso8601String(),
      'priority': priority,
      'building': _stringOrNull(building),
      'room': _stringOrNull(room),
      'color': _stringOrNull(colorHex),
      'completed': completed,
      'notification_enabled': notificationEnabled,
    };
  }
}

@immutable
class AcademicEvent {
  const AcademicEvent({
    this.id,
    this.sourcePublicEventId,
    required this.title,
    this.description,
    this.location,
    this.building,
    this.room,
    required this.startAt,
    this.endAt,
    this.category = 'general',
    this.colorHex,
    this.imageUrl,
    this.allDay = false,
    this.notificationEnabled = true,
  });

  final String? id;
  final String? sourcePublicEventId;
  final String title;
  final String? description;
  final String? location;
  final String? building;
  final String? room;
  final DateTime startAt;
  final DateTime? endAt;
  final String category;
  final String? colorHex;
  final String? imageUrl;
  final bool allDay;
  final bool notificationEnabled;

  AcademicEvent copyWith({
    String? id,
    String? sourcePublicEventId,
    String? title,
    String? description,
    String? location,
    String? building,
    String? room,
    DateTime? startAt,
    DateTime? endAt,
    String? category,
    String? colorHex,
    String? imageUrl,
    bool? allDay,
    bool? notificationEnabled,
  }) {
    return AcademicEvent(
      id: id ?? this.id,
      sourcePublicEventId: sourcePublicEventId ?? this.sourcePublicEventId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      building: building ?? this.building,
      room: room ?? this.room,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      category: category ?? this.category,
      colorHex: colorHex ?? this.colorHex,
      imageUrl: imageUrl ?? this.imageUrl,
      allDay: allDay ?? this.allDay,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }

  factory AcademicEvent.fromJson(Map<String, dynamic> json) {
    return AcademicEvent(
      id: _stringOrNull(json['id']),
      sourcePublicEventId: _stringOrNull(json['source_public_event_id']),
      title: (json['title'] as String?) ?? '',
      description: _stringOrNull(json['description']),
      location: _stringOrNull(json['location']),
      building: _stringOrNull(json['building']),
      room: _stringOrNull(json['room']),
      startAt: _dateTimeFromJson(json['start_at']) ?? DateTime.now(),
      endAt: _dateTimeFromJson(json['end_at']),
      category: (_stringOrNull(json['category']) ?? 'general').toLowerCase(),
      colorHex: _stringOrNull(json['color']),
      imageUrl: _stringOrNull(json['image_url']),
      allDay: _boolOrDefault(json['all_day'], defaultValue: false),
      notificationEnabled: _boolOrDefault(json['notification_enabled']),
    );
  }

  Map<String, dynamic> toUpsertJson(String userId) {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'user_id': userId,
      'source_public_event_id': sourcePublicEventId,
      'title': title.trim(),
      'description': description?.trim() ?? '',
      'location': location?.trim() ?? '',
      'building': _stringOrNull(building),
      'room': _stringOrNull(room),
      'start_at': startAt.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'all_day': allDay,
      'category': category,
      'color': _stringOrNull(colorHex),
      'image_url': _stringOrNull(imageUrl),
      'notification_enabled': notificationEnabled,
    };
  }

  bool get isImportedFromFeed => sourcePublicEventId != null;
}

@immutable
class TodoItem {
  const TodoItem({
    this.id,
    required this.title,
    this.description,
    this.completed = false,
    this.completedAt,
    this.colorHex,
    this.priority = 'medium',
    this.dueDate,
    this.notificationEnabled = true,
  });

  final String? id;
  final String title;
  final String? description;
  final bool completed;
  final DateTime? completedAt;
  final String? colorHex;
  final String priority;
  final DateTime? dueDate;
  final bool notificationEnabled;

  bool get isOverdue =>
      !completed && dueDate != null && dueDate!.isBefore(DateTime.now());

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    DateTime? completedAt,
    String? colorHex,
    String? priority,
    DateTime? dueDate,
    bool? notificationEnabled,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      colorHex: colorHex ?? this.colorHex,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: _stringOrNull(json['id']),
      title: (json['title'] as String?) ?? '',
      description: _stringOrNull(json['description']),
      completed: _boolOrDefault(json['completed'], defaultValue: false),
      completedAt: _dateTimeFromJson(json['completed_at']),
      colorHex: _stringOrNull(json['color']),
      priority: (_stringOrNull(json['priority']) ?? 'medium').toLowerCase(),
      dueDate: _dateTimeFromJson(json['due_date']),
      notificationEnabled: _boolOrDefault(json['notification_enabled']),
    );
  }

  Map<String, dynamic> toUpsertJson(String userId) {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title.trim(),
      'description': _stringOrNull(description),
      'completed': completed,
      'completed_at': completed ? completedAt?.toIso8601String() : null,
      'color': _stringOrNull(colorHex),
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'notification_enabled': notificationEnabled,
    };
  }
}

@immutable
class GamificationProfile {
  const GamificationProfile({
    this.xp = 0,
    this.streakDays = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
  });

  final int xp;
  final int streakDays;
  final int longestStreak;
  final DateTime? lastActivityDate;

  int get level => (xp ~/ 250) + 1;
  int get xpIntoLevel => xp % 250;
  double get progressToNextLevel => xpIntoLevel / 250;

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    return GamificationProfile(
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      lastActivityDate: _dateTimeFromJson(json['last_activity_date']),
    );
  }
}

@immutable
class CalendarEntry {
  const CalendarEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.startAt,
    this.endAt,
    this.subtitle,
    this.colorHex,
    this.trailingLabel,
    this.isCompleted = false,
  });

  final String id;
  final AcademicItemType type;
  final String title;
  final DateTime startAt;
  final DateTime? endAt;
  final String? subtitle;
  final String? colorHex;
  final String? trailingLabel;
  final bool isCompleted;

  factory CalendarEntry.fromDeadline(DeadlineItem item) {
    return CalendarEntry(
      id: item.id ?? item.title,
      type: item.type,
      title: item.title,
      startAt: item.dueDate,
      subtitle: item.unitCode,
      colorHex: item.colorHex,
      trailingLabel: item.priority,
      isCompleted: item.completed,
    );
  }

  factory CalendarEntry.fromEvent(AcademicEvent item) {
    return CalendarEntry(
      id: item.id ?? item.title,
      type: AcademicItemType.event,
      title: item.title,
      startAt: item.startAt,
      endAt: item.endAt,
      subtitle: item.location ?? item.category,
      colorHex: item.colorHex,
    );
  }

  factory CalendarEntry.fromTodo(TodoItem item) {
    return CalendarEntry(
      id: item.id ?? item.title,
      type: AcademicItemType.todo,
      title: item.title,
      startAt: item.dueDate ?? DateTime.now(),
      subtitle: item.description,
      colorHex: item.colorHex,
      trailingLabel: item.priority,
      isCompleted: item.completed,
    );
  }
}

@immutable
class StressSnapshot {
  const StressSnapshot({
    required this.score,
    required this.label,
    required this.summary,
  });

  final int score;
  final String label;
  final String summary;

  factory StressSnapshot.fromData({
    required List<DeadlineItem> deadlines,
    required List<TodoItem> todos,
    required List<AcademicEvent> upcomingEvents,
  }) {
    var score = 0;
    final now = DateTime.now();
    final urgentDeadlines = deadlines.where(
      (item) =>
          !item.completed &&
          item.dueDate.isBefore(now.add(const Duration(days: 3))),
    );
    final overdueTodos = todos.where((item) => item.isOverdue);
    final priorityTodos = todos.where(
      (item) => !item.completed && item.priority == 'high',
    );

    score += deadlines.where((item) => item.isOverdue).length * 25;
    score += urgentDeadlines.length * 14;
    score += overdueTodos.length * 10;
    score += priorityTodos.length * 8;
    score += upcomingEvents.length > 4 ? 8 : 0;
    if (score > 100) {
      score = 100;
    }

    if (score >= 75) {
      return StressSnapshot(
        score: score,
        label: 'Critical',
        summary: 'Multiple urgent items need attention this week.',
      );
    }
    if (score >= 50) {
      return StressSnapshot(
        score: score,
        label: 'Busy',
        summary: 'Your workload is elevated. Focus on near-term deadlines.',
      );
    }
    if (score >= 25) {
      return StressSnapshot(
        score: score,
        label: 'Managed',
        summary:
            'You are on top of things, with a few upcoming pressure points.',
      );
    }
    return StressSnapshot(
      score: score,
      label: 'Low',
      summary: 'Your schedule looks healthy and under control.',
    );
  }
}

@immutable
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.units,
    required this.deadlines,
    required this.events,
    required this.todos,
    required this.gamification,
    required this.stress,
  });

  final List<UnitSummary> units;
  final List<DeadlineItem> deadlines;
  final List<AcademicEvent> events;
  final List<TodoItem> todos;
  final GamificationProfile gamification;
  final StressSnapshot stress;

  List<DeadlineItem> get upcomingDeadlines => deadlines.take(3).toList();
  List<DeadlineItem> get upcomingExams =>
      deadlines.where((item) => item.isExam).take(3).toList();
  List<AcademicEvent> get upcomingEvents => events.take(3).toList();
  List<TodoItem> get openTodos =>
      todos.where((item) => !item.completed).take(4).toList();
}

@immutable
class AcademicBundle {
  const AcademicBundle({
    required this.units,
    required this.deadlines,
    required this.events,
    required this.todos,
    required this.gamification,
  });

  final List<UnitSummary> units;
  final List<DeadlineItem> deadlines;
  final List<AcademicEvent> events;
  final List<TodoItem> todos;
  final GamificationProfile gamification;

  List<CalendarEntry> toCalendarEntries({
    DateTime? rangeStart,
    DateTime? rangeEnd,
    bool includeCompletedTodos = true,
  }) {
    final entries = <CalendarEntry>[
      ...deadlines.map(CalendarEntry.fromDeadline),
      ...events.map(CalendarEntry.fromEvent),
      ...todos
          .where((item) => item.dueDate != null)
          .where((item) => includeCompletedTodos || !item.completed)
          .map(CalendarEntry.fromTodo),
    ];

    return entries.where((entry) {
      final startsAfterRangeStart =
          rangeStart == null || !entry.startAt.isBefore(rangeStart);
      final endsBeforeRangeEnd =
          rangeEnd == null || !entry.startAt.isAfter(rangeEnd);
      return startsAfterRangeStart && endsBeforeRangeEnd;
    }).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));
  }
}

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

bool _boolOrDefault(Object? value, {bool defaultValue = true}) {
  if (value is bool) {
    return value;
  }
  return defaultValue;
}

DateTime? _dateTimeFromJson(Object? value) {
  final text = _stringOrNull(value);
  if (text == null) {
    return null;
  }
  return DateTime.tryParse(text);
}
