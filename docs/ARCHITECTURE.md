# MQ Navigation: Technical Architecture (2026)

## Overview
Feature-First Clean Architecture for high-concurrency campus navigation, transit data, compass mode, and safety toolkit. Privacy by design: zero account, zero tracking, zero location history.

## Directory Structure

```
lib/
├── app/
│   ├── bootstrap/          → App init, Supabase + Firebase setup
│   ├── l10n/               → ARB files (35 locales) + generated localisations
│   ├── router/             → GoRouter config (StatefulShellRoute, 4 tabs)
│   └── theme/              → MQ design tokens (MqColors, MqTypography, MqSpacing)
├── core/
│   ├── config/             → Env vars via --dart-define
│   ├── error/              → App exceptions, error boundary
│   ├── logging/            → Structured logger
│   ├── network/            → Connectivity service
│   ├── security/           → Flutter secure storage
│   └── utils/              → Result type, validators, haptics
├── shared/
│   ├── extensions/         → BuildContext extensions (theme, dark mode, snackbar)
│   ├── models/             → UserPreferences
│   └── widgets/            → MqButton, MqCard, MqInput, MqBottomSheet, GlassPane
└── features/
    ├── deep_link/          → Syllabus Sync deep link contract
    ├── home/               → Welcome dashboard, onboarding, metro countdown
    ├── map/                → Campus map (178 buildings, dual renderer, routing, compass)
    ├── notifications/      → FCM push + local study prompts
    ├── open_day/           → Open Day event browsing & reminders
    ├── safety/             → Campus Safety Toolkit (flashlight, contacts, first aid, AED)
    ├── settings/           → Theme, locale, commute, notifications, data, privacy badge
    ├── timetable/          → Unit & class schedule management
    └── transit/            → Metro/bus/train stop search & commute prefs
```

## Layering Strategy

### Presentation Layer (Riverpod)
- **Controllers**: `MapController`, `SettingsController`, `NotificationsController`
- **Widgets**: Atomic design (`MqButton`, `MqCard`, `SafetyActionCard`) + feature-specific views
- **Compass**: `CompassModeView` — real-time heading via `flutter_compass`, `AnimatedRotation`, heading accuracy bar

### Domain Layer (Pure Dart)
- **Entities**: `Building`, `MapRoute`, `NavInstruction`, `SafetyPoi`, `EmergencyContact`, `LocationSample`
- **Services**: `GeoUtils`, `MapPolylineCodec`, `OfflineMapsService`

### Data Layer
- **Repositories**: `MapRepositoryImpl`, `SettingsRepository`
- **Data Sources**: `MapsRoutesRemoteSource` (Supabase Edge Functions), `SafetyPoiSource` (curated campus data), `SecureStorageService`
- **Location**: `LocationSource` (GPS + last-known fallback, Android emulator mock rejection)

## Navigation & Routing (GoRouter 17.x)

```
StatefulShellRoute.indexedStack (3 tabs + standalone routes)
├── /home                  → HomePage (dashboard)
├── /map                   → MapPage (dual renderer, building search, route panel)
│   └── /map/building/:id  → MapPage (focus building)
├── /settings              → SettingsPage (privacy badge, commute, data, danger zone)
├── /safety                → SafetyToolkitPage (standalone, no auto location)
├── /notifications         → NotificationsPage (covers shell)
├── /open-day              → OpenDayPage (temporal feature)
├── /onboarding            → OnboardingPage (first-launch gate)
├── /meet                  → MapPage (meet-at-point lat/lng)
└── /open                  → Deep link router (Syllabus Sync)
```

## Key Features

### Campus Map (Dual-Renderer)
- **Google Maps** (`google_maps_flutter` 2.15): traffic, map-type, clustering, bearing camera
- **Campus Map** (`flutter_map` + `CrsSimple`): custom raster calibrated to MQ GPS coordinates
- **Routing**: Supabase Edge Functions (Google Routes API + Directions API fallback), 4 travel modes
- **Compass Mode**: `flutter_compass` 0.8.1 stream, bearing-to-destination calculation, `AnimatedRotation` smooth heading, heading accuracy display, privacy-safe (all on-device)

### Campus Safety Toolkit
- Flashlight toggle (via `torch_light`)
- Emergency contacts: 000, Campus Security, Health Service, 1800 CRISIS (tap-to-dial via `url_launcher`)
- 3 first aid + 5 AED locations with building codes and descriptions
- Security shuttle info + call button
- Privacy banner: "Your location is never shared automatically"
- **Zero automatic location sharing** — user manually calls or navigates

### Privacy by Design
- No account system (no email, no password, no profile)
- No analytics/tracking packages (enforced by `check.sh` privacy guard)
- All data stored locally via `SharedPreferences` + `FlutterSecureStorage`
- No location history, no telemetry, no crash reporting
- Settings page shows permanent **Privacy Badge**: "Private by design: no account, no tracking, no location history"

## CI / Validation (`scripts/check.sh`)
```
8-9 steps depending on --quick:
  1. flutter pub get
  2. dart format (--fix available)
  3. flutter analyze (single-pass, --no-fatal-infos)
  4. flutter test (228+ tests)
  5. flutter gen-l10n
  6. untranslated l10n check (non-blocking)
  7. privacy guard (blocks analytics packages)
  8. secret scan (hardcoded API keys in lib/test/scripts)
  9. flutter build apk --debug (skipped with --quick)
```
Supports `--quick`, `--fix`, `--verbose` flags. Structured logs under `.dart_tool/check_logs/`.

## Dependencies (Key)
- **State**: `flutter_riverpod` 3.2 | **Router**: `go_router` 17
- **Maps**: `google_maps_flutter` 2.15 + `flutter_map` 8.2
- **Location**: `geolocator` 14 | **Compass**: `flutter_compass` 0.8
- **Safety**: `torch_light` 1.1 | **Links**: `url_launcher` 6.3
- **i18n**: `flutter_localizations` / `intl` (35 ARB locales, RTL for ar/fa/he/ur)

## Supporting Documentation

Detailed inventories live alongside this file in `docs/`:

| File | What it covers |
|------|---------------|
| `endpoint_inventory.md` | API routes, Edge Functions, and web-only endpoints |
| `entity_inventory.md` | Shared Supabase schema (profiles, units, events, notifications, RPCs) |
| `env_inventory.md` | All `--dart-define` variables and Supabase Edge Function secrets |
| `key_inventory.md` | API keys, service accounts, and where they're used |
| `map_inventory.md` | Building registry, overlay layers, and map renderer specifics |
| `notification_matrix.md` | Notification types, triggers, and delivery channels |
| `route_matrix.md` | GoRouter route table and deep link mapping |
