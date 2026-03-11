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

    test('supabaseUrl falls back to dev default in debug mode', () {
      expect(EnvConfig.supabaseUrl, isNotEmpty);
      expect(EnvConfig.supabaseUrl, contains('supabase.co'));
    });

    test('supabaseAnonKey falls back to dev default in debug mode', () {
      expect(EnvConfig.supabaseAnonKey, isNotEmpty);
    });

    test('googleMapsApiKey stays empty until explicitly configured', () {
      expect(EnvConfig.googleMapsApiKey, isEmpty);
      expect(EnvConfig.hasGoogleMapsApiKey, isFalse);
    });
  });
}
