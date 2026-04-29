import 'package:flutter/foundation.dart';

/// Domain models for the Open Day feature.
///
/// The data flow is: `assets/data/open_day.json` → loader → these models →
/// controllers → UI. The schema is intentionally simple so an updated
/// XLSX/CSV can be transformed into the same JSON shape without any Dart
/// changes.
@immutable
class OpenDayStudyArea {
  const OpenDayStudyArea({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;

  /// Material icon family name (e.g. `science`, `medical_services`). Kept
  /// as a string so the JSON can stay framework-agnostic.
  final String icon;

  factory OpenDayStudyArea.fromJson(Map<String, dynamic> json) {
    return OpenDayStudyArea(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: (json['icon'] as String?) ?? 'school',
    );
  }
}

@immutable
class OpenDayBachelor {
  const OpenDayBachelor({
    required this.id,
    required this.name,
    required this.studyAreaId,
  });

  final String id;
  final String name;
  final String studyAreaId;

  factory OpenDayBachelor.fromJson(Map<String, dynamic> json) {
    return OpenDayBachelor(
      id: json['id'] as String,
      name: json['name'] as String,
      studyAreaId: json['studyAreaId'] as String,
    );
  }
}

@immutable
class OpenDayEvent {
  const OpenDayEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.venueName,
    required this.bachelorIds,
    this.buildingCode,
    this.description,
  });

  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String venueName;

  /// Optional link into the campus `buildings.json` registry. When present,
  /// the "View in Campus Map" action can route directly to the building
  /// detail page; when absent, the action is hidden gracefully.
  final String? buildingCode;
  final List<String> bachelorIds;
  final String? description;

  /// Returns true if this event is relevant to a given bachelor selection.
  /// An empty `bachelorIds` list is treated as "open to everyone".
  bool isRelevantTo(String? bachelorId) {
    if (bachelorIds.isEmpty) return true;
    if (bachelorId == null) return false;
    return bachelorIds.contains(bachelorId);
  }

  factory OpenDayEvent.fromJson(Map<String, dynamic> json) {
    return OpenDayEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      venueName: json['venueName'] as String,
      buildingCode: json['buildingCode'] as String?,
      description: json['description'] as String?,
      bachelorIds:
          (json['bachelorIds'] as List?)?.cast<String>() ?? const <String>[],
    );
  }
}

/// Top-level Open Day dataset, loaded once and held in memory.
@immutable
class OpenDayData {
  const OpenDayData({
    required this.openDayDate,
    required this.lastUpdated,
    required this.studyAreas,
    required this.bachelors,
    required this.events,
  });

  final DateTime openDayDate;
  final DateTime lastUpdated;
  final List<OpenDayStudyArea> studyAreas;
  final List<OpenDayBachelor> bachelors;
  final List<OpenDayEvent> events;

  OpenDayBachelor? bachelorById(String? id) {
    if (id == null) return null;
    for (final b in bachelors) {
      if (b.id == id) return b;
    }
    return null;
  }

  OpenDayStudyArea? studyAreaById(String id) {
    for (final s in studyAreas) {
      if (s.id == id) return s;
    }
    return null;
  }

  factory OpenDayData.fromJson(Map<String, dynamic> json) {
    return OpenDayData(
      openDayDate: DateTime.parse(json['openDayDate'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      studyAreas: ((json['studyAreas'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(OpenDayStudyArea.fromJson)
          .toList(growable: false),
      bachelors: ((json['bachelors'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(OpenDayBachelor.fromJson)
          .toList(growable: false),
      events: ((json['events'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(OpenDayEvent.fromJson)
          .toList(growable: false),
    );
  }
}
