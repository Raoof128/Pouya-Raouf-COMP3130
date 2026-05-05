import 'package:flutter/material.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';

/// Immutable local data model representing a user's app-wide preferences.
///
/// This object is persisted in secure storage and read during app startup
/// to configure the root theme and localization delegates.
@immutable
class UserPreferences {
  const UserPreferences({
    this.hasCompletedOnboarding = false,
    this.commuteMode = 'none',
    this.favoriteDirection = '',
    this.favoriteRoute = '',
    this.favoriteStopId = '',
    this.favoriteStopName = '',
    this.themeMode = ThemeMode.system,
    this.localeCode,
    this.notificationsEnabled = true,
    this.defaultRenderer = MapRendererType.campus,
    this.defaultTravelMode = TravelMode.walk,
    this.lowDataMode = false,
    this.reducedMotion = false,
    this.hapticsEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '23:00',
    this.quietHoursEnd = '08:00',
    this.highContrastMap = false,
    this.offlineCampusMapsEnabled = false,
    this.selectedBachelorId,
    this.openDayRemindersEnabled = true,
    this.openDayReminderMinutesBefore = 15,
  });

  final bool hasCompletedOnboarding;
  final ThemeMode themeMode;
  final String commuteMode;
  final String favoriteDirection;
  final String favoriteRoute;
  final String favoriteStopId;
  final String favoriteStopName;
  final String? localeCode;
  final bool notificationsEnabled;
  final MapRendererType defaultRenderer;
  final TravelMode defaultTravelMode;
  final bool lowDataMode;
  final bool reducedMotion;
  final bool hapticsEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool highContrastMap;
  final bool offlineCampusMapsEnabled;

  /// Open Day study-interest preference. `null` means the user hasn't
  /// chosen a bachelor yet — the Home screen treats this as the trigger
  /// for the lightweight onboarding card. Stored on-device only.
  final String? selectedBachelorId;

  /// Whether to schedule local reminders for Open Day events relevant
  /// to the selected bachelor. Defaults on; users can flip via Settings.
  final bool openDayRemindersEnabled;

  /// How many minutes before each event's start time the reminder fires.
  /// Sensible bounds (5–60) are enforced at the controller; the model
  /// stores the raw int so an updated UI can offer extra increments
  /// without a model migration.
  final int openDayReminderMinutesBefore;

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  UserPreferences copyWith({
    bool? hasCompletedOnboarding,
    ThemeMode? themeMode,
    String? commuteMode,
    String? favoriteDirection,
    String? favoriteRoute,
    String? favoriteStopId,
    String? favoriteStopName,
    String? localeCode,
    bool clearLocale = false,
    bool? notificationsEnabled,
    MapRendererType? defaultRenderer,
    TravelMode? defaultTravelMode,
    bool? lowDataMode,
    bool? reducedMotion,
    bool? hapticsEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? highContrastMap,
    bool? offlineCampusMapsEnabled,
    String? selectedBachelorId,
    bool clearSelectedBachelor = false,
    bool? openDayRemindersEnabled,
    int? openDayReminderMinutesBefore,
  }) {
    return UserPreferences(
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      themeMode: themeMode ?? this.themeMode,
      commuteMode: commuteMode ?? this.commuteMode,
      favoriteDirection: favoriteDirection ?? this.favoriteDirection,
      favoriteRoute: favoriteRoute ?? this.favoriteRoute,
      favoriteStopId: favoriteStopId ?? this.favoriteStopId,
      favoriteStopName: favoriteStopName ?? this.favoriteStopName,
      localeCode: clearLocale ? null : localeCode ?? this.localeCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultRenderer: defaultRenderer ?? this.defaultRenderer,
      defaultTravelMode: defaultTravelMode ?? this.defaultTravelMode,
      lowDataMode: lowDataMode ?? this.lowDataMode,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      highContrastMap: highContrastMap ?? this.highContrastMap,
      offlineCampusMapsEnabled:
          offlineCampusMapsEnabled ?? this.offlineCampusMapsEnabled,
      selectedBachelorId: clearSelectedBachelor
          ? null
          : (selectedBachelorId ?? this.selectedBachelorId),
      openDayRemindersEnabled:
          openDayRemindersEnabled ?? this.openDayRemindersEnabled,
      openDayReminderMinutesBefore:
          openDayReminderMinutesBefore ?? this.openDayReminderMinutesBefore,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          hasCompletedOnboarding == other.hasCompletedOnboarding &&
          themeMode == other.themeMode &&
          commuteMode == other.commuteMode &&
          favoriteDirection == other.favoriteDirection &&
          favoriteRoute == other.favoriteRoute &&
          favoriteStopId == other.favoriteStopId &&
          favoriteStopName == other.favoriteStopName &&
          localeCode == other.localeCode &&
          notificationsEnabled == other.notificationsEnabled &&
          defaultRenderer == other.defaultRenderer &&
          defaultTravelMode == other.defaultTravelMode &&
          lowDataMode == other.lowDataMode &&
          reducedMotion == other.reducedMotion &&
          hapticsEnabled == other.hapticsEnabled &&
          quietHoursEnabled == other.quietHoursEnabled &&
          quietHoursStart == other.quietHoursStart &&
          quietHoursEnd == other.quietHoursEnd &&
          highContrastMap == other.highContrastMap &&
          offlineCampusMapsEnabled == other.offlineCampusMapsEnabled &&
          selectedBachelorId == other.selectedBachelorId &&
          openDayRemindersEnabled == other.openDayRemindersEnabled &&
          openDayReminderMinutesBefore == other.openDayReminderMinutesBefore;

  @override
  int get hashCode => Object.hashAll([
    hasCompletedOnboarding,
    themeMode,
    commuteMode,
    favoriteDirection,
    favoriteRoute,
    favoriteStopId,
    favoriteStopName,
    localeCode,
    notificationsEnabled,
    defaultRenderer,
    defaultTravelMode,
    lowDataMode,
    reducedMotion,
    hapticsEnabled,
    quietHoursEnabled,
    quietHoursStart,
    quietHoursEnd,
    highContrastMap,
    offlineCampusMapsEnabled,
    selectedBachelorId,
    openDayRemindersEnabled,
    openDayReminderMinutesBefore,
  ]);
}
