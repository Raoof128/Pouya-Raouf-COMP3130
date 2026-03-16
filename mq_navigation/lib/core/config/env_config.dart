import 'package:flutter/foundation.dart';

/// Environment configuration loaded from --dart-define at build time.
///
/// In **debug mode**, falls back to development defaults so that a bare
/// `flutter run` works without flags. In **release mode**, missing values
/// cause a [StateError] — you must supply them via `--dart-define` or
/// `--dart-define-from-file=.env`.
///
/// **Security Note:** Real `.env` files are ignored by git to prevent
/// credential leaks. The fallbacks here are safe public identifiers.
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
  static const String _devSupabaseUrl = String.fromEnvironment(
    'DEV_SUPABASE_URL',
  );
  static const String _devSupabaseAnonKey = String.fromEnvironment(
    'DEV_SUPABASE_ANON_KEY',
  );
  static const String _devGoogleMapsApiKey = String.fromEnvironment(
    'DEV_GOOGLE_MAPS_API_KEY',
  );

  // ── Hardcoded debug-only fallbacks ──────────────────────────────────────
  // These are intentionally committed so that a plain `flutter run` just
  // works for local development.  The anon key is a *public* key gated by
  // Row-Level Security – not a secret.
  static const String _fallbackSupabaseUrl =
      'https://cxsqlgvbwtevkkljzolg.supabase.co';
  static const String _fallbackSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4c3FsZ3Zid3RldmtrbGp6b2xnIiwi'
      'cm9sZSI6ImFub24iLCJpYXQiOjE3NjcwMjkwNTEsImV4cCI6MjA4MjYwNTA1MX0.'
      '5OXdkYfflYE27WRhw2PKf-up3UYctGKn3w2RQbTZrWw';
  static const String _fallbackGoogleMapsApiKey =
      'AIzaSyCwI7XmkparxuCaiDkUDmPCjpIDoMRsS00';

  /// Supabase project URL. Falls back to dev env var → hardcoded fallback in debug mode.
  static String get supabaseUrl {
    if (_supabaseUrl.isNotEmpty) return _supabaseUrl;
    if (_devSupabaseUrl.isNotEmpty) return _devSupabaseUrl;
    return kDebugMode ? _fallbackSupabaseUrl : '';
  }

  /// Supabase anonymous key (public, RLS-enforced). Falls back to dev env var → hardcoded fallback in debug mode.
  static String get supabaseAnonKey {
    if (_supabaseAnonKey.isNotEmpty) return _supabaseAnonKey;
    if (_devSupabaseAnonKey.isNotEmpty) return _devSupabaseAnonKey;
    return kDebugMode ? _fallbackSupabaseAnonKey : '';
  }

  /// Google Maps client-side API key. Falls back to dev env var → hardcoded fallback in debug mode.
  static String get googleMapsApiKey {
    if (_googleMapsApiKey.isNotEmpty) return _googleMapsApiKey;
    if (_devGoogleMapsApiKey.isNotEmpty) return _devGoogleMapsApiKey;
    return kDebugMode ? _fallbackGoogleMapsApiKey : '';
  }

  /// App environment. Defaults to 'development'.
  static String get appEnv => _appEnv.isNotEmpty ? _appEnv : 'development';

  static bool get isProduction => appEnv == 'production';
  static bool get isStaging => appEnv == 'staging';
  static bool get isDevelopment => appEnv == 'development';
  static bool get hasGoogleMapsApiKey => googleMapsApiKey.trim().isNotEmpty;

  /// Throws [StateError] if required env vars are missing **in release mode**.
  /// In debug mode, logs a warning but does NOT throw — this lets bare
  /// `flutter run` work without `--dart-define-from-file=.env` by falling
  /// back to the hardcoded development defaults below.
  static void validate() {
    if (supabaseUrl.isEmpty) {
      if (kReleaseMode) {
        throw StateError('SUPABASE_URL must be set via --dart-define');
      }
      // Debug fallback handled by getter.
    }
    if (supabaseAnonKey.isEmpty) {
      if (kReleaseMode) {
        throw StateError('SUPABASE_ANON_KEY must be set via --dart-define');
      }
    }
  }
}
