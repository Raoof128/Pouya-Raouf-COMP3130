import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';

@immutable
class ReminderRequest {
  const ReminderRequest({
    required this.notificationId,
    required this.stableId,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledFor,
    this.link,
    this.payload = const <String, dynamic>{},
    this.repeatsDaily = false,
  });

  final int notificationId;
  final String stableId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime scheduledFor;
  final String? link;
  final Map<String, dynamic> payload;
  final bool repeatsDaily;

  String get encodedPayload => jsonEncode(<String, dynamic>{
    'managedBy': 'mq_navigation',
    'notificationId': notificationId,
    'stableId': stableId,
    'type': type.value,
    'link': link,
    ...payload,
  });
}
