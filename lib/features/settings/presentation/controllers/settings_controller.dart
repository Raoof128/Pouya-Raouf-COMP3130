import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/notifications/domain/entities/app_notification.dart';
import 'package:mq_navigation/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:mq_navigation/features/settings/data/repositories/settings_repository.dart';
import 'package:mq_navigation/shared/models/user_preferences.dart';

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, UserPreferences>(
      SettingsController.new,
    );

/// Manages the application's global preferences state.
///
/// This controller uses an optimistic update pattern: when a user changes
/// a setting, the UI updates immediately. If the storage write fails in the
/// background, the controller reverts the state and returns an error string
/// which the UI can display as a SnackBar.
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
    final result = await _save(
      currentPreferences.copyWith(notificationsEnabled: enabled),
    );
    // Sync the master toggle to all notification preferences.
    try {
      final notifier = ref.read(notificationsControllerProvider.notifier);
      for (final type in NotificationType.values) {
        await notifier.updatePreference(type, enabled);
      }
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to sync notification preferences',
        error,
        stackTrace,
      );
    }
    return result;
  }

  Future<String?> updateDefaultRenderer(MapRendererType renderer) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(currentPreferences.copyWith(defaultRenderer: renderer));
  }

  Future<String?> updateDefaultTravelMode(TravelMode mode) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(currentPreferences.copyWith(defaultTravelMode: mode));
  }

  Future<String?> updateLowDataMode(bool enabled) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(currentPreferences.copyWith(lowDataMode: enabled));
  }

  Future<String?> updateReducedMotion(bool enabled) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(currentPreferences.copyWith(reducedMotion: enabled));
  }

  Future<String?> updateHapticsEnabled(bool enabled) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(currentPreferences.copyWith(hapticsEnabled: enabled));
  }

  Future<String?> updateQuietHoursEnabled(bool enabled) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(currentPreferences.copyWith(quietHoursEnabled: enabled));
  }

  Future<String?> updateQuietHoursStart(String time) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(currentPreferences.copyWith(quietHoursStart: time));
  }

  Future<String?> updateQuietHoursEnd(String time) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(currentPreferences.copyWith(quietHoursEnd: time));
  }

  Future<String?> updateHighContrastMap(bool enabled) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(currentPreferences.copyWith(highContrastMap: enabled));
  }

  Future<String?> updateOfflineCampusMapsEnabled(bool enabled) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(
      currentPreferences.copyWith(offlineCampusMapsEnabled: enabled),
    );
  }

  Future<String?> updateCommutePreferences({
    String? commuteMode,
    String? favoriteRoute,
  }) async {
    final currentPreferences = state.value ?? const UserPreferences();
    return _save(
      currentPreferences.copyWith(
        commuteMode: commuteMode,
        favoriteRoute: favoriteRoute,
      ),
    );
  }

  /// Wipes all local data and resets the controller to its initial state.
  ///
  /// This will reset theme, locale, and all other preferences to defaults.
  Future<String?> wipeAllLocalData() async {
    try {
      await ref.read(settingsRepositoryProvider).wipeAllLocalData();
      // Reload the state to ensure everything is reset to defaults.
      state = AsyncData(await build());
      return null;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to wipe data', error, stackTrace);
      return 'Unable to wipe data.';
    }
  }

  Future<String?> _save(UserPreferences preferences) async {
    final previous = state.value;
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
      // Revert to previous state so the UI stays usable.
      if (previous != null) {
        state = AsyncData(previous);
      }
      return _saveErrorMessage;
    }
  }

  static const _saveErrorMessage = 'Unable to save settings.';
}
