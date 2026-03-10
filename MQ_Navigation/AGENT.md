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
