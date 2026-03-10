# Syllabus Sync Flutter — Agent Rules

## Project Overview
Flutter mobile client for Syllabus Sync (Macquarie University campus management platform).
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
- Custom scheme: `io.syllabussync://callback`
- Android: Intent filters in AndroidManifest.xml + assetlinks.json (TODO: deploy)
- iOS: URL scheme in Info.plist + AASA file (TODO: deploy)

---

Raouf: 2026-03-10 (AEDT) — Initial
- Scope: Phase 0 + Phase 1 foundation sprint
- Created project scaffold, core architecture, theme, routing, l10n, CI/CD
- Files: 30+ files across lib/, test/, .github/
- Status: flutter analyze clean, 4/4 tests passing

Raouf: 2026-03-10 (AEDT) — Phase 0+1 Completion
- Scope: All Phase 0 inventories, full l10n (35 locales), building registry, deep links
- Added: 8 inventory docs, tools/convert_i18n.dart, 35 ARB locale files (1995 keys each)
- Added: Building entity model + cache data source, deep link config (Android + iOS)
- Wired: AppLocalizations delegates in SyllabusSyncApp
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
- Files changed: `lib/app/router/*`, `lib/app/syllabus_sync_app.dart`, `lib/shared/providers/auth_provider.dart`, `lib/shared/models/*`, `lib/core/utils/validators.dart`, `lib/features/auth/**`, `lib/features/profiles/**`, `lib/features/settings/**`, `lib/features/home/**`, `lib/features/calendar/**`, `test/app/route_guard_test.dart`, `test/features/auth/**`, `test/features/home/**`, `test/features/calendar/**`, `README.md`, `route_matrix.md`.
- Verification: `flutter analyze` → no issues, `flutter test` → 91/91 passing, `scripts/check.sh --quick` → all 5 checks passed.
- Follow-ups: detail routes for unit/deadline/event pages can be expanded further if the product wants dedicated screens beyond the new in-place editors; map/feed phases remain separate milestones.

Raouf: 2026-03-11 (AEDT) — Context7 Audit for Phase 2 + Phase 3
- Scope: Re-audited the migrated auth/profile/settings/dashboard/calendar slices against current Flutter, go_router, and Supabase guidance fetched via Context7.
- Summary: Confirmed the overall Phase 2 and Phase 3 architecture is aligned with current docs: `MaterialApp.router`, async `go_router` redirects, `refreshListenable`, and Supabase auth event handling all remain valid. Fixed four resilience issues and two timeline correctness gaps found during the audit. Router auth guards now fail safely when Supabase MFA/profile checks error. Verify-email refresh now handles the no-session case instead of throwing. Google OAuth launch failures now surface a user-visible error. Biometric lock now recovers if device biometric support disappears after the setting is enabled. Calendar timeline entries are now constrained to the focused week and exclude undated todos from agenda/day/week views. Anonymous users now leave `/splash` once loading completes.
- Files changed: `lib/app/router/app_router.dart`, `lib/app/router/route_guard.dart`, `lib/features/auth/data/repositories/auth_repository.dart`, `lib/features/auth/presentation/controllers/auth_flow_controller.dart`, `lib/features/auth/presentation/pages/verify_email_page.dart`, `lib/features/auth/presentation/widgets/biometric_lock_gate.dart`, `lib/features/calendar/presentation/controllers/calendar_controller.dart`, `lib/shared/models/academic_models.dart`, `test/app/route_guard_test.dart`, `test/features/auth/auth_flow_controller_test.dart`, `test/features/calendar/calendar_state_test.dart`.
- Verification: `flutter analyze` → no issues, `flutter test` → 94/94 passing, `scripts/check.sh --quick` → all 5 checks passed.
- Follow-ups: upstream `origin/main` still needs a safe history reconciliation because the root branch has diverged into the `MQ_Navigation` tree while this work remains under `syllabus-sync_flutter`.

Raouf: 2026-03-11 (AEDT) — Repository Cleanup After Merge
- Scope: Remove the unrelated `MQ_Navigation` tree from the parent repository so the Syllabus Sync Flutter app remains the only active mobile app in the shared repo.
- Summary: Cleaned the parent repository after the upstream merge by deleting `MQ_Navigation`, keeping `syllabus-sync_flutter` as the authoritative Flutter codebase, and restoring the root documentation paths to this app.
- Files changed: parent repo root `README.md`, root git tree (removed `../MQ_Navigation/**`).
- Verification: root repository now retains `syllabus-sync_flutter` as the only Flutter app directory.
- Follow-ups: none.

Raouf: 2026-03-11 (AEDT) — Phase 0 Gap Closure: Edge Functions + Fastlane
- Scope: Close the two remaining Phase 0 gaps found during the full blueprint audit — Supabase Edge Functions scaffold and Fastlane distribution config.
- Summary: Created the complete Supabase Edge Functions scaffold with 7 production-ready Deno functions matching the endpoint inventory: auth-email (Resend email verification), auth-cleanup (expired token cleanup), routes-proxy (Google Routes API), places-proxy (Google Places API), weather-proxy (Google Weather API), security-utils (HIBP password breach check), cleanup-cron (rate-limit/audit log cleanup). All functions include CORS support, error handling, and cron-secret verification where needed. Created Fastlane configs for both Android (build_debug, build_release, deploy_internal, promote_beta) and iOS (build_debug, build_release, deploy_testflight, promote_appstore) with --dart-define env var injection.
- Files created: `supabase/config.toml`, `supabase/functions/_shared/cors.ts`, `supabase/functions/auth-email/index.ts`, `supabase/functions/auth-cleanup/index.ts`, `supabase/functions/routes-proxy/index.ts`, `supabase/functions/places-proxy/index.ts`, `supabase/functions/weather-proxy/index.ts`, `supabase/functions/security-utils/index.ts`, `supabase/functions/cleanup-cron/index.ts`, `android/Gemfile`, `android/fastlane/Appfile`, `android/fastlane/Fastfile`, `ios/Gemfile`, `ios/fastlane/Appfile`, `ios/fastlane/Fastfile`.
- Verification: `flutter analyze` → no issues, `flutter test` → 94/94 passing, `scripts/check.sh --quick` → all 5 checks passed.
- Follow-ups: Deploy AASA + assetlinks.json to web domain; configure Apple/Google developer account credentials in CI secrets for Fastlane.
