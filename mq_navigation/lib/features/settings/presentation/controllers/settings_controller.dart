import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/settings/data/repositories/settings_repository.dart';
import 'package:mq_navigation/shared/models/user_preferences.dart';

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, UserPreferences>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() {
    return ref.read(settingsRepositoryProvider).loadPreferences();
  }

  Future<String?> updateThemeMode(ThemeMode themeMode) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(currentPreferences.copyWith(themeMode: themeMode));
  }

  Future<String?> updateLocaleCode(String? localeCode) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(
      currentPreferences.copyWith(
        localeCode: localeCode,
        clearLocale: localeCode == null,
      ),
    );
  }

  Future<String?> updateNotificationsEnabled(bool enabled) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(currentPreferences.copyWith(notificationsEnabled: enabled));
  }

  Future<String?> updateEmailNotifications(bool enabled) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(currentPreferences.copyWith(emailNotifications: enabled));
  }

  Future<String?> _save(UserPreferences preferences) async {
    try {
      // Optimistic update — show new value immediately, no loading spinner.
      state = AsyncData(preferences);
      final saved = await ref
          .read(settingsRepositoryProvider)
          .savePreferences(preferences);
      state = AsyncData(saved);
      return null;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to persist settings', error, stackTrace);
      state = AsyncError(error, stackTrace);
      return 'Unable to save your settings.';
    }
  }
}
