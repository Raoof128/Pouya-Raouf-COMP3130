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
    this.commuteMode = 'none',
    this.favoriteRoute = '',
    this.favoriteStopId = '',
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
  });

  final ThemeMode themeMode;
  final String commuteMode;
  final String favoriteRoute;
  final String favoriteStopId;
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

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  UserPreferences copyWith({
    ThemeMode? themeMode,
    String? commuteMode,
    String? favoriteRoute,
    String? favoriteStopId,
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
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      commuteMode: commuteMode ?? this.commuteMode,
      favoriteRoute: favoriteRoute ?? this.favoriteRoute,
      favoriteStopId: favoriteStopId ?? this.favoriteStopId,
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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          commuteMode == other.commuteMode &&
          favoriteRoute == other.favoriteRoute &&
          favoriteStopId == other.favoriteStopId &&
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
          offlineCampusMapsEnabled == other.offlineCampusMapsEnabled;

  @override
  int get hashCode => Object.hash(
    themeMode,
    commuteMode,
    favoriteRoute,
    favoriteStopId,
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
  );
}
