# MQ Navigation

A full-stack campus management platform for Macquarie University, built as part of COMP3130 Mobile Application Development.

MQ Navigation helps students manage their academic life — deadlines, calendars, campus navigation, events, and more — through a unified mobile experience backed by a shared cloud infrastructure.

## Architecture

**Two frontends, one backend:**

```
┌──────────────────┐     ┌──────────────────┐
│  Flutter Mobile   │     │  Next.js Web App  │
│  (this repo)      │     │  (production)     │
└────────┬─────────┘     └────────┬─────────┘
         │                        │
         └───────┐    ┌───────────┘
                 │    │
           ┌─────▼────▼─────┐
           │    Supabase     │
           │  Auth · Postgres│
           │  RLS · Realtime │
           │  Edge Functions │
           └─────────────────┘
```

Both clients share a single Supabase backend — Auth, Postgres with Row-Level Security, Realtime subscriptions, and Edge Functions. The Flutter app is a presentation-layer-only client with no server logic in the binary.

## Project Structure

```
Pouya-Raouf-COMP3130/
└── MQ_Navigation/              # Flutter mobile app
    ├── lib/
    │   ├── app/                # Bootstrap, router, theme, l10n
    │   ├── core/               # Config, errors, logging, security, network
    │   ├── shared/             # Design system widgets, providers, extensions
    │   └── features/           # Feature modules (auth, home, calendar, map, feed, settings)
    ├── test/                   # 78 unit and widget tests
    ├── scripts/                # Quality gate scripts
    ├── tools/                  # i18n conversion utilities
    ├── docs/                   # Architecture documentation
    └── .github/workflows/      # CI/CD pipeline
```

## Features

- **Dashboard** — upcoming deadlines, schedule overview, study streaks
- **Academic Calendar** — deadline and exam tracking with reminders
- **Campus Map** — interactive Google Maps with 100+ buildings, search, and routing
- **Events Feed** — university events with filtering and bookmarking
- **Settings** — profile management, theme preferences, notifications
- **35-Language Support** — full i18n including RTL (Arabic, Farsi, Hebrew, Urdu)
- **Dark Mode** — system-aware light and dark themes using Macquarie University design tokens
- **Biometric Auth** — optional fingerprint/face authentication
- **Offline Awareness** — connectivity monitoring with graceful degradation

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.11+ / Dart 3.11+ |
| State Management | Riverpod 3.2 |
| Routing | GoRouter 17.1 with auth guards |
| Backend | Supabase (Auth, Postgres, RLS, Realtime, Edge Functions) |
| Maps | Google Maps Flutter 2.14 |
| Security | flutter_secure_storage, local_auth |
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
cd MQ_Navigation

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

### Quality Checks

```bash
# Full check (format, analyze, test, l10n, build)
./scripts/check.sh

# Quick check (skip build step)
./scripts/check.sh --quick
```

All 6 checks must pass: dependency resolution, formatting, static analysis, 78 tests, localisation generation, and APK build.

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

1. **Analyze & Test** — formatting, static analysis, 78 unit/widget tests with coverage
2. **Build Android** — release APK with secrets injection (main branch only)
3. **Build iOS** — release build without code signing (main branch only)

## Documentation

| Document | Location |
|----------|----------|
| Architecture Overview | [`MQ_Navigation/docs/ARCHITECTURE.md`](MQ_Navigation/docs/ARCHITECTURE.md) |
| Contributing Guidelines | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| Code of Conduct | [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) |
| Security Policy | [`SECURITY.md`](SECURITY.md) |
| Changelog | [`MQ_Navigation/CHANGELOG.md`](MQ_Navigation/CHANGELOG.md) |

## Roadmap

- [x] **Phase 0** — Foundation: project scaffold, inventories, CI/CD
- [x] **Phase 1** — App Shell: theme, routing, design system, i18n, core services
- [ ] **Phase 2** — Auth: login, signup, MFA, OAuth, profile
- [ ] **Phase 3** — Home & Calendar: dashboard widgets, academic calendar
- [ ] **Phase 4** — Feed & Notifications: events, push notifications
- [ ] **Phase 5** — Map: Google Maps integration, building search, routing
- [ ] **Phase 6** — Polish: performance, accessibility audit, store release

## Authors

- **Raouf Abedini** (47990805) — COMP3130, Macquarie University
- **Pouya Alavi** (48160202) — COMP3130, Macquarie University

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
