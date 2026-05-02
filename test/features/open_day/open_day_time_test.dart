import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/open_day/domain/services/open_day_time.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  // The production codebase initialises timezones inside
  // `LocalNotificationsService.initialize()` at app startup. Tests run
  // outside that path, so we initialise here too — without it, the
  // Sydney lookup throws.
  setUpAll(() => tz.initializeTimeZones());

  group('OpenDayTime', () {
    test(
      'formats AEST instants as PM regardless of device timezone offset in input',
      () {
        // 13:00 +10:00 is 1:00 PM in Sydney. Whatever the device locale,
        // this must format as "1:00 PM" — *not* "3:00 AM" (UTC) or
        // "10:00 PM previous day" (PST). This is the AM/PM bug fix.
        final instant = DateTime.parse('2026-08-08T13:00:00+10:00');
        expect(OpenDayTime.formatTimeOfDay(instant), '1:00 PM');
      },
    );

    test('formats AEST 10:00 as 10:00 AM (boundary check)', () {
      final instant = DateTime.parse('2026-08-08T10:00:00+10:00');
      expect(OpenDayTime.formatTimeOfDay(instant), '10:00 AM');
    });

    test('formats time range with consistent AM/PM markers', () {
      final start = DateTime.parse('2026-08-08T13:00:00+10:00');
      final end = DateTime.parse('2026-08-08T13:30:00+10:00');
      expect(OpenDayTime.formatTimeRange(start, end), '1:00 PM – 1:30 PM');
    });

    test('long date renders as Saturday in Sydney for the 2026 cycle', () {
      // 2026-08-08 is a Saturday.
      final date = DateTime.parse('2026-08-08T10:00:00+10:00');
      expect(OpenDayTime.formatLongDate(date), startsWith('Saturday'));
    });

    test('sydneyHour returns wall-clock Sydney hour', () {
      // Same instant from two different perspectives — both must give
      // the Sydney hour.
      final asAEST = DateTime.parse('2026-08-08T13:00:00+10:00');
      final asUtc = DateTime.parse('2026-08-08T03:00:00Z'); // same moment
      expect(OpenDayTime.sydneyHour(asAEST), 13);
      expect(OpenDayTime.sydneyHour(asUtc), 13);
    });
  });
}
