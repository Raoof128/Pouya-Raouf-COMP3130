# Security Posture (OWASP 2026 Standards)

## Privacy by Design (Zero Data Collection)
- **No account system**: The app starts directly at `/home` — no login, no signup, no email, no password.
- **No tracking**: No analytics, telemetry, or crash reporting packages (enforced by `check.sh` privacy guard).
- **No location history**: GPS data is used ephemerally for routing — never stored, never transmitted.
- **Settings Privacy Badge**: Permanent "Private by design: no account, no tracking, no location history." card in Settings.
- **Safety Toolkit**: Emergency contacts use tap-to-dial (`url_launcher`) — location is never shared automatically.
- **Compass Mode**: All heading calculation is on-device via `FlutterCompass.events` — no data leaves the device.

## Authentication & Authorization
- **No auth in app binary**: The Flutter app has zero authentication code. Login/signup flows exist only on the web app.
- **Supabase Auth** (GoTrue) with PKCE is used by the web frontend — mobile never holds user credentials.
- **Row-Level Security (RLS)** is enforced at the database layer for any Edge Function queries.

## Data Security
- **At Rest**: Sensitive keys (Supabase tokens) are stored in the hardware-backed **iOS Keychain** or **Android Keystore** via `flutter_secure_storage`.
- **In Transit**: TLS 1.3 enforced for all Supabase and TfNSW API traffic.
- **Local Only**: User preferences, commute settings, and Open Day lead times are stored in `SharedPreferences` — never sent to a server.

## API & Edge Security
- **Proxy Pattern**: All third-party SDK keys (Google Maps, OpenRouteService) are stored as secrets in **Supabase Edge Functions**. The mobile client never holds server-side keys.
- **Secret Scan**: `scripts/check.sh` scans `lib/` `test/` `scripts/` for hardcoded API key patterns (`sk-*`, `AIza*`) on every CI run.
- **Throttling**: Rate limiting applied per IP at the Edge to prevent scrapers or DDoS on the routing proxy.
- **Input Validation**: All coordinate and route requests are validated against MQ campus bounding boxes.

## CI/CD Security
- **Privacy Guard**: `check.sh` fails if analytics/tracking packages (`firebase_analytics`, `google_analytics`, `appsflyer`, `amplitude`, `mixpanel`, `segment`, `sentry_flutter`, `facebook_app_events`) are added to `pubspec.yaml`.
- **Secret Scan**: grep-based detection of hardcoded API keys — excludes `supabase/` Edge Functions (which use `Deno.env.get()` for runtime env vars).
- **Dependency Check**: `flutter pub get` validates all transitive dependencies — no unvetted packages.

## 2026 Offensive Security Mitigation
- **Deep Link Protection**: Intent filters restricted to verified `mq.edu.au` domains via App Links (Android) and Universal Links (iOS).
- **Script Injection**: All HTML-rich routing instructions sanitized via `NavInstruction` normalization to prevent XSS.
- **Android Emulator Guard**: `LocationSource` rejects the default mocked Googleplex coordinate (`37.4219983, -122.084`) to prevent locate-me jumping to a US location on emulators.
