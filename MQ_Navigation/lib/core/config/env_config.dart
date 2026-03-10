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

  /// Whether Supabase credentials are configured.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Whether a real Google Maps API key is configured.
  static bool get hasGoogleMapsKey =>
      googleMapsApiKey.isNotEmpty &&
      googleMapsApiKey != 'your-google-maps-api-key';

  /// Logs warnings for missing env vars instead of crashing.
  ///
  /// In production, missing Supabase credentials are fatal.
  /// In development, the app runs in demo mode with sample data.
  static void validate() {
    if (!hasSupabase && isProduction) {
      throw StateError('SUPABASE_URL and SUPABASE_ANON_KEY must be set via --dart-define');
    }
  }
}
