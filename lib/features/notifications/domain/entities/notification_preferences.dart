import 'package:flutter/foundation.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';

@immutable
class NotificationPreference {
  const NotificationPreference({
    required this.type,
    required this.enabled,
    this.scheduledHour = 9,
    this.scheduledMinute = 0,
    this.updatedAt,
  });

  final NotificationType type;
  final bool enabled;
  final int scheduledHour;
  final int scheduledMinute;
  final DateTime? updatedAt;

  NotificationPreference copyWith({
    NotificationType? type,
    bool? enabled,
    int? scheduledHour,
    int? scheduledMinute,
    DateTime? updatedAt,
  }) {
    return NotificationPreference(
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      scheduledHour: scheduledHour ?? this.scheduledHour,
      scheduledMinute: scheduledMinute ?? this.scheduledMinute,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      type: NotificationType.fromValue(json['type'] as String?),
      enabled: json['enabled'] as bool? ?? true,
      scheduledHour: (json['scheduled_hour'] as num?)?.toInt() ?? 9,
      scheduledMinute: (json['scheduled_minute'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson(String userId) {
    return <String, dynamic>{
      'user_id': userId,
      'type': type.value,
      'enabled': enabled,
      'scheduled_hour': scheduledHour,
      'scheduled_minute': scheduledMinute,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static List<NotificationPreference> defaults() {
    return const <NotificationPreference>[
      NotificationPreference(type: NotificationType.deadline, enabled: true),
      NotificationPreference(type: NotificationType.exam, enabled: true),
      NotificationPreference(type: NotificationType.event, enabled: true),
      NotificationPreference(
        type: NotificationType.announcement,
        enabled: true,
      ),
      NotificationPreference(type: NotificationType.system, enabled: true),
      NotificationPreference(type: NotificationType.studyPrompt, enabled: true),
    ];
  }

  static List<NotificationPreference> normalized(
    List<NotificationPreference> preferences,
  ) {
    final byType = <NotificationType, NotificationPreference>{
      for (final preference in preferences) preference.type: preference,
    };
    return NotificationType.values
        .map((type) => byType[type] ?? _defaultFor(type))
        .toList();
  }

  static NotificationPreference _defaultFor(NotificationType type) {
    return defaults().firstWhere((preference) => preference.type == type);
  }
}
