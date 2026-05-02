import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/notifications/data/datasources/local_notifications_service.dart';
import 'package:mq_navigation/features/notifications/domain/entities/reminder_request.dart';
import 'package:mq_navigation/features/open_day/data/open_day_reminder_scheduler.dart';
import 'package:mq_navigation/features/open_day/domain/entities/open_day_data.dart';
import 'package:mq_navigation/shared/models/user_preferences.dart';

/// Fake [LocalNotificationsService] that records calls instead of
/// touching the platform channel. Letting the scheduler depend on the
/// concrete service rather than an interface kept the wiring simple in
/// production; the trade-off is that this fake subclasses the real
/// service and overrides the three methods the scheduler actually uses.
class _FakeLocalNotifications extends LocalNotificationsService {
  _FakeLocalNotifications();

  final List<ReminderRequest> scheduled = [];
  final List<Set<int>> cancelExceptCalls = [];

  @override
  Future<void> scheduleReminder(ReminderRequest request) async {
    scheduled.add(request);
  }

  @override
  Future<void> cancelManagedNotificationsExcept(Set<int> retainedIds) async {
    cancelExceptCalls.add(Set<int>.from(retainedIds));
  }

  @override
  int notificationIdForStableId(String stableId) {
    // Use the real algorithm so the scheduler's pendingIds set matches
    // what the production service would compute.
    return stableId.hashCode & 0x7fffffff;
  }
}

OpenDayBachelor _bachelor(String id) =>
    OpenDayBachelor(id: id, name: 'Test $id', studyAreaId: 'fse');

OpenDayEvent _event({
  required String id,
  required DateTime startTime,
  Duration duration = const Duration(minutes: 30),
  List<String> bachelorIds = const ['computing'],
  String? buildingCode = 'MQTH',
}) {
  return OpenDayEvent(
    id: id,
    title: 'Event $id',
    startTime: startTime,
    endTime: startTime.add(duration),
    venueName: 'Test Venue',
    bachelorIds: bachelorIds,
    buildingCode: buildingCode,
  );
}

UserPreferences _prefs({
  bool master = true,
  bool openDay = true,
  int minutes = 15,
  String? bachelorId = 'computing',
}) {
  return UserPreferences(
    notificationsEnabled: master,
    openDayRemindersEnabled: openDay,
    openDayReminderMinutesBefore: minutes,
    selectedBachelorId: bachelorId,
    // Other fields irrelevant — defaults are fine.
    themeMode: ThemeMode.system,
    defaultRenderer: MapRendererType.campus,
    defaultTravelMode: TravelMode.walk,
  );
}

void main() {
  group('OpenDayReminderScheduler', () {
    late _FakeLocalNotifications fake;
    late OpenDayReminderScheduler scheduler;

    setUp(() {
      fake = _FakeLocalNotifications();
      scheduler = OpenDayReminderScheduler(localNotifications: fake);
    });

    test(
      'schedules a reminder for each future event, lead-time minutes before',
      () async {
        // Arrange — fix `now` so the test isn't time-of-day-flaky.
        final now = DateTime(2026, 8, 8, 9, 0); // 9:00 AM local on Open Day
        final eventA = _event(id: 'a', startTime: DateTime(2026, 8, 8, 10, 0));
        final eventB = _event(id: 'b', startTime: DateTime(2026, 8, 8, 11, 0));

        // Act
        await scheduler.reschedule(
          preferences: _prefs(minutes: 15),
          events: [eventA, eventB],
          selectedBachelor: _bachelor('computing'),
          now: now,
        );

        // Assert — both events scheduled, fired 15 minutes before start.
        expect(fake.scheduled, hasLength(2));
        expect(
          fake.scheduled[0].scheduledFor,
          DateTime(2026, 8, 8, 9, 45),
          reason: '10:00 minus 15 min = 9:45',
        );
        expect(
          fake.scheduled[1].scheduledFor,
          DateTime(2026, 8, 8, 10, 45),
          reason: '11:00 minus 15 min = 10:45',
        );
        // The cancel-except call is what wipes stale reminders; its
        // retained set must contain exactly the new reminder IDs.
        expect(fake.cancelExceptCalls, hasLength(1));
        expect(
          fake.cancelExceptCalls.single,
          equals(fake.scheduled.map((r) => r.notificationId).toSet()),
        );
      },
    );

    test('skips events whose reminder time has already passed', () async {
      final now = DateTime(2026, 8, 8, 12, 0);
      // Reminder for 10:00 event would fire at 9:45 — already in the past.
      final pastEvent = _event(
        id: 'past',
        startTime: DateTime(2026, 8, 8, 10, 0),
      );
      // Reminder for 13:00 event fires at 12:45 — still in the future.
      final futureEvent = _event(
        id: 'future',
        startTime: DateTime(2026, 8, 8, 13, 0),
      );

      await scheduler.reschedule(
        preferences: _prefs(minutes: 15),
        events: [pastEvent, futureEvent],
        selectedBachelor: _bachelor('computing'),
        now: now,
      );

      expect(fake.scheduled, hasLength(1));
      expect(fake.scheduled.single.stableId, contains('future'));
    });

    test(
      'cancels everything when the master notifications toggle is off',
      () async {
        await scheduler.reschedule(
          preferences: _prefs(master: false),
          events: [_event(id: 'a', startTime: DateTime(2099, 1, 1, 10, 0))],
          selectedBachelor: _bachelor('computing'),
          now: DateTime(2026, 1, 1),
        );

        expect(fake.scheduled, isEmpty);
        expect(
          fake.cancelExceptCalls.single,
          isEmpty,
          reason: 'Empty retention set means "cancel everything we own"',
        );
      },
    );

    test(
      'cancels everything when the Open Day reminders toggle is off',
      () async {
        await scheduler.reschedule(
          preferences: _prefs(openDay: false),
          events: [_event(id: 'a', startTime: DateTime(2099, 1, 1, 10, 0))],
          selectedBachelor: _bachelor('computing'),
          now: DateTime(2026, 1, 1),
        );

        expect(fake.scheduled, isEmpty);
        expect(fake.cancelExceptCalls.single, isEmpty);
      },
    );

    test('cancels everything when no bachelor is selected', () async {
      await scheduler.reschedule(
        preferences: _prefs(bachelorId: null),
        events: [_event(id: 'a', startTime: DateTime(2099, 1, 1, 10, 0))],
        selectedBachelor: null,
        now: DateTime(2026, 1, 1),
      );

      expect(fake.scheduled, isEmpty);
      expect(fake.cancelExceptCalls.single, isEmpty);
    });

    test('lead-time changes shift the scheduled fire time correctly', () async {
      final now = DateTime(2026, 8, 8, 9, 0);
      final event = _event(id: 'a', startTime: DateTime(2026, 8, 8, 10, 0));

      // 30-minute lead — reminder fires at 9:30.
      await scheduler.reschedule(
        preferences: _prefs(minutes: 30),
        events: [event],
        selectedBachelor: _bachelor('computing'),
        now: now,
      );
      expect(fake.scheduled.single.scheduledFor, DateTime(2026, 8, 8, 9, 30));

      // 60-minute lead — reminder fires at 9:00 (at `now`, but `isBefore`
      // is strict so 9:00 == 9:00 still schedules, not skips).
      fake.scheduled.clear();
      await scheduler.reschedule(
        preferences: _prefs(minutes: 60),
        events: [event],
        selectedBachelor: _bachelor('computing'),
        now: now,
      );
      expect(fake.scheduled.single.scheduledFor, DateTime(2026, 8, 8, 9, 0));
    });

    test(
      'reminder body includes event title and venue for personalisation',
      () async {
        await scheduler.reschedule(
          preferences: _prefs(),
          events: [_event(id: 'a', startTime: DateTime(2099, 1, 1, 12, 0))],
          selectedBachelor: _bachelor('computing'),
          now: DateTime(2026, 1, 1),
        );

        final reminder = fake.scheduled.single;
        expect(reminder.body, contains('Test Venue'));
        expect(reminder.body, contains('Event a'));
        expect(reminder.title, contains('15 min'));
      },
    );

    test(
      'lead-time is clamped to the 5-60 minute range even if state has out-of-range value',
      () async {
        final event = _event(id: 'a', startTime: DateTime(2099, 1, 1, 12, 0));

        // Way too high — should be clamped to 60.
        await scheduler.reschedule(
          preferences: _prefs(minutes: 9999),
          events: [event],
          selectedBachelor: _bachelor('computing'),
          now: DateTime(2026, 1, 1),
        );
        expect(
          fake.scheduled.single.scheduledFor,
          DateTime(2099, 1, 1, 11, 0), // 12:00 minus 60 minutes
        );
      },
    );
  });
}
