import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';
import 'package:mq_navigation/features/notifications/domain/entities/notification_preferences.dart';

class NotificationRemoteSource {
  NotificationRemoteSource(this._client);

  final SupabaseClient _client;

  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: const <String>['id'])
        .eq('user_id', userId)
        .map((rows) {
          final items =
              rows
                  .cast<Map<String, dynamic>>()
                  .where((row) => row['deleted_at'] == null)
                  .map(AppNotification.fromJson)
                  .toList()
                ..sort(
                  (left, right) => right.createdAt.compareTo(left.createdAt),
                );
          return items;
        });
  }

  Future<List<NotificationPreference>> fetchPreferences(String userId) async {
    final response = await _client
        .from('notification_preferences')
        .select()
        .eq('user_id', userId);
    final preferences = (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(NotificationPreference.fromJson)
        .toList();
    return NotificationPreference.normalized(
      preferences.isEmpty ? NotificationPreference.defaults() : preferences,
    );
  }

  Future<void> upsertPreference(
    String userId,
    NotificationPreference preference,
  ) {
    return _client
        .from('notification_preferences')
        .upsert(preference.toJson(userId), onConflict: 'user_id,type');
  }

  Future<void> markRead(String notificationId) {
    return _client
        .from('notifications')
        .update(<String, dynamic>{'read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllRead(String userId) {
    return _client
        .from('notifications')
        .update(<String, dynamic>{'read': true})
        .eq('user_id', userId);
  }

  Future<void> softDelete(String notificationId) {
    return _client
        .from('notifications')
        .update(<String, dynamic>{
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', notificationId);
  }

  Future<void> upsertFcmToken({
    required String userId,
    required String token,
    required String platform,
  }) {
    return _client.from('user_fcm_tokens').upsert(<String, dynamic>{
      'user_id': userId,
      'token': token,
      'platform': platform,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,token');
  }

  Future<void> deleteFcmToken({required String userId, required String token}) {
    return _client
        .from('user_fcm_tokens')
        .delete()
        .eq('user_id', userId)
        .eq('token', token);
  }
}

final notificationRemoteSourceProvider = Provider<NotificationRemoteSource>((
  ref,
) {
  return NotificationRemoteSource(Supabase.instance.client);
});
