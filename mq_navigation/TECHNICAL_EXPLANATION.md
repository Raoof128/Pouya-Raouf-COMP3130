# MQ Navigation Technical Explanation

## Overview

MQ Navigation is a Flutter-based mobile application for Macquarie University campus navigation. The repository is structured as a production-leaning mobile client that combines a native Flutter UI, device capabilities such as maps, notifications, and secure storage, and a shared Supabase backend that also serves a separate web frontend.

The project is intentionally scoped around navigation. Earlier auth, calendar, feed, profile, and gamification features were removed, and the current codebase focuses on four primary product areas:

- Home hub
- Campus map and routing
- Notifications
- Settings and preferences

The app is cross-platform and includes Android, iOS, web, macOS, Linux, and Windows runner scaffolding, but the most complete feature integration is clearly targeted at Android and iOS.

## High-Level Architecture

The repository follows a feature-first architecture with shared infrastructure and design-system layers.

### Top-level layout

- `lib/app`: app bootstrap, router, theme, localization
- `lib/core`: environment config, logging, error handling, networking, secure storage, utility primitives
- `lib/shared`: reusable widgets, shared models, convenience extensions
- `lib/features`: isolated feature modules
- `supabase/functions`: backend edge functions used by the app
- `assets/data`: bundled map/building dataset
- `test`: unit and widget tests
- `scripts`: local developer automation
- `docs` and root markdown files: architecture and operational documentation

### Layering model

Each major feature generally follows a `data` / `domain` / `presentation` split:

- `data`: concrete data sources and repository implementations
- `domain`: entities and service contracts
- `presentation`: pages, widgets, and Riverpod controllers

This is applied most strongly in the `map` and `notifications` features. Simpler features such as `home` are presentation-only, while `settings` uses a lighter repository-plus-controller pattern.

## Application Startup

The app starts in [`lib/main.dart`](lib/main.dart), which delegates immediately to the bootstrap layer.

### Bootstrap sequence

[`lib/app/bootstrap/bootstrap.dart`](lib/app/bootstrap/bootstrap.dart) is responsible for application startup order:

1. Enter `runZonedGuarded` so uncaught async failures are captured.
2. Call `WidgetsFlutterBinding.ensureInitialized()` inside the guarded zone.
3. Install global error handlers through `installErrorHandlers()`.
4. Validate environment configuration through `EnvConfig.validate()`.
5. Initialize Firebase when the platform is not web.
6. Register the FCM background message handler.
7. Initialize Supabase with the configured project URL and anon key.
8. Run the app inside `ProviderScope` and `ErrorBoundary`.

This startup path is designed so that major infrastructure is in place before any widgets mount.

## Root App Composition

[`lib/app/mq_navigation_app.dart`](lib/app/mq_navigation_app.dart) builds the root `MaterialApp.router`.

Three global states are composed there:

- `appRouterProvider` for navigation
- `settingsControllerProvider` for theme and locale
- `notificationsControllerProvider` for notification setup side effects

The app theme switches dynamically from saved preferences:

- `ThemeMode.system`
- `ThemeMode.light`
- `ThemeMode.dark`

The locale also comes from saved preferences, and localization delegates are generated from ARB files under `lib/app/l10n`.

## Routing Model

The routing system uses GoRouter.

### Route definitions

[`lib/app/router/route_names.dart`](lib/app/router/route_names.dart) centralizes route names:

- `home`
- `map`
- `settings`
- `notifications`
- `building-detail`

[`lib/app/router/app_router.dart`](lib/app/router/app_router.dart) defines the concrete route table:

- `/home`
- `/map`
- `/map/building/:buildingId`
- `/settings`
- `/notifications`

### Shell navigation

The app uses `StatefulShellRoute.indexedStack` to preserve tab navigation state across the 3 persistent tabs:

- Home
- Map
- Settings

[`lib/app/router/app_shell.dart`](lib/app/router/app_shell.dart) renders the `NavigationBar` and switches branches using `navigationShell.goBranch(...)`.

This gives the app a standard mobile tab architecture while still allowing stacked detail routes like notifications or building deep links.

## Core Infrastructure

### Environment configuration

[`lib/core/config/env_config.dart`](lib/core/config/env_config.dart) reads build-time configuration from `String.fromEnvironment`.

Primary variables:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GOOGLE_MAPS_API_KEY`
- `APP_ENV`

There are also debug-only fallback variables prefixed with `DEV_`, intended to be supplied through `--dart-define-from-file=.env`.

Important behavior:

- missing Supabase values are fatal
- app environment defaults to `development`
- `hasGoogleMapsApiKey` is used to determine whether the map can render fully

### Error handling

The repo implements multi-layered error capture:

- widget-level fallback through [`lib/core/error/error_boundary.dart`](lib/core/error/error_boundary.dart)
- `FlutterError.onError`
- `PlatformDispatcher.instance.onError`
- `runZonedGuarded` in bootstrap

This gives the app both logging and user-visible fallback behavior instead of crashing directly into framework error output.

### Logging

[`lib/core/logging/app_logger.dart`](lib/core/logging/app_logger.dart) wraps the `logger` package. In release mode it only emits warnings and errors, which reduces noise in production builds.

### Connectivity

[`lib/core/network/connectivity_service.dart`](lib/core/network/connectivity_service.dart) wraps `connectivity_plus` and exposes:

- an immediate connectivity check
- a broadcast stream of connectivity changes
- a Riverpod provider and `StreamProvider`

The notifications system uses this to resync local reminders when the device comes back online.

### Secure storage

[`lib/core/security/secure_storage_service.dart`](lib/core/security/secure_storage_service.dart) provides encrypted key-value persistence over platform-native secure storage:

- iOS Keychain
- Android Keystore-backed storage

All storage operations are wrapped in `try/catch`, logged, and rethrown as `StorageException`.

### Error and result primitives

[`lib/core/error/app_exception.dart`](lib/core/error/app_exception.dart) defines a small app exception hierarchy:

- `NetworkException`
- `AuthException`
- `ServerException`
- `StorageException`
- `UnsupportedException`

[`lib/core/utils/result.dart`](lib/core/utils/result.dart) defines a sealed `Result<T>` abstraction with `Success<T>` and `Failure<T>`. It exists mainly as a shared primitive, although most of the app currently leans on Riverpod `AsyncValue` and exception handling.

## Design System

The app includes an internal design system built around Macquarie branding.

### Tokens

- [`lib/app/theme/mq_colors.dart`](lib/app/theme/mq_colors.dart): brand, neutral, semantic, and map-specific color constants
- [`lib/app/theme/mq_spacing.dart`](lib/app/theme/mq_spacing.dart): spacing, radii, and minimum tap target constants
- [`lib/app/theme/mq_typography.dart`](lib/app/theme/mq_typography.dart): text theme definitions and a serif helper

Typography currently uses system fonts because the branded font family names are intentionally left `null` until bundled fonts are added to the app.

### Theme composition

[`lib/app/theme/mq_theme.dart`](lib/app/theme/mq_theme.dart) builds complete Material 3 light and dark `ThemeData` objects. It customizes:

- color schemes
- app bars
- navigation bars
- cards
- input decoration
- filled, outlined, and text button themes
- divider styling

### Shared widgets

Reusable UI components live under `lib/shared/widgets`:

- `MqAppBar`
- `MqButton`
- `MqCard`
- `MqInput`

These abstract repetitive styling and enforce a more consistent UI surface across features.

## Shared Models and Extensions

[`lib/shared/models/user_preferences.dart`](lib/shared/models/user_preferences.dart) is the local settings aggregate. It stores:

- theme mode
- locale code
- notifications enabled
- email notifications enabled

The model includes `copyWith`, derived `Locale`, and value equality.

[`lib/shared/extensions/context_extensions.dart`](lib/shared/extensions/context_extensions.dart) adds a small set of convenience getters and a snackbar helper to `BuildContext`.

## Localization

The project uses Flutter ARB localization with 35 locales. The ARB files live under `lib/app/l10n`.

Examples include:

- `app_en.arb`
- `app_ar.arb`
- `app_zh.arb`
- and many others

The conversion tool [`tools/convert_i18n.dart`](tools/convert_i18n.dart) migrates translations from the web app JSON format into ARB files. It:

- reads JSON from a sibling web repository
- converts Handlebars interpolation to ICU placeholders
- sanitizes keys into valid Dart identifiers
- excludes building-specific translation keys

Localization is therefore part of a broader shared-content strategy between the web and Flutter frontends.

## Feature: Home

The home feature is implemented entirely in [`lib/features/home/presentation/pages/home_page.dart`](lib/features/home/presentation/pages/home_page.dart).

Its responsibilities are simple:

- present branding and welcome copy
- route users into the map
- expose four quick-search entry points for common campus intents

The quick access cards navigate to the map route with a query string, for example:

- food
- parking
- library
- health

This page acts as a navigation launcher rather than a data-heavy dashboard.

## Feature: Settings

The settings feature provides local app preferences and a branded settings UI.

### Repository

[`lib/features/settings/data/repositories/settings_repository.dart`](lib/features/settings/data/repositories/settings_repository.dart) persists preferences into secure storage. Four keys are used:

- `settings.theme_mode`
- `settings.locale_code`
- `settings.notifications_enabled`
- `settings.email_notifications`

Load behavior is forgiving: on failure it logs and returns default preferences.

Save behavior is strict: on failure it logs and rethrows so the controller can react.

### Controller

[`lib/features/settings/presentation/controllers/settings_controller.dart`](lib/features/settings/presentation/controllers/settings_controller.dart) is an `AsyncNotifier<UserPreferences>`.

It supports:

- theme updates
- locale updates
- notifications master toggle updates
- email notifications toggle updates

The controller uses optimistic updates, then persists through the repository. On persistence failure it restores the previous state and returns a user-facing error string.

It also attempts to synchronize the master notifications toggle with all notification preference types through the notifications controller.

### UI

[`lib/features/settings/presentation/pages/settings_page.dart`](lib/features/settings/presentation/pages/settings_page.dart) is a fully custom-styled page with:

- dark-mode glow treatment
- section headers
- custom card containers
- bottom-sheet pickers
- full-row tap areas for toggles
- semantics wrappers for read-only rows

The page groups settings into:

- General
- Notifications
- Experience
- About

It exposes all supported locale codes, not just a small subset.

## Feature: Notifications

The notifications feature combines remote inbox data, FCM registration, in-app notification display, and local recurring reminders.

### Domain model

[`lib/features/notifications/domain/entities/app_notification.dart`](lib/features/notifications/domain/entities/app_notification.dart) defines the notification entity and supported types:

- deadline
- exam
- event
- announcement
- system
- study prompt

It can be built either from Supabase JSON or directly from an incoming `RemoteMessage`.

[`lib/features/notifications/domain/entities/notification_preferences.dart`](lib/features/notifications/domain/entities/notification_preferences.dart) stores per-type enablement and scheduling fields.

[`lib/features/notifications/domain/entities/reminder_request.dart`](lib/features/notifications/domain/entities/reminder_request.dart) represents a scheduled local reminder and encodes a payload for click handling.

### Local scheduling

[`lib/features/notifications/domain/services/notification_scheduler.dart`](lib/features/notifications/domain/services/notification_scheduler.dart) currently schedules only one recurring local reminder type:

- daily study prompt

The scheduler:

1. derives reminder requests from preferences
2. cancels previously managed notifications that are no longer valid
3. schedules the remaining requests through the local notifications service

### Device services

[`lib/features/notifications/data/datasources/fcm_service.dart`](lib/features/notifications/data/datasources/fcm_service.dart) wraps Firebase Messaging. It handles:

- permission checks and requests
- foreground notification observation
- tap/open handling for notifications
- app-open-from-notification handling
- token acquisition and token refresh sync

[`lib/features/notifications/data/datasources/local_notifications_service.dart`](lib/features/notifications/data/datasources/local_notifications_service.dart) wraps `flutter_local_notifications`. It:

- initializes timezone data
- creates Android notification channels
- displays foreground notifications locally
- schedules recurring reminders
- filters and cancels app-managed pending notifications

### Remote source and repository

[`lib/features/notifications/data/datasources/notification_remote_source.dart`](lib/features/notifications/data/datasources/notification_remote_source.dart) uses Supabase directly for:

- streaming notifications
- fetching notification preferences
- upserting preferences
- marking notifications as read
- marking all notifications as read
- soft deletion
- FCM token insert/delete

[`lib/features/notifications/data/repositories/notification_repository_impl.dart`](lib/features/notifications/data/repositories/notification_repository_impl.dart) is a thin abstraction over that remote source.

### Controller orchestration

[`lib/features/notifications/presentation/controllers/notifications_controller.dart`](lib/features/notifications/presentation/controllers/notifications_controller.dart) is the main orchestration layer.

Its responsibilities include:

- initializing local and remote notification services
- reading current permission state
- loading remote notification preferences when a Supabase user exists
- syncing FCM tokens when push is allowed
- rescheduling reminders after preference changes
- marking notifications read or deleted
- routing in-app links from push or local notifications

An important security detail here is `_openLink`, which only allows navigation to trusted internal path prefixes:

- `/home`
- `/map`
- `/settings`
- `/notifications`

That prevents arbitrary external or malformed deep links from being opened through notification payloads.

### UI

[`lib/features/notifications/presentation/pages/notifications_page.dart`](lib/features/notifications/presentation/pages/notifications_page.dart) is a mixed management and inbox page. It includes:

- a prompt to enable push permissions when not granted
- per-type notification preference switches
- a time picker for study prompt scheduling
- a streamed notification inbox

[`lib/features/notifications/presentation/widgets/notification_tile.dart`](lib/features/notifications/presentation/widgets/notification_tile.dart) renders each inbox item with:

- icon by type
- read/unread styling
- timestamp
- action buttons for mark-as-read and delete

## Feature: Map

The map feature is the most substantial feature in the repository. It combines local dataset management, optional remote registry refresh, location access, route retrieval, map rendering, and navigation state.

### Domain entities

[`lib/features/map/domain/entities/building.dart`](lib/features/map/domain/entities/building.dart) models a building or campus location. It stores:

- identity and display metadata
- category
- building center coordinates
- optional entrance coordinates
- optional Google place ID
- accessibility and tagging metadata

It also implements:

- query matching
- best routing coordinate selection
- a `isHighTraffic` heuristic for key campus destinations

[`lib/features/map/domain/entities/route_leg.dart`](lib/features/map/domain/entities/route_leg.dart) defines:

- `TravelMode`
- `LocationSample`
- `MapRoute`

`MapRoute.fromJson(...)` now handles both the normalized `maps-routes` response and legacy-compatible route payloads, and builds:

- total distance
- duration
- encoded polyline
- optional explicit route points
- turn-by-turn instructions
- derived `arrivalAt`

[`lib/features/map/domain/entities/nav_instruction.dart`](lib/features/map/domain/entities/nav_instruction.dart) normalizes HTML-rich or API-v2-style instruction payloads into a plain text representation.

### Building registry data source

[`lib/features/map/data/datasources/building_registry_source.dart`](lib/features/map/data/datasources/building_registry_source.dart) uses a three-level fallback strategy:

1. secure-storage cache
2. Supabase `app_config` value under `building_registry`
3. bundled asset at `assets/data/buildings.json`

This gives the app a degree of offline resilience and optional server-driven registry updates.

The asset currently contains 153 records.

### Location data source

[`lib/features/map/data/datasources/location_source.dart`](lib/features/map/data/datasources/location_source.dart) normalizes permissions and location fetching.

Important behaviors:

- unsupported platforms are treated as effectively granted so fallback routing still works
- when real GPS is unavailable, a campus-center fallback location is used
- continuous updates come from `Geolocator.getPositionStream`

This makes the map feature more robust across emulators and non-mobile platforms.

### Route retrieval

[`lib/features/map/data/datasources/maps_routes_remote_source.dart`](lib/features/map/data/datasources/maps_routes_remote_source.dart) is the shared route client used by both renderer-specific data sources. It:

- calls the `maps-routes` Supabase Edge Function
- sends the active renderer, origin, destination, and travel mode in one normalized request
- relies on `SUPABASE_URL` + `SUPABASE_ANON_KEY` rather than a client-side routing key
- enforces a 15 second timeout
- converts the normalized server response into a shared `MapRoute`

### Repository

[`lib/features/map/data/repositories/map_repository_impl.dart`](lib/features/map/data/repositories/map_repository_impl.dart) composes building data, location, and routing behind a single map-facing interface.

### State controller

[`lib/features/map/presentation/controllers/map_controller.dart`](lib/features/map/presentation/controllers/map_controller.dart) holds the runtime map state.

Its `MapState` includes:

- all buildings
- current search results
- selected building
- current location
- current route
- search query
- renderer (`campus` or `google`)
- travel mode
- permission state
- loading flag
- high-level error enum

Controller operations include:

- initial building loading
- search query updates with prioritization of strong matches
- selecting a building
- selecting a building by route parameter
- loading a route
- centering on current location
- changing travel mode
- clearing a route
- opening platform settings

When navigation starts, the controller also starts a location subscription and updates current position reactively.

### Map page and widgets

[`lib/features/map/presentation/pages/map_page.dart`](lib/features/map/presentation/pages/map_page.dart) is the main screen container. It:

- applies route parameters on first frame
- shows a search trigger
- shows a banner for route or location issues
- embeds the map viewport
- renders the route panel
- exposes a floating action button to center on location

[`lib/features/map/presentation/widgets/building_search_sheet.dart`](lib/features/map/presentation/widgets/building_search_sheet.dart) is a bottom-sheet search UI backed by map controller state.

[`lib/features/map/presentation/widgets/campus_map_view.dart`](lib/features/map/presentation/widgets/campus_map_view.dart) wraps `GoogleMap` and handles:

- initial campus camera
- camera bounds
- marker selection
- selected marker emphasis
- map controller disposal
- polyline decoding and rendering
- camera animation on destination or user location changes

[`lib/features/map/presentation/widgets/route_panel.dart`](lib/features/map/presentation/widgets/route_panel.dart) renders:

- travel mode segmented buttons
- selected destination title
- ETA and distance
- the first few navigation instructions
- route load / clear actions

## Backend: Supabase Edge Functions

The repo contains server-side TypeScript functions under `supabase/functions`.

### Shared CORS

[`supabase/functions/_shared/cors.ts`](supabase/functions/_shared/cors.ts) defines permissive CORS headers and a helper for `OPTIONS` preflight responses.

### `maps-routes`

[`supabase/functions/maps-routes/index.ts`](supabase/functions/maps-routes/index.ts) is the shared route proxy for the Flutter map stack. It:

- accepts anon requests and upgrades to user-aware throttling when a valid bearer token is present
- validates renderer, coordinates, and travel mode
- rate limits requests by user ID or client IP
- calls Google Routes API with a server-side API key for Google mode
- calls OpenRouteService for campus mode when configured, with a generated demo fallback when it is not
- returns one normalized route payload for both renderers

### `notify`

[`supabase/functions/notify/index.ts`](supabase/functions/notify/index.ts) is the notification dispatch backend. It:

- authenticates the caller
- enforces caller ownership or admin access
- validates notification payload structure
- inserts a notification inbox row
- checks per-type preference state
- fetches the target device token set
- sends push notifications through FCM
- removes stale tokens

It supports two delivery strategies:

- preferred FCM HTTP v1 via service account JSON
- legacy fallback via server key

### `cleanup-cron`

[`supabase/functions/cleanup-cron/index.ts`](supabase/functions/cleanup-cron/index.ts) deletes:

- expired `rate_limits` rows
- old `audit_logs` rows

It is protected by a cron secret and intended for scheduled maintenance.

### Supabase config

[`supabase/config.toml`](supabase/config.toml) configures the local Supabase project and JWT verification behavior for each function.

## Platform Integration

### Android

[`android/app/build.gradle.kts`](android/app/build.gradle.kts) sets up:

- application ID
- Java 17 compatibility
- optional Google services plugin application
- Google Maps manifest placeholder injection
- release signing config with debug fallback

[`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml) declares:

- fine and coarse location permissions
- notification permission
- boot completed permission
- Google Maps API metadata
- launcher activity
- custom scheme deep link for auth callback
- verified app link for hosted auth callback

### iOS

[`ios/Runner/AppDelegate.swift`](ios/Runner/AppDelegate.swift) conditionally initializes Firebase and Google Maps.

[`ios/Runner/Info.plist`](ios/Runner/Info.plist) configures:

- app display name and bundle settings
- Google Maps API key lookup
- custom URL scheme
- location usage description
- `remote-notification` background mode

## Tooling and Automation

### CI

[`/.github/workflows/ci.yml`](.github/workflows/ci.yml) defines a three-job pipeline:

- analyze and test on push and pull request
- Android release build on `main` pushes
- iOS release build without code signing on `main` pushes

### Scripts

[`scripts/check.sh`](scripts/check.sh) runs:

- dependency install
- format check
- analysis
- tests
- localization generation
- optional debug APK build

[`scripts/run.sh`](scripts/run.sh) launches the app using a local `.env` file and `--dart-define-from-file`.

### Fastlane

Fastlane lanes exist for both Android and iOS:

- build debug and release variants
- upload Android to Play internal track
- upload iOS to TestFlight

This shows the repo is set up not only for local development but also for mobile delivery workflows.

## Documentation Surface

The repository includes a broad documentation set:

- `README.md`
- `SECURITY.md`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `docs/ARCHITECTURE.md`
- `Flutter_Migration_Plan.md`
- `entity_inventory.md`
- `endpoint_inventory.md`
- `env_inventory.md`
- `notification_matrix.md`
- `route_matrix.md`
- `map_inventory.md`
- `key_inventory.md`
- `auth_matrix.md`

These documents collectively describe product scope, architecture, backend schema, routing, notifications, environment variables, and migration history.

## Testing Strategy

The test suite under `test/` is focused on unit and widget coverage.

### Covered areas

- theme tokens and theme composition
- route name constants
- app exception classes
- environment configuration behavior
- result type behavior
- shared widgets
- building entity parsing and search behavior
- building registry asset integrity
- map route JSON parsing
- notification preference normalization
- notification scheduler logic

This gives reasonable confidence around design tokens, data parsing, and several isolated behaviors, though higher-level integration coverage is still limited.

## Key Strengths

- Clear feature-first organization
- Good separation between UI, state, and data access in core features
- Strong documentation compared with the size of the codebase
- Real mobile integration for maps, notifications, and secure storage
- Defensive error handling in infrastructure code
- Broad localization support
- Useful local and CI automation

## Important Gaps and Architectural Tensions

The largest remaining gap in the map feature is no longer routing security; that path is now aligned on the `maps-routes` Edge Function. The remaining tension is product parity depth:

- campus mode now uses the real raster overlay asset, shared pixel metadata, and the same calibrated GPS projection data as the web overlay
- campus routing can use OpenRouteService when configured, but still falls back to a generated demo route when `ORS_API_KEY` is absent
- Street View / Pegman parity remains richer on the web app than in Flutter

Other notable observations:

- notification remote features still assume an optional authenticated Supabase user even though the app is positioned as navigation-first without auth flows
- some documentation references can lag behind code reality after rapid cleanup work
- the design system is well organized, but branded fonts are not yet bundled, so typography is structurally ready but not fully brand-complete

## Conclusion

MQ Navigation is a well-structured Flutter project centered on campus navigation, notifications, and local preferences. The repository shows deliberate architectural cleanup, strong documentation habits, and a clear mobile-first implementation strategy. The map and notifications features are the technical core of the product, supported by a lightweight but competent infrastructure layer.

From a technical perspective, the app is already beyond a default scaffold or coursework prototype. Its strongest qualities are structure, clarity, and operational completeness. Its biggest remaining issue is product-parity depth rather than backend architecture: Street View/Pegman depth still exceeds the Flutter implementation, even though the shared overlay assets, secure route backend, and calibrated campus projection are now aligned.
