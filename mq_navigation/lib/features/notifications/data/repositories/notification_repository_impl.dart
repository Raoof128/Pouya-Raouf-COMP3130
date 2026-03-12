import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/features/notifications/data/datasources/notification_remote_source.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';
import 'package:mq_navigation/features/notifications/domain/entities/notification_preferences.dart';

/// Repository for managing push notifications and local inbox state.
///
/// Typically acts as a thin wrapper over [NotificationRemoteSource], but
/// abstracts the network layer away from the UI controllers so that local
/// caching or offline support can be added later without touching presentation.
abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications(String userId);
  Future<List<NotificationPreference>> fetchPreferences(String userId);
  Future<void> savePreference(String userId, NotificationPreference preference);
  Future<void> markRead(String notificationId);
  Future<void> markAllRead(String userId);
  Future<void> deleteNotification(String notificationId);
}

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._remoteSource);

  final NotificationRemoteSource _remoteSource;

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _remoteSource.watchNotifications(userId);
  }

  @override
  Future<List<NotificationPreference>> fetchPreferences(String userId) {
    return _remoteSource.fetchPreferences(userId);
  }

  @override
  Future<void> savePreference(
    String userId,
    NotificationPreference preference,
  ) {
    return _remoteSource.upsertPreference(userId, preference);
  }

  @override
  Future<void> markRead(String notificationId) {
    return _remoteSource.markRead(notificationId);
  }

  @override
  Future<void> markAllRead(String userId) {
    return _remoteSource.markAllRead(userId);
  }

  @override
  Future<void> deleteNotification(String notificationId) {
    return _remoteSource.softDelete(notificationId);
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    ref.watch(notificationRemoteSourceProvider),
  );
});
