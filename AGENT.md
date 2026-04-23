# MQ Navigation Flutter — Agent Rules

## Project Overview
Flutter mobile client for MQ Navigation (Macquarie University campus navigation platform).
Two frontends, one backend architecture: Flutter + Next.js sharing a Supabase backend.

## Architecture
- **Pattern**: Feature-first with data/domain/presentation layers per feature
- **State management**: Riverpod (flutter_riverpod ^3.2.1)
- **Routing**: go_router with StatefulShellRoute for 3-tab bottom nav (Home, Map, Settings)
- **Backend**: Supabase (Postgres, RLS, Realtime, Edge Functions)
- **Theme**: MQ design tokens (MqColors, MqTypography, MqSpacing) mapped from web app
- **i18n**: Flutter ARB files with 35 locales, RTL support for ar/fa/he/ur
- **No auth**: App starts directly at `/home` — no login, signup, or profile management

## Non-Negotiable Constraints
1. Supabase is the system of record — no parallel backend
2. Web app stays alive — no feature freeze on the web product
3. Flutter is a presentation layer only — no server logic in app binary
4. No server secrets in Flutter — API keys stay in Edge Functions
5. Security is non-negotiable — encrypted storage, RLS enforcement
6. Accessibility from day one — 48x48dp tap targets, semantic labels, RTL

## Directory Structure
```
lib/
  app/bootstrap/    → App init, Supabase + Firebase setup
  app/router/       → go_router config, route names
  app/theme/        → MQ design tokens (colors, typography, spacing)
  app/l10n/         → ARB files + generated localisations
  core/config/      → Env vars via --dart-define
  core/error/       → App exceptions, error boundary
  core/logging/     → Structured logger
  core/network/     → Connectivity service
  core/security/    → Secure storage
  core/utils/       → Result type, validators
  shared/widgets/   → MQ button, card, input, bottom sheet, app bar
  shared/models/    → UserPreferences
  shared/extensions/→ BuildContext extensions
  features/home/    → Welcome hub
  features/map/     → Campus map (153 buildings, search, routing)
  features/notifications/ → FCM push + local study prompts
  features/settings/ → Theme, locale, notification preferences (local storage)
```

## Key Environment Variables (--dart-define)
- SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_MAPS_API_KEY, APP_ENV
- DEV_SUPABASE_URL, DEV_SUPABASE_ANON_KEY, DEV_GOOGLE_MAPS_API_KEY (debug-only fallbacks)
- All keys loaded via `--dart-define-from-file=.env` — never hardcoded in source
- Use `scripts/run.sh` to launch with native key injection for Maps SDKs

### Raouf: 2026-04-22 (AEST) — Environment setup
**Scope:** `.env` creation.
**Summary:** Created a `.env` file from `.env.example` template with placeholders for Supabase and Google Maps credentials. This enables usage of `scripts/run.sh` and proper environment configuration.
**Files Changed:** `.env` (new, gitignored)
**Verification:** File exists and matches `.env.example` structure.

### Raouf: 2026-04-22 (AEST) — Zero-data features & settings implementation
**Scope:** Architecture & UI improvement.
**Summary:** Implemented the "zero-data" features blueprint. Updated `UserPreferences` and `SettingsRepository` to support default renderer, travel mode, low data mode, and reduced motion. Implemented "Low Data Guard" in building search and "Reduced Motion Guard" in animations. Added a "Nuclear Reset" (wipe data) feature. Built the corresponding UI in `SettingsPage`.
**Files Changed:** `lib/shared/models/user_preferences.dart`, `lib/features/settings/data/repositories/settings_repository.dart`, `lib/features/settings/presentation/controllers/settings_controller.dart`, `lib/features/map/presentation/controllers/map_controller.dart`, `lib/app/theme/mq_animations.dart`, `lib/features/map/presentation/widgets/building_search_sheet.dart`, `lib/features/settings/presentation/pages/settings_page.dart`
**Verification:** Manual logic verification for guards and repository methods.

## Coding Conventions
- Use Riverpod providers (not setState or Bloc)
- Use go_router named routes (RouteNames constants)
- Use MqSpacing/MqColors/MqTypography for all styling — no magic numbers
- Minimum tap target: 48dp
- All interactive elements must have semantic labels
- Use EdgeInsetsDirectional for RTL support

## Inventory Documents
Located in project root:
- `entity_inventory.md` — Shared Supabase schema (Flutter uses subset only)
- `endpoint_inventory.md` — API routes → Edge Functions / SDK mapping
- `env_inventory.md` — Environment variables (client vs server)
- `notification_matrix.md` — Push/local notification flows
- `route_matrix.md` — Flutter route map
- `key_inventory.md` — Translation key inventory (35 locales)
- `map_inventory.md` — Map dependencies, APIs, building registry

## i18n Convention
- Web uses `{{variable}}` (Handlebars). ARB uses `{variable}` (ICU).
- Dart reserved words are prefixed with `k` (e.g. `class` → `kClass`, `continue` → `kContinue`)
- Run `dart tools/convert_i18n.dart` to regenerate ARB files from web JSON

## Change History

See `CHANGELOG.md` for full development history.

### Raouf: 2026-04-23 (AEST) — Dark/Light parity audit pass (Home + Settings)
**Scope:** Visual parity verification for dark mode and light mode branches.
**Summary:** Performed a full parity audit across `HomePage` and `SettingsPage` surface/background/accent usage. Confirmed shared scaffold backgrounds (`alabaster` light / `charcoal850` dark), matching dark-mode radial glow treatment, and consistent card token usage (`sand200`/`white-13%` borders, `charcoal850` dark surfaces). Fixed one remaining mismatch by aligning Home section-header light accent from `brightRed` to `red` so it matches Settings headers exactly. Also corrected stale Home documentation comment to reflect that the background photo now renders in both theme modes.
**Files Changed:** `lib/features/home/presentation/pages/home_page.dart`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — Home bento hero swap + Settings kinetic/tactile refresh
**Scope:** Home quick-access hierarchy update and Settings interaction polish.
**Summary:** Updated Home Bento hierarchy so the large left hero card now routes to `Student Services` (query: `services`) and moved `Food & Drink` to the secondary quick row. Refreshed Settings with kinetic section/title animation, tactile row interactions via `MqTactileButton`, and a standout Danger Zone Bento block for wipe-data action while preserving existing controller wiring and i18n keys.
**Files Changed:** `lib/features/home/presentation/pages/home_page.dart`, `lib/features/settings/presentation/pages/settings_page.dart`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — Home background image dark-mode + clarity fix
**Scope:** Home background image rendering and visual clarity.
**Summary:** Fixed Home background photo visibility in dark mode by always rendering the campus background layer (instead of conditionally hiding it in dark mode). Reduced the background wash/veil opacity to avoid the “blurry/foggy” look: light overlay changed to `MqColors.alabaster` alpha `0.50` (from `0.78`) and dark overlay uses `MqColors.charcoal950` alpha `0.42` to preserve readability while keeping image detail visible.
**Files Changed:** `lib/features/home/presentation/pages/home_page.dart`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — Home tactical UI refresh (tactile + kinetic + bento)
**Scope:** Home UX enhancement with tactile interactions and asymmetric quick access layout.
**Summary:** Added reusable `MqTactileButton` (`lib/shared/widgets/mq_tactile_button.dart`) with press-scale animation, drop-shadow depth, and configurable haptic feedback. Upgraded home hero text to a kinetic intro using `TweenAnimationBuilder` (fade + slide-up). Replaced the old symmetric quick-access grid with an asymmetrical Bento layout (hero card + stacked compact cards), while preserving tokenized styling and localized labels. Wired haptic preference from `SettingsController` into all home tactile cards.
**Files Changed:** `lib/shared/widgets/mq_tactile_button.dart`, `lib/features/home/presentation/pages/home_page.dart`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — Settings/Home background parity
**Scope:** Visual consistency in Settings scaffold background.
**Summary:** Updated `SettingsPage` scaffold background to exactly match `HomePage` base colors in both theme modes (`MqColors.alabaster` in light mode and `MqColors.charcoal850` in dark mode), so both tabs now share identical page-level background surfaces.
**Files Changed:** `lib/features/settings/presentation/pages/settings_page.dart`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — Settings Audit & Functional Wiring
**Scope:** Verify all 12 settings are fully functional, persisted, and accurately consumed app-wide.
**Summary:** Conducted a comprehensive audit of `SettingsRepository`, `SettingsController`, and all app-wide consumers. Verified that `themeMode`, `localeCode`, `notificationsEnabled`, `lowDataMode`, `reducedMotion`, `quietHoursEnabled`, `quietHoursStart`, `quietHoursEnd`, and `highContrastMap` were perfectly wired. Fixed two functional bugs: 
1) `MapController` was using `ref.watch(settingsControllerProvider.future)` in its `build()` method, causing the entire map state (selected building, route, search query) to reset whenever *any* unrelated setting (e.g., theme or haptics) was toggled. Swapped to `ref.read` for initial load and `ref.listen` to selectively update `renderer` and `travelMode` dynamically.
2) `hapticsEnabled` was cosmetic (only used in the dev Easter egg). Wired it up to `MqHaptics.light` on all `SettingsPage` toggles/pickers and `MqHaptics.selection` in `BuildingSearchSheet`.
**Files Changed:** `lib/features/map/presentation/controllers/map_controller.dart`, `lib/features/settings/presentation/pages/settings_page.dart`, `lib/features/map/presentation/widgets/building_search_sheet.dart`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — Home/Settings 100% theme & colour parity
**Scope:** UI polish — locking `HomePage` to the same design language as `SettingsPage`.
**Summary:** Rewrote `lib/features/home/presentation/pages/home_page.dart` so every surface, border, text and accent colour mirrors `SettingsPage`: dual-theme branching via `context.isDarkMode`, charcoal850/white cards with `sand200` / `white-13%` borders, `vividRed` (dark) / `red` (light) accents, the Settings-style uppercase letter-spaced red section header, and the Settings red radial glow layered on dark-mode Home. Removed all hardcoded strings (i18n rule) by adding 11 `home_*` ARB keys to `app_en.arb` and propagating them with English fallback to all 34 non-English locales. Swapped `EdgeInsets` for `EdgeInsetsDirectional` for RTL safety.
**Files Changed:** `lib/features/home/presentation/pages/home_page.dart`, `lib/app/l10n/app_en.arb`, `lib/app/l10n/app_*.arb` (34 locales), `lib/app/l10n/generated/*` (regenerated).
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Summary

The project was built through phases 0–5, originally including auth, calendar, event feed, profile management, and gamification features. These were subsequently removed to focus the Flutter app on campus navigation: 3-tab nav (Home/Map/Settings), local-only settings, FCM push + study prompt notifications, and dual-renderer campus map with building search and routing via Edge Function proxy.

### Raouf: 2026-04-22 (AEST) — iOS deployment target synchronization & build fixes
**Scope:** iOS build configuration.
**Summary:** Updated IPHONEOS_DEPLOYMENT_TARGET from 13.0 to 17.0 in `ios/Runner.xcodeproj/project.pbxproj`, `ios/Podfile`, and `ios/Flutter/AppFrameworkInfo.plist` (added `MinimumOSVersion`) to resolve version conflicts with Firebase 12.12.0+ and fix a compilation error in `connectivity_plus` (^7.0.0) which requires the iOS 17 SDK for `isUltraConstrained`. Synchronized `ios/Podfile.lock` via `pod update`. Added warning suppressions for third-party pods to ensure clean CI logs.
**Files Changed:** `ios/Runner.xcodeproj/project.pbxproj`, `ios/Podfile`, `ios/Podfile.lock`, `ios/Flutter/AppFrameworkInfo.plist`
**Verification:** `pod update` successful; ready for CI retry.

### Raouf: 2026-04-22 (AEST) — Zero-data features (Haptics, Quiet Hours, High-Contrast)

**Scope:** Maintenance.
**Summary:** Performed final cleanup: added `build/` to `.gitignore`, applied project-wide formatting via `dart format .`, and synchronized generated CMake files for Linux and Windows after dependency updates. Deleted temporary synchronization scripts.
**Files Changed:** `.gitignore`, `lib/**`, `linux/flutter/generated_plugins.cmake`, `windows/flutter/generated_plugins.cmake`
**Verification:** `git status` shows a clean working tree (excluding gitignored files).

### Raouf: 2026-04-22 (AEST) — Localization synchronization
**Scope:** Internationalization.
**Summary:** Synchronized 34 localization files (`app_*.arb`) with the master `app_en.arb`. Ensured all languages have the same set of keys, including the newly added settings and accessibility strings. Used English as the fallback value for missing translations to prevent UI breakage and "missing key" warnings during generation.
**Files Changed:** All `.arb` files in `lib/app/l10n/`.
**Verification:** `flutter gen-l10n` reported 0 untranslated messages.
**Scope:** Quality assurance & build stability.
**Summary:** Executed `scripts/check.sh` and resolved all issues. Added missing localization keys to `app_en.arb`. Fixed a Kotlin compilation error in `android/app/build.gradle.kts` by adding missing imports. Updated `MapController` tests to correctly mock the new `SettingsController` dependency, eliminating binding and storage errors during testing. Verified that all checks (format, analyze, test, build) now pass cleanly.
**Files Changed:** `lib/app/l10n/app_en.arb`, `android/app/build.gradle.kts`, `test/features/map/map_controller_test.dart`
**Verification:** `./scripts/check.sh` passed with 6/6 steps successful.

### Raouf: 2026-04-22 (AEST) — macOS deployment target synchronization
**Scope:** macOS build configuration.
**Summary:** Updated MACOSX_DEPLOYMENT_TARGET from 11.0 to 13.0 in `macos/Runner.xcodeproj/project.pbxproj` (both build settings and shell script phases) to align with Podfile and resolve plugin compilation errors (specifically for `app_links`).
**Files Changed:** `macos/Runner.xcodeproj/project.pbxproj`
**Verification:** Synchronized with Podfile and run.sh; ready for build retry.

### Raouf: 2026-04-22 (AEST) — Environment setup
**Scope:** `.env` creation.
**Summary:** Created a `.env` file from `.env.example` template with placeholders for Supabase and Google Maps credentials. This enables usage of `scripts/run.sh` and proper environment configuration.
**Files Changed:** `.env` (new, gitignored)
**Verification:** File exists and matches `.env.example` structure.

### Raouf: 2026-04-22 (AEST) — Run script robustness & parsing fix
**Scope:** `scripts/run.sh` logic improvement.
**Summary:** Refined argument parsing to distinguish between device targets and Flutter flags. Added quote stripping for API keys from `.env` to prevent JS/native syntax errors. Optimized `gradle.properties` modification to be idempotent. Added early `flutter` command check and switched `echo` to `printf` for safe variable handling.
**Files Changed:** `scripts/run.sh`
**Verification:** `bash -n scripts/run.sh` passed.
