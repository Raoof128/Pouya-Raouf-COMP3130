import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

enum NotificationType {
  deadline,
  exam,
  event,
  announcement,
  system,
  studyPrompt;

  static NotificationType fromValue(String? value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.system,
    );
  }

  String get value => switch (this) {
    NotificationType.deadline => 'deadline',
    NotificationType.exam => 'exam',
    NotificationType.event => 'event',
    NotificationType.announcement => 'announcement',
    NotificationType.system => 'system',
    NotificationType.studyPrompt => 'study_prompt',
  };
}

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.link,
    this.relatedId,
    this.isRead = false,
    this.deletedAt,
    this.data = const <String, dynamic>{},
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? link;
  final String? relatedId;
  final bool isRead;
  final DateTime? deletedAt;
  final Map<String, dynamic> data;

  bool get isDeleted => deletedAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.fromValue(json['type'] as String?),
      title: (json['title'] as String?) ?? '',
      body: (json['message'] as String?) ?? (json['body'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      link: json['link'] as String?,
      relatedId: json['related_id'] as String?,
      isRead: json['read'] as bool? ?? false,
      deletedAt: DateTime.tryParse(json['deleted_at'] as String? ?? ''),
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const <String, dynamic>{},
    );
  }

  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    return AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.fromValue(message.data['type'] as String?),
      title:
          message.notification?.title ??
          (message.data['title'] as String?) ??
          '',
      body:
          message.notification?.body ?? (message.data['body'] as String?) ?? '',
      createdAt: DateTime.now(),
      link: message.data['link'] as String?,
      relatedId: message.data['relatedId'] as String?,
      data: Map<String, dynamic>.from(message.data),
    );
  }
}
