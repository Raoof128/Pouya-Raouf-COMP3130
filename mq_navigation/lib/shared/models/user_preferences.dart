import 'package:flutter/material.dart';

@immutable
class UserPreferences {
  const UserPreferences({
    this.themeMode = ThemeMode.system,
    this.localeCode,
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.biometricLockEnabled = false,
  });

  final ThemeMode themeMode;
  final String? localeCode;
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool biometricLockEnabled;

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  UserPreferences copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    bool clearLocale = false,
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? biometricLockEnabled,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      localeCode: clearLocale ? null : localeCode ?? this.localeCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
    );
  }

  factory UserPreferences.fromRemoteJson(
    Map<String, dynamic>? json, {
    ThemeMode? localThemeMode,
    String? localLocaleCode,
    bool? localBiometricLockEnabled,
  }) {
    return UserPreferences(
      themeMode:
          _themeModeFromString(json?['theme'] as String?) ??
          localThemeMode ??
          ThemeMode.system,
      localeCode: localLocaleCode,
      notificationsEnabled: (json?['notifications_enabled'] as bool?) ?? true,
      emailNotifications: (json?['email_notifications'] as bool?) ?? true,
      biometricLockEnabled: localBiometricLockEnabled ?? false,
    );
  }

  Map<String, dynamic> toRemoteJson(String userId) {
    return <String, dynamic>{
      'user_id': userId,
      'theme': themeMode.name,
      'notifications_enabled': notificationsEnabled,
      'email_notifications': emailNotifications,
    };
  }
}

ThemeMode? _themeModeFromString(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return ThemeMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => ThemeMode.system,
  );
}
