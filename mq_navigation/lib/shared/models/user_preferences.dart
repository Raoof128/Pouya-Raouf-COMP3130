import 'package:flutter/material.dart';

@immutable
class UserPreferences {
  const UserPreferences({
    this.themeMode = ThemeMode.system,
    this.localeCode,
    this.notificationsEnabled = true,
  });

  final ThemeMode themeMode;
  final String? localeCode;
  final bool notificationsEnabled;

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  UserPreferences copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    bool clearLocale = false,
    bool? notificationsEnabled,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      localeCode: clearLocale ? null : localeCode ?? this.localeCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          localeCode == other.localeCode &&
          notificationsEnabled == other.notificationsEnabled;

  @override
  int get hashCode => Object.hash(themeMode, localeCode, notificationsEnabled);
}
