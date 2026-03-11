import 'package:flutter/foundation.dart';

/// Environment configuration loaded from --dart-define at build time.
///
/// In **debug mode**, falls back to development defaults so that a bare
/// `flutter run` works without flags. In **release mode**, missing values
/// cause a [StateError] — you must supply them via `--dart-define` or
/// `--dart-define-from-file=.env`.
///
/// Usage (release / CI):
///   flutter run --release \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ... \
///     --dart-define=GOOGLE_MAPS_API_KEY=AIza... \
///     --dart-define=APP_ENV=production
class EnvConfig {
  const EnvConfig._();

  // --dart-define values (empty string when not provided)
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );
  static const String _appEnv = String.fromEnvironment('APP_ENV');

  // Development defaults loaded via --dart-define-from-file=.env
  // NEVER hardcode API keys in source. Use:
  //   flutter run --dart-define-from-file=.env
  static const String _devSupabaseUrl = String.fromEnvironment(
    'DEV_SUPABASE_URL',
  );
  static const String _devSupabaseAnonKey = String.fromEnvironment(
    'DEV_SUPABASE_ANON_KEY',
  );
  static const String _devGoogleMapsApiKey = String.fromEnvironment(
    'DEV_GOOGLE_MAPS_API_KEY',
  );

  /// Supabase project URL. Falls back to dev env var in debug mode.
  static String get supabaseUrl => _supabaseUrl.isNotEmpty
      ? _supabaseUrl
      : (kDebugMode ? _devSupabaseUrl : '');

  /// Supabase anonymous key (public, RLS-enforced). Falls back to dev env var in debug mode.
  static String get supabaseAnonKey => _supabaseAnonKey.isNotEmpty
      ? _supabaseAnonKey
      : (kDebugMode ? _devSupabaseAnonKey : '');

  /// Google Maps client-side API key. Falls back to dev env var in debug mode.
  static String get googleMapsApiKey => _googleMapsApiKey.isNotEmpty
      ? _googleMapsApiKey
      : (kDebugMode ? _devGoogleMapsApiKey : '');

  /// App environment. Defaults to 'development'.
  static String get appEnv => _appEnv.isNotEmpty ? _appEnv : 'development';

  static bool get isProduction => appEnv == 'production';
  static bool get isStaging => appEnv == 'staging';
  static bool get isDevelopment => appEnv == 'development';
  static bool get hasGoogleMapsApiKey => googleMapsApiKey.trim().isNotEmpty;

  /// Throws [StateError] if required env vars are missing.
  ///
  /// In debug mode this always passes (dev defaults are used).
  /// In release mode, missing `--dart-define` values are fatal.
  static void validate() {
    if (supabaseUrl.isEmpty) {
      throw StateError('SUPABASE_URL must be set via --dart-define');
    }
    if (supabaseAnonKey.isEmpty) {
      throw StateError('SUPABASE_ANON_KEY must be set via --dart-define');
    }
  }
}
