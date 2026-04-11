# MQ Navigation

A cross-platform mobile client for Macquarie University's campus navigation platform, built with Flutter. Part of a **two frontends, one backend** architecture sharing a Supabase backend with the existing [Next.js web application](https://github.com/Raoof128/Pouya-Raouf-COMP3130).

## Architecture

```
┌──────────────────┐     ┌──────────────────┐
│  Flutter Mobile   │     │  Next.js Web App  │
│  mq_navigation    │     │  (production)     │
│                   │     │                   │
└────────┬─────────┘     └────────┬─────────┘
         │                        │
         └───────┐    ┌───────────┘
                 │    │
           ┌─────▼────▼─────┐
           │    Supabase     │
           │  Postgres · RLS │
           │  Realtime       │
           │  Edge Functions │
           └─────────────────┘
```

The mobile app shares a single Supabase backend with the web product — Postgres with Row-Level Security, Realtime subscriptions, and Edge Functions. The Flutter app is a presentation-layer-only client with no server logic in the binary.

## Project Structure

```
Pouya-Raouf-COMP3130/
└── mq_navigation/                  # Flutter mobile app
    ├── lib/
    │   ├── app/                    # Bootstrap, router, theme, l10n
    │   ├── core/                   # Config, errors, logging, security, network
    │   ├── shared/                 # Design system widgets, providers, extensions
    │   └── features/              # Feature modules (home, map, settings, notifications)
    ├── test/                       # 83 unit and widget tests
    ├── supabase/functions/         # 9 Edge Functions (Deno/TypeScript)
    ├── scripts/                    # Quality gate scripts
    ├── tools/                      # i18n conversion utilities
    ├── assets/data/                # 153-building campus registry
    ├── docs/                       # Architecture documentation
    └── .github/workflows/          # CI/CD pipeline
```

## Features

- **Home** -- campus dashboard with time-of-day greeting, building category grid, popular destinations carousel
- **Campus Map** -- interactive Google Maps with 153 building entries, search, and server-proxied routing
- **Notifications** -- Supabase inbox, FCM push, and local study-prompt scheduling
- **Settings** -- theme preferences, notification controls, locale selection
- **35-Language Support** -- full i18n including RTL (Arabic, Farsi, Hebrew, Urdu)
- **Dark Mode** -- system-aware light and dark themes using Macquarie University design tokens
- **Offline Awareness** -- connectivity monitoring with graceful degradation

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.11+ / Dart 3.11+ |
| State Management | Riverpod 3.2 |
| Routing | GoRouter 17.1 (StatefulShellRoute, 3-tab bottom nav) |
| Backend | Supabase (Postgres, RLS, Realtime, Edge Functions) |
| Maps | Google Maps Flutter 2.14 |
| Security | flutter_secure_storage |
| Notifications | Firebase Cloud Messaging |
| CI/CD | GitHub Actions |
| Localisation | Flutter ARB (35 locales, 1,995 keys each) |

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ^3.11.0 (stable channel)
- [Android Studio](https://developer.android.com/studio) or [Xcode](https://developer.apple.com/xcode/)
- A Supabase project

### Setup

```bash
cd mq_navigation

# Install dependencies
flutter pub get

# Generate localisation files
flutter gen-l10n

# Run the app
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

### Quality Checks

```bash
# Full check (format, analyze, test, l10n, build)
./scripts/check.sh

# Quick check (skip build step)
./scripts/check.sh --quick
```

All checks must pass: dependency resolution, formatting, static analysis, 83 tests, localisation generation, and APK build.

## Design System

The MQ Design System maps Macquarie University's brand identity to Flutter:

| Token | Class | Examples |
|-------|-------|---------|
| Colors | `MqColors` | MQ Red `#A6192E`, Alabaster `#EDEADE`, Charcoal shades |
| Typography | `MqTypography` | Work Sans (UI), Source Serif Pro (headings) |
| Spacing | `MqSpacing` | 4px base scale, 48dp minimum tap targets |
| Theme | `MqTheme` | Complete light + dark `ThemeData` |

Shared UI components: `MqButton`, `MqCard`, `MqInput`, `MqAppBar`, `MqBottomSheet`

## CI/CD

GitHub Actions runs on every push and PR to `main`:

1. **Analyze & Test** -- formatting, static analysis, 83 unit/widget tests with coverage
2. **Build Android** -- release APK with secrets injection (main branch only)
3. **Build iOS** -- release build without code signing (main branch only)

## Documentation

| Document | Location |
|----------|----------|
| Architecture Overview | [`mq_navigation/docs/ARCHITECTURE.md`](mq_navigation/docs/ARCHITECTURE.md) |
| Contributing Guidelines | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| Code of Conduct | [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) |
| Security Policy | [`SECURITY.md`](SECURITY.md) |
| Changelog | [`mq_navigation/CHANGELOG.md`](mq_navigation/CHANGELOG.md) |
| Agent Rules | [`mq_navigation/AGENT.md`](mq_navigation/AGENT.md) |

## Roadmap

- [x] **Phase 0** -- Foundation: project scaffold, inventories, CI/CD
- [x] **Phase 1** -- App Shell: theme, routing, design system, i18n, core services
- [x] **Phase 2** -- Settings: theme preferences, notification controls, locale selection
- [x] **Phase 3** -- Home: campus dashboard with category grid, popular destinations, campus stats
- [x] **Phase 4** -- Notifications: Supabase inbox, FCM push, local study-prompt reminders
- [x] **Phase 5** -- Map: Google Maps integration, 153-building search, server-proxied routing
- [ ] **Phase 6** -- Polish: performance, accessibility audit, store release

## Authors

- **Raouf Abedini** (47990805) -- COMP3130, Macquarie University
- **Pouya Alavi** (48160202) -- COMP3130, Macquarie University

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
