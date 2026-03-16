# Environment Variable Inventory

All environment variables used by MQ Navigation, categorised by client/server exposure.

## Client-Side (--dart-define in Flutter)

| Variable | Required | Default | Notes |
|----------|----------|---------|-------|
| `SUPABASE_URL` | Release only | Hardcoded dev fallback | Supabase project URL |
| `SUPABASE_ANON_KEY` | Release only | Hardcoded dev fallback | Public anon key (RLS enforced) |
| `GOOGLE_MAPS_API_KEY` | No | None | Client-side Google Maps renderer key |
| `APP_ENV` | No | `development` | development / staging / production |

> In **debug mode** a bare `flutter run` works for Supabase without
> `--dart-define-from-file=.env` because `env_config.dart` falls back to
> development defaults.
> The Google Maps client key must still be supplied locally.
> In **release mode** you must supply at least `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

## Server-Only (Edge Functions env / Supabase dashboard)

| Variable | Service | Notes |
|----------|---------|-------|
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Functions | Bypasses RLS — never in client code |
| `GOOGLE_ROUTES_API_KEY` | `maps-routes` EF | Google Routes API key for Google map mode |
| `ORS_API_KEY` | `maps-routes` EF | Optional OpenRouteService key for campus routing |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | `notify` EF | Firebase service account JSON for FCM HTTP v1 |
| `CRON_SECRET` | `cleanup-cron` EF | Protects cron endpoints |

> **Note:** Route computation is now server-side again. Flutter only needs the
> client Maps SDK key for rendering; route secrets stay in Supabase Edge
> Function configuration.

## Firebase (Flutter-specific, not in web app)

| Variable | Location | Notes |
|----------|----------|-------|
| `google-services.json` | `android/app/` | Firebase Android config |
| `GoogleService-Info.plist` | `ios/Runner/` | Firebase iOS config |
| APNs auth key / certificate | Apple Developer + Firebase | Required for iOS push delivery |
