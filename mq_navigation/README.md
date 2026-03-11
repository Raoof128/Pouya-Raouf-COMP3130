# MQ Navigation - Flutter Mobile App

A cross-platform mobile client for Macquarie University's campus management platform, built with Flutter. Part of a **two frontends, one backend** architecture sharing a Supabase backend with the existing [Next.js web application](https://github.com/Raoof128/Pouya-Raouf-COMP3130).

## Features

- **Dashboard** -- upcoming deadlines, today's schedule, recent events, study streaks
- **Calendar** -- academic calendar with deadline and exam tracking
- **Notifications** -- Supabase inbox, FCM push, and local reminder scheduling
- **Campus Map** -- interactive Google Maps with 153 building entries, search, and server-proxied routing
- **Events Feed** -- university events with filtering and bookmarking
- **Settings** -- profile management, theme preferences, notification controls
- **35-Language Support** -- full i18n with RTL support (Arabic, Farsi, Hebrew, Urdu)
- **Dark Mode** -- system-aware light and dark themes using MQ design tokens
- **Biometric Auth** -- optional fingerprint/face authentication for sensitive actions
- **Offline Awareness** -- connectivity monitoring with graceful degradation

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.11+ (Dart 3.11+) |
| State Management | Riverpod 3.2 |
| Routing | GoRouter 17.1 (StatefulShellRoute, auth guards) |
| Backend | Supabase (Auth, Postgres, RLS, Realtime, Edge Functions) |
| Maps | Google Maps Flutter 2.14 |
| Security | flutter_secure_storage, local_auth |
| Push Notifications | Firebase Cloud Messaging |
| CI/CD | GitHub Actions (analyze, test, build Android + iOS) |
| Localisation | Flutter ARB (35 locales, 1,995 keys each) |

## Architecture

Feature-first clean architecture with three layers per module:

```
lib/
  app/          # Bootstrap, router, theme, l10n
  core/         # Config, error handling, logging, security, networking
  shared/       # Design system widgets, providers, extensions
  features/     # auth, home, calendar, map, feed, settings, ...
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
# Clone the repository
git clone https://github.com/Raoof128/Pouya-Raouf-COMP3130.git
cd Pouya-Raouf-COMP3130/mq-navigation_flutter

# Install dependencies
flutter pub get

# Generate localisation files
flutter gen-l10n

# Run the app (development mode)
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=GOOGLE_MAPS_API_KEY=your-maps-key \
  --dart-define=APP_ENV=development
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | Supabase anonymous API key |
| `GOOGLE_MAPS_API_KEY` | No | Google Maps SDK key (needed for map feature) |
| `APP_ENV` | No | `development` (default), `staging`, or `production` |

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
| `GOOGLE_ROUTES_API_KEY` | `maps-routes` | Server-side routing proxy |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | `notify` (preferred) | FCM HTTP v1 service account JSON |
| `FCM_SERVER_KEY` | `notify` (legacy fallback) | Supported as a compatibility fallback |
| `CRON_SECRET` | `cleanup-cron` | Protects scheduled cleanup runs |
| `RESEND_API_KEY` | `auth-email` | Email verification delivery |

## Development

### Quality Checks

Run the full check suite (mirrors the web app's `npm run check`):

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

Coverage spans core utilities, routing, auth flows, calendar state, feed-import models, notification scheduling, map parsing, the bundled building registry, and shared widgets.

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

1. **Analyze & Test** -- format check, static analysis, 78 unit/widget tests with coverage
2. **Build Android** -- release APK with secrets injection (main branch only)
3. **Build iOS** -- release build without code signing (main branch only)

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

### Phase 0 Inventory Documents

| Document | Content |
|----------|---------|
| `entity_inventory.md` | 22 Supabase tables, 4 views, 20+ RPC functions |
| `endpoint_inventory.md` | 58 API routes mapped to SDK/Edge Functions |
| `env_inventory.md` | Client/server/web-only environment variables |
| `auth_matrix.md` | Auth state machine, route guards, deep link callbacks |
| `notification_matrix.md` | Push/local notification flows and FCM lifecycle |
| `route_matrix.md` | Web route to Flutter route mappings |
| `map_inventory.md` | Map APIs, building registry schema |
| `key_inventory.md` | 35-locale translation key inventory |

## Roadmap

- [x] **Phase 0** -- Foundation: project scaffold, inventories, CI/CD
- [x] **Phase 1** -- App Shell: theme, routing, design system, i18n, core services
- [x] **Phase 2** -- Auth, onboarding, profile, settings, MFA, biometric lock
- [x] **Phase 3** -- Dashboard + calendar core with agenda/day/week views and CRUD quick-add flows
- [x] **Phase 4** -- Feed & Notifications: events, push notifications
- [x] **Phase 5** -- Map: Google Maps integration, building search, routing
- [ ] **Phase 6** -- Polish: performance, accessibility audit, store release

## Authors

- **Raouf Abedini** (47990805) — COMP3130, Macquarie University
- **Pouya Alavi** (48160202) — COMP3130, Macquarie University

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
