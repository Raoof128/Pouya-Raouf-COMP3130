# MQ Navigation - Flutter Mobile App

A cross-platform mobile client for Macquarie University's campus navigation, built with Flutter. Part of a **two frontends, one backend** architecture sharing a Supabase backend with the existing [Next.js web application](https://github.com/Raoof128/Pouya-Raouf-COMP3130).

## Features

- **Home** -- welcome hub for Macquarie University campus navigation
- **Dual-Renderer Map** -- raster campus overlay via `flutter_map` plus live Google basemap via `google_maps_flutter`
- **Shared Map State** -- one building registry, search flow, selection model, and route state across both map modes
- **Settings** -- theme preferences, language selection, notification controls
- **Notifications** -- FCM push notifications and local study prompt scheduling
- **35-Language Support** -- full i18n with RTL support (Arabic, Farsi, Hebrew, Urdu)
- **Dark Mode** -- system-aware light and dark themes using MQ design tokens
- **Offline Awareness** -- connectivity monitoring with graceful degradation

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.11+ (Dart 3.11+) |
| State Management | Riverpod 3.2 |
| Routing | GoRouter 17.1 (StatefulShellRoute, 3-tab bottom nav) |
| Backend | Supabase (Postgres, Realtime, Edge Functions) |
| Maps | google_maps_flutter 2.15 + flutter_map 8.2 |
| Security | flutter_secure_storage |
| Push Notifications | Firebase Cloud Messaging |
| CI/CD | GitHub Actions (analyze, test, build Android + iOS) |
| Localisation | Flutter ARB (35 locales) |

## Architecture

Feature-first clean architecture with three layers per module:

```
lib/
  app/          # Bootstrap, router, theme, l10n
  core/         # Config, error handling, logging, security, networking
  shared/       # Design system widgets, providers, extensions
  features/     # home, map, notifications, settings
    <feature>/
      data/           # Data sources + repositories
      domain/         # Entities, value objects, interfaces
      presentation/   # Pages, widgets, controllers
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full architecture overview.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ^3.11.0 (stable channel)
- [Android Studio](https://developer.android.com/studio) or [Xcode](https://developer.apple.com/xcode/) for platform builds
- A Supabase project (shared with the web app)

### Setup

```bash
# Clone the repository and enter the Flutter app
git clone <repo-url>
cd mq_navigation

# Install dependencies
flutter pub get

# Generate localisation files
flutter gen-l10n

# Refresh the bundled building registry when backend map data changes
dart run tools/sync_buildings.dart

# Run the app
flutter run                     # Android emulator (default)
flutter run -d chrome           # Web (Chrome)
./scripts/run.sh chrome         # Web (alternative — loads .env overrides)

# For release builds, supply secrets via --dart-define or .env:
flutter run --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=GOOGLE_MAPS_API_KEY=your-maps-key \
  --dart-define=APP_ENV=production
```

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SUPABASE_URL` | Release only | Dev fallback | Supabase project URL |
| `SUPABASE_ANON_KEY` | Release only | Dev fallback | Supabase anonymous API key |
| `GOOGLE_MAPS_API_KEY` | No | None | Google Maps SDK key for the Google renderer |
| `APP_ENV` | No | `development` | `development`, `staging`, or `production` |

> In **debug mode**, Supabase uses development fallbacks, but the Google Maps
> client key must still come from local environment config when you want the
> Google renderer or web Google Maps integration.

### Mobile Platform Setup

1. Add Firebase mobile config files outside version control:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - Android auto-enables the Google Services Gradle plugin when `google-services.json` exists.
   - iOS `AppDelegate` configures Firebase automatically when `GoogleService-Info.plist` exists.
2. Enable push prerequisites in Firebase/Apple Developer:
   - iOS APNs key/certificate
   - iOS Background Modes -> `remote-notification`
   - Android notification permission on Android 13+
3. Provide a restricted client Maps SDK key at build time:
   - Android reads `GOOGLE_MAPS_API_KEY` through the manifest placeholder
   - iOS reads `GOOGLE_MAPS_API_KEY` through `Info.plist` / `AppDelegate`
4. Do not commit Firebase service files, APNs secrets, or unrestricted API keys.

### Edge Function Secrets

| Secret | Required For | Notes |
|--------|--------------|-------|
| `SUPABASE_SERVICE_ROLE_KEY` | All privileged Edge Functions | Server-only |
| `GOOGLE_ROUTES_API_KEY` | `maps-routes` | Server-only Google Routes API key |
| `ORS_API_KEY` | `maps-routes` campus routing | Optional; when omitted, campus mode falls back to a generated demo route |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | `notify` | FCM HTTP v1 service account JSON |
| `CRON_SECRET` | `cleanup-cron` | Protects scheduled cron endpoints |
| `ALLOWED_WEB_ORIGINS` | `maps-routes`, `maps-places` | Optional comma-separated browser origin allowlist for Flutter web / hosted web |

> Route requests no longer use the client-side Google Directions flow.
> Both renderers call the `maps-routes` Supabase Edge Function, which keeps
> server-side routing keys out of the Flutter binary.

> Campus mode currently supports walking routes only. For driving, cycling, or
> transit directions, switch to the Google renderer.

> `maps-places` is now rate-limited and server-cached. For browser deployments,
> set `ALLOWED_WEB_ORIGINS` so only your own web origins can call the map Edge
> Functions with an `Origin` header.

## Development

### Quality Checks

```bash
# Full check (includes debug APK build)
./scripts/check.sh

# Quick check (skips build step)
./scripts/check.sh --quick
```

This executes: `pub get` -> `format check` -> `analyze` -> `test` -> `gen-l10n` -> `build`

### Running Tests

```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Specific test file
flutter test test/features/map/building_test.dart
```

Coverage spans core utilities, routing, map parsing, the bundled building registry, notification scheduling, and shared widgets.

### Project Scripts

| Script | Purpose |
|--------|---------|
| `scripts/check.sh` | Full quality gate (format, analyze, test, l10n, build) |
| `scripts/check.sh --quick` | Quality gate without build step |
| `tools/convert_i18n.dart` | Convert web app JSON translations to Flutter ARB format |

## Design System

The MQ Design System maps Macquarie University's brand tokens to Flutter:

| Component | Class | Description |
|-----------|-------|-------------|
| Colors | `MqColors` | Brand palette (MQ Red, Alabaster, Charcoal, semantic colors) |
| Typography | `MqTypography` | Work Sans + Source Serif Pro type scale |
| Spacing | `MqSpacing` | 4px-base spacing scale, radius tokens, 48dp tap targets |
| Theme | `MqTheme` | Light + dark `ThemeData` builders |
| Button | `MqButton` | Filled, outlined, and text variants with loading state |
| Card | `MqCard` | Themed card with optional tap handler |
| Input | `MqInput` | Text input with validation, prefix/suffix icons |
| App Bar | `MqAppBar` | Standard app bar with MQ styling |
| Bottom Sheet | `MqBottomSheet` | Modal sheet with drag handle |

## CI/CD

GitHub Actions runs on every push and PR to `main`:

1. **Analyze & Test** -- format check, static analysis, Flutter test suite with coverage, and `deno check` for `maps-routes`/`maps-places`
2. **Build Android Smoke** -- debug APK build on pull requests
3. **Build Android** -- release APK with secrets injection (main branch only)
4. **Build iOS** -- release build without code signing (main branch only)

## Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Full architecture overview |
| [env_inventory.md](env_inventory.md) | Client/server environment inventory |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Community standards |
| [SECURITY.md](SECURITY.md) | Security policy and practices |
| [CHANGELOG.md](CHANGELOG.md) | Development history |
| [AGENT.md](AGENT.md) | Architecture rules and coding conventions |

### Inventory Documents

| Document | Content |
|----------|---------|
| `entity_inventory.md` | Supabase tables and RPC functions (shared backend schema) |
| `endpoint_inventory.md` | API routes mapped to SDK/Edge Functions |
| `env_inventory.md` | Client/server environment variables |
| `notification_matrix.md` | Push/local notification flows |
| `route_matrix.md` | Flutter route map |
| `map_inventory.md` | Map APIs, building registry schema |
| `key_inventory.md` | 35-locale translation key inventory |


## Authors

- **Raouf Abedini** (47990805) — COMP3130, Macquarie University
- **Pouya Alavi** (48160202) — COMP3130, Macquarie University

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
