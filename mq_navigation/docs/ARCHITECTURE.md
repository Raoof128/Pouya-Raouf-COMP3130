# Architecture Overview

This document describes the technical architecture of the MQ Navigation Flutter mobile app.

## System Context

MQ Navigation uses a **two frontends, one backend** architecture:

```
+------------------+     +------------------+
|  Flutter Mobile  |     |  Next.js Web App  |
|  (this repo)     |     |  (mq-navigation)  |
+--------+---------+     +--------+---------+
         |                         |
         +--------+    +-----------+
                  |    |
            +-----v----v-----+
            |    Supabase     |
            |  (Auth, DB,     |
            |   RLS, Realtime,|
            |   Edge Fns)     |
            +-----------------+
```

Both clients share the same Supabase backend. The Flutter app is a **presentation-layer-only** client --- no server logic runs in the app binary.

## Project Structure

```
lib/
  main.dart                     # Entry point
  app/
    bootstrap/bootstrap.dart    # Supabase init, Firebase init, error handlers, ProviderScope
    mq_navigation_app.dart      # Root MaterialApp.router
    router/
      app_router.dart           # GoRouter with StatefulShellRoute (3-tab bottom nav)
      app_shell.dart            # Bottom NavigationBar (3-tab shell: Home, Map, Settings)
      route_names.dart          # Named route constants
    theme/
      mq_colors.dart            # MQ brand palette (mapped from web tokens)
      mq_typography.dart        # Work Sans / Source Serif Pro type scale
      mq_spacing.dart           # Spacing, radius, and tap-target tokens
      mq_theme.dart             # Light + dark ThemeData builders
    l10n/
      app_en.arb                # English template
      app_*.arb                 # 34 other locale files
      generated/                # Auto-generated AppLocalizations

  core/                         # Framework-level infrastructure
    config/env_config.dart      # --dart-define environment config
    error/
      app_exception.dart        # Sealed exception hierarchy
      error_boundary.dart       # Widget error boundary + global handlers
    logging/app_logger.dart     # Structured logger
    network/connectivity_service.dart
    security/
      secure_storage_service.dart
    utils/result.dart           # Result<T> sealed type

  shared/                       # Cross-feature shared code
    widgets/                    # MQ design system widgets
    models/                     # UserPreferences
    extensions/                 # BuildContext extensions

  features/                     # Feature modules
    home/
      presentation/pages/home_page.dart
    map/
      data/datasources/
      data/repositories/
      domain/entities/
      domain/services/
      presentation/controllers/
      presentation/pages/
      presentation/widgets/
    notifications/
      data/datasources/
      data/repositories/
      domain/entities/
      domain/services/
      presentation/controllers/
      presentation/pages/
      presentation/widgets/
    settings/
      data/repositories/
      presentation/controllers/
      presentation/pages/
```

## Feature Module Pattern

Each feature follows a three-layer structure:

```
features/<name>/
  data/           # Data sources (Supabase, local cache) + repository implementations
  domain/         # Entities, value objects, repository interfaces, use cases
  presentation/   # Pages, widgets, Riverpod controllers/providers
```

**Rules:**
- Features never import from another feature's `data/` or `domain/` layer directly
- Cross-feature communication happens through `shared/providers/`
- Only `presentation/` widgets may use `BuildContext`

## Subsystems

### Notifications

- `features/notifications/` owns FCM token sync, local study prompt scheduling, the notification inbox, and preference state.
- FCM tokens are stored in `user_fcm_tokens` and refreshed on token rotation.
- `supabase/functions/notify` stores the inbox row in `notifications` and dispatches push delivery through Firebase without exposing push credentials to Flutter.
- Local notifications are limited to study prompt reminders scheduled via `flutter_local_notifications`.

### Campus Map

- `features/map/` loads the building registry from the bundled JSON asset (153 buildings from the audited web registry).
- The 6 high-traffic buildings carry explicit `entranceLocation` and `googlePlaceId` enrichments for routing parity.
- The map now uses a shared controller state with two renderer targets: `flutter_map` for campus mode and `google_maps_flutter` for Google mode.
- `MapRendererType` decides how the map is drawn; search, selected building, route state, travel mode, and location state stay shared.
- The campus renderer now consumes the exported web raster image (`assets/maps/mq-campus.png`) plus shared overlay metadata, calibrated GPS projection coefficients, and pixel-space building coordinates.
- Both renderers route through the `maps-routes` Supabase Edge Function, which normalizes Google Routes and campus walking responses into the same `MapRoute` contract.
- Client-side location uses `geolocator`, with renderer-specific drawing handled by `GoogleMapView` and `CampusMapView`.

## State Management

**Riverpod** (v3.2.1) is the sole state management solution.

| Provider Type | Use Case |
|--------------|----------|
| `Provider` | Singletons (router, services) |
| `AsyncNotifierProvider` | Map state, data fetching with lifecycle |
| `StreamProvider` | Real-time data (connectivity) |
| `FutureProvider` | One-shot async data loading |

**No `setState`, no Bloc, no ChangeNotifier.**

## Routing

**GoRouter** (v17.1.0) with:
- `StatefulShellRoute.indexedStack` for the 3-tab bottom navigation (Home, Map, Settings)
- `/notifications` as a standalone route pushed on top of the shell
- `/map/building/:buildingId` for deep-linking to a specific building
- Named routes via `RouteNames` constants
- App starts at `/home` with no auth guards

## Design System

The MQ Design System maps Macquarie University's web CSS tokens to Flutter:

| Token | Source | Flutter |
|-------|--------|---------|
| Colors | `mq-tokens.css` | `MqColors` |
| Typography | Work Sans + Source Serif Pro | `MqTypography` |
| Spacing | 4px base scale | `MqSpacing` |
| Radii | `radius-sm/md/lg` | `MqSpacing.radius*` |

Both **light** and **dark** themes are built from these tokens via `MqTheme.light` and `MqTheme.dark`.

## Localisation

- 35 locales, converted from the web app's JSON files to Flutter ARB format
- RTL support for Arabic, Farsi, Hebrew, and Urdu
- ICU message syntax (`{variable}`) with Dart reserved word prefixing (`class` -> `kClass`)
- Conversion tool: `dart tools/convert_i18n.dart`

## Security Model

1. **No server secrets in client** --- API keys stay in Edge Functions
2. **Encrypted storage** --- `flutter_secure_storage` (iOS Keychain / Android Keystore)
3. **RLS enforcement** --- all database access governed by Supabase Row-Level Security

## Environment Configuration

Build-time injection via `--dart-define`:

| Variable | Required | Purpose |
|----------|----------|---------|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | Supabase anonymous API key |
| `GOOGLE_MAPS_API_KEY` | No | Google Maps SDK key for the embedded map |
| `APP_ENV` | No | `development` / `staging` / `production` |

`EnvConfig.validate()` throws `StateError` in all build modes if required vars are missing.

## CI/CD Pipeline

GitHub Actions (`.github/workflows/ci.yml`):

```
Push/PR to main
  -> Analyze & Test (ubuntu)
     -> format check
     -> flutter analyze
     -> flutter test --coverage

Push to main only
  -> Build Android (ubuntu, Java 17)
     -> flutter build apk --release
     -> Upload artifact
  -> Build iOS (macos)
     -> flutter build ios --release --no-codesign
```

## Error Handling

- **Sealed exceptions** (`AppException`): `NetworkException`, `AuthException`, `ServerException`, `StorageException`, `UnsupportedException`
- **Result type**: `Result<T>` sealed class with `Success<T>` and `Failure<T>`
- **Error boundary**: `ErrorBoundary` widget wrapping the app tree, showing a friendly fallback UI instead of the red screen
- **Zone guard**: `runZonedGuarded` in `bootstrap()` catches unhandled async errors
- **Structured logging**: `AppLogger` wrapping the `logger` package

## Testing Strategy

| Layer | Tool | Location |
|-------|------|----------|
| Unit tests | `flutter_test` | `test/core/`, `test/features/` |
| Widget tests | `flutter_test` | `test/shared/`, `test/app/` |

Quality gate: `scripts/check.sh` runs format, analyze, test, and gen-l10n in sequence.
