import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/core/error/app_exception.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/core/security/secure_storage_service.dart';
import 'package:mq_navigation/shared/models/user_preferences.dart';

const _themeModeKey = 'settings.theme_mode';
const _localeCodeKey = 'settings.locale_code';
const _biometricLockKey = 'settings.biometric_lock_enabled';

abstract interface class SettingsRepository {
  Future<UserPreferences> loadPreferences();
  Future<UserPreferences> savePreferences(UserPreferences preferences);
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return SupabaseSettingsRepository(
    client: Supabase.instance.client,
    storage: storage,
  );
});

class SupabaseSettingsRepository implements SettingsRepository {
  const SupabaseSettingsRepository({
    required SupabaseClient client,
    required SecureStorageService storage,
  }) : _client = client,
       _storage = storage;

  final SupabaseClient _client;
  final SecureStorageService _storage;

  @override
  Future<UserPreferences> loadPreferences() async {
    try {
      final themeModeString = await _storage.read(_themeModeKey);
      final localeCode = await _storage.read(_localeCodeKey);
      final biometricLockString = await _storage.read(_biometricLockKey);
      final localThemeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeString,
        orElse: () => ThemeMode.system,
      );
      final localBiometricLockEnabled = biometricLockString == 'true';
      final user = _client.auth.currentUser;

      if (user == null) {
        return UserPreferences(
          themeMode: localThemeMode,
          localeCode: localeCode,
          biometricLockEnabled: localBiometricLockEnabled,
        );
      }

      final response = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      return UserPreferences.fromRemoteJson(
        response == null ? null : Map<String, dynamic>.from(response),
        localThemeMode: localThemeMode,
        localLocaleCode: localeCode,
        localBiometricLockEnabled: localBiometricLockEnabled,
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load user preferences', error, stackTrace);
      throw ServerException('Unable to load your settings.', cause: error);
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
        _biometricLockKey,
        preferences.biometricLockEnabled.toString(),
      );

      final user = _client.auth.currentUser;
      if (user != null) {
        await _client
            .from('user_preferences')
            .upsert(preferences.toRemoteJson(user.id), onConflict: 'user_id');
      }

      return preferences;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to save user preferences', error, stackTrace);
      throw ServerException('Unable to save your settings.', cause: error);
    }
  }
}
