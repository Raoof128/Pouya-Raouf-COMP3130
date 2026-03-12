import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/error/app_exception.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';

/// Encrypted key-value storage backed by Keychain (iOS) / Keystore (Android).
///
/// Used to persist sensitive settings and tokens. Every operation is wrapped
/// in a try-catch that logs the native platform error and rethrows it as a
/// [StorageException] to keep the caller agnostic of the underlying plugin.
class SecureStorageService {
  SecureStorageService([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, s) {
      AppLogger.error('SecureStorage read failed', e, s);
      throw StorageException('Failed to read key "$key"', e);
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e, s) {
      AppLogger.error('SecureStorage write failed', e, s);
      throw StorageException('Failed to write key "$key"', e);
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e, s) {
      AppLogger.error('SecureStorage delete failed', e, s);
      throw StorageException('Failed to delete key "$key"', e);
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e, s) {
      AppLogger.error('SecureStorage deleteAll failed', e, s);
      throw StorageException('Failed to delete all keys', e);
    }
  }

  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e, s) {
      AppLogger.error('SecureStorage containsKey failed', e, s);
      throw StorageException('Failed to check key "$key"', e);
    }
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
