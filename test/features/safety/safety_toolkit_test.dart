import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_theme.dart';
import 'package:mq_navigation/features/safety/data/datasources/safety_poi_source.dart';
import 'package:mq_navigation/features/safety/domain/entities/emergency_contact.dart';
import 'package:mq_navigation/features/safety/domain/entities/safety_poi.dart';
import 'package:mq_navigation/features/safety/presentation/pages/safety_toolkit_page.dart';
import 'package:mq_navigation/features/safety/presentation/widgets/safety_action_card.dart';

Widget _testApp(Widget widget) {
  return MaterialApp(
    theme: MqTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: widget,
  );
}

void main() {
  group('SafetyPoi', () {
    test('creates first aid POI with correct type', () {
      const poi = SafetyPoi(
        id: 'fa_test',
        type: SafetyPoiType.firstAid,
        name: 'Test First Aid',
        buildingCode: 'TST',
      );
      expect(poi.type, SafetyPoiType.firstAid);
      expect(poi.name, 'Test First Aid');
    });

    test('creates defibrillator POI with correct type', () {
      const poi = SafetyPoi(
        id: 'aed_test',
        type: SafetyPoiType.defibrillator,
        name: 'Test AED',
        buildingCode: 'TST',
      );
      expect(poi.type, SafetyPoiType.defibrillator);
    });

    test('creates security office POI with coordinates', () {
      const poi = SafetyPoi(
        id: 'sec_test',
        type: SafetyPoiType.securityOffice,
        name: 'Security Office',
        buildingCode: 'U9A',
        latitude: -33.773,
        longitude: 151.112,
      );
      expect(poi.latitude, -33.773);
      expect(poi.longitude, 151.112);
    });
  });

  group('EmergencyContact', () {
    test('creates emergency contact with number', () {
      const contact = EmergencyContact(
        label: 'Test Emergency',
        phoneNumber: '000',
        isEmergency: true,
      );
      expect(contact.phoneNumber, '000');
      expect(contact.isEmergency, isTrue);
    });

    test('creates non-emergency contact', () {
      const contact = EmergencyContact(
        label: 'Test Non-Emergency',
        phoneNumber: '1234 5678',
        isEmergency: false,
      );
      expect(contact.isEmergency, isFalse);
    });
  });

  group('SafetyPoiSource', () {
    test('returns 3 first aid locations', () {
      final source = SafetyPoiSource();
      expect(source.firstAidLocations, hasLength(3));
    });

    test('all first aid locations have type firstAid', () {
      final source = SafetyPoiSource();
      for (final poi in source.firstAidLocations) {
        expect(poi.type, SafetyPoiType.firstAid);
      }
    });

    test('returns 5 defibrillator locations', () {
      final source = SafetyPoiSource();
      expect(source.defibrillatorLocations, hasLength(5));
    });

    test('all defibrillator locations have type defibrillator', () {
      final source = SafetyPoiSource();
      for (final poi in source.defibrillatorLocations) {
        expect(poi.type, SafetyPoiType.defibrillator);
      }
    });

    test('returns 4 emergency contacts', () {
      final source = SafetyPoiSource();
      expect(source.emergencyContacts, hasLength(4));
    });

    test('first contact is emergency (000)', () {
      final source = SafetyPoiSource();
      expect(source.emergencyContacts.first.phoneNumber, '000');
      expect(source.emergencyContacts.first.isEmergency, isTrue);
    });

    test('shuttle info is non-empty', () {
      final source = SafetyPoiSource();
      expect(source.securityShuttleInfo, isNotEmpty);
    });
  });

  group('SafetyActionCard', () {
    testWidgets('renders title and icon', (tester) async {
      await tester.pumpWidget(
        _testApp(
          const SafetyActionCard(
            icon: Icons.flashlight_on,
            title: 'Flashlight',
          ),
        ),
      );
      expect(find.text('Flashlight'), findsOneWidget);
      expect(find.byIcon(Icons.flashlight_on), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        _testApp(
          const SafetyActionCard(
            icon: Icons.phone,
            title: 'Call',
            subtitle: 'Tap to call',
          ),
        ),
      );
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('Tap to call'), findsOneWidget);
    });

    testWidgets('renders value badge when provided', (tester) async {
      await tester.pumpWidget(
        _testApp(
          const SafetyActionCard(
            icon: Icons.phone,
            title: 'Campus Security',
            value: '(02) 9850 7111',
          ),
        ),
      );
      expect(find.text('(02) 9850 7111'), findsOneWidget);
    });

    testWidgets('responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _testApp(
          SafetyActionCard(
            icon: Icons.flashlight_on,
            title: 'Toggle',
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.text('Toggle'));
      expect(tapped, isTrue);
    });

    testWidgets('destructive variant shows red styling', (tester) async {
      await tester.pumpWidget(
        _testApp(
          const SafetyActionCard(
            icon: Icons.warning,
            title: 'Emergency',
            isDestructive: true,
          ),
        ),
      );
      expect(find.text('Emergency'), findsOneWidget);
    });
  });

  group('SafetyToolkitPage', () {
    testWidgets('renders privacy notice', (tester) async {
      await tester.pumpWidget(_testApp(const SafetyToolkitPage()));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.privacy_tip), findsOneWidget);
    });

    testWidgets('renders first aid section', (tester) async {
      await tester.pumpWidget(_testApp(const SafetyToolkitPage()));
      await tester.pumpAndSettle();
      expect(find.text('First Aid Locations'), findsOneWidget);
    });

    testWidgets('renders AED section', (tester) async {
      await tester.pumpWidget(_testApp(const SafetyToolkitPage()));
      await tester.pumpAndSettle();
      expect(find.text('AED Locations'), findsOneWidget);
    });

    testWidgets('renders security shuttle section', (tester) async {
      await tester.pumpWidget(_testApp(const SafetyToolkitPage()));
      await tester.pumpAndSettle();
      expect(find.text('Security Shuttle'), findsAtLeast(1));
    });

    testWidgets('renders at least one first aid location', (tester) async {
      await tester.pumpWidget(_testApp(const SafetyToolkitPage()));
      await tester.pumpAndSettle();
      expect(find.text('University Health Service'), findsOneWidget);
    });

    testWidgets('renders at least one defibrillator location', (tester) async {
      await tester.pumpWidget(_testApp(const SafetyToolkitPage()));
      await tester.pumpAndSettle();
      expect(find.text('Waranara Library'), findsOneWidget);
    });

    testWidgets('renders Quick Actions section', (tester) async {
      await tester.pumpWidget(_testApp(const SafetyToolkitPage()));
      await tester.pumpAndSettle();
      expect(find.text('Quick Actions'), findsOneWidget);
    });
  });
}
