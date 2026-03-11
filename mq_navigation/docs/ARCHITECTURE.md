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
    bootstrap/bootstrap.dart    # Supabase init, error handlers, ProviderScope
    mq_navigation_app.dart      # Root MaterialApp.router
    router/
      app_router.dart           # GoRouter with auth guards + refreshListenable
      app_shell.dart            # Bottom NavigationBar (5-tab shell)
      route_names.dart          # Named route constants
    theme/
      mq_colors.dart            # MQ brand palette (mapped from web tokens)
      mq_typography.dart        # Work Sans / Source Serif Pro type scale
      mq_spacing.dart           # Spacing, radius, and tap-target tokens
      mq_theme.dart             # Light + dark ThemeData builders
    l10n/
      app_en.arb                # English template (1995 keys)
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
      biometric_service.dart
    utils/result.dart           # Result<T> sealed type

  shared/                       # Cross-feature shared code
    widgets/                    # MQ design system widgets
    providers/                  # Auth, connectivity providers
    extensions/                 # BuildContext extensions

  features/                     # Feature modules
    auth/
      data/datasources/
      data/repositories/
      domain/entities/
      domain/services/
      presentation/controllers/
      presentation/pages/
      presentation/widgets/
    home/
    calendar/
    map/
    feed/
    settings/
    ...
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

## Phase 4 and Phase 5 Subsystems

### Notifications and Feed

- `features/notifications/` owns FCM token sync, local reminder scheduling, the notification inbox, and preference state.
- FCM tokens are stored in `user_fcm_tokens` and refreshed on login/token rotation; stale tokens are removed on logout or push failure.
- Notification preferences are stored in `notification_preferences`, not local-only storage, and are normalized on the client so missing rows fall back safely.
- `supabase/functions/notify` stores the inbox row in `notifications` and dispatches push delivery through Firebase without exposing push credentials to Flutter.
- `features/feed/` reads `public_events`, preserves `source_public_event_id` when importing to the personal calendar, and keeps pagination ordered by cursor-safe `start_at`.

### Campus Map

- `features/map/` loads the building registry from Supabase `app_config` when available and otherwise falls back to the bundled asset generated from the audited web registry.
- The bundled map asset currently contains 153 buildings, with the 6 high-traffic buildings carrying explicit `entranceLocation` and `googlePlaceId` enrichments for routing parity.
- `supabase/functions/maps-routes` is the authenticated routing proxy. It validates input, enforces a per-user `rate_limits` window, and keeps `GOOGLE_ROUTES_API_KEY` server-side.
- Client-side routing uses `google_maps_flutter` for rendering, `geolocator` for point-of-need location access, and `GoogleMap` camera bounds locked to the campus extent.

## State Management

**Riverpod** (v3.2.1) is the sole state management solution.

| Provider Type | Use Case |
|--------------|----------|
| `Provider` | Singletons (router, services) |
| `AsyncNotifierProvider` | Auth state, data fetching with lifecycle |
| `StreamProvider` | Real-time data (connectivity, Supabase subscriptions) |
| `FutureProvider` | One-shot async data loading |

**No `setState`, no Bloc, no ChangeNotifier** (except the `AuthRefreshNotifier` bridge for GoRouter's `refreshListenable`).

## Routing

**GoRouter** (v17.1.0) with:
- `StatefulShellRoute.indexedStack` for the 5-tab bottom navigation
- `refreshListenable` pattern: a single stable `GoRouter` instance that re-evaluates redirects via `AuthRefreshNotifier` when auth state changes
- Auth guard in `redirect` callback: unauthenticated users are sent to `/login`, authenticated users bypass `/splash` and `/login`
- Named routes via `RouteNames` constants

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
3. **Biometric gates** --- `local_auth` for sensitive operations
4. **PKCE auth flow** --- secure OAuth token exchange
5. **RLS enforcement** --- all database access governed by Supabase Row-Level Security

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
| Integration tests | `integration_test` | `test/integration/` (planned) |

Quality gate: `scripts/check.sh` runs format, analyze, test, and gen-l10n in sequence.
