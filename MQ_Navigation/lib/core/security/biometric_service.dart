import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mq_navigation/core/error/app_exception.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';

/// Wrapper around `local_auth` for biometric authentication gates.
class BiometricService {
  BiometricService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Whether the device has biometric hardware and enrolled biometrics.
  Future<bool> get isAvailable async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e, s) {
      AppLogger.warning('Biometric availability check failed', e, s);
      return false;
    }
  }

  /// Returns the list of enrolled biometric types (fingerprint, face, iris).
  Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e, s) {
      AppLogger.warning('Failed to get available biometrics', e, s);
      return [];
    }
  }

  /// Prompt the user for biometric authentication.
  ///
  /// Returns `true` if authentication succeeded.
  /// Throws [UnsupportedException] if biometrics are not available.
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
  }) async {
    final available = await isAvailable;
    if (!available) {
      throw const UnsupportedException(
        'Biometric authentication is not available on this device',
      );
    }

    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
      );
    } catch (e, s) {
      AppLogger.error('Biometric authentication failed', e, s);
      return false;
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});
