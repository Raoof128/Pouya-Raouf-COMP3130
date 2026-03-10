/// Environment configuration loaded from --dart-define at build time.
///
/// Usage:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ... \
///     --dart-define=GOOGLE_MAPS_API_KEY=AIza... \
///     --dart-define=APP_ENV=development
class EnvConfig {
  const EnvConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const String orsApiKey = String.fromEnvironment(
    'ORS_API_KEY',
    defaultValue: '',
  );

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => appEnv == 'production';
  static bool get isStaging => appEnv == 'staging';
  static bool get isDevelopment => appEnv == 'development';

  /// Throws [StateError] if required env vars are missing.
  ///
  /// Unlike `assert`, this check runs in **all** build modes including release.
  static void validate() {
    if (supabaseUrl.isEmpty) {
      throw StateError('SUPABASE_URL must be set via --dart-define');
    }
    if (supabaseAnonKey.isEmpty) {
      throw StateError('SUPABASE_ANON_KEY must be set via --dart-define');
    }
  }
}
