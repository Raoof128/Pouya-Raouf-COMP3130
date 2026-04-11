import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mq_navigation/core/error/app_exception.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Encrypted key-value storage backed by Keychain (iOS) / Keystore (Android).
///
/// On **macOS / Linux / Windows / Web** the native Keychain requires a signed
/// build with Keychain Sharing capability. To keep local development working
/// without Xcode signing, desktop & web builds fall back to
/// [SharedPreferences] (unencrypted but functional).
/// On iOS and Android the real [FlutterSecureStorage] is used.
class SecureStorageService {
  SecureStorageService([FlutterSecureStorage? storage])
    : _explicitStorage = storage,
      _useFallback = storage == null && _shouldUseFallback();

  final FlutterSecureStorage? _explicitStorage;
  final bool _useFallback;

  /// Desktop / web platforms cannot reliably access the Keychain without
  /// code-signing, so we fall back to SharedPreferences.
  static bool _shouldUseFallback() {
    if (kIsWeb) return true;
    return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }

  // ── Lazy SharedPreferences accessor ────────────────────────────────────
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  FlutterSecureStorage get _secure =>
      _explicitStorage ?? const FlutterSecureStorage();

  // ── Public API ─────────────────────────────────────────────────────────

  Future<String?> read(String key) async {
    try {
      if (_useFallback) {
        final prefs = await _getPrefs();
        return prefs.getString(key);
      }
      return await _secure.read(key: key);
    } catch (e, s) {
      AppLogger.error('SecureStorage read failed', e, s);
      throw StorageException('Failed to read key "$key"', e);
    }
  }

  Future<void> write(String key, String value) async {
    try {
      if (_useFallback) {
        final prefs = await _getPrefs();
        await prefs.setString(key, value);
        return;
      }
      await _secure.write(key: key, value: value);
    } catch (e, s) {
      AppLogger.error('SecureStorage write failed', e, s);
      throw StorageException('Failed to write key "$key"', e);
    }
  }

  Future<void> delete(String key) async {
    try {
      if (_useFallback) {
        final prefs = await _getPrefs();
        await prefs.remove(key);
        return;
      }
      await _secure.delete(key: key);
    } catch (e, s) {
      AppLogger.error('SecureStorage delete failed', e, s);
      throw StorageException('Failed to delete key "$key"', e);
    }
  }

  Future<void> deleteAll() async {
    try {
      if (_useFallback) {
        final prefs = await _getPrefs();
        await prefs.clear();
        return;
      }
      await _secure.deleteAll();
    } catch (e, s) {
      AppLogger.error('SecureStorage deleteAll failed', e, s);
      throw StorageException('Failed to delete all keys', e);
    }
  }

  Future<bool> containsKey(String key) async {
    try {
      if (_useFallback) {
        final prefs = await _getPrefs();
        return prefs.containsKey(key);
      }
      return await _secure.containsKey(key: key);
    } catch (e, s) {
      AppLogger.error('SecureStorage containsKey failed', e, s);
      throw StorageException('Failed to check key "$key"', e);
    }
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
