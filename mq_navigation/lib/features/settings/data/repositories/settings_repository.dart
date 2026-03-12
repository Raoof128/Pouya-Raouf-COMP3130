import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/core/security/secure_storage_service.dart';
import 'package:mq_navigation/shared/models/user_preferences.dart';

const _themeModeKey = 'settings.theme_mode';
const _localeCodeKey = 'settings.locale_code';
const _notificationsEnabledKey = 'settings.notifications_enabled';

/// Data source for persisting and retrieving user settings.
///
/// Uses secure storage under the hood. Fails safely on read by returning
/// defaults, but throws on write so the UI controller can show an error
/// and revert any optimistic updates.
abstract interface class SettingsRepository {
  Future<UserPreferences> loadPreferences();
  Future<UserPreferences> savePreferences(UserPreferences preferences);
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return LocalSettingsRepository(storage: storage);
});

class LocalSettingsRepository implements SettingsRepository {
  const LocalSettingsRepository({required SecureStorageService storage})
    : _storage = storage;

  final SecureStorageService _storage;

  @override
  Future<UserPreferences> loadPreferences() async {
    try {
      // Keys are read individually rather than as a JSON blob so that
      // failure to parse one key doesn't corrupt the entire preference state.
      final themeModeString = await _storage.read(_themeModeKey);
      final localeCode = await _storage.read(_localeCodeKey);
      final notificationsEnabled = await _storage.read(
        _notificationsEnabledKey,
      );
      final localThemeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeString,
        orElse: () => ThemeMode.system,
      );

      return UserPreferences(
        themeMode: localThemeMode,
        localeCode: localeCode,
        notificationsEnabled: notificationsEnabled != 'false',
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load user preferences', error, stackTrace);
      return const UserPreferences();
    }
  }

  @override
  Future<UserPreferences> savePreferences(UserPreferences preferences) async {
    try {
      await _storage.write(_themeModeKey, preferences.themeMode.name);
      if (preferences.localeCode != null) {
        await _storage.write(_localeCodeKey, preferences.localeCode!);
      } else {
        await _storage.delete(_localeCodeKey);
      }
      await _storage.write(
        _notificationsEnabledKey,
        preferences.notificationsEnabled.toString(),
      );
      return preferences;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to save user preferences', error, stackTrace);
      rethrow;
    }
  }
}
