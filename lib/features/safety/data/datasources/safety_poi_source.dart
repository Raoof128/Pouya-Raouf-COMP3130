import 'package:mq_navigation/features/safety/domain/entities/emergency_contact.dart';
import 'package:mq_navigation/features/safety/domain/entities/safety_poi.dart';

class SafetyPoiSource {
  List<SafetyPoi> get firstAidLocations => const [
    SafetyPoi(
      id: 'fa_1cc',
      type: SafetyPoiType.firstAid,
      name: 'University Health Service',
      buildingCode: '1CC',
      description: 'Ground Floor, 1 Central Courtyard',
      latitude: -33.7731,
      longitude: 151.1138,
    ),
    SafetyPoi(
      id: 'fa_18ww',
      type: SafetyPoiType.firstAid,
      name: 'Service Connect',
      buildingCode: '18WW',
      description: 'Level 1, 18 Wally\'s Walk',
      latitude: -33.7740,
      longitude: 151.1126,
    ),
    SafetyPoi(
      id: 'fa_sport',
      type: SafetyPoiType.firstAid,
      name: 'Sport & Aquatic Centre',
      buildingCode: 'SPORT',
      description: 'Reception desk',
      latitude: -33.7715,
      longitude: 151.1142,
    ),
  ];

  List<SafetyPoi> get defibrillatorLocations => const [
    SafetyPoi(
      id: 'aed_lib',
      type: SafetyPoiType.defibrillator,
      name: 'Waranara Library',
      buildingCode: 'LIB',
      description: 'Level 1 near lift',
      latitude: -33.7757,
      longitude: 151.1131,
    ),
    SafetyPoi(
      id: 'aed_1cc',
      type: SafetyPoiType.defibrillator,
      name: '1 Central Courtyard',
      buildingCode: '1CC',
      description: 'Ground floor near security desk',
      latitude: -33.7731,
      longitude: 151.1138,
    ),
    SafetyPoi(
      id: 'aed_sport',
      type: SafetyPoiType.defibrillator,
      name: 'Sport & Aquatic Centre',
      buildingCode: 'SPORT',
      description: 'Main reception',
      latitude: -33.7715,
      longitude: 151.1142,
    ),
    SafetyPoi(
      id: 'aed_18ww',
      type: SafetyPoiType.defibrillator,
      name: '18 Wally\'s Walk',
      buildingCode: '18WW',
      description: 'Ground floor foyer',
      latitude: -33.7740,
      longitude: 151.1126,
    ),
    SafetyPoi(
      id: 'aed_c5c',
      type: SafetyPoiType.defibrillator,
      name: 'Building C5C',
      buildingCode: 'C5C',
      description: 'Ground floor entrance',
      latitude: -33.7759,
      longitude: 151.1108,
    ),
  ];

  List<EmergencyContact> get emergencyContacts => const [
    EmergencyContact(
      label: 'Emergency (Police, Fire, Ambulance)',
      phoneNumber: '000',
      isEmergency: true,
      description: 'Life-threatening emergencies only',
    ),
    EmergencyContact(
      label: 'Campus Security',
      phoneNumber: '(02) 9850 7111',
      isEmergency: false,
      description: '24/7 campus security, shuttle, first aid',
    ),
    EmergencyContact(
      label: 'Health Service',
      phoneNumber: '(02) 9850 7476',
      isEmergency: false,
      description: 'University Health Service appointments',
    ),
    EmergencyContact(
      label: 'MQ Afterhours Support',
      phoneNumber: '1800 275 227',
      isEmergency: false,
      description: '1800 CRISIS — Mental health support line',
    ),
  ];

  String get securityShuttleInfo =>
      'The MQ Security Shuttle provides 24/7 on-demand transport '
      'around campus during semester. Call Campus Security to request '
      'a pickup from your current location to your destination on campus. '
      'The shuttle is free for all students and staff.';
}
