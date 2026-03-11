import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/app/router/app_router.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/core/network/connectivity_service.dart';
import 'package:mq_navigation/features/calendar/data/repositories/calendar_repository.dart';
import 'package:mq_navigation/features/notifications/data/datasources/fcm_service.dart';
import 'package:mq_navigation/features/notifications/data/datasources/local_notifications_service.dart';
import 'package:mq_navigation/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';
import 'package:mq_navigation/features/notifications/domain/entities/notification_preferences.dart';
import 'package:mq_navigation/features/notifications/domain/services/notification_scheduler.dart';
import 'package:mq_navigation/shared/providers/auth_provider.dart';

@immutable
class NotificationsState {
  const NotificationsState({
    required this.permissionStatus,
    required this.preferences,
    this.isInitialised = false,
    this.isSyncing = false,
  });

  final NotificationPermissionStatus permissionStatus;
  final List<NotificationPreference> preferences;
  final bool isInitialised;
  final bool isSyncing;

  NotificationPreference preferenceFor(NotificationType type) {
    return preferences.firstWhere(
      (item) => item.type == type,
      orElse: () => NotificationPreference(type: type, enabled: true),
    );
  }

  NotificationsState copyWith({
    NotificationPermissionStatus? permissionStatus,
    List<NotificationPreference>? preferences,
    bool? isInitialised,
    bool? isSyncing,
  }) {
    return NotificationsState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      preferences: preferences ?? this.preferences,
      isInitialised: isInitialised ?? this.isInitialised,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return Stream.value(const <AppNotification>[]);
      }
      return ref
          .watch(notificationRepositoryProvider)
          .watchNotifications(user.id);
    });

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).value;
  if (notifications == null) {
    return 0;
  }
  return notifications.where((notification) => !notification.isRead).length;
});

class NotificationsController extends AsyncNotifier<NotificationsState> {
  @override
  Future<NotificationsState> build() async {
    ref.listen<AsyncValue<Session?>>(authProvider, _handleAuthStateChanged);
    ref.listen<AsyncValue<ConnectivityStatus>>(connectivityStatusProvider, (
      _,
      next,
    ) {
      if (next.value == ConnectivityStatus.online) {
        unawaited(_syncScheduledReminders());
      }
    });

    await ref
        .read(localNotificationsServiceProvider)
        .initialize(onOpenLink: _openLink);
    await ref.read(fcmServiceProvider).initialize(onOpenLink: _openLink);

    final permissionStatus = await ref
        .read(fcmServiceProvider)
        .getPermissionStatus();
    final userId = ref.read(currentUserProvider)?.id;
    final preferences = userId == null
        ? NotificationPreference.defaults()
        : await ref
              .read(notificationRepositoryProvider)
              .fetchPreferences(userId);

    if (userId != null &&
        (permissionStatus == NotificationPermissionStatus.granted ||
            permissionStatus == NotificationPermissionStatus.provisional)) {
      await ref.read(fcmServiceProvider).syncToken(userId);
    }

    final initialState = NotificationsState(
      permissionStatus: permissionStatus,
      preferences: preferences,
      isInitialised: true,
    );
    unawaited(_syncScheduledReminders(preferencesOverride: preferences));
    return initialState;
  }

  Future<void> requestPermissions() async {
    final current =
        state.value ??
        const NotificationsState(
          permissionStatus: NotificationPermissionStatus.unknown,
          preferences: <NotificationPreference>[],
        );
    final permissionStatus = await ref
        .read(fcmServiceProvider)
        .requestPermission();
    state = AsyncData(current.copyWith(permissionStatus: permissionStatus));

    final userId = ref.read(currentUserProvider)?.id;
    if (userId != null &&
        (permissionStatus == NotificationPermissionStatus.granted ||
            permissionStatus == NotificationPermissionStatus.provisional)) {
      await ref.read(fcmServiceProvider).syncToken(userId);
    }
  }

  Future<void> updatePreference(NotificationType type, bool enabled) async {
    final current = state.value;
    final userId = ref.read(currentUserProvider)?.id;
    if (current == null) {
      return;
    }

    final updatedPreferences = current.preferences
        .map(
          (preference) => preference.type == type
              ? preference.copyWith(enabled: enabled, updatedAt: DateTime.now())
              : preference,
        )
        .toList();
    state = AsyncData(
      current.copyWith(preferences: updatedPreferences, isSyncing: true),
    );

    try {
      if (userId != null) {
        await ref
            .read(notificationRepositoryProvider)
            .savePreference(
              userId,
              updatedPreferences.firstWhere((item) => item.type == type),
            );
      }
      state = AsyncData(
        current.copyWith(preferences: updatedPreferences, isSyncing: false),
      );
      await _syncScheduledReminders(preferencesOverride: updatedPreferences);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to update notification preference',
        error,
        stackTrace,
      );
      state = AsyncData(current.copyWith(isSyncing: false));
    }
  }

  Future<void> updateStudyPromptTime(TimeOfDay time) async {
    final current = state.value;
    final userId = ref.read(currentUserProvider)?.id;
    if (current == null) {
      return;
    }

    final updatedPreferences = current.preferences
        .map(
          (preference) => preference.type == NotificationType.studyPrompt
              ? preference.copyWith(
                  scheduledHour: time.hour,
                  scheduledMinute: time.minute,
                  updatedAt: DateTime.now(),
                )
              : preference,
        )
        .toList();
    state = AsyncData(
      current.copyWith(preferences: updatedPreferences, isSyncing: true),
    );

    try {
      if (userId != null) {
        await ref
            .read(notificationRepositoryProvider)
            .savePreference(
              userId,
              updatedPreferences.firstWhere(
                (item) => item.type == NotificationType.studyPrompt,
              ),
            );
      }
      state = AsyncData(
        current.copyWith(preferences: updatedPreferences, isSyncing: false),
      );
      await _syncScheduledReminders(preferencesOverride: updatedPreferences);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to update study prompt time', error, stackTrace);
      state = AsyncData(current.copyWith(isSyncing: false));
    }
  }

  Future<void> markRead(String notificationId) {
    return ref.read(notificationRepositoryProvider).markRead(notificationId);
  }

  Future<void> markAllRead() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      return;
    }
    await ref.read(notificationRepositoryProvider).markAllRead(userId);
  }

  Future<void> deleteNotification(String notificationId) {
    return ref
        .read(notificationRepositoryProvider)
        .deleteNotification(notificationId);
  }

  void _handleAuthStateChanged(
    AsyncValue<Session?>? previous,
    AsyncValue<Session?> next,
  ) {
    final previousUserId = previous?.value?.user.id;
    final nextUserId = next.value?.user.id;
    if (previousUserId == nextUserId) {
      return;
    }

    if (previousUserId != null) {
      unawaited(ref.read(fcmServiceProvider).removeToken(previousUserId));
    }
    if (nextUserId != null) {
      unawaited(_reloadForUser(nextUserId));
    } else {
      state = const AsyncData(
        NotificationsState(
          permissionStatus: NotificationPermissionStatus.unknown,
          preferences: <NotificationPreference>[],
          isInitialised: true,
        ),
      );
    }
  }

  Future<void> _reloadForUser(String userId) async {
    final permissionStatus = await ref
        .read(fcmServiceProvider)
        .getPermissionStatus();
    final preferences = await ref
        .read(notificationRepositoryProvider)
        .fetchPreferences(userId);
    if (permissionStatus == NotificationPermissionStatus.granted ||
        permissionStatus == NotificationPermissionStatus.provisional) {
      await ref.read(fcmServiceProvider).syncToken(userId);
    }
    state = AsyncData(
      NotificationsState(
        permissionStatus: permissionStatus,
        preferences: preferences,
        isInitialised: true,
      ),
    );
    await _syncScheduledReminders(preferencesOverride: preferences);
  }

  Future<void> _syncScheduledReminders({
    List<NotificationPreference>? preferencesOverride,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      return;
    }

    try {
      final now = DateTime.now();
      final bundle = await ref
          .read(calendarRepositoryProvider)
          .fetchBundle(
            rangeStart: now.subtract(const Duration(days: 2)),
            rangeEnd: now.add(const Duration(days: 60)),
          );
      await ref
          .read(notificationSchedulerProvider)
          .syncAcademicItems(
            deadlines: bundle.deadlines,
            events: bundle.events,
            preferences:
                preferencesOverride ??
                state.value?.preferences ??
                NotificationPreference.defaults(),
          );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to sync notification reminders',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _openLink(String link) async {
    final router = ref.read(appRouterProvider);
    router.go(link.startsWith('/') ? link : '/$link');
  }
}
