import 'dart:convert';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';
import 'package:mq_navigation/features/notifications/domain/entities/reminder_request.dart';

/// Wraps `flutter_local_notifications` to schedule and display notifications
/// generated locally by the device rather than sent from the server.
///
/// Responsible for Android channel creation, timezone initialization,
/// and handling taps on locally-scheduled reminders.
class LocalNotificationsService {
  LocalNotificationsService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialised = false;

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize({
    required Future<void> Function(String link) onOpenLink,
  }) async {
    if (_isInitialised || !_isSupported) {
      return;
    }

    tz.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = _decodePayload(response.payload);
        final link = payload['link'] as String?;
        if (link != null && link.isNotEmpty) {
          await onOpenLink(link);
        }
      },
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      for (final channel in _channels) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    _isInitialised = true;
  }

  Future<void> showForegroundNotification(AppNotification notification) async {
    if (!_isSupported) {
      return;
    }

    await _plugin.show(
      id: notificationIdForStableId(notification.id),
      title: notification.title,
      body: notification.body,
      notificationDetails: _detailsFor(notification.type),
      payload: jsonEncode(<String, dynamic>{
        'managedBy': 'mq_navigation',
        'link': notification.link,
        'type': notification.type.value,
      }),
    );
  }

  Future<void> scheduleReminder(ReminderRequest request) async {
    if (!_isSupported) {
      return;
    }

    final scheduledAt = tz.TZDateTime.from(request.scheduledFor, tz.local);
    if (scheduledAt.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    await _plugin.zonedSchedule(
      id: request.notificationId,
      title: request.title,
      body: request.body,
      scheduledDate: scheduledAt,
      notificationDetails: _detailsFor(request.type),
      payload: request.encodedPayload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: request.repeatsDaily
          ? DateTimeComponents.time
          : null,
    );
  }

  Future<void> cancel(int notificationId) {
    return _plugin.cancel(id: notificationId);
  }

  Future<void> cancelManagedNotificationsExcept(Set<int> retainedIds) async {
    // We only cancel notifications created by this app (tagged in payload).
    // This allows other plugins or modules to use the local notifications
    // system without us accidentally clearing their scheduled items.
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final payload = _decodePayload(request.payload);
      if (payload['managedBy'] == 'mq_navigation' &&
          !retainedIds.contains(request.id)) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  int notificationIdForStableId(String stableId) {
    return stableId.hashCode & 0x7fffffff;
  }

  NotificationDetails _detailsFor(NotificationType type) {
    final channel = switch (type) {
      NotificationType.deadline => _deadlineChannel,
      NotificationType.exam => _examChannel,
      NotificationType.event => _eventChannel,
      NotificationType.announcement => _announcementChannel,
      NotificationType.system => _systemChannel,
      NotificationType.studyPrompt => _studyChannel,
    };

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  Map<String, dynamic> _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return const <String, dynamic>{};
    }

    try {
      return Map<String, dynamic>.from(jsonDecode(payload) as Map);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to decode notification payload',
        error,
        stackTrace,
      );
      return const <String, dynamic>{};
    }
  }
}

const AndroidNotificationChannel _deadlineChannel = AndroidNotificationChannel(
  'deadline_reminders',
  'Deadline Reminders',
  description: 'Upcoming deadline reminders.',
  importance: Importance.high,
);

const AndroidNotificationChannel _examChannel = AndroidNotificationChannel(
  'exam_reminders',
  'Exam Reminders',
  description: 'Upcoming exam reminders.',
  importance: Importance.max,
);

const AndroidNotificationChannel _eventChannel = AndroidNotificationChannel(
  'event_reminders',
  'Event Reminders',
  description: 'Campus event reminders.',
  importance: Importance.high,
);

const AndroidNotificationChannel _announcementChannel =
    AndroidNotificationChannel(
      'announcements',
      'Announcements',
      description: 'Campus announcements and updates.',
      importance: Importance.high,
    );

const AndroidNotificationChannel _systemChannel = AndroidNotificationChannel(
  'system_alerts',
  'System Alerts',
  description: 'Urgent system alerts.',
  importance: Importance.max,
);

const AndroidNotificationChannel _studyChannel = AndroidNotificationChannel(
  'study_prompts',
  'Study Prompts',
  description: 'Daily study prompts.',
  importance: Importance.defaultImportance,
);

const List<AndroidNotificationChannel> _channels = <AndroidNotificationChannel>[
  _deadlineChannel,
  _examChannel,
  _eventChannel,
  _announcementChannel,
  _systemChannel,
  _studyChannel,
];

final localNotificationsServiceProvider = Provider<LocalNotificationsService>((
  ref,
) {
  return LocalNotificationsService();
});
