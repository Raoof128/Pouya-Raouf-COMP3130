# Changelog

All notable changes to the MQ Navigation Flutter app.

## [Unreleased]

### Raouf: 2026-03-11 (AEDT) — Full Project Rename: Syllabus Sync → MQ Navigation

**Scope:** Rename every reference across the entire codebase from "Syllabus Sync" to "MQ Navigation".

**Summary:**
Renamed all name variants across the full project: Dart package name (`syllabus_sync` → `mq_navigation`), main app class (`SyllabusSyncApp` → `MqNavigationApp`), Android/iOS bundle identifiers (`io.syllabussync.*` → `io.mqnavigation.*`), URL schemes (`io.syllabussync://` → `io.mqnavigation://`), display name in all 35 ARB locale files, UI hardcoded strings, Edge Function email subjects, documentation, and platform config files. Renamed the main app file from `syllabus_sync_app.dart` to `mq_navigation_app.dart`. Regenerated Flutter l10n. Preserved external URLs pointing to the web app's GitHub repo and Vercel deployment. Renamed the project folder from `syllabus-sync_flutter` to `mq_navigation`.

**Files changed:**
- 300+ files across all categories:
  - All Dart source and test files (`package:syllabus_sync/` → `package:mq_navigation/`)
  - `lib/app/syllabus_sync_app.dart` → `lib/app/mq_navigation_app.dart` (file rename)
  - `pubspec.yaml` — package name
  - `android/app/build.gradle.kts` — namespace + applicationId
  - `android/fastlane/Appfile` — package name
  - `ios/Runner/Info.plist` — bundle name, URL scheme, usage descriptions
  - `ios/fastlane/Appfile` — app identifier
  - `supabase/config.toml` — project ID, redirect URIs
  - `supabase/functions/auth-email/index.ts` — email subject lines
  - 35 ARB locale files — display name references
  - All `.md` documentation files
  - Platform configs: `CMakeLists.txt`, `manifest.json`, `index.html`, `.xcscheme`, `.pbxproj`, `.xcconfig`, `Runner.rc`, `.cc`, `.cpp`

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 99/99 passed
- Zero remaining old-name references in source/config files (only external web app URLs preserved)

**Follow-ups:**
- Commit and push
- If the sibling web app folder is also renamed, update `tools/convert_i18n.dart` path

### Raouf: 2026-03-11 (AEDT) — Updated Migration Plan Document

**Scope:** Create a comprehensive Flutter Migration Plan document reflecting the actual completed state of all phases 0–5.

**Summary:**
Built a full migration plan document (`Flutter_Migration_Plan.md`) aligned with the user's provided template format. The document covers the current state of both the web and mobile apps, the two-frontends-one-backend architecture, the complete tech stack with pinned dependencies, full project structure with feature-first clean architecture, navigation and route maps with cascading auth guards, detailed feature breakdown with Pouya/Raouf ownership across all 5 implementation phases, the 9-function Edge Functions inventory, i18n details (35 ARB locales with RTL support), the security model, environment configuration for both client and server, CI/CD pipeline (GitHub Actions + Fastlane), testing summary (99 tests across 15 files), team contributions, external deployment prerequisites, and how-to-run instructions.

**Files created:**
- `Flutter_Migration_Plan.md`

**Verification:**
- `flutter analyze --no-fatal-infos` → 0 issues
- `flutter test` → 99/99 passed

**Follow-ups:**
- Commit and push the migration plan document

### Raouf: 2026-03-11 (AEDT) — Final Stage Verification + Release Handoff

**Scope:** Close verification for the last Phase 4/5 patch and document what remains outside the repo.

**Summary:**
Verified the completed Phase 4/5 implementation after the final native Firebase, localization, and typed map-error patch. Android now builds cleanly with conditional Google Services activation, iOS safely configures Firebase only when the service plist exists, notification/detail UI strings resolve through ARB-backed localization, and the map page now routes failures through typed `MapStateError` values instead of English sentinel strings. The only remaining gaps are external deployment prerequisites: real `android/app/google-services.json`, real `ios/Runner/GoogleService-Info.plist`, APNs/FCM console setup, Google Cloud key restrictions, Supabase Edge Function secrets, and deployment of `notify` / `maps-routes`.

**Files changed:**
- `AGENT.md`
- `CHANGELOG.md`

**Verification:**
- `flutter analyze --no-fatal-infos` → no issues
- `flutter test` → 99/99 passed
- `./scripts/check.sh` → 6/6 checks passed, including debug APK build
- `deno check supabase/functions/maps-routes/index.ts` → passed
- `deno check supabase/functions/notify/index.ts` → passed
- `deno check supabase/functions/cleanup-cron/index.ts` → passed

**Follow-ups:**
- Commit and push the completed Phase 4/5 repo state to `origin/main`
- Apply Firebase, Supabase, and Google Cloud secrets/configuration in the target environments

### Raouf: 2026-03-11 (AEDT) — Phase 4 + Phase 5 Runtime Stabilization

**Scope:** Resolve the first client runtime gaps found after the initial feed/notifications/map implementation pass.

**Summary:**
Normalized notification preferences so partially populated `notification_preferences` rows no longer break toggle updates, hardened notification/map JSON parsing and route-coordinate validation, and fixed feed pagination ordering so cursor-based pagination remains stable instead of reordering featured items ahead of the cursor. Added concrete `/detail/deadline/:deadlineId`, `/detail/exam/:examId`, and `/detail/event/:eventId` routes plus repository-backed academic item detail pages so notification deep links now land on real Flutter screens rather than unresolved paths. Also removed the last map analyze warning and replaced a small set of hardcoded map action labels with existing localized strings.

**Files changed:**
- `lib/features/notifications/domain/entities/notification_preferences.dart`
- `lib/features/notifications/data/datasources/notification_remote_source.dart`
- `lib/features/notifications/domain/entities/app_notification.dart`
- `lib/features/feed/data/repositories/feed_repository.dart`
- `lib/features/map/domain/entities/building.dart`
- `lib/features/map/data/datasources/google_routes_remote_source.dart`
- `lib/features/map/presentation/pages/map_page.dart`
- `lib/features/map/presentation/widgets/campus_map_view.dart`
- `lib/features/map/presentation/widgets/route_panel.dart`
- `lib/features/calendar/data/repositories/calendar_repository.dart`
- `lib/features/calendar/presentation/pages/academic_item_detail_page.dart`
- `lib/app/router/app_router.dart`

**Verification:**
- Pending final analyze/test pass after the server functions, docs, and tests are added in this same implementation cycle.

### Raouf: 2026-03-11 (AEDT) — Phase 4 + Phase 5 Edge Functions

**Scope:** Add the Supabase server-side implementation required by the new Flutter notification and map flows.

**Summary:**
Added a dedicated `maps-routes` Edge Function for the Flutter map stack with authenticated Google Routes proxying, strict request validation, and per-user `rate_limits` throttling at 60 requests per minute. Added a new `notify` Edge Function that validates the caller, writes the inbox record to `notifications`, dispatches push notifications through Firebase using server-side credentials, and removes stale `user_fcm_tokens` on push failures. Also corrected the existing cleanup cron so rate-limit cleanup now targets the documented `reset_time_ms` column instead of the stale `window_end` name, and registered both new functions in `supabase/config.toml`.

**Files changed:**
- `supabase/functions/maps-routes/index.ts`
- `supabase/functions/notify/index.ts`
- `supabase/functions/cleanup-cron/index.ts`
- `supabase/config.toml`

**Verification:**
- Pending final repo-wide verification after the Phase 4/5 tests and documentation updates are completed.

### Raouf: 2026-03-11 (AEDT) — Edge Function TypeScript Cleanup

**Scope:** Correct the first-pass TypeScript issues in the new `notify` function before verification.

**Summary:**
Replaced invalid Dart-style array helpers in `supabase/functions/notify/index.ts` with standard TypeScript collection methods, made FCM v1 response parsing tolerant of non-JSON upstream error bodies, and tightened the remaining equality check so the new push dispatcher can be formatted and validated cleanly.

**Files changed:**
- `supabase/functions/notify/index.ts`

**Verification:**
- Pending function formatting and the final repo-wide verification pass.

### Raouf: 2026-03-11 (AEDT) — Phase 5 Registry + Regression Tests

**Scope:** Replace the temporary map asset with the audited web registry and add regression coverage for the new Phase 4/5 behavior.

**Summary:**
Regenerated `assets/data/buildings.json` from the sibling web app's `features/map/lib/buildings.ts` source so Flutter now bundles the full 153-building campus registry instead of a temporary sample list. The generated asset preserves the six audited `entranceLocation` and `googlePlaceId` enrichments and fills missing marker coordinates from the calibrated pixel map data so the MVP map can render the whole campus. Added targeted tests for notification preference normalization and stable reminder scheduling, feed-import event persistence through `source_public_event_id`, map route parsing, `/notifications` route constants, and an asset-level guard that fails if the bundled building registry drops below full campus scale.

**Files changed:**
- `assets/data/buildings.json`
- `test/app/route_names_test.dart`
- `test/features/home/academic_models_test.dart`
- `test/features/notifications/notification_scheduler_test.dart`
- `test/features/map/map_route_test.dart`
- `test/features/map/building_registry_asset_test.dart`

**Verification:**
- Pending final repo-wide analyze/test/check pass after the documentation updates are completed.

### Raouf: 2026-03-11 (AEDT) — Phase 4 + Phase 5 Documentation Alignment

**Scope:** Bring the repository documentation and inventories in line with the implemented notifications, feed, and map stack.

**Summary:**
Updated the README with the delivered Phase 4/5 scope, the required mobile Firebase/Maps setup steps, and the Edge Function secret inventory for `notify` and `maps-routes`. Expanded `docs/ARCHITECTURE.md` with concrete subsystem notes for notifications/feed/map, corrected `env_inventory.md` to match the removed client-side Maps key fallback and the preferred Firebase service-account secret, and refreshed the endpoint, notification, map, and route inventories so they describe the implemented `/notifications`, `/detail/...`, `notify`, and `maps-routes` flows rather than the older placeholders. Also updated the stale `EnvConfig` test that still expected a committed debug Google Maps key fallback.

**Files changed:**
- `README.md`
- `docs/ARCHITECTURE.md`
- `env_inventory.md`
- `endpoint_inventory.md`
- `notification_matrix.md`
- `map_inventory.md`
- `route_matrix.md`
- `test/core/env_config_test.dart`

**Verification:**
- Pending the final analyze/test/check pass.

### Raouf: 2026-03-11 (AEDT) — Phase 4 + Phase 5 Final Verification

**Scope:** Close the implementation cycle with repo-wide validation.

**Summary:**
Verified the completed Phase 4/5 pass end-to-end. `flutter analyze --no-fatal-infos` returned 0 issues, `flutter test` passed 99/99 tests including the new notification/map regressions and building-registry asset guard, `scripts/check.sh --quick` passed all 5 checks, and `deno check` succeeded for `supabase/functions/maps-routes`, `supabase/functions/notify`, and `supabase/functions/cleanup-cron`.

**Files changed:**
- `AGENT.md`
- `CHANGELOG.md`

**Verification:**
- Complete.

### Raouf: 2026-03-11 (AEDT) — Final Stage Gap Closure

**Scope:** Finish the remaining concrete Phase 4/5 implementation gaps before commit.

**Summary:**
Added the missing native Firebase activation hooks so Android now auto-applies the Google Services plugin when `android/app/google-services.json` exists and iOS now configures Firebase automatically when `GoogleService-Info.plist` is present. Replaced the remaining hardcoded notification/detail strings with ARB-backed localization usage, and replaced map error sentinel strings with a typed `MapStateError` flow so the map UI no longer relies on English string comparisons for routing or location failures.

**Files changed:**
- `android/settings.gradle.kts`
- `android/app/build.gradle.kts`
- `ios/Runner/AppDelegate.swift`
- `lib/app/l10n/app_en.arb`
- `lib/features/notifications/presentation/widgets/notification_tile.dart`
- `lib/features/notifications/presentation/pages/notifications_page.dart`
- `lib/features/calendar/presentation/pages/academic_item_detail_page.dart`
- `lib/features/map/presentation/controllers/map_controller.dart`
- `lib/features/map/presentation/pages/map_page.dart`
- `README.md`

**Verification:**
- Pending final analyze/test/build pass for this closing patch.

### Raouf: 2026-03-11 (AEDT) — Phase 4 + Phase 5 Implementation

**Scope:** Notifications foundation, feed implementation, map MVP implementation, mobile notification/bootstrap wiring, and native map SDK setup for the Phase 4/5 implementation pass.

**Summary:**
Added the first production notification slice: Firebase bootstrap registration, Android/iOS mobile notification permission hooks, local notification channels and scheduling services, Supabase-backed notification inbox/preferences data sources, a Riverpod notifications controller, and the `/notifications` route/page. Also resolved the first integration issues found by `flutter analyze` (`FirebaseMessaging` bootstrap import, the required `uiLocalNotificationDateInterpretation` scheduling parameter, and the feed query `DateTimeRange` import), replaced the placeholder feed screen with a Supabase-backed events/announcements feed plus filter/search/pagination and calendar-import wiring, replaced the placeholder map screen with a repository/controller/widget stack covering building registry loading, building search, location permission handling, Google Maps rendering, routing, and `/map/building/:id` deep links, and removed the committed Dart Google Maps dev key so the implementation depends on explicit client build configuration rather than a source-controlled key.

**Files changed:**
- `pubspec.yaml`
- `lib/core/config/env_config.dart`
- `lib/app/bootstrap/bootstrap.dart`
- `lib/app/mq_navigation_app.dart`
- `lib/app/router/app_router.dart`
- `lib/app/router/route_names.dart`
- `lib/features/notifications/**`
- `lib/features/feed/**`
- `lib/features/map/**`
- `lib/shared/models/academic_models.dart`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`
- `ios/Runner/Info.plist`
- `ios/Runner/AppDelegate.swift`
- `assets/data/buildings.json`

**Verification:**
- Pending until the edge functions, tests, docs, and full check suite are complete in this same pass.

**Follow-ups:**
- Add the `notify` and `maps-routes` Supabase Edge Functions
- Document the required native Firebase service files and APNs setup
- Run `flutter analyze`, `flutter test`, and `scripts/check.sh --quick`

### Raouf: 2026-03-11 (AEDT) — Phase 0 Gap Closure: Edge Functions + Fastlane

**Scope:** Close the two remaining Phase 0 blueprint gaps — Supabase Edge Functions scaffold and Fastlane distribution config — identified during a full Phases 0–3 audit.

**Summary:**
Created the complete Supabase Edge Functions scaffold with 7 production-ready Deno functions matching the endpoint inventory: `auth-email` (Resend-based email verification send/resend/verify), `auth-cleanup` (expired password-reset and email-verification token cleanup), `routes-proxy` (Google Routes API proxy keeping billing key server-side), `places-proxy` (Google Places API search and detail proxy), `weather-proxy` (Google Weather API proxy for campus conditions), `security-utils` (Have I Been Pwned k-anonymity password breach check), and `cleanup-cron` (rate-limit and audit-log retention cleanup). All functions include shared CORS headers, structured error handling, and cron-secret verification where applicable.

Created Fastlane configs for both platforms: Android lanes (`build_debug`, `build_release`, `deploy_internal`, `promote_beta`) and iOS lanes (`build_debug`, `build_release`, `deploy_testflight`, `promote_appstore`), both with `--dart-define` environment variable injection for Supabase and Google Maps keys.

**Files created:**
- `supabase/config.toml` — Supabase project config with auth, redirect URLs, and per-function JWT settings
- `supabase/functions/_shared/cors.ts` — Shared CORS headers and OPTIONS handler
- `supabase/functions/auth-email/index.ts` — Email verification via Resend API
- `supabase/functions/auth-cleanup/index.ts` — Expired token cleanup (cron)
- `supabase/functions/routes-proxy/index.ts` — Google Routes API proxy
- `supabase/functions/places-proxy/index.ts` — Google Places API proxy
- `supabase/functions/weather-proxy/index.ts` — Google Weather API proxy
- `supabase/functions/security-utils/index.ts` — HIBP password breach check
- `supabase/functions/cleanup-cron/index.ts` — Rate-limit and audit-log cleanup (cron)
- `android/Gemfile` — Fastlane Ruby dependency
- `android/fastlane/Appfile` — Android package name config
- `android/fastlane/Fastfile` — Android build and deploy lanes
- `ios/Gemfile` — Fastlane Ruby dependency
- `ios/fastlane/Appfile` — iOS app identifier config
- `ios/fastlane/Fastfile` — iOS build and deploy lanes

**Verification:**
- `flutter analyze` → No issues found
- `flutter test` → 94/94 tests passed
- `scripts/check.sh --quick` → 5/5 checks passed

**Follow-ups:**
- Deploy AASA + assetlinks.json to web domain for universal link verification
- Configure Apple/Google developer account credentials in CI secrets for Fastlane
- Set Supabase Edge Function secrets via `supabase secrets set`

---

### Raouf: 2026-03-11 (AEDT) — Remove Unrelated MQ_Navigation Tree

**Scope:** Clean the parent repository so `mq-navigation_flutter` remains the sole active Flutter application after the earlier history merge.

**Summary:**
Removed the unrelated `MQ_Navigation` directory from the repository root and restored the root documentation to point back to `mq-navigation_flutter` as the primary mobile app. No application logic inside `mq-navigation_flutter` was changed in this cleanup.

**Files changed:**
- Parent repo `README.md` — restored project paths to `mq-navigation_flutter`
- Parent repo git tree — removed `MQ_Navigation/**`

**Verification:**
- Root repository tree confirms `mq-navigation_flutter` is the only remaining Flutter app directory

---

### Raouf: 2026-03-11 (AEDT) — Context7 Audit Hardening for Phase 2 + Phase 3

**Scope:** Re-audit the completed Phase 2 and Phase 3 migration slices against current Flutter, go_router, and Supabase docs fetched via Context7, then correct any concrete deviations.

**Summary:**
Confirmed that the project’s core 2026 patterns are still correct: `MaterialApp.router`, `ErrorWidget.builder`, async `go_router` redirects, `refreshListenable`, and Supabase `onAuthStateChange` usage match current guidance. Tightened the implementation in the places where the audit found real runtime risks.

Auth routing now handles upstream Supabase failures safely by logging and falling back instead of throwing from the router redirect. Email verification refresh now guards the no-session state so the action does not fail before the verification deep link completes. Google OAuth sign-in now reports browser-launch failures instead of silently acting like the flow started. Biometric unlock now recovers when biometric support disappears after the preference was enabled by bypassing the lock for the session and turning the setting off. Calendar timeline state also now excludes undated or out-of-range to-dos and events from agenda/day/week views, and anonymous users now leave `/splash` for `/login` once auth loading completes.

**Files changed:**
- `lib/app/router/app_router.dart` — wrapped async MFA/profile guard reads with safe error handling
- `lib/app/router/route_guard.dart` — corrected post-loading anonymous redirect behavior from splash
- `lib/features/auth/data/repositories/auth_repository.dart` — surfaced Google OAuth launch failure as an app exception
- `lib/features/auth/presentation/controllers/auth_flow_controller.dart` — returned app exception messages to the UI
- `lib/features/auth/presentation/pages/verify_email_page.dart` — guarded verification refresh when no session exists yet
- `lib/features/auth/presentation/widgets/biometric_lock_gate.dart` — handled unsupported biometrics without leaving the app stuck behind the lock overlay
- `lib/features/calendar/presentation/controllers/calendar_controller.dart` — constrained timeline entries to the focused week
- `lib/shared/models/academic_models.dart` — excluded undated to-dos from `CalendarEntry` timelines
- `test/app/route_guard_test.dart` — added anonymous splash redirect coverage
- `test/features/auth/auth_flow_controller_test.dart` — added Google OAuth launch failure coverage
- `test/features/calendar/calendar_state_test.dart` — added undated/out-of-range to-do timeline coverage

**Verification:**
- `flutter analyze` → No issues found
- `flutter test` → 94/94 tests passed
- `scripts/check.sh --quick` → 5/5 checks passed (All checks passed!)

---

### Raouf: 2026-03-11 (AEDT) — Phase 2 + Phase 3 Delivery

**Scope:** Implement the migration blueprint’s mobile auth/profile/settings stack and home/calendar core inside the Flutter client.

**Summary:**
Replaced the placeholder Phase 2 experience with production-backed routes and screens for login, signup, email verification, password reset, MFA challenge/enrollment, onboarding, profile editing, and settings management. Added Supabase-backed repositories and Riverpod controllers for auth, profile, user preferences, and MFA state. Wired app-level theme, locale, and biometric lock behavior into `MaterialApp.router` and routing guards.

Replaced the placeholder Phase 3 experience with a repository-backed dashboard and calendar. Added shared academic models for units, deadlines, events, todos, gamification, dashboard stress metrics, and calendar entries. Implemented agenda/day/week calendar views, unit filters, quick-add/edit/delete sheets for deadlines, exams, events, and todos, plus dashboard cards for deadlines, events, units, XP, streaks, and workload pressure.

**Files changed:**
- `lib/app/router/app_router.dart` and `lib/app/router/route_guard.dart` — Added Phase 2 routes and multi-step auth/onboarding/MFA recovery guards
- `lib/app/mq_navigation_app.dart` — Wired settings-driven theme/locale plus biometric app lock overlay
- `lib/shared/providers/auth_provider.dart` — Added auth event tracking for password recovery and router refreshes
- `lib/shared/models/*` — Added profile, preference, and academic domain models
- `lib/core/utils/validators.dart` — Added reusable form validation helpers
- `lib/features/auth/**` — Added auth repository, controllers, reusable scaffold, biometric lock gate, and real auth pages
- `lib/features/profiles/**` — Added profile repository, controller, and edit/onboarding page
- `lib/features/settings/**` — Added settings repository, controller, and settings shell implementation
- `lib/features/home/**` — Added dashboard repository/controller and production dashboard page
- `lib/features/calendar/**` — Added calendar repository/controller and production calendar page with CRUD editors
- `test/app/route_guard_test.dart` — Added redirect/guard coverage
- `test/features/auth/auth_flow_controller_test.dart` — Added auth controller coverage
- `test/features/home/academic_models_test.dart` — Added dashboard/stress/gamification model coverage
- `test/features/calendar/calendar_state_test.dart` — Added calendar state/filter coverage
- `README.md` and `route_matrix.md` — Updated migration status to reflect completed Phase 2 and Phase 3 core slices

**Verification:**
- `flutter analyze` → No issues found
- `flutter test` → 91/91 tests passed
- `scripts/check.sh --quick` → 5/5 checks passed (All checks passed!)

---

### Raouf: 2026-03-10 (AEDT) — Context7 Docs Compliance Fixes

**Scope:** Compare codebase against latest 2026 Flutter/Riverpod/GoRouter/Supabase/local_auth docs via Context7; fix deviations.

**Summary:**
Fetched latest documentation for Flutter, Riverpod 3, GoRouter 17, Supabase Flutter, and local_auth 3 via Context7 MCP. Compared all patterns against our code. Found 3 deviations from the Flutter error handling docs: missing `PlatformDispatcher.instance.onError` (Layer 2 error catcher), missing `ErrorWidget.builder` customisation in MaterialApp, and missing `FlutterError.presentError` call for debug console output. All other patterns (ColorScheme.fromSeed, NavigationBar, AsyncNotifier, ref.listen/read/watch, refreshListenable, StatefulShellRoute, PKCE auth, onAuthStateChange, biometric API) confirmed correct.

**Files changed:**
- `lib/core/error/error_boundary.dart` — Added `PlatformDispatcher.instance.onError` (Layer 2) + `FlutterError.presentError` call
- `lib/app/mq_navigation_app.dart` — Added `MaterialApp.builder` with custom `ErrorWidget.builder`

**Verification:**
- `flutter analyze` -> No issues found
- `flutter test` -> 78/78 tests passed
- 12/12 patterns confirmed matching latest 2026 docs

---

### Raouf: 2026-03-10 (AEDT) — Production-Grade Audit & Polish

**Scope:** Comprehensive audit fixing critical bugs, adding professional docs, hardening configs.

**Summary:**
Full production-grade audit identified and fixed 14 code issues: EnvConfig.validate() now throws StateError in release builds (was assert-only, invisible in production); GoRouter rebuilt to use a single stable instance with AuthRefreshNotifier/refreshListenable pattern (was recreating on every auth state change, destroying navigator); ErrorBoundary now mounted in widget tree; debugLogDiagnostics gated behind isDevelopment; ConnectivityService performs initial check on construction; MFA check logs errors instead of silent catch; biometric service removed deprecated param; nav bar labels localised; login page uses MqInput; Building entity has ==/hashCode; MqTheme switched from dead BottomNavigationBarTheme to NavigationBarTheme; Result<T> unsafe getters removed; splash magic numbers replaced with tokens; pubspec pinned all `any` deps.

Added full professional documentation suite: README.md, LICENSE (MIT), CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, docs/ARCHITECTURE.md. Hardened analysis_options.yaml with 20+ lint rules. Added .editorconfig, .vscode/settings.json, .vscode/extensions.json.

**Files created:**
- `README.md` — comprehensive project documentation with tech stack, setup, design system
- `LICENSE` — MIT License
- `CONTRIBUTING.md` — contribution guidelines, branch naming, commit conventions
- `CODE_OF_CONDUCT.md` — Contributor Covenant v2.1
- `SECURITY.md` — security policy, vulnerability reporting, security practices
- `docs/ARCHITECTURE.md` — full system architecture, state management, routing, design system
- `.editorconfig` — editor-agnostic formatting rules
- `.vscode/settings.json` — VS Code workspace settings
- `.vscode/extensions.json` — recommended extensions

**Files changed:**
- `lib/core/config/env_config.dart` — assert() -> StateError throws in all build modes
- `lib/app/router/app_router.dart` — stable GoRouter with AuthRefreshNotifier
- `lib/app/router/app_shell.dart` — localised nav bar labels
- `lib/app/bootstrap/bootstrap.dart` — ErrorBoundary wrapping widget tree
- `lib/core/network/connectivity_service.dart` — initial check() on construction
- `lib/shared/providers/auth_provider.dart` — MFA error logging, AuthRefreshNotifier, doc comments
- `lib/core/security/biometric_service.dart` — removed persistAcrossBackgrounding
- `lib/features/auth/presentation/pages/splash_page.dart` — MqSpacing tokens
- `lib/features/auth/presentation/pages/login_page.dart` — MqInput, const constructors
- `lib/features/map/domain/entities/building.dart` — @immutable, ==/hashCode
- `lib/app/theme/mq_theme.dart` — NavigationBarTheme, const fixes
- `lib/core/utils/result.dart` — removed unsafe .value/.error getters
- `pubspec.yaml` — pinned intl ^0.20.2, geolocator ^13.0.0, flutter_local_notifications ^18.0.0
- `analysis_options.yaml` — hardened with prefer_const, unawaited_futures, prefer_final_locals, etc.
- `test/core/result_test.dart` — adapted to Result API changes
- `test/app/mq_theme_test.dart` — removed unnecessary dart:ui import

**Verification:**
- `flutter analyze` -> No issues found
- `flutter test` -> 78/78 tests passed
- `scripts/check.sh --quick` -> 5/5 checks passed (All checks passed!)

---

### Raouf: 2026-03-10 (AEDT) — Comprehensive Test Suite & Check Script

**Scope:** Full test coverage for Phase 0+1 deliverables, CI-ready check script.

**Summary:**
Created comprehensive test suite covering all Phase 0+1 components: theme tokens (colors, spacing, typography, ThemeData), env config defaults, exception hierarchy, Result type, route name constants, Building entity model (JSON round-trips, search, routing), and shared widget tests (MqButton variants/loading/icons, MqCard tapping, MqInput obscure/disabled). Built `scripts/check.sh` mirroring the web app's `npm run check` (pub get → format:check → analyze → test → gen-l10n → build). All 78 tests pass, all 5 checks green.

**Files created/changed:**
- `test/widget_test.dart` — Theme token smoke tests (4 tests)
- `test/core/env_config_test.dart` — EnvConfig defaults (7 tests)
- `test/core/app_exception_test.dart` — Exception hierarchy (7 tests)
- `test/core/result_test.dart` — Result type switching (6 tests)
- `test/app/mq_theme_test.dart` — Colors, spacing, typography, theme (21 tests)
- `test/app/route_names_test.dart` — Route name constants (3 tests)
- `test/features/map/building_test.dart` — Building entity model (12 tests)
- `test/shared/mq_widgets_test.dart` — MqButton, MqCard, MqInput widget tests (18 tests)
- `scripts/check.sh` — Flutter check script (format, analyze, test, gen-l10n, build)

**Verification:**
- `flutter test` → 78/78 tests passed
- `scripts/check.sh --quick` → 5/5 checks passed (All checks passed!)

---

### Raouf: 2026-03-10 (AEDT) — Phase 0+1 Completion Pass

**Scope:** Close all Phase 0+1 gaps — inventories, full l10n, building registry, deep links.

**Summary:**
Audit revealed missing Phase 0 documentation and incomplete Phase 1 deliverables. Created all 8 required inventory documents from web app source data. Built JSON→ARB conversion script and converted all 35 locales (1995 keys each) with Handlebars→ICU interpolation fix and Dart reserved word handling. Wired l10n delegates into MqNavigationApp. Created Building entity model and cached data source. Configured deep link intent filters for Android and iOS (URL scheme + App Links).

**Files created/changed:**
- `entity_inventory.md` — 22 Supabase tables, 4 views, 20+ RPC functions
- `endpoint_inventory.md` — 58 API routes mapped to SDK/Edge Function
- `env_inventory.md` — Client/server/web-only env var catalogue
- `auth_matrix.md` — Auth state machine, route guards, deep link callbacks
- `notification_matrix.md` — Push/local flows, FCM lifecycle, channels, tap routing
- `route_matrix.md` — All web→Flutter route mappings
- `map_inventory.md` — Map APIs, keys, building registry schema, migration steps
- `key_inventory.md` — 35-locale translation key inventory
- `tools/convert_i18n.dart` — JSON→ARB converter (handles {{var}}→{var}, reserved words)
- `lib/app/l10n/app_*.arb` — 35 ARB locale files (1995 keys each)
- `lib/app/l10n/generated/*` — 36 generated Dart l10n classes
- `lib/app/mq_navigation_app.dart` — Wired localizationsDelegates + supportedLocales
- `lib/features/map/domain/entities/building.dart` — Building entity model
- `lib/features/map/data/datasources/building_registry_source.dart` — Cache data source
- `android/app/src/main/AndroidManifest.xml` — Deep link intent filters
- `ios/Runner/Info.plist` — URL scheme + permission descriptions

**Verification:**
- `flutter analyze` → No issues found
- `flutter test` → 4/4 tests passed
- `dart tools/convert_i18n.dart` → 35 locales converted successfully

---

### Raouf: 2026-03-10 (AEDT) — Phase 0 + Phase 1 Foundation Sprint

**Scope:** Full project scaffold, core architecture, MQ theme, routing shell, l10n setup, CI/CD pipeline, shared widgets, security services.

**Summary:**
Implemented Phase 0 (Foundation Sprint) and Phase 1 (App Shell) of the Flutter Migration Blueprint v3.0. Created the feature-first project structure, wired Supabase bootstrap with --dart-define env config, built the MQ design system (colors, typography, spacing from web tokens), set up go_router with StatefulShellRoute bottom navigation, implemented auth guard + splash resolver, and created core infrastructure services.

**Files created/changed:**
- `pubspec.yaml` — Core dependencies (supabase_flutter, flutter_riverpod, go_router, etc.)
- `l10n.yaml` — Localisation configuration
- `lib/main.dart` — App entry point
- `lib/app/bootstrap/bootstrap.dart` — Supabase init, ProviderScope, error handling
- `lib/app/mq_navigation_app.dart` — Root MaterialApp.router widget
- `lib/app/router/app_router.dart` — go_router with auth guards + shell
- `lib/app/router/app_shell.dart` — Bottom NavigationBar shell (5 tabs)
- `lib/app/router/route_names.dart` — Named route constants
- `lib/app/theme/mq_colors.dart` — MQ brand palette (red, alabaster, charcoal, etc.)
- `lib/app/theme/mq_typography.dart` — Work Sans / Source Serif Pro type scale
- `lib/app/theme/mq_spacing.dart` — Spacing & radius tokens
- `lib/app/theme/mq_theme.dart` — Light + dark ThemeData
- `lib/app/l10n/app_en.arb` — English ARB template (70+ keys)
- `lib/core/config/env_config.dart` — --dart-define environment config
- `lib/core/error/app_exception.dart` — Sealed exception hierarchy
- `lib/core/error/error_boundary.dart` — Widget error boundary + global handlers
- `lib/core/logging/app_logger.dart` — Structured logger wrapper
- `lib/core/network/connectivity_service.dart` — Connectivity monitor + Riverpod providers
- `lib/core/security/secure_storage_service.dart` — Encrypted key-value storage
- `lib/core/security/biometric_service.dart` — Biometric auth gate
- `lib/core/utils/result.dart` — Result<T> type (Success/Failure)
- `lib/shared/widgets/mq_button.dart` — MQ button (filled/outlined/text variants)
- `lib/shared/widgets/mq_card.dart` — MQ card with tap support
- `lib/shared/widgets/mq_input.dart` — MQ text input
- `lib/shared/widgets/mq_bottom_sheet.dart` — MQ modal bottom sheet
- `lib/shared/widgets/mq_app_bar.dart` — MQ app bar
- `lib/shared/providers/auth_provider.dart` — Auth state notifier (Supabase)
- `lib/shared/extensions/context_extensions.dart` — BuildContext convenience extensions
- `lib/features/auth/presentation/pages/splash_page.dart` — Splash screen
- `lib/features/auth/presentation/pages/login_page.dart` — Login placeholder
- `lib/features/home/presentation/pages/home_page.dart` — Dashboard placeholder
- `lib/features/calendar/presentation/pages/calendar_page.dart` — Calendar placeholder
- `lib/features/map/presentation/pages/map_page.dart` — Map placeholder
- `lib/features/feed/presentation/pages/feed_page.dart` — Feed placeholder
- `lib/features/settings/presentation/pages/settings_page.dart` — Settings shell
- `.github/workflows/ci.yml` — GitHub Actions CI (analyze, test, build Android/iOS)
- `test/widget_test.dart` — Theme token unit tests

**Verification:**
- `flutter analyze` → No issues found
- `flutter test` → 4/4 tests passed
- `flutter pub get` → 158 dependencies resolved

**Follow-ups:**
- Phase 2: Auth screens (login/signup wired to Supabase), profile, MFA, OAuth
- Convert all 35 locale JSON files to ARB format
- Configure Fastlane for store distribution
- Deploy AASA + assetlinks.json for deep links
- Add Supabase mobile redirect URLs
