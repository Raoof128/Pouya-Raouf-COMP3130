# Changelog

All notable changes to the MQ Navigation Flutter app.

## [Unreleased]

### Pouya: 2026-03-11 — Project Cleanup

**Scope:** Remove references to unimplemented features, align documentation with actual project state.

**Summary:**
Cleaned up all documentation to accurately reflect the shipped Open Day navigation app. Removed references to calendar, feed, notifications, MFA, gamification, and other features from the original web app that were never built in Flutter. Updated all inventory docs, architecture docs, and README to match the actual 3-tab (Home, Map, Settings) navigation-focused app.

**Files deleted:**
- `notification_matrix.md` — no push/local notifications exist

**Files updated:**
- `route_matrix.md` — reduced to actual 6 routes, 3-tab shell
- `AGENT.md` — updated directory structure, constraints, env vars
- `CHANGELOG.md` — cleaned up history
- `docs/ARCHITECTURE.md` — corrected to 3-tab shell, 4 features
- `entity_inventory.md` — reduced to tables actually used
- `endpoint_inventory.md` — reduced to endpoints actually called
- `env_inventory.md` — corrected client/server var placement, removed FCM
- `auth_matrix.md` — rewritten for guest-mode Open Day auth
- `map_inventory.md` — removed unused packages, corrected ORS usage
- `CONTRIBUTING.md` — minor example fixes
- `README.md` — removed calendar/feed from architecture listing
- `SECURITY.md` — removed unimplemented security features

---

### Raouf: 2026-03-10 (AEDT) — Context7 Docs Compliance Fixes

**Scope:** Compare codebase against latest 2026 Flutter/Riverpod/GoRouter/Supabase/local_auth docs via Context7; fix deviations.

**Summary:**
Fetched latest documentation for Flutter, Riverpod 3, GoRouter 17, Supabase Flutter, and local_auth 3 via Context7 MCP. Compared all patterns against our code. Found 3 deviations from the Flutter error handling docs: missing `PlatformDispatcher.instance.onError` (Layer 2 error catcher), missing `ErrorWidget.builder` customisation in MaterialApp, and missing `FlutterError.presentError` call for debug console output. All other patterns (ColorScheme.fromSeed, NavigationBar, AsyncNotifier, ref.listen/read/watch, refreshListenable, StatefulShellRoute, PKCE auth, onAuthStateChange, biometric API) confirmed correct.

**Files changed:**
- `lib/core/error/error_boundary.dart` — Added `PlatformDispatcher.instance.onError` (Layer 2) + `FlutterError.presentError` call
- `lib/app/mq_navigation_app.dart` — Added `MaterialApp.builder` with custom `ErrorWidget.builder`

---

### Raouf: 2026-03-10 (AEDT) — Production-Grade Audit & Polish

**Scope:** Comprehensive audit fixing critical bugs, adding professional docs, hardening configs.

**Summary:**
Full production-grade audit identified and fixed 14 code issues. Added professional documentation suite (README, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, ARCHITECTURE). Hardened analysis_options.yaml with 20+ lint rules.

**Key fixes:**
- EnvConfig.validate() now throws StateError in all build modes
- GoRouter uses single stable instance with AuthRefreshNotifier
- ErrorBoundary mounted in widget tree
- Nav bar labels localised via AppLocalizations
- Building entity has ==/hashCode
- MqTheme uses NavigationBarTheme
- Result<T> removed unsafe getters
- pubspec.yaml pinned all `any` deps

---

### Raouf: 2026-03-10 (AEDT) — Comprehensive Test Suite & Check Script

**Scope:** 78 unit/widget tests + scripts/check.sh.

**Summary:**
Created test suite covering theme tokens, env config, exceptions, Result type, route names, Building entity, and shared widgets (MqButton, MqCard, MqInput). Built `scripts/check.sh` mirroring the web app's `npm run check`.

---

### Raouf: 2026-03-10 (AEDT) — Phase 0+1 Completion Pass

**Scope:** All Phase 0 inventories, full l10n (35 locales), building registry, deep links.

**Summary:**
Created 8 inventory documents, built JSON→ARB conversion tool, converted 35 locales (1995 keys each). Created Building entity model and cached data source. Configured deep link intent filters for Android and iOS.

---

### Raouf: 2026-03-10 (AEDT) — Phase 0 + Phase 1 Foundation Sprint

**Scope:** Full project scaffold, core architecture, MQ theme, routing shell, l10n setup, CI/CD pipeline, shared widgets, security services.

**Summary:**
Created feature-first project structure, wired Supabase bootstrap with --dart-define env config, built MQ design system, set up go_router with StatefulShellRoute bottom navigation (3 tabs: Home, Map, Settings), implemented auth guard + splash resolver, and created core infrastructure services.
