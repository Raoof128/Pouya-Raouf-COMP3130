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

Summary: The project was built through phases 0–5, originally including auth, calendar, event feed, profile management, and gamification features. These were subsequently removed to focus the Flutter app on campus navigation: 3-tab nav (Home/Map/Settings), local-only settings, FCM push + study prompt notifications, and Google Maps with building search and routing via Edge Function proxy.

2026-03-12: Comprehensive audit fix batch — 30+ issues fixed across security (hardcoded keys removed, open redirect blocked), correctness (polyline decoder, didChangeDependencies→initState, location subscription leak, UTC timestamps), reliability (ErrorBoundary, Firebase background handler, HTTP timeout, onError handlers), and quality (MqColors tokens, MqAppBar, RouteNames, production log filter, variant-aware spinner, focusedErrorBorder). All tests pass (83/83), zero analyzer issues.

2026-03-12: Settings page redesign — Rewrote settings_page.dart to match HTML reference design. Dark charcoal surfaces (#12080A/#1C0D0F) with red glow gradient, uppercase red section headers with letter-spacing, rounded cards with white/5 borders, bottom-sheet pickers instead of inline dropdowns, custom toggle switches with vivid red (#FF0025) active track, branded about-app row with red shadow. Added vividRed/charcoal950/charcoal850 to MqColors. Light + dark mode support, RTL-compatible. 83/83 tests pass, zero analyzer issues.

2026-03-12: Flutter upgrade + i18n fix — upgraded Flutter 3.41.2→3.41.4, 4 major deps (flutter_local_notifications 18→21, connectivity_plus 6→7, geolocator 13→14, timezone 0.10→0.11). Fixed breaking API changes in local notifications (named params). Added 2 missing translation keys (studyPromptNotificationTitle/Body) to all 34 locale ARB files. 83/83 tests pass, zero analyzer issues, zero untranslated messages.

2026-03-12: Settings audit fix batch — 10 issues across 4 files. Critical: null locale picker regression fixed with _PickerItem wrapper. High: repository save errors now propagate (rethrow), controller reverts state on failure instead of AsyncError. Medium: retry button on error state, 48dp tap targets in picker, corrected Experience section l10n keys. Low: UserPreferences value equality, toggle row fully tappable, Semantics on info/about rows. 83/83 tests pass, zero analyzer issues.

Raouf:
2026-03-12: Technical explanation document added — created a full repository-level technical explanation covering runtime flow, architecture, feature modules, backend Edge Functions, platform integration, tooling, testing scope, and notable implementation-vs-documentation gaps. Files changed: `TECHNICAL_EXPLANATION.md`, `AGENT.md`, `CHANGELOG.md`. Verification: document reviewed for consistency against current codebase; no runtime code paths changed. Follow-ups: keep this document updated when routing architecture or feature scope changes.

Raouf:
2026-03-12: Technical explanation doc polish — corrected an internal markdown path in `TECHNICAL_EXPLANATION.md` so theme token references resolve cleanly. Files changed: `TECHNICAL_EXPLANATION.md`, `AGENT.md`, `CHANGELOG.md`. Verification: reviewed the corrected link target in the document. Follow-ups: none.

Raouf:
2026-03-12: Dual-renderer map foundation — refactored the map feature toward web-parity architecture with one shared controller state and two renderer widgets. Added `MapRendererType`, campus-coordinate support on `Building`, a shared polyline decoder, a campus-route adapter data source, a shared `MapShell` with renderer toggle/search/location controls, a `flutter_map` campus renderer foundation, and an explicit `GoogleMapView`. Updated the map page to switch renderers without losing selected-building or route state, added controller coverage for renderer switching, and refreshed architecture/inventory docs to document the new split and the still-open routing backend gap. Files changed: `pubspec.yaml`, `pubspec.lock`, `lib/features/map/data/datasources/campus_routes_remote_source.dart`, `lib/features/map/data/datasources/google_routes_remote_source.dart`, `lib/features/map/data/datasources/location_source.dart`, `lib/features/map/data/repositories/map_repository_impl.dart`, `lib/features/map/domain/entities/building.dart`, `lib/features/map/domain/entities/campus_point.dart`, `lib/features/map/domain/entities/map_renderer_type.dart`, `lib/features/map/domain/entities/nav_instruction.dart`, `lib/features/map/domain/entities/route_leg.dart`, `lib/features/map/domain/services/map_polyline_codec.dart`, `lib/features/map/presentation/controllers/map_controller.dart`, `lib/features/map/presentation/pages/map_page.dart`, `lib/features/map/presentation/widgets/campus_map_view.dart`, `lib/features/map/presentation/widgets/google_map_view.dart`, `lib/features/map/presentation/widgets/map_action_stack.dart`, `lib/features/map/presentation/widgets/map_mode_toggle.dart`, `lib/features/map/presentation/widgets/map_shell.dart`, `lib/features/map/presentation/widgets/map_view_helpers.dart`, `lib/features/map/presentation/widgets/route_panel.dart`, `test/features/map/building_test.dart`, `test/features/map/map_controller_test.dart`, `docs/ARCHITECTURE.md`, `map_inventory.md`, `AGENT.md`, `CHANGELOG.md`. Verification: `flutter pub get`, `flutter analyze`, `flutter test` (85/85 passed). Follow-ups: replace the campus-route fallback with the planned server-backed campus engine, add the missing raster overlay asset and campus-space metadata, and migrate Google routing off the legacy client/Directions path.

Raouf:
2026-03-12: Dual-renderer audit fix pass — audited the new map foundation and fixed the main correctness hole plus two UI/state inconsistencies. Protected `MapController.loadRoute()` against stale async responses so an old route result can no longer overwrite a newer building/renderer/travel-mode state, seeded the search sheet with the current query so the input matches visible results, removed the stale unused `map_mode.dart` entity left over from the pre-renderer state model, and tightened map-shell top control spacing to avoid double-counting safe-area top padding under the app bar. Added a regression test covering stale route responses after destination changes. Files changed: `lib/features/map/presentation/controllers/map_controller.dart`, `lib/features/map/presentation/widgets/building_search_sheet.dart`, `lib/features/map/presentation/widgets/map_shell.dart`, `lib/features/map/domain/entities/map_mode.dart` (deleted), `test/features/map/map_controller_test.dart`, `AGENT.md`, `CHANGELOG.md`. Verification: `dart format lib/features/map/presentation/controllers/map_controller.dart lib/features/map/presentation/widgets/building_search_sheet.dart lib/features/map/presentation/widgets/map_shell.dart test/features/map/map_controller_test.dart`, `flutter test test/features/map/map_controller_test.dart`, `flutter analyze`, `flutter test` (86/86 passed). Follow-ups: the remaining gap is still asset-backed rather than code-backed — campus mode needs the real raster overlay asset plus campus-space metadata before it can reach full web-parity overlay behaviour.
