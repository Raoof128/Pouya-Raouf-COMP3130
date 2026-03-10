# MQ Navigation - Flutter Mobile App

Navigation-focused mobile app for Macquarie University Open Day. Migrated from the [Syllabus Sync web app](https://github.com/mrpouyaalavi/syllabus-sync).

## Overview

MQ Navigation provides interactive campus navigation for Macquarie University's Open Day. Built with Flutter, it shares the same Supabase backend as the web application, reusing building data, API structure, and MQ branding.

## Features

- **Interactive Campus Map** -- Google Maps with 20+ building markers, colour-coded by category
- **Building Search** -- search buildings by name, alias, tag, or description
- **Category Filtering** -- filter by Academic, Food, Health, Sports, Services, Venue, Research, Residential
- **Building Details** -- photos, description, floor count, wheelchair access, grid reference
- **Walking Directions** -- turn-by-turn walking routes via OpenRouteService API
- **GPS Positioning** -- real-time device location on the campus map
- **Navigation-Focused Home** -- quick access to map, food, parking, library, health
- **35-Language Support** -- full i18n with RTL support (Arabic, Farsi, Hebrew, Urdu)
- **Dark Mode** -- system-aware light and dark themes using MQ design tokens
- **Offline Awareness** -- connectivity monitoring with graceful degradation

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.11+ (Dart 3.11+) |
| State Management | Riverpod 3.2 |
| Routing | GoRouter 17.1 (StatefulShellRoute, auth guards) |
| Backend | Supabase (same database as web app) |
| Maps | Google Maps Flutter 2.14 |
| Directions | OpenRouteService API (walking routes) |
| Location | Geolocator 13.0 |
| Images | cached_network_image 3.3 |
| Security | flutter_secure_storage, local_auth |
| CI/CD | GitHub Actions (analyze, test, build Android + iOS) |
| Localisation | Flutter ARB (35 locales) |

## Data Migration

All building data is migrated from the existing Syllabus Sync web app:

| Web App (React/Next.js) | Flutter Equivalent | Status |
|---|---|---|
| Leaflet campus map | Google Maps Flutter | Done |
| Building data (OSM) | Supabase buildings + sample data | Done |
| Category filter chips | FilterChip horizontal list | Done |
| Building detail modal | BuildingDetailPage (SliverAppBar) | Done |
| Directions (ORS) | DirectionsPage with polylines | Done |
| Home dashboard | Navigation-focused HomePage | Done |

### What Was NOT Migrated (not needed for Open Day)

- Calendar (FullCalendar)
- Deadline management
- Unit management
- Student profiles
- Gamification system

## Architecture

Feature-first clean architecture with three layers per module:

```
lib/
  app/          # Bootstrap, router, theme, l10n
  core/         # Config, error handling, logging, security, networking
  shared/       # Design system widgets, providers, extensions
  features/
    auth/       # Splash, login pages
    home/       # Navigation-focused home screen
    map/
      data/
        datasources/    # BuildingRegistrySource, sample_buildings
        services/       # LocationService, SearchService, DirectionsService
      domain/
        entities/       # Building, BuildingCategory
      presentation/
        pages/          # MapPage, BuildingDetailPage, DirectionsPage
        providers/      # buildings_provider (category filter, search)
    settings/   # App settings
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
git clone https://github.com/mrpouyaalavi/syllabus-sync.git
cd syllabus-sync/MQ_Navigation

# Install dependencies
flutter pub get

# Generate localisation files
flutter gen-l10n

# Run the app (development mode)
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=GOOGLE_MAPS_API_KEY=your-maps-key \
  --dart-define=ORS_API_KEY=your-ors-key \
  --dart-define=APP_ENV=development
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | Yes | Supabase project URL (same as web app) |
| `SUPABASE_ANON_KEY` | Yes | Supabase anonymous API key (same as web app) |
| `GOOGLE_MAPS_API_KEY` | No | Google Maps SDK key (needed for map feature) |
| `ORS_API_KEY` | No | OpenRouteService key (needed for walking directions) |
| `APP_ENV` | No | `development` (default), `staging`, or `production` |

## Development

### Quality Checks

```bash
# Full check (includes debug APK build)
./scripts/check.sh

# Quick check (skips build step)
./scripts/check.sh --quick
```

### Running Tests

```bash
flutter test
flutter test --coverage
flutter test test/features/map/building_test.dart
```

## Team Contributions

### Pouya Alavi (Frontend - 50%)
- Map screen with Google Maps integration
- Building detail screens with SliverAppBar
- Search UI and category filters
- Walking directions UI with polylines
- Navigation-focused home screen
- MQ theming and design system

### Raouf Abedini (Backend - 50%)
- Supabase integration and data migration
- Building data export from web app (OSM)
- Buildings API and provider layer
- Search functionality (buildings_provider)
- Directions API integration (OpenRouteService)
- Location services (GPS positioning)

## Repository Links

- **Web App**: https://github.com/Raoof128/Pouya-Raouf-COMP3130
- **Mobile App**: This repository (`MQ_Navigation/` directory)

## Timeline

| Week | Tasks | Deliverable |
|------|-------|-------------|
| 1-2 (Mar) | Flutter setup, data export, Dart models | Basic app runs |
| 3-4 (Apr) | Map screen, category filters, building cards | Map works |
| 5-6 (Apr) | Search, building details, GPS | Search works |
| 7-8 (Early May) | Directions, polish UI | Directions work |
| 9-10 (Mid May) | Testing, bug fixes, documentation | Ready to submit |
| 11-12 (Late May) | Final polish, video, submit | May 24 Submitted |
| Jun-Jul | Beta testing, App Store prep | Production ready |
| Aug | Open Day Launch | Live |

## Authors

- **Raouf Abedini** (47990805) -- COMP3130, Macquarie University
- **Pouya Alavi** (48160202) -- COMP3130, Macquarie University

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
