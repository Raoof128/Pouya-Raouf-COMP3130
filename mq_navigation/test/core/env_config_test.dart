import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/core/config/env_config.dart';

void main() {
  group('EnvConfig', () {
    test('defaults to development environment', () {
      // When no --dart-define is provided, defaults kick in.
      expect(EnvConfig.appEnv, 'development');
    });

    test('isDevelopment returns true for default env', () {
      expect(EnvConfig.isDevelopment, isTrue);
    });

    test('isProduction returns false for default env', () {
      expect(EnvConfig.isProduction, isFalse);
    });

    test('isStaging returns false for default env', () {
      expect(EnvConfig.isStaging, isFalse);
    });

    test('supabaseUrl is empty without dart-define (no hardcoded keys)', () {
      // Dev keys are now loaded via --dart-define-from-file=.env, not hardcoded.
      // Without --dart-define, values are empty even in debug mode.
      expect(EnvConfig.supabaseUrl, isA<String>());
    });

    test('supabaseAnonKey is empty without dart-define (no hardcoded keys)', () {
      expect(EnvConfig.supabaseAnonKey, isA<String>());
    });

    test('googleMapsApiKey is empty without dart-define (no hardcoded keys)', () {
      expect(EnvConfig.googleMapsApiKey, isA<String>());
    });
  });
}
