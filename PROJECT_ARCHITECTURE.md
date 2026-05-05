# MQ Navigation Project Architecture

## Overview
MQ Navigation is a production-ready cross-platform mobile client for Macquarie University's campus navigation platform, built with Flutter. It's part of a **two frontends, one backend** architecture sharing a Supabase backend with a Next.js web application.

## System Architecture

```
graph TD
    A[Flutter Mobile Client] -->|HTTPS/WSS| B(Supabase Backend)
    C[Next.js Web Client] -->|HTTPS/WSS| B
    
    subgraph "Supabase"
        B --> D[(Postgres + RLS)]
        B --> E[Realtime]
        B --> F[Edge Functions]
    end
    
    subgraph "External APIs"
        F --> G[Google Routes V2]
        F --> H[Google Places]
        F --> I[TfNSW Open Data]
    end
```

## Core Components

### 1. State Management
- **Riverpod 3.2** (AsyncNotifier) for state management
- Centralized state controllers in feature directories
- AsyncNotifiers handle data fetching and UI state

### 2. Routing
- **GoRouter 17.1** with StatefulShellRoute for persistent bottom navigation
- Route names defined in `app/router/route_names.dart`

### 3. Maps & Navigation
- Dual renderer support: Google Maps (`google_maps_flutter`) and Campus Map (`flutter_map`)
- Server-side routing via Supabase Edge Functions
- Real-time location tracking and navigation with arrival/off-route detection

### 4. Backend Integration
- **Supabase** (PostgreSQL + Realtime + Edge Functions)
- Row-Level Security (RLS) for data protection
- PKCE auth flow for secure mobile authentication
- Edge Functions for Google Routes V2, Places, and TfNSW Open Data integration

## Feature Modules

### Home Feature
- **Hero Section**: MQ shield logo + welcome copy + CTA
- **Metro Countdown Card**: Real-time transit departure tracking
- **Quick Access**: Bento layout with Student Services, Faculty, Parking, Campus Hub, Food & Drink
- Open Day integration with dynamic cards

### Map Feature
- Building search and selection (153-building registry)
- Dual-map renderer switching (Google/Campus)
- Route calculation and turn-by-turn navigation
- Location tracking with arrival detection
- Category-based browsing (Faculty, Student Services, Campus Hub)
- Overlay system for additional map data layers

### Transit Feature
- Real-time metro/train/bus departure tracking
- Integration with TfNSW Open Data via Supabase Edge Functions
- Configurable commute settings

### Notifications Feature
- Supabase-backed persistent notifications
- Local study-prompt scheduling
- FCM integration for push notifications

### Settings Feature
- User preferences management
- Biometric app lock (local_auth)
- Map renderer and travel mode preferences
- Notification preferences

## Technical Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.11+ (Stable) |
| **State** | Riverpod 3.2 (AsyncNotifier) |
| **Routing** | GoRouter 17.1 (StatefulShellRoute) |
| **Maps** | google_maps_flutter 2.15 / flutter_map 7.0 |
| **Backend** | Supabase (RLS + Deno Edge Functions) |
| **Notifications** | Firebase Messaging (native) |
| **Localization** | 35 locales (RTL compliant) |

## Quality Gates

All contributions must pass the automated quality gate:
```bash
./scripts/check.sh --quick
```

- **Tests**: 154 unit and widget tests (100% pass required)
- **Lints**: Strict adherence to `analysis_options.yaml`
- **i18n**: Full localization support

## Security Features

- Biometric app lock using `local_auth`
- Secure credential storage
- PKCE authentication flow with Supabase
- Environment variable validation
- Row-Level Security (RLS) on Supabase backend

## Key Architectural Patterns

1. **Separation of Concerns**: Clear division between data, domain, and presentation layers
2. **Dependency Injection**: Riverpod providers for service location
3. **Immutable State**: MapState uses copyWith pattern for state updates
4. **Error Handling**: Global error boundaries and zone-guarded bootstrap
5. **Performance**: AsyncNotifiers prevent unnecessary rebuilds
6. **Accessibility**: Semantic labels and proper contrast ratios

## Data Flow

1. Bootstrap initializes services (Firebase, Supabase, timezone)
2. Riverpod ProviderScope wraps the app for state management
3. Feature controllers fetch data from repositories
4. Repositories interact with Supabase or local services
5. UI rebuilds when state changes via ConsumerWidget/ref.watch
6. User interactions trigger controller methods that update state
7. Navigation handled by GoRouter with deep linking support

## Localization & Internationalization

- 35 supported locales
- Right-to-left (RTL) language support
- ARB file-based translations
- Localization delegate setup in main app

## Platform Support

- iOS (mobile/tablet)
- Android (mobile/tablet)
- Web (responsive)
- macOS (desktop)
- Windows (desktop)
- Linux (desktop)

## Development Workflow

1. Environment setup with `.env.example`
2. Code generation: `flutter pub run build_runner watch`
3. Local development: `flutter run`
4. Testing: `flutter test`
5. Linting: `dart analyze`
6. Quality check: `./scripts/check.sh --quick`

## CI/CD Pipeline

- Automated testing on pull requests
- Quality gate enforcement
- Beta distribution via Firebase App Store
- Production releases to App Store/Google Play

## Roadmap Features

- Gamification: XP and Streaks logic (models present, UI pending)
- Popular Destinations: Data-driven trending spots carousel
- Accessibility Audit: Full WCAG 2.2 compliance