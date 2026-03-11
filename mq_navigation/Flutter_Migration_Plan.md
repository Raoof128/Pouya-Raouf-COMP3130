# MQ Navigation — Flutter Migration Plan (Updated)

Based on the completed `mq-navigation_flutter` repository.

---

## Current State Analysis

### What You Have (React/Next.js — Web App):

**Completed:**
- Next.js 16 + TypeScript foundation
- Home dashboard with Today's Schedule, Next Deadline, Events Feed
- Zustand state management
- Tailwind CSS + Shadcn UI design system
- Supabase backend (Auth, Postgres, RLS, Realtime, Edge Functions)
- MQ branding (colours: #A6192E, #76232F, #FFB81C, #002A45)
- Full calendar, deadline/event/todo CRUD
- Campus map (Leaflet + Google Maps JS API)
- 35-language i18n with RTL support
- Gamification (XP, levels, streaks)
- Push notifications (browser Service Worker)

### What You Have (Flutter — Mobile App):

**All Phases Complete (0–5).** The Flutter client is a feature-complete native companion to the web app.

| Metric | Value |
|--------|-------|
| Production Dart files | 89 |
| Test files | 15 (99 tests) |
| Locale files | 35 ARB (70k lines) |
| Edge Functions | 9 Deno TypeScript |
| Building registry | 153 buildings |
| Analysis issues | 0 |
| CI checks passing | 6/6 |

---

## Migration Strategy: React → Flutter

### Architecture: Two Frontends, One Backend

The Flutter app is **not** a port of the website. It is a **separate native client** that shares the same Supabase backend. Both clients evolve independently.

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

### What Was Migrated

| Web Component | Flutter Equivalent | Status |
|--------------|-------------------|--------|
| Map page (Leaflet + Google JS) | Google Maps Flutter + routes proxy | Done |
| Building data (100+ buildings) | 153-building bundled registry + Supabase | Done |
| Home dashboard | Dashboard with stress, XP, upcoming items | Done |
| Calendar (FullCalendar) | Agenda / Day / Week views + CRUD | Done |
| Events feed | Paginated feed with filters + calendar import | Done |
| Auth (email, OAuth, MFA) | Supabase auth + TOTP MFA + biometrics | Done |
| Profiles | Profile edit + onboarding flow | Done |
| Settings | Theme, locale, notifications, security | Done |
| Notifications (browser push) | FCM push + local reminders + inbox | Done |
| i18n (19 JSON locales) | 35 ARB locales with RTL | Done |

---

## Tech Stack

```yaml
# pubspec.yaml — pinned dependencies
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Core
  supabase_flutter: ^2.12.0      # Same backend as web app
  firebase_core: ^4.2.0           # Firebase bootstrap
  flutter_riverpod: ^3.2.1        # State management (replaces Zustand)
  go_router: ^17.1.0              # Declarative routing (replaces Next.js App Router)
  intl: ^0.20.2                   # i18n formatting
  timezone: ^0.10.1               # Timezone-aware scheduling

  # Maps & Location
  google_maps_flutter: ^2.14.2    # Native Google Maps
  geolocator: ^13.0.0             # GPS location
  permission_handler: ^12.0.1     # Runtime permissions

  # Security
  local_auth: ^3.0.0              # Biometric auth (Face ID / fingerprint)
  flutter_secure_storage: ^10.0.0 # Encrypted token storage

  # Notifications
  firebase_messaging: ^16.1.2     # Push notifications (FCM)
  flutter_local_notifications: ^18.0.0  # Scheduled reminders

  # Utilities
  connectivity_plus: ^6.1.4       # Network monitoring
  logger: ^2.5.0                  # Structured logging

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

---

## Project Structure

```
lib/
  main.dart                           # Entry point
  app/
    bootstrap/bootstrap.dart          # Supabase + Firebase init, error handlers
    mq_navigation_app.dart            # Root MaterialApp.router
    router/
      app_router.dart                 # GoRouter with auth guards + refreshListenable
      app_shell.dart                  # Bottom NavigationBar (5-tab shell)
      route_guard.dart                # Auth/MFA/onboarding cascading guards
      route_names.dart                # Named route constants
    theme/
      mq_colors.dart                  # MQ brand palette (#A6192E, #002A45, etc.)
      mq_typography.dart              # Work Sans / Source Serif Pro type scale
      mq_spacing.dart                 # Spacing, radius, tap-target tokens
      mq_theme.dart                   # Light + dark ThemeData builders
    l10n/
      app_en.arb                      # English template
      app_*.arb                       # 34 other locale files (35 total)
      generated/                      # Auto-generated AppLocalizations

  core/
    config/env_config.dart            # --dart-define env vars with debug fallbacks
    error/
      app_exception.dart              # Sealed exception hierarchy
      error_boundary.dart             # Global error catcher + friendly UI
    logging/app_logger.dart           # Structured logger
    network/connectivity_service.dart # Connectivity stream + Riverpod providers
    security/
      secure_storage_service.dart     # Encrypted key-value storage
      biometric_service.dart          # Face ID / fingerprint gate
    utils/
      result.dart                     # Result<T> sealed type
      validators.dart                 # Form validation helpers

  shared/
    models/
      academic_models.dart            # Units, deadlines, events, todos, stress, XP
      user_profile.dart               # User profile model
      user_preferences.dart           # Theme, locale, notification prefs
    widgets/
      mq_button.dart                  # Filled / outlined / text variants
      mq_card.dart                    # Tappable card
      mq_input.dart                   # Text input
      mq_bottom_sheet.dart            # Modal bottom sheet
      mq_app_bar.dart                 # App bar
    providers/
      auth_provider.dart              # Auth state notifier (Supabase)
    extensions/
      context_extensions.dart         # BuildContext helpers

  features/
    auth/                             # Login, signup, verify, reset, MFA, biometric
    profiles/                         # Profile view/edit, onboarding
    home/                             # Dashboard cards, stress, XP, upcoming items
    calendar/                         # Agenda/day/week views, CRUD editors
    map/                              # Campus map, building search, routing
    feed/                             # Public events, announcements, filters
    notifications/                    # FCM push, local reminders, inbox
    settings/                         # Theme, locale, notifications, security
    gamification/                     # XP/levels (scaffold)
```

Each feature follows a three-layer structure:
```
features/<name>/
  data/
    datasources/    # Supabase, Firebase, local cache, assets
    repositories/   # Repository implementations
  domain/
    entities/       # Business models / value objects
    services/       # Domain logic / use cases
  presentation/
    controllers/    # Riverpod AsyncNotifiers
    pages/          # Full-screen routes
    widgets/        # Feature-specific UI
```

---

## Navigation & Route Map

### Bottom Navigation Shell (5 Tabs)

| Tab | Icon | Route | Page |
|-----|------|-------|------|
| Home | home | `/home` | HomePage |
| Calendar | calendar_month | `/calendar` | CalendarPage |
| Map | map | `/map` | MapPage |
| Feed | feed | `/feed` | FeedPage |
| Settings | settings | `/settings` | SettingsPage |

### Auth Flow Routes

| Route | Page | Description |
|-------|------|-------------|
| `/splash` | SplashPage | Session check + redirect |
| `/login` | LoginPage | Email/password + Google OAuth |
| `/signup` | SignupPage | Registration with email confirmation |
| `/verify-email` | VerifyEmailPage | Email verification handler |
| `/reset-password` | ResetPasswordPage | Password reset (request or recovery mode) |
| `/mfa` | MfaPage | TOTP challenge / enrollment |
| `/onboarding` | ProfileEditPage | First-run profile completion |

### Detail Routes (pushed on top of shell)

| Route | Page | Description |
|-------|------|-------------|
| `/notifications` | NotificationsPage | Notification inbox + preferences |
| `/profile/edit` | ProfileEditPage | Profile editor |
| `/detail/deadline/:id` | AcademicItemDetailPage | Deadline detail |
| `/detail/exam/:id` | AcademicItemDetailPage | Exam detail |
| `/detail/event/:id` | AcademicItemDetailPage | Event detail |
| `/map/building/:id` | MapPage | Map pre-focused on building |

### Route Guards (cascading)

```
1. Loading?         → stay on /splash
2. Password recovery? → /reset-password?mode=recovery
3. Not authenticated? → /login
4. Email unverified?  → /verify-email
5. MFA required?      → /mfa
6. Profile incomplete? → /onboarding
7. On auth route after login? → /home
```

---

## Feature Breakdown

### 1. Auth + Profiles + Settings (Phase 2)

**Pouya — UI:**
- Login page (email/password form + Google OAuth button)
- Signup page (email, password, confirmation)
- Verify email page (resend + refresh)
- Reset password page (dual-mode: request or recovery)
- Profile edit / onboarding page (name, student ID, faculty, course, year)
- Settings page (theme toggle, locale picker, notification prefs, biometric lock, MFA)

**Raouf — Backend:**
- Auth repository (Supabase auth calls: signIn, signUp, OAuth, resetPassword, MFA)
- Auth flow controller (error handling, loading state)
- MFA controller (TOTP enroll, verify, unenroll)
- Profile repository (fetch/save to `profiles` table)
- Settings repository (hybrid: secure storage + Supabase `user_preferences`)
- Biometric lock gate widget
- Route guards (auth, email verify, MFA, onboarding)

### 2. Home Dashboard (Phase 3)

**Pouya — UI:**
- Welcome card with user greeting
- Stress metrics card (score 0–100 with colour coding)
- XP progress card (level, streak, progress bar)
- Upcoming deadlines / exams / events / todos lists

**Raouf — Backend:**
- Dashboard repository (fetches 7-day past to 21-day future bundle)
- Stress calculation algorithm (overdue weight=3, urgent weight=2, todo weight=1, capped 100)
- Gamification model (level = xp/1000, progress = xp % 1000 / 1000)

### 3. Calendar (Phase 3)

**Pouya — UI:**
- Agenda view (scrollable entry list)
- Day view (focused-day entries)
- Week view (7-column horizontal scroll)
- Quick-add FAB → intent picker → 4 editor bottom sheets (deadline, exam, event, todo)
- Unit filter chips, completed-items toggle

**Raouf — Backend:**
- Calendar repository (CRUD for deadlines, events, todos via Supabase)
- Calendar controller (AsyncNotifier with CalendarState: view mode, filters, focused date)
- CalendarEntry model (unified from deadline/event/todo with date range filtering)

### 4. Notifications + Feed (Phase 4)

**Pouya — UI:**
- Notification inbox page with per-type toggles
- Notification tile widget (type icon, title, body, timestamp)
- Unread badge on app bar
- Feed page with search bar, type/date filters, pagination
- Feed event card with "add to calendar" action

**Raouf — Backend:**
- FCM service (token sync, foreground/background handlers)
- Local notifications service (6 Android channels, timezone-aware scheduling)
- Notification remote source (Supabase real-time stream, preference CRUD)
- Notification scheduler (deadline/exam reminders, study prompts)
- Feed repository (paginated Supabase query with cursor, full-text search)
- `notify` Edge Function (inbox row + FCM push dispatch)

### 5. Campus Map (Phase 5)

**Pouya — UI:**
- Google Maps widget with campus camera bounds
- Building search bottom sheet (ranked search by name, code, alias)
- Route panel (ETA, distance, travel mode selector)
- Building markers + info windows
- Location permission request flow

**Raouf — Backend:**
- Building registry source (Supabase → asset fallback, 153 buildings)
- Google Routes remote source (via `maps-routes` Edge Function)
- Location source (Geolocator with 5m distance filter)
- Map controller (AsyncNotifier with MapState: buildings, route, location, permissions)
- Typed MapStateError enum (no English sentinel strings)
- `maps-routes` Edge Function (rate-limited Google Routes proxy)

---

## Supabase Edge Functions (Server-Side)

| Function | Purpose | Auth |
|----------|---------|------|
| `auth-email` | Email verification via Resend API | JWT |
| `auth-cleanup` | Expired token cleanup (cron) | CRON_SECRET |
| `routes-proxy` | Google Routes API proxy (legacy) | JWT |
| `maps-routes` | Authenticated routing proxy with rate limiting | JWT |
| `places-proxy` | Google Places search/detail proxy | JWT |
| `weather-proxy` | Google Weather API proxy | JWT |
| `security-utils` | HIBP password breach check | None |
| `notify` | Inbox row + FCM push dispatch | JWT |
| `cleanup-cron` | Rate-limit + audit-log retention | CRON_SECRET |

---

## Localisation (i18n)

**35 languages** with RTL support for Arabic, Persian, Hebrew, and Urdu.

Converted from web JSON to Flutter ARB via `dart tools/convert_i18n.dart`.

| Feature | Web | Flutter |
|---------|-----|---------|
| Format | JSON (Handlebars `{{var}}`) | ARB (ICU `{var}`) |
| Locales | 35 | 35 |
| Keys per locale | ~1995 | ~1995 |
| RTL | ar, fa, he, ur | ar, fa, he, ur |
| Reserved words | N/A | Prefixed with `k` (`class` → `kClass`) |
| Building keys | Included | Excluded (loaded from Supabase at runtime) |

---

## Security Model

| Measure | Implementation |
|---------|---------------|
| Encrypted token storage | flutter_secure_storage (iOS Keychain / Android Keystore) |
| Biometric gate | local_auth before sensitive actions |
| PKCE auth flow | Supabase OAuth with deep-link return |
| No server secrets in client | API keys stay in Edge Functions |
| RLS enforcement | All database access via Supabase Row-Level Security |
| Deep link validation | Custom scheme `io.mqnavigation://callback` |

---

## Environment Configuration

### Client-Side (--dart-define)

| Variable | Required | Debug Default |
|----------|----------|---------------|
| `SUPABASE_URL` | Yes | Dev project URL |
| `SUPABASE_ANON_KEY` | Yes | Dev anon key |
| `GOOGLE_MAPS_API_KEY` | No | Empty |
| `APP_ENV` | No | `development` |

In **debug mode**, `flutter run` works without flags (dev defaults).
In **release mode**, missing values throw `StateError`.

### Server-Side (Edge Function secrets)

| Variable | Function(s) |
|----------|-------------|
| `SUPABASE_SERVICE_ROLE_KEY` | auth-email, auth-cleanup, notify, cleanup-cron |
| `GOOGLE_ROUTES_API_KEY` | maps-routes, routes-proxy, places-proxy |
| `GOOGLE_WEATHER_API_KEY` | weather-proxy |
| `RESEND_API_KEY` | auth-email |
| `CRON_SECRET` | auth-cleanup, cleanup-cron |
| `FIREBASE_SERVICE_ACCOUNT` | notify |

---

## CI/CD Pipeline

### GitHub Actions (`.github/workflows/ci.yml`)

```
Push/PR to main
  → Analyze & Test (ubuntu)
     → format check
     → flutter analyze
     → flutter test --coverage

Push to main only
  → Build Android (ubuntu, Java 17)
     → flutter build apk --release
     → Upload artifact
  → Build iOS (macos)
     → flutter build ios --release --no-codesign
```

### Fastlane

**Android** (`android/fastlane/Fastfile`):
- `build_debug` — debug APK
- `build_release` — release AAB
- `deploy_internal` — Google Play internal track
- `promote_beta` — promote internal → beta

**iOS** (`ios/fastlane/Fastfile`):
- `build_debug` — debug build (no codesign)
- `build_release` — release IPA
- `deploy_testflight` — upload to TestFlight
- `promote_appstore` — submit for App Store review

### Quality Gate

```bash
./scripts/check.sh          # Full: pub get → format → analyze → test → gen-l10n → build
./scripts/check.sh --quick   # Skip build step
./scripts/run.sh [device]    # Launch with .env dart-defines
```

---

## Testing

| Layer | Count | Scope |
|-------|-------|-------|
| Core unit tests | 20 | EnvConfig, AppException, Result, validators |
| Theme tests | 21 | MQ colours, spacing, typography, ThemeData |
| Route tests | 11 | Route names, guards, redirects |
| Auth tests | 8 | Auth controller, OAuth, MFA |
| Calendar tests | 3 | State, filters, date range |
| Model tests | 2 | Stress, gamification levels |
| Map tests | 15 | Building entity, route parsing, registry asset |
| Notification tests | 1 | Scheduler, preferences |
| Widget tests | 18 | MqButton, MqCard, MqInput |
| **Total** | **99** | |

---

## What's Reused from the Web App

| Asset | How |
|-------|-----|
| Same Supabase database | Shared backend, same tables/RLS/RPCs |
| Same data models | TypeScript types → Dart models |
| Same API structure | SDK calls + Edge Functions |
| Same MQ branding | Colour tokens mapped to Flutter ThemeData |
| Same building coordinates | 153 buildings exported from web `buildings.ts` |
| Same translation keys | JSON → ARB conversion (35 locales) |
| Same auth flows | Supabase auth with PKCE + MFA |

---

## Team Contributions

### Pouya Alavi (Frontend & UI/UX)
- Flutter project scaffold and architecture
- MQ design system (colours, typography, spacing, light/dark themes)
- All screen layouts: login, signup, dashboard, calendar, map, feed, settings
- Shared widget library (MqButton, MqCard, MqInput, MqBottomSheet, MqAppBar)
- go_router shell with 5-tab bottom navigation
- Quick-add calendar editors (deadline, exam, event, todo)
- Building search sheet and route panel
- Feed filters, event cards, pagination UI
- Notification inbox and preference toggles
- i18n ARB conversion script (35 locales)

### Raouf Abedini (Backend & Security)
- Supabase integration and Edge Functions (9 server functions)
- Auth repository, MFA controller, biometric service
- Route guards (auth, email verify, MFA, onboarding)
- All data repositories (dashboard, calendar, feed, map, profile, settings, notifications)
- FCM push + local notification scheduling service
- Building registry with 153-building asset + Supabase fallback
- Google Routes proxy with rate limiting
- Security: encrypted storage, cert pinning config, deep link validation
- CI/CD pipeline (GitHub Actions + Fastlane for Android/iOS)
- Environment config with debug-mode dev defaults

---

## External Prerequisites (Not in Repo)

These are deployment-time configurations needed before production release:

| Item | Owner | Notes |
|------|-------|-------|
| `android/app/google-services.json` | Raouf | Firebase console → download for Android |
| `ios/Runner/GoogleService-Info.plist` | Raouf | Firebase console → download for iOS |
| APNs key in Firebase console | Raouf | Required for iOS push notifications |
| Google Cloud key restrictions | Raouf | Restrict Maps API key to app bundle IDs |
| Supabase Edge Function secrets | Raouf | `supabase secrets set` for all server keys |
| AASA file on domain | Raouf | iOS universal link verification |
| assetlinks.json on domain | Raouf | Android app link verification |
| Apple Developer signing | Pouya | Code signing for TestFlight/App Store |
| Google Play signing | Pouya | Upload key for Play Store |

---

## How to Run

```bash
# Clone and install
git clone https://github.com/Raoof128/Pouya-Raouf-COMP3130.git
cd mq-navigation_flutter
flutter pub get

# Run on device (debug mode — no flags needed)
flutter run

# Run on specific device
flutter run -d <device-id>

# Or use the run script (loads .env)
./scripts/run.sh <device-id>

# Run quality checks
./scripts/check.sh --quick

# Run tests
flutter test
```

---

## Repository Links

- **Mobile App:** https://github.com/Raoof128/Pouya-Raouf-COMP3130 (`mq-navigation_flutter/`)
- **Web App:** https://github.com/mrpouyaalavi/syllabus-sync
- **Live Web:** https://syllabus-sync-ashy.vercel.app
