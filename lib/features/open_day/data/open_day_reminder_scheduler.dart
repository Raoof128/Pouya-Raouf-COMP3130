import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/notifications/data/datasources/local_notifications_service.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';
import 'package:mq_navigation/features/notifications/domain/entities/reminder_request.dart';
import 'package:mq_navigation/features/open_day/data/open_day_providers.dart';
import 'package:mq_navigation/features/open_day/domain/entities/open_day_data.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_navigation/shared/models/user_preferences.dart';

/// Stable-ID prefix used in payloads so the scheduler can identify
/// reminders it owns when reconciling. The base service's
/// `cancelManagedNotificationsExcept` already filters by `managedBy`,
/// so the prefix is purely defensive — useful if a future feature
/// adds non-Open-Day reminders.
const String _reminderStableIdPrefix = 'open_day:event:';

/// Personalised local-notification scheduler for Open Day events.
///
/// **Lifecycle**
///   1. App boots; settings + Open Day data load.
///   2. The Riverpod listener wired in `openDayReminderSchedulerProvider`
///      observes the *derived inputs* (selected bachelor, master
///      notifications toggle, Open Day toggle, lead-time minutes,
///      relevant events list).
///   3. On any input change, [reschedule] is called: it cancels every
///      previously-scheduled Open Day reminder and re-schedules a fresh
///      set based on the current state.
///
/// **Why this is a *reconciliation* model, not a diff model**
///   Rebuilding the full set is O(n) where n ≤ ~20 events — well within
///   the budget for "happens once per settings change." A diff approach
///   would have to reason about identity and timing changes; the cost
///   isn't worth it for this scale.
///
/// **Privacy**
///   Everything is local. No FCM, no Supabase. The bachelor preference
///   and the entire reminder schedule live on-device only.
class OpenDayReminderScheduler {
  OpenDayReminderScheduler({
    required LocalNotificationsService localNotifications,
  }) : _localNotifications = localNotifications;

  final LocalNotificationsService _localNotifications;

  /// Reconciles the reminder schedule with current preferences and data.
  ///
  /// Always cancels stale reminders first (via the managed-cancel API
  /// on the local-notifications service), then reschedules only when
  /// every condition for sending reminders is met.
  Future<void> reschedule({
    required UserPreferences preferences,
    required List<OpenDayEvent> events,
    required OpenDayBachelor? selectedBachelor,
    DateTime? now,
  }) async {
    try {
      final shouldSchedule =
          preferences.notificationsEnabled &&
          preferences.openDayRemindersEnabled &&
          selectedBachelor != null;

      if (!shouldSchedule) {
        // Cancel everything we own and stop. Passing an empty retention
        // set means: keep nothing of ours.
        await _localNotifications.cancelManagedNotificationsExcept(<int>{});
        return;
      }

      final leadMinutes = preferences.openDayReminderMinutesBefore.clamp(5, 60);
      final lead = Duration(minutes: leadMinutes);
      final cutoff = now ?? DateTime.now();

      final pendingIds = <int>{};
      final scheduled = <ReminderRequest>[];

      for (final event in events) {
        final fireAt = event.startTime.subtract(lead);
        if (fireAt.isBefore(cutoff)) {
          // Past or too-imminent reminder — skip rather than fire late.
          continue;
        }
        final stableId = '$_reminderStableIdPrefix${event.id}';
        final notificationId = _localNotifications.notificationIdForStableId(
          stableId,
        );
        pendingIds.add(notificationId);

        scheduled.add(
          ReminderRequest(
            notificationId: notificationId,
            stableId: stableId,
            type: NotificationType.event,
            title: _formatTitle(event, leadMinutes),
            body: _formatBody(event, selectedBachelor),
            scheduledFor: fireAt,
            link: 'mqnav://open-day',
            payload: {
              'eventId': event.id,
              'buildingCode': event.buildingCode,
              'venue': event.venueName,
            },
          ),
        );
      }

      // Cancel anything we previously scheduled that isn't in the new set.
      // The base service filters by `managedBy: mq_navigation` so other
      // notification surfaces (deadlines, exams, system alerts) are safe.
      await _localNotifications.cancelManagedNotificationsExcept(pendingIds);

      // Schedule the new set.
      for (final request in scheduled) {
        await _localNotifications.scheduleReminder(request);
      }

      AppLogger.info(
        'Open Day reminders reconciled: '
        '${scheduled.length} scheduled, lead=${leadMinutes}m, '
        'bachelor=${selectedBachelor.id}',
      );
    } catch (error, stackTrace) {
      // Failing to schedule reminders must never break the rest of the
      // app. Log and move on — the user still has the in-app schedule.
      AppLogger.warning(
        'Failed to reschedule Open Day reminders',
        error,
        stackTrace,
      );
    }
  }

  /// Headline copy. Keeps the lead-minutes context so users know how
  /// far ahead the reminder is firing without needing to open the app.
  static String _formatTitle(OpenDayEvent event, int leadMinutes) {
    return 'Open Day · in $leadMinutes min';
  }

  /// Body copy includes venue and bachelor for personalisation, e.g.
  /// "Engineering & Technology Info Session at Macquarie Theatre".
  static String _formatBody(OpenDayEvent event, OpenDayBachelor bachelor) {
    return '${event.title} at ${event.venueName}';
  }
}

/// Provider that constructs the scheduler *and* wires it to the
/// reactive state. The listener is the production trigger: any time a
/// preference upstream changes, this fires and reconciles.
///
/// The provider is intentionally `keepAlive`-ish — once watched in
/// `main.dart` (or via an app-startup listener) it stays subscribed for
/// the app's lifetime. Disposing it would cancel the listener and stop
/// rescheduling, which we never want.
final openDayReminderSchedulerProvider = Provider<OpenDayReminderScheduler>((
  ref,
) {
  final scheduler = OpenDayReminderScheduler(
    localNotifications: ref.watch(localNotificationsServiceProvider),
  );

  // Reactive trigger: combine the four inputs that influence the
  // schedule into one watched record. When any of them changes,
  // recompute. Returning the record from `select` lets Riverpod
  // do equality-based change detection so we don't reschedule on
  // unrelated preference updates (e.g. theme toggles).
  ref.listen<({bool master, bool openDay, int minutes, String? bachelorId})>(
    settingsControllerProvider.select((async) {
      final p = async.value ?? const UserPreferences();
      return (
        master: p.notificationsEnabled,
        openDay: p.openDayRemindersEnabled,
        minutes: p.openDayReminderMinutesBefore,
        bachelorId: p.selectedBachelorId,
      );
    }),
    (_, _) => _reconcile(ref, scheduler),
    fireImmediately: true,
  );

  // The events list also changes when the dataset finishes loading
  // for the first time. Watch it separately so we react to that.
  ref.listen<List<OpenDayEvent>>(
    relevantOpenDayEventsProvider,
    (_, _) => _reconcile(ref, scheduler),
  );

  return scheduler;
});

void _reconcile(Ref ref, OpenDayReminderScheduler scheduler) {
  final prefs =
      ref.read(settingsControllerProvider).value ?? const UserPreferences();
  final events = ref.read(relevantOpenDayEventsProvider);
  final bachelor = ref.read(selectedBachelorProvider);
  // Fire-and-forget — the scheduler internally swallows errors.
  scheduler.reschedule(
    preferences: prefs,
    events: events,
    selectedBachelor: bachelor,
  );
}
