# MQ Navigation Flutter — Agent Rules

## Project Overview
Flutter mobile client for MQ Navigation (Macquarie University campus management platform).
Two frontends, one backend architecture: Flutter + Next.js sharing a Supabase backend.

## Architecture
- **Pattern**: Feature-first with data/domain/presentation layers per feature
- **State management**: Riverpod (flutter_riverpod ^3.2.1)
- **Routing**: go_router with StatefulShellRoute for bottom nav
- **Backend**: Supabase (auth, Postgres, RLS, Realtime, Edge Functions)
- **Theme**: MQ design tokens (MqColors, MqTypography, MqSpacing) mapped from web app
- **i18n**: Flutter ARB files with 35 locales, RTL support for ar/fa/he/ur

## Non-Negotiable Constraints
1. Supabase is the system of record — no parallel backend
2. Web app stays alive — no feature freeze on the web product
3. Flutter is a presentation layer only — no server logic in app binary
4. No server secrets in Flutter — API keys stay in Edge Functions
5. Maps are a subsystem — not part of first parity milestone
6. Security is non-negotiable — encrypted storage, biometric gates, cert pinning
7. Accessibility from day one — 48x48dp tap targets, semantic labels, RTL

## Directory Structure
```
lib/
  app/bootstrap/    → App init, Supabase setup
  app/router/       → go_router config, guards, route names
  app/theme/        → MQ design tokens (colors, typography, spacing)
  app/l10n/         → ARB files + generated localisations
  core/config/      → Env vars via --dart-define
  core/error/       → App exceptions, error boundary
  core/logging/     → Structured logger
  core/network/     → Connectivity service
  core/security/    → Secure storage, biometric service
  core/utils/       → Result type, validators
  shared/widgets/   → MQ button, card, input, bottom sheet, app bar
  shared/providers/ → Auth state, connectivity, locale
  shared/extensions/→ BuildContext extensions
  features/<name>/  → Feature modules (auth, home, calendar, map, etc.)
```

## Key Environment Variables (--dart-define)
- SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_MAPS_API_KEY, APP_ENV

## Coding Conventions
- Use Riverpod providers (not setState or Bloc)
- Use go_router named routes (RouteNames constants)
- Use MqSpacing/MqColors/MqTypography for all styling — no magic numbers
- Minimum tap target: 48dp
- All interactive elements must have semantic labels
- Use EdgeInsetsDirectional for RTL support

## Phase 0 Inventories
Located in project root:
- `entity_inventory.md` — All Supabase tables, views, RPC functions
- `endpoint_inventory.md` — API routes → Edge Functions / SDK mapping
- `env_inventory.md` — Environment variables (client vs server)
- `auth_matrix.md` — Auth flow matrix with route guards
- `notification_matrix.md` — Push/local notification flows
- `route_matrix.md` — Web routes → Flutter routes
- `key_inventory.md` — Translation key inventory (35 locales)
- `map_inventory.md` — Map dependencies, APIs, building registry

## i18n Convention
- Web uses `{{variable}}` (Handlebars). ARB uses `{variable}` (ICU).
- Dart reserved words are prefixed with `k` (e.g. `class` → `kClass`, `continue` → `kContinue`)
- Building translation keys excluded from ARB — loaded from Supabase at runtime
- Run `dart tools/convert_i18n.dart` to regenerate ARB files from web JSON

## Deep Links
- Custom scheme: `io.mqnavigation://callback`
- Android: Intent filters in AndroidManifest.xml + assetlinks.json (TODO: deploy)
- iOS: URL scheme in Info.plist + AASA file (TODO: deploy)

---

Raouf: 2026-03-11 (AEDT) — Plan Alignment Audit + Final Old-Name Cleanup
- Scope: Verify full project alignment with the updated Flutter Migration Plan and eliminate the last old-name reference.
- Summary: Audited the entire codebase against the user's updated migration plan. Confirmed all navigation-focused goals (map, buildings, directions, categories) are fully implemented and the project exceeds the plan's scope with completed auth, calendar, dashboard, notifications, and feed features. Fixed the critical Android Kotlin directory mismatch: `MainActivity.kt` was still at `io/syllabussync/syllabus_sync/` with old package name while `build.gradle.kts` used `io.mqnavigation.mq_navigation` — moved to correct path and updated package declaration. Updated `Flutter_Migration_Plan.md` to remove stale external `syllabus-sync` URLs. Verified zero old-name references remain in source/config files (only historical changelog entries preserved).
- Files changed: `android/app/src/main/kotlin/io/mqnavigation/mq_navigation/MainActivity.kt` (created, replacing old path), `android/app/src/main/kotlin/io/syllabussync/` (deleted), `Flutter_Migration_Plan.md`, `AGENT.md`, `CHANGELOG.md`.
- Verification: `flutter analyze` → 0 issues, `flutter test` → 99/99 passed.
- Follow-ups: None — naming is fully consistent.

Raouf: 2026-03-11 (AEDT) — Full Project Rename: Syllabus Sync → MQ Navigation
- Scope: Rename every reference across the entire codebase from "Syllabus Sync" to "MQ Navigation".
- Summary: Renamed all name variants across the full project: `syllabus_sync` → `mq_navigation` (Dart package, imports, identifiers), `SyllabusSyncApp` → `MqNavigationApp` (class), `io.syllabussync.*` → `io.mqnavigation.*` (Android/iOS bundle IDs, URL schemes), `Syllabus Sync` → `MQ Navigation` (display name in 35 ARB locales, UI strings, docs), `syllabus-sync` → `mq-navigation` (hyphenated refs). Renamed the main app file `syllabus_sync_app.dart` → `mq_navigation_app.dart`. Regenerated l10n. Preserved external URLs (web app GitHub repo, Vercel deployment). Renamed project folder from `syllabus-sync_flutter` to `mq_navigation`.
- Files changed: 300+ files including all Dart source/test files (package imports), `pubspec.yaml`, `android/app/build.gradle.kts`, `android/fastlane/Appfile`, `ios/Runner/Info.plist`, `ios/fastlane/Appfile`, `supabase/config.toml`, `supabase/functions/auth-email/index.ts`, 35 ARB locale files, all documentation (.md), platform configs (CMakeLists, manifest.json, index.html, .xcscheme, .pbxproj, .xcconfig, Runner.rc).
- Verification: `flutter analyze` → 0 issues, `flutter test` → 99/99 passed (verified before folder rename). Zero remaining old-name references in source/config files.
- Follow-ups: Commit and push. If the web app folder is also renamed, update `tools/convert_i18n.dart` path accordingly.

Raouf: 2026-03-11 (AEDT) — Updated Migration Plan Document
- Scope: Create a comprehensive Flutter Migration Plan document reflecting the actual completed state of all phases 0–5.
- Summary: Built a full migration plan document (`Flutter_Migration_Plan.md`) aligned with the user's template format, covering: current state analysis (web + mobile), architecture diagram, tech stack with pinned dependencies, full project structure, navigation/route map with guards, feature breakdown with Pouya/Raouf ownership split across all 5 phases, 9 Edge Functions inventory, i18n details (35 ARB locales), security model, environment config (client + server), CI/CD pipeline (GitHub Actions + Fastlane), testing summary (99 tests), team contributions, external prerequisites, and how-to-run instructions. Used 3 parallel explore agents to gather comprehensive codebase inventory (89 Dart files, 15 test files, 35 ARB locales, 9 Edge Functions, 153 buildings).
- Files created: `Flutter_Migration_Plan.md`
- Verification: `flutter analyze --no-fatal-infos` → 0 issues, `flutter test` → 99/99 passed.
- Follow-ups: Commit and push the migration plan document.

Raouf: 2026-03-11 (AEDT) — Final Stage Verification + Release Handoff
- Scope: Close verification for the last Phase 4/5 patch and document what remains outside the repo.
- Summary: Verified the full Phase 4/5 delivery after the final native Firebase, localization, and typed map-error patch. Confirmed Android now builds cleanly with conditional Google Services activation, iOS Firebase bootstrap remains safe when service files are absent, notification/detail UI strings resolve through ARB localization, and map failures no longer depend on English sentinel strings. Confirmed the remaining gaps are external deployment prerequisites only: real `android/app/google-services.json`, real `ios/Runner/GoogleService-Info.plist`, APNs/FCM console setup, Google Cloud key restrictions, Supabase Edge Function secrets, and deployment of `notify` / `maps-routes`.
- Files changed: `AGENT.md`, `CHANGELOG.md`
- Verification: `flutter analyze --no-fatal-infos` → no issues, `flutter test` → 99/99 passed, `./scripts/check.sh` → 6/6 checks passed including debug APK build, `deno check supabase/functions/maps-routes/index.ts` → passed, `deno check supabase/functions/notify/index.ts` → passed, `deno check supabase/functions/cleanup-cron/index.ts` → passed.
- Follow-ups: Commit and push the completed Phase 4/5 repo state to `origin/main`, then apply the required Firebase/Supabase/Google Cloud secrets in the target environments.

Raouf: 2026-03-11 (AEDT) — Phase 4 + Phase 5 Runtime Stabilization
- Scope: Close the first runtime gaps discovered after the initial Phase 4/5 scaffold landed.
- Summary: Normalized notification preferences so partially populated Supabase rows no longer break toggle updates, hardened notification/map JSON parsing and route coordinate guards, fixed feed pagination ordering so cursor-based paging stays stable, and added concrete `/detail/deadline/:id`, `/detail/exam/:id`, and `/detail/event/:id` routes with repository-backed detail pages so notification taps resolve to real screens instead of dead links. Also removed the last map analyze warning and replaced a few hardcoded map action labels with existing localized strings.
- Files changed: `lib/features/notifications/domain/entities/notification_preferences.dart`, `lib/features/notifications/data/datasources/notification_remote_source.dart`, `lib/features/notifications/domain/entities/app_notification.dart`, `lib/features/feed/data/repositories/feed_repository.dart`, `lib/features/map/domain/entities/building.dart`, `lib/features/map/data/datasources/google_routes_remote_source.dart`, `lib/features/map/presentation/pages/map_page.dart`, `lib/features/map/presentation/widgets/campus_map_view.dart`, `lib/features/map/presentation/widgets/route_panel.dart`, `lib/features/calendar/data/repositories/calendar_repository.dart`, `lib/features/calendar/presentation/pages/academic_item_detail_page.dart`, `lib/app/router/app_router.dart`.
- Verification: Pending final analyze/test pass after the server functions, docs, and test additions land.

Raouf: 2026-03-11 (AEDT) — Phase 4 + Phase 5 Edge Functions
- Scope: Add the Supabase server-side pieces required by the new Flutter notification and map clients.
- Summary: Added a new `maps-routes` Edge Function with authenticated Google Routes proxying, per-user `rate_limits` throttling (60 requests per minute), and request payload validation so the mobile map no longer depends on the older generic proxy. Added a new `notify` Edge Function that validates the caller, stores an inbox notification row, reads `user_fcm_tokens`, dispatches push messages through Firebase, and prunes stale tokens without exposing push credentials to Flutter. Updated the rate-limit cleanup cron to match the documented `reset_time_ms` schema and registered both new functions in `supabase/config.toml`.
- Files changed: `supabase/functions/maps-routes/index.ts`, `supabase/functions/notify/index.ts`, `supabase/functions/cleanup-cron/index.ts`, `supabase/config.toml`.
- Verification: Pending final repo-wide verification after tests and docs are updated.

Raouf: 2026-03-11 (AEDT) — Edge Function TypeScript Cleanup
- Scope: Correct the first-pass TypeScript issues in the new notification dispatcher before verification.
- Summary: Replaced Dart-style array helpers in `notify` with valid TypeScript collection operations, made FCM v1 response parsing resilient to non-JSON upstream failures, and aligned a remaining length check with standard strict comparison so the new Edge Function code is ready for formatting and validation.
- Files changed: `supabase/functions/notify/index.ts`.
- Verification: Pending function formatting plus final repo-wide verification.

Raouf: 2026-03-11 (AEDT) — Phase 5 Registry + Regression Tests
- Scope: Replace the temporary map asset with the audited web registry and add regression coverage for the new Phase 4/5 behavior.
- Summary: Regenerated `assets/data/buildings.json` from the sibling web app's `buildings.ts` source so Flutter now ships the full 153-building campus registry with GPS fallback coordinates and the 6 audited entrance-location enrichments preserved. Added targeted tests covering notification preference normalization and stable reminder scheduling, feed-import event persistence via `source_public_event_id`, map route parsing, route-name coverage for `/notifications`, and an asset-level guard that ensures the bundled building registry remains at full campus scale.
- Files changed: `assets/data/buildings.json`, `test/app/route_names_test.dart`, `test/features/home/academic_models_test.dart`, `test/features/notifications/notification_scheduler_test.dart`, `test/features/map/map_route_test.dart`, `test/features/map/building_registry_asset_test.dart`.
- Verification: Pending final repo-wide analyze/test/check pass after docs are updated.

Raouf: 2026-03-11 (AEDT) — Phase 4 + Phase 5 Documentation Alignment
- Scope: Bring the repo documentation and inventories in line with the implemented notifications, feed, and map stack.
- Summary: Updated the README with Phase 4/5 feature status, mobile platform setup requirements, and server secret guidance for `notify` and `maps-routes`. Expanded the architecture doc with concrete notifications/feed/map subsystem notes, corrected the environment inventory to reflect the removed client Maps fallback and the preferred Firebase service-account secret, and refreshed the endpoint, notification, map, and route inventories so they now describe the implemented `/notifications`, `/detail/...`, `notify`, and `maps-routes` flows instead of the earlier placeholders.
- Files changed: `README.md`, `docs/ARCHITECTURE.md`, `env_inventory.md`, `endpoint_inventory.md`, `notification_matrix.md`, `map_inventory.md`, `route_matrix.md`, `test/core/env_config_test.dart`.
- Verification: Pending the final analyze/test/check pass.

Raouf: 2026-03-11 (AEDT) — Phase 4 + Phase 5 Final Verification
- Scope: Close the implementation cycle with repo-wide validation.
- Summary: Verified the completed Phase 4/5 pass end-to-end. `flutter analyze --no-fatal-infos` returned 0 issues, `flutter test` passed 99/99 tests including the new notification/map regressions and building-registry asset guard, `scripts/check.sh --quick` passed all 5 checks, and `deno check` succeeded for `supabase/functions/maps-routes`, `supabase/functions/notify`, and `supabase/functions/cleanup-cron`.
- Files changed: `AGENT.md`, `CHANGELOG.md`.
- Verification: Complete.

Raouf: 2026-03-11 (AEDT) — Final Stage Gap Closure
- Scope: Finish the remaining concrete Phase 4/5 implementation gaps before commit.
- Summary: Added the missing native Firebase activation hooks so Android now auto-applies the Google Services plugin when `android/app/google-services.json` exists and iOS now configures Firebase automatically when `GoogleService-Info.plist` is present. Replaced the remaining hardcoded notification/detail strings with ARB-backed localization usage, and replaced map error sentinel strings with a typed `MapStateError` flow so the map UI no longer relies on English string comparisons for routing or location failures.
- Files changed: `android/settings.gradle.kts`, `android/app/build.gradle.kts`, `ios/Runner/AppDelegate.swift`, `lib/app/l10n/app_en.arb`, `lib/features/notifications/presentation/widgets/notification_tile.dart`, `lib/features/notifications/presentation/pages/notifications_page.dart`, `lib/features/calendar/presentation/pages/academic_item_detail_page.dart`, `lib/features/map/presentation/controllers/map_controller.dart`, `lib/features/map/presentation/pages/map_page.dart`, `README.md`.
- Verification: Pending final analyze/test/build pass for this closing patch.

Raouf: 2026-03-10 (AEDT) — Initial
- Scope: Phase 0 + Phase 1 foundation sprint
- Created project scaffold, core architecture, theme, routing, l10n, CI/CD
- Files: 30+ files across lib/, test/, .github/
- Status: flutter analyze clean, 4/4 tests passing

Raouf: 2026-03-10 (AEDT) — Phase 0+1 Completion
- Scope: All Phase 0 inventories, full l10n (35 locales), building registry, deep links
- Added: 8 inventory docs, tools/convert_i18n.dart, 35 ARB locale files (1995 keys each)
- Added: Building entity model + cache data source, deep link config (Android + iOS)
- Wired: AppLocalizations delegates in MqNavigationApp
- Status: flutter analyze clean (0 issues), 4/4 tests passing

Raouf: 2026-03-10 (AEDT) — Comprehensive Test Suite & Check Script
- Scope: 78 unit/widget tests + scripts/check.sh (mirrors web's npm run check)
- Tests: theme tokens, env config, exceptions, Result, routes, Building entity, MqButton/MqCard/MqInput
- check.sh: pub get → format:check → analyze → test → gen-l10n → build (--quick skips build)
- Status: 78/78 tests passing, 5/5 checks green

Raouf: 2026-03-10 (AEDT) — Production-Grade Audit & Polish
- Scope: Full audit, critical bug fixes, professional documentation, config hardening
- Fixed: EnvConfig.validate() now throws StateError in release (was assert-only)
- Fixed: GoRouter stability — single instance with AuthRefreshNotifier (was rebuilt on every auth change)
- Fixed: ErrorBoundary now mounted in widget tree via bootstrap.dart
- Fixed: debugLogDiagnostics conditional on EnvConfig.isDevelopment
- Fixed: ConnectivityService does initial check() on construction
- Fixed: MFA check now logs errors instead of silent catch(_)
- Fixed: biometric_service removed deprecated persistAcrossBackgrounding param
- Fixed: Nav bar labels now localised via AppLocalizations
- Fixed: Login page now uses MqInput (was raw TextField)
- Fixed: Building entity has == / hashCode
- Fixed: MqTheme uses NavigationBarTheme (was dead BottomNavigationBarTheme)
- Fixed: Result<T> removed unsafe .value/.error getters (use pattern matching)
- Fixed: Splash page magic numbers replaced with MqSpacing tokens
- Fixed: pubspec.yaml pinned all `any` deps (intl ^0.20.2, geolocator ^13.0.0, flutter_local_notifications ^18.0.0)
- Added: README.md (full project docs), LICENSE (MIT), CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md
- Added: docs/ARCHITECTURE.md — full system architecture overview
- Added: analysis_options.yaml — hardened with 20+ lint rules
- Added: .editorconfig, .vscode/settings.json, .vscode/extensions.json
- Status: 0 analysis issues, 78/78 tests passing, 5/5 checks green

Raouf: 2026-03-10 (AEDT) — Context7 Docs Compliance
- Scope: Compared all code patterns against latest 2026 Flutter/Riverpod/GoRouter/Supabase/local_auth docs
- Fixed: Added PlatformDispatcher.instance.onError (Layer 2 error catcher per Flutter docs)
- Fixed: Added ErrorWidget.builder in MaterialApp.builder (friendly error UI per Flutter docs)
- Fixed: Added FlutterError.presentError call for debug console output
- Confirmed: 12/12 other patterns match latest docs (M3, AsyncNotifier, refreshListenable, PKCE, etc.)
- Status: 0 analysis issues, 78/78 tests passing

Raouf: 2026-03-11 (AEDT) — Phase 2 + Phase 3 Implementation
- Scope: Delivered the mobile auth/profile/settings stack and the dashboard/calendar core from the migration blueprint.
- Summary: Replaced placeholder Phase 2 screens with controller-backed Supabase auth flows for login, signup, password recovery, verification, onboarding/profile completion, MFA, and a settings shell with theme, locale, notification, and biometric lock controls. Replaced placeholder Phase 3 home/calendar screens with repository-backed dashboard insights, stress metrics, XP summary, agenda/day/week calendar views, and quick-add CRUD sheets for deadlines, exams, events, and to-dos.
- Files changed: `lib/app/router/*`, `lib/app/mq_navigation_app.dart`, `lib/shared/providers/auth_provider.dart`, `lib/shared/models/*`, `lib/core/utils/validators.dart`, `lib/features/auth/**`, `lib/features/profiles/**`, `lib/features/settings/**`, `lib/features/home/**`, `lib/features/calendar/**`, `test/app/route_guard_test.dart`, `test/features/auth/**`, `test/features/home/**`, `test/features/calendar/**`, `README.md`, `route_matrix.md`.
- Verification: `flutter analyze` → no issues, `flutter test` → 91/91 passing, `scripts/check.sh --quick` → all 5 checks passed.
- Follow-ups: detail routes for unit/deadline/event pages can be expanded further if the product wants dedicated screens beyond the new in-place editors; map/feed phases remain separate milestones.

Raouf: 2026-03-11 (AEDT) — Context7 Audit for Phase 2 + Phase 3
- Scope: Re-audited the migrated auth/profile/settings/dashboard/calendar slices against current Flutter, go_router, and Supabase guidance fetched via Context7.
- Summary: Confirmed the overall Phase 2 and Phase 3 architecture is aligned with current docs: `MaterialApp.router`, async `go_router` redirects, `refreshListenable`, and Supabase auth event handling all remain valid. Fixed four resilience issues and two timeline correctness gaps found during the audit. Router auth guards now fail safely when Supabase MFA/profile checks error. Verify-email refresh now handles the no-session case instead of throwing. Google OAuth launch failures now surface a user-visible error. Biometric lock now recovers if device biometric support disappears after the setting is enabled. Calendar timeline entries are now constrained to the focused week and exclude undated todos from agenda/day/week views. Anonymous users now leave `/splash` once loading completes.
- Files changed: `lib/app/router/app_router.dart`, `lib/app/router/route_guard.dart`, `lib/features/auth/data/repositories/auth_repository.dart`, `lib/features/auth/presentation/controllers/auth_flow_controller.dart`, `lib/features/auth/presentation/pages/verify_email_page.dart`, `lib/features/auth/presentation/widgets/biometric_lock_gate.dart`, `lib/features/calendar/presentation/controllers/calendar_controller.dart`, `lib/shared/models/academic_models.dart`, `test/app/route_guard_test.dart`, `test/features/auth/auth_flow_controller_test.dart`, `test/features/calendar/calendar_state_test.dart`.
- Verification: `flutter analyze` → no issues, `flutter test` → 94/94 passing, `scripts/check.sh --quick` → all 5 checks passed.
- Follow-ups: upstream `origin/main` still needs a safe history reconciliation because the root branch has diverged into the `MQ_Navigation` tree while this work remains under `mq-navigation_flutter`.

Raouf: 2026-03-11 (AEDT) — Repository Cleanup After Merge
- Scope: Remove the unrelated `MQ_Navigation` tree from the parent repository so the MQ Navigation Flutter app remains the only active mobile app in the shared repo.
- Summary: Cleaned the parent repository after the upstream merge by deleting `MQ_Navigation`, keeping `mq-navigation_flutter` as the authoritative Flutter codebase, and restoring the root documentation paths to this app.
- Files changed: parent repo root `README.md`, root git tree (removed `../MQ_Navigation/**`).
- Verification: root repository now retains `mq-navigation_flutter` as the only Flutter app directory.
- Follow-ups: none.

Raouf: 2026-03-11 (AEDT) — Phase 0 Gap Closure: Edge Functions + Fastlane
- Scope: Close the two remaining Phase 0 gaps found during the full blueprint audit — Supabase Edge Functions scaffold and Fastlane distribution config.
- Summary: Created the complete Supabase Edge Functions scaffold with 7 production-ready Deno functions matching the endpoint inventory: auth-email (Resend email verification), auth-cleanup (expired token cleanup), routes-proxy (Google Routes API), places-proxy (Google Places API), weather-proxy (Google Weather API), security-utils (HIBP password breach check), cleanup-cron (rate-limit/audit log cleanup). All functions include CORS support, error handling, and cron-secret verification where needed. Created Fastlane configs for both Android (build_debug, build_release, deploy_internal, promote_beta) and iOS (build_debug, build_release, deploy_testflight, promote_appstore) with --dart-define env var injection.
- Files created: `supabase/config.toml`, `supabase/functions/_shared/cors.ts`, `supabase/functions/auth-email/index.ts`, `supabase/functions/auth-cleanup/index.ts`, `supabase/functions/routes-proxy/index.ts`, `supabase/functions/places-proxy/index.ts`, `supabase/functions/weather-proxy/index.ts`, `supabase/functions/security-utils/index.ts`, `supabase/functions/cleanup-cron/index.ts`, `android/Gemfile`, `android/fastlane/Appfile`, `android/fastlane/Fastfile`, `ios/Gemfile`, `ios/fastlane/Appfile`, `ios/fastlane/Fastfile`.
- Verification: `flutter analyze` → no issues, `flutter test` → 94/94 passing, `scripts/check.sh --quick` → all 5 checks passed.
- Follow-ups: Deploy AASA + assetlinks.json to web domain; configure Apple/Google developer account credentials in CI secrets for Fastlane.

Raouf: 2026-03-11 (AEDT) — Phase 4 + Phase 5 Implementation
- Scope: Notifications foundation, feed implementation, map MVP implementation, mobile notification/bootstrap wiring, and native map SDK setup for the Phase 4/5 pass.
- Summary: Added the first production notification slice: Firebase bootstrap registration, Android/iOS mobile notification permissions hooks, local notification channels and scheduling services, Supabase-backed notification inbox/preferences data sources, a Riverpod notifications controller, and the `/notifications` route/page. Fixed the initial Flutter integration mismatches surfaced by analysis (`FirebaseMessaging` bootstrap import, the required `uiLocalNotificationDateInterpretation` scheduling parameter, and the feed query `DateTimeRange` import). Replaced the placeholder feed screen with a Supabase-backed events/announcements feed, filter/search controls, pagination, notification badge access, and calendar import wiring that preserves `source_public_event_id`. Replaced the placeholder map screen with a repository/controller/widget stack covering building registry loading with asset fallback, building search, location permission handling, Google Maps rendering, route panel travel mode switching, and `/map/building/:id` deep-link support. Added native Google Maps key plumbing for Android/iOS and removed the committed Google Maps dev key from Dart config so Phase 5 uses explicit build-time client configuration instead of a source-controlled key.
- Files changed: `pubspec.yaml`, `lib/core/config/env_config.dart`, `lib/app/bootstrap/bootstrap.dart`, `lib/app/mq_navigation_app.dart`, `lib/app/router/app_router.dart`, `lib/app/router/route_names.dart`, `lib/features/notifications/**`, `lib/features/feed/**`, `lib/features/map/**`, `lib/shared/models/academic_models.dart`, `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`, `ios/Runner/Info.plist`, `ios/Runner/AppDelegate.swift`, `assets/data/buildings.json`.
- Verification: Pending until the Supabase edge functions, repository docs, tests, and full check suite are completed.
- Follow-ups: Add Supabase `notify` and `maps-routes` functions, account for missing native Firebase service files in docs/setup, then run `flutter analyze`, `flutter test`, and `scripts/check.sh --quick`.
