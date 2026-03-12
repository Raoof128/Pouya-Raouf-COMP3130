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

Raouf:
2026-03-12: Campus overlay bounds normalization fix — fixed the runtime assertion from `flutter_map` caused by feeding raw campus image pixels into `LatLngBounds` under `CrsSimple`. The campus renderer now keeps the raster asset in full pixel resolution but exposes a normalized map-space coordinate system through `CampusOverlayMeta`, so overlay bounds, marker positions, current-location points, and route polylines all stay within `flutter_map`’s valid latitude range while preserving the original image aspect ratio and pixel alignment. Added regressions proving large overlay assets normalize below the `LatLng` limits and that the exported web overlay metadata resolves to safe map-space bounds. Files changed: `lib/features/map/domain/entities/campus_overlay_meta.dart`, `lib/features/map/data/mappers/campus_projection_impl.dart`, `lib/features/map/presentation/widgets/campus_map_view.dart`, `test/features/map/campus_projection_test.dart`, `test/features/map/building_registry_asset_test.dart`, `AGENT.md`, `CHANGELOG.md`. Verification: `dart format lib/features/map/domain/entities/campus_overlay_meta.dart lib/features/map/data/mappers/campus_projection_impl.dart lib/features/map/presentation/widgets/campus_map_view.dart test/features/map/campus_projection_test.dart test/features/map/building_registry_asset_test.dart`, `flutter test test/features/map/campus_projection_test.dart test/features/map/building_registry_asset_test.dart`, `flutter analyze` (0 issues), `flutter test` (99/99 passed). Follow-ups: if the web export ever starts shipping cropped overlay bounds instead of full-image bounds, keep using the normalized map-space helpers rather than rebuilding `LatLngBounds` directly from raw pixels.

Raouf:
2026-03-12: ErrorBoundary fallback hardening — aligned the app with Flutter’s official error-handling guidance after confirming the remaining crash was a recursive fallback failure, not a live `setState` path. `FlutterError.onError` now remains logging-only, `ErrorWidget.builder` stays owned by the `MaterialApp.router` shell, and the fallback widget in `lib/core/error/error_boundary.dart` was rewritten to be context-free so it can render without `Material`, `Theme`, `MediaQuery`, or an inherited `Directionality`. This prevents the `No Directionality widget found` recursion that was re-entering the framework error pipeline and making the old `setState() or markNeedsBuild() called during build` trace appear to persist. Added a regression test that pumps the fallback directly with no `MaterialApp` to prove it can render safely at the top of the tree. Files changed: `lib/core/error/error_boundary.dart`, `test/core/error_boundary_test.dart`, `AGENT.md`, `CHANGELOG.md`. Verification: `dart format lib/core/error/error_boundary.dart lib/app/mq_navigation_app.dart test/core/error_boundary_test.dart`, `flutter test test/core/error_boundary_test.dart`, `flutter analyze` (0 issues), `flutter test` (98/98 passed). Follow-ups: app restarts must be full hot restarts or stop/start runs when changing bootstrap-level error hooks because Flutter hot reload does not rerun `main()`.

Raouf:
2026-03-12: ErrorBoundary framework-hook removal — replaced the unsafe React-style boundary approach with Flutter-native error presentation after the deferred `setState` attempt still proved brittle in real runs. `ErrorBoundary` is now a transparent wrapper used only for app-shell API stability, while `installErrorHandlers()` owns error presentation through `ErrorWidget.builder` plus the global `FlutterError.onError` and `PlatformDispatcher.instance.onError` logging hooks. This removes every widget-level `setState` path from framework error callbacks, which fully eliminates the `setState() or markNeedsBuild() called during build` and `owner!._debugCurrentBuildTarget != null` assertions tied to `ErrorBoundary`. Added regression coverage for the transparent wrapper behavior and the installed render-fallback widget path. Files changed: `lib/core/error/error_boundary.dart`, `test/core/error_boundary_test.dart`, `AGENT.md`, `CHANGELOG.md`. Verification: `dart format lib/core/error/error_boundary.dart test/core/error_boundary_test.dart`, `flutter test test/core/error_boundary_test.dart`, `flutter analyze` (0 issues), `flutter test` (97/97 passed). Follow-ups: if feature-specific recovery UX is needed later, build it above the failing widget tree instead of intercepting `FlutterError.onError` inside a stateful widget.

Raouf:
2026-03-12: ErrorBoundary deferred-state fix — resolved the Flutter assertion caused by calling `setState` directly from `FlutterError.onError` while the framework was still inside its own error/build cycle. `ErrorBoundary` now chains the previously installed Flutter error handler, queues the caught exception, and applies the fallback UI state in a post-frame callback instead of synchronously mutating the widget tree from the error callback. Added a regression widget test that triggers the boundary’s handler and verifies the fallback appears only after the deferred frame, preventing the `owner!._debugCurrentBuildTarget != null` assertion from recurring. Files changed: `lib/core/error/error_boundary.dart`, `test/core/error_boundary_test.dart`, `AGENT.md`, `CHANGELOG.md`. Verification: `dart format lib/core/error/error_boundary.dart test/core/error_boundary_test.dart`, `flutter analyze` (0 issues), `flutter test test/core/error_boundary_test.dart`, `flutter test` (96/96 passed). Follow-ups: if more granular feature-level boundaries are added later, reuse this deferred error-state pattern instead of direct `setState` inside framework error hooks.

Raouf:
2026-03-12: Campus overlay parity correction — aligned the Flutter campus renderer with the web `CRS.Simple` overlay math instead of the earlier mixed-offset fallback. Exported calibrated GPS projection metadata from the web tooling, extended `campus_overlay_meta.json` to carry pixel bounds plus affine projection coefficients, split the Flutter projection so building markers alone receive the shared `BUILDING_PIXEL_OFFSET_X` while GPS-derived route/current-location points use the calibrated web transform without that offset, corrected the campus raster bounds to the real image dimensions, switched the campus camera to a fit-bounds setup that mirrors the web map padding/zoom envelope, and fixed campus marker anchoring so the visual point lands on the intended coordinate. Added regression coverage for metadata parsing and projection behavior, and refreshed the map architecture/inventory docs to describe the calibrated overlay pipeline. Files changed: `lib/features/map/domain/entities/campus_overlay_meta.dart`, `lib/features/map/domain/services/campus_projection.dart`, `lib/features/map/data/mappers/campus_projection_impl.dart`, `lib/features/map/presentation/widgets/campus_map_view.dart`, `test/features/map/campus_projection_test.dart`, `test/features/map/building_registry_asset_test.dart`, `map_inventory.md`, `docs/ARCHITECTURE.md`, `TECHNICAL_EXPLANATION.md`, `assets/data/campus_overlay_meta.json`, `AGENT.md`, `CHANGELOG.md`. Verification: `node --experimental-strip-types tools/export_buildings.mjs` (web repo), `flutter analyze` (0 issues), `flutter test` (95/95 passed). Follow-ups: if the web team changes the GCP set or affine calibration logic, rerun the export bridge so Flutter stays pixel-aligned.

Raouf:
2026-03-12: Dual-map parity pass — completed the next production map milestone by wiring the real campus raster asset flow, web-parity building search, and server-side route loading. Flutter now bundles exported `campusX/campusY` building coordinates plus `campus_overlay_meta.json`, renders campus mode against the shared raster overlay via `flutter_map` `CrsSimple`, ranks search results with the same score ladder as the web `buildingSearch.ts`, and routes both campus and Google mode through the `maps-routes` Supabase Edge Function instead of the legacy client/Directions path. Added the shared `MapsRoutesRemoteSource`, campus projection/asset loaders, normalized route parsing with explicit path points, new map tests, and refreshed the map/docs inventories to match the secure backend path. Files changed: `assets/data/buildings.json`, `assets/data/campus_overlay_meta.json`, `assets/maps/mq-campus.png`, `pubspec.yaml`, `lib/features/map/data/datasources/map_assets_source.dart`, `lib/features/map/data/datasources/maps_routes_remote_source.dart`, `lib/features/map/data/datasources/google_routes_remote_source.dart`, `lib/features/map/data/datasources/campus_routes_remote_source.dart`, `lib/features/map/data/mappers/campus_projection_impl.dart`, `lib/features/map/domain/entities/building.dart`, `lib/features/map/domain/entities/campus_overlay_meta.dart`, `lib/features/map/domain/entities/nav_instruction.dart`, `lib/features/map/domain/entities/route_leg.dart`, `lib/features/map/domain/services/building_search.dart`, `lib/features/map/domain/services/campus_projection.dart`, `lib/features/map/presentation/controllers/map_controller.dart`, `lib/features/map/presentation/pages/map_page.dart`, `lib/features/map/presentation/widgets/building_search_sheet.dart`, `lib/features/map/presentation/widgets/campus_map_view.dart`, `lib/features/map/presentation/widgets/google_map_view.dart`, `lib/features/map/presentation/widgets/map_view_helpers.dart`, `supabase/functions/maps-routes/index.ts`, `supabase/config.toml`, `README.md`, `TECHNICAL_EXPLANATION.md`, `docs/ARCHITECTURE.md`, `map_inventory.md`, `endpoint_inventory.md`, `env_inventory.md`, `test/features/map/building_search_test.dart`, `test/features/map/building_test.dart`, `test/features/map/map_route_test.dart`, `test/features/map/building_registry_asset_test.dart`, `AGENT.md`, `CHANGELOG.md`. Verification: `node --experimental-strip-types tools/export_buildings.mjs` (web repo), `deno check supabase/functions/maps-routes/index.ts`, `flutter analyze` (0 issues), `flutter test` (92/92 passed). Follow-ups: the main parity gap left is Street View/Pegman richness on Flutter compared with the web Google Maps stack.

Raouf:
2026-03-12: Web Google Maps teardown fix — resolved the Chrome crash triggered when `google_maps_flutter_web` asserted during widget disposal before the platform view finished building. `GoogleMapView` now keeps explicit controller disposal on native platforms only and lets the web widget lifecycle release the web view. Re-validated the dependency state with `flutter pub outdated`; all direct and dev dependencies are current and the remaining version notices are upstream-transitive constraints, not repo-owned drift. Files changed: `lib/features/map/presentation/widgets/google_map_view.dart`, `AGENT.md`, `CHANGELOG.md`. Verification: `dart format lib/features/map/presentation/widgets/google_map_view.dart`, `flutter analyze` (0 issues), `flutter test` (86/86 passed). Follow-ups: if a future upstream `google_maps_flutter_web` release fixes teardown ordering, reevaluate whether the native/web dispose split is still needed.

Raouf:
2026-03-12: Workspace cleanup ignore — added `.codex/` to the Flutter app `.gitignore` so Codex desktop workspace metadata no longer leaves the repo dirty after local runs. Files changed: `.gitignore`, `AGENT.md`, `CHANGELOG.md`. Verification: `git status --short` now excludes `.codex/`. Follow-ups: none.

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
