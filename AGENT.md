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

### Raouf: 2026-04-25 (AEST) — Metro favourite line picker
**Scope:** Settings commute preferences and emulator runtime validation.
**Summary:** Tested the currently running Android emulator app logs: Supabase initialised successfully and no TfNSW network permission failure appeared, while the old installed build still logged a small keyboard `RenderFlex` overflow. Replaced the Metro favorite route free-text row with a localized bottom-sheet selector for `Any metro line` and `M1 Metro North West & Bankstown Line`, while keeping Bus/Train on the existing route text input. Tightened Preferred Stop sheet sizing further to account for the bottom sheet chrome above the keyboard.
**Files Changed:** `lib/features/settings/presentation/pages/settings_page.dart`, `lib/app/l10n/app_en.arb`, `lib/app/l10n/app_*.arb` (34 locale files), `AGENT.md`, `CHANGELOG.md`.
**Verification:** Emulator log inspection → app running, Supabase initialised, exact-alarm warnings only, old build still had a 9.4px keyboard overflow; deployed TfNSW endpoint with `mode=metro&stopId=211310&route=M1` → 3 live M1 departures; `flutter analyze` → no issues; `./scripts/check.sh --quick` → 5/5 passed with 151 tests; `ReadLints` on Settings page → no linter errors. Attempted `flutter attach -d emulator-5554 --debug-port 33525` for hot reload, but the VM service returned HTTP 403 and the attach process was stopped.
**Follow-ups:** Rebuild/reinstall or hot restart the app from the active Flutter run session so the new Metro line picker and tighter sheet sizing are loaded on the emulator.

### Raouf: 2026-04-25 (AEST) — Emulator diagnosis + route fallback hardening
**Scope:** Android runtime networking, Settings stop picker overflow, and TfNSW route filtering.
**Summary:** Verified the emulator can reach Supabase and the installed app has `INTERNET` granted, so the live metro issue was not an emulator network block. Hardened the TfNSW proxy so an unmatched saved route such as a stop name falls back to live departures for the selected mode instead of returning an empty list. Resized the Preferred Stop sheet against the remaining keyboard-safe height and added `INTERNET` to the main Android manifest so release installs cannot lose network access.
**Files Changed:** `android/app/src/main/AndroidManifest.xml`, `lib/features/settings/presentation/pages/settings_page.dart`, `supabase/functions/tfnsw-proxy/index.ts`, `AGENT.md`, `CHANGELOG.md`.
**Verification:** Emulator shell ping to Supabase → success; installed app permissions showed `android.permission.INTERNET: granted=true`; deployed proxy with `mode=metro&stopId=211310&route=Macquarie%20University` → 3 live M1 departures; `./scripts/check.sh --quick` → 5/5 passed; `deno fmt --check supabase/functions/tfnsw-proxy/index.ts` → pass; `deno check supabase/functions/tfnsw-proxy/index.ts` → pass; `ReadLints` on edited files → no linter errors. Attempted `flutter run -d emulator-5554 --dart-define-from-file=.env`, but Gradle stalled at `assembleDebug` and was stopped.
**Follow-ups:** Rebuild/reinstall the Android app from Android Studio or rerun `flutter run` after Gradle is unstuck so the local Dart layout change is present on the emulator.

### Raouf: 2026-04-25 (AEST) — Stop picker overflow + live TfNSW departures fix
**Scope:** Settings stop picker layout and Home live commute departures.
**Summary:** Fixed the yellow Flutter bottom overflow stripe by padding the Preferred Stop bottom sheet against the active keyboard inset. Fixed the deployed TfNSW departure proxy so live commute cards parse `stopEvents` responses, request real-time departure monitor output, and filter transport modes with TfNSW `excludedMeans`/`exclMOT_*` parameters instead of the ineffective `itdMot` parameter.
**Files Changed:** `lib/features/settings/presentation/pages/settings_page.dart`, `lib/features/home/presentation/pages/home_page.dart`, `supabase/functions/tfnsw-proxy/index.ts`, `AGENT.md`, `CHANGELOG.md`.
**Verification:** `flutter analyze` → no issues; `flutter test` → 151/151 passed; `deno fmt --check supabase/functions/tfnsw-proxy/index.ts` → pass; `deno check supabase/functions/tfnsw-proxy/index.ts` → pass; `supabase functions deploy tfnsw-proxy --no-verify-jwt` → success; deployed metro endpoint for stop `211310` returned 3 live M1 departures; deployed bus endpoint for stop `G2113230` returned 3 live bus departures; `ReadLints` on edited Flutter files → no linter errors.
**Follow-ups:** Reopen the app or refresh Home so the stream hits the newly deployed `tfnsw-proxy`.

### Raouf: 2026-04-23 (AEST) — Commute Preferences in Settings + Home countdown filtering
**Scope:** Settings personalization and Home live departure behavior.
**Summary:** Added persisted `commuteMode` and `favoriteRoute` preferences, a new Settings commute card (transport picker + route input dialog), and Home live-card filtering so departure countdown focuses on the user’s saved route/line preference. Added all new copy via i18n keys and synchronized them to all locale ARB files.
**Files Changed:** `lib/shared/models/user_preferences.dart`, `lib/features/settings/data/repositories/settings_repository.dart`, `lib/features/settings/presentation/controllers/settings_controller.dart`, `lib/features/settings/presentation/pages/settings_page.dart`, `lib/features/home/presentation/pages/home_page.dart`, `lib/app/l10n/app_en.arb`, `lib/app/l10n/app_*.arb` (34 locale files).
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-25 (AEST) — Mode-aware Preferred Stop picker + bottom-sheet lifecycle fix
**Scope:** Preferred Stop picker runtime stability and mode-specific search.
**Summary:** Replaced the Preferred Stop `AlertDialog` with a Settings-style modal bottom sheet to avoid the Flutter dirty-widget/build-scope error involving `AnimatedDefaultTextStyle`. Passed active commute mode from Settings into Flutter stop search and `tfnsw-proxy`, then filtered stop-search results server-side so Metro/Train show station results while Bus shows bus/interchange-style stops. Redeployed `tfnsw-proxy` and verified mode-specific deployed results.
**Files Changed:** `lib/features/settings/presentation/pages/settings_page.dart`, `lib/features/transit/presentation/providers/tfnsw_provider.dart`, `supabase/functions/tfnsw-proxy/index.ts`, `AGENT.md`, `CHANGELOG.md`.
**Verification:** `deno fmt --check supabase/functions/tfnsw-proxy/index.ts` → pass; `deno check supabase/functions/tfnsw-proxy/index.ts` → pass; focused Flutter tests → 12/12 passed; `supabase functions deploy tfnsw-proxy --no-verify-jwt` → success; deployed stop-search for `Macquarie University` returned `Macquarie University Station` for metro/train and bus/interchange stops for bus; `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 151 tests, gen-l10n); `ReadLints` on edited Dart files → no linter errors.
**Follow-ups:** Reopen the app and test the stop picker after changing Main Transport between Bus, Train, and Metro.

### Raouf: 2026-04-25 (AEST) — TfNSW stream disposal fix + deployed stop search
**Scope:** Runtime stability for `tfnswMetroProvider` and Preferred Stop search availability.
**Summary:** Fixed the Riverpod `Cannot use the Ref ... after it has been disposed` runtime error by guarding `tfnswMetroProvider` with `ref.mounted` checks after async gaps and avoiding `ref.read` inside the polling loop. Deployed `tfnsw-proxy` with the stop-search branch so Preferred Stop search no longer hits the stale departures-only function and now returns actual stop results from the deployed backend.
**Files Changed:** `lib/features/transit/presentation/providers/tfnsw_provider.dart`, `AGENT.md`, `CHANGELOG.md`.
**Verification:** Focused Flutter tests → 12/12 passed; `supabase functions deploy tfnsw-proxy --no-verify-jwt` → success; deployed stop-search endpoint for `Macquarie University` → `HTTP 200` with 3 stop results including `Macquarie University Station`; `deno fmt --check supabase/functions/tfnsw-proxy/index.ts` → pass; `deno check supabase/functions/tfnsw-proxy/index.ts` → pass; `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 151 tests, gen-l10n); `ReadLints` on transit provider → no linter errors.
**Follow-ups:** Reopen the app stop picker after deployment so it issues a fresh request to the updated Edge Function.

### Raouf: 2026-04-25 (AEST) — Preferred Stop implementation part-by-part verification
**Scope:** Preferred Stop testing, persistence coverage, and live TfNSW request validation.
**Summary:** Tested the Preferred Stop implementation in layers: controller, repository, stop entity parsing, localization parity, Edge Function type safety, full Flutter checks, and live TfNSW `stop_finder` request shape. Added repository and stop-entity tests for `favoriteStopId`/`favoriteStopName` persistence and JSON parsing. The live TfNSW check showed `type_sf=any` can return POIs, so `tfnsw-proxy` now filters stop-search results to stop/platform types before returning them to Flutter.
**Files Changed:** `supabase/functions/tfnsw-proxy/index.ts`, `test/features/settings/settings_repository_test.dart`, `test/features/transit/transit_stop_test.dart`, `AGENT.md`, `CHANGELOG.md`.
**Verification:** Focused Flutter tests → 12/12 passed; ARB stop-search key parity script → pass; `flutter gen-l10n` → pass; live TfNSW `stop_finder` request for `Macquarie University` returned stop-filtered sample including `Macquarie University Station`; `deno fmt --check supabase/functions/tfnsw-proxy/index.ts` → pass; `deno check supabase/functions/tfnsw-proxy/index.ts` → pass; `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 151 tests, gen-l10n); `ReadLints` on edited Dart files → no linter errors.
**Follow-ups:** Local Edge Function serving is blocked until Docker Desktop is running; deploy `tfnsw-proxy` or start Docker to test the exact Edge HTTP path end-to-end.

### Raouf: 2026-04-25 (AEST) — Preferred Stop name search picker
**Scope:** Commute stop selection UX and TfNSW stop search integration.
**Summary:** Replaced manual Preferred Stop ID entry with a localized searchable stop/station picker that calls `tfnsw-proxy?action=stop-search`, which forwards to TfNSW Trip Planner `stop_finder` with the server-side API key. Added persisted `favoriteStopName` so Settings shows readable stop names while `favoriteStopId` remains the value used by Home/TfNSW departure requests. Added clear-stop behavior, a `TransitStop` entity/provider, locale key parity, and controller test coverage; also fixed a TypeScript `isNotEmpty` typo in the edge function caught by `deno check`.
**Files Changed:** `lib/shared/models/user_preferences.dart`, `lib/features/settings/data/repositories/settings_repository.dart`, `lib/features/settings/presentation/controllers/settings_controller.dart`, `lib/features/settings/presentation/pages/settings_page.dart`, `lib/features/transit/domain/entities/transit_stop.dart`, `lib/features/transit/presentation/providers/tfnsw_provider.dart`, `lib/app/l10n/app_en.arb`, `lib/app/l10n/app_*.arb` (34 locale files), `supabase/functions/tfnsw-proxy/index.ts`, `test/features/settings/settings_controller_test.dart`, `AGENT.md`, `CHANGELOG.md`.
**Verification:** `flutter gen-l10n`; `flutter test test/features/settings/settings_controller_test.dart` → 7/7 passed; `deno fmt supabase/functions/tfnsw-proxy/index.ts`; `deno check supabase/functions/tfnsw-proxy/index.ts` → pass; `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 146 tests, gen-l10n); `ReadLints` on edited Dart files → no linter errors.
**Follow-ups:** Deploy `tfnsw-proxy` so stop-name search is available in the runtime backend.

### Raouf: 2026-04-25 (AEST) — Commute tracking end-to-end audit + refresh hardening
**Scope:** Commute Preferences state, persistence, and Home/TfNSW live tracking flow.
**Summary:** Completed a full commute tracking audit across Settings UI, controller/repository persistence, `UserPreferences`, Home countdown consumption, and `tfnswMetroProvider`. Fixed the provider to watch settings changes for immediate refresh and skip location/TfNSW work when commute mode is disabled. Added commute-mode normalization in both controller and repository paths, made route/stop dialogs surface persistence errors and dispose controllers, and added tests covering commute persistence plus unsupported-mode normalization.
**Files Changed:** `lib/features/settings/presentation/pages/settings_page.dart`, `lib/features/settings/presentation/controllers/settings_controller.dart`, `lib/features/settings/data/repositories/settings_repository.dart`, `lib/features/transit/presentation/providers/tfnsw_provider.dart`, `test/features/settings/settings_controller_test.dart`, `AGENT.md`, `CHANGELOG.md`.
**Verification:** `flutter test test/features/settings/settings_controller_test.dart` → 7/7 passed; `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 146 tests, gen-l10n); `ReadLints` on edited Dart files → no linter errors.
**Follow-ups:** Runtime-test with valid TfNSW credentials and stop ID on a simulator/device to confirm live external data.

### Raouf: 2026-04-25 (AEST) — Danger Zone solid red parity
**Scope:** Settings Danger Zone theme correction.
**Summary:** Replaced the Danger Zone charcoal/dark gradient with a solid `MqColors.red` danger surface for both light and dark mode. Updated icon/title/subtitle colors to white so the action reads as danger red instead of dark while maintaining contrast.
**Files Changed:** `lib/features/settings/presentation/pages/settings_page.dart`, `AGENT.md`, `CHANGELOG.md`.
**Verification:** `dart format lib/features/settings/presentation/pages/settings_page.dart`; `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n); `ReadLints` on `lib/features/settings/presentation/pages/settings_page.dart` → no linter errors.

### Raouf: 2026-04-25 (AEST) — Settings row shadow bleed white-surface fix
**Scope:** Final Settings row-surface correction for light mode.
**Summary:** Fixed the remaining grey cast inside Settings sections by wrapping tactile `_TapRow` and `_ToggleRow` content in explicit white light-mode row backgrounds. This blocks `MqTactileButton` shadow bleed-through while retaining the white/red visual language and dark-mode charcoal surfaces.
**Files Changed:** `lib/features/settings/presentation/pages/settings_page.dart`, `AGENT.md`, `CHANGELOG.md`.
**Verification:** `dart format lib/features/settings/presentation/pages/settings_page.dart`; `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n); `ReadLints` on `lib/features/settings/presentation/pages/settings_page.dart` → no linter errors.

### Raouf: 2026-04-25 (AEST) — Settings strict de-grey pass (light mode)
**Scope:** Final white/red visual cleanup for `SettingsPage` light mode.
**Summary:** Removed residual grey appearance from Settings cards/rows based on screenshot feedback by setting light-mode cards to pure white, changing row icon/chevron accents to red, using primary content color for light-mode value/subtitle text, and tinting inactive switch tracks red instead of neutral grey.
**Files Changed:** `lib/features/settings/presentation/pages/settings_page.dart`, `AGENT.md`, `CHANGELOG.md`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-25 (AEST) — Settings light-card surface parity with Home
**Scope:** Home/Settings light-mode visual consistency.
**Summary:** Addressed residual grey appearance in `SettingsPage` cards by aligning `_SettingsCard` light-mode surface to Home’s card token treatment (`Colors.white` with alpha `0.88`). This removes the perceived mismatch and keeps Settings aligned with the requested white/red aesthetic.
**Files Changed:** `lib/features/settings/presentation/pages/settings_page.dart`, `AGENT.md`, `CHANGELOG.md`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-25 (AEST) — Home/Settings white-red aesthetic audit + i18n hardening
**Scope:** Visual parity and localization compliance for `HomePage` and `SettingsPage`.
**Summary:** Audited both tabs for white/red consistency and removed mixed accent usage by standardizing screen-level red accents away from `vividRed`. Updated Settings input dialogs to white surfaces with red action accents to match the requested aesthetic. Replaced one remaining hardcoded Settings helper sentence with a new localization key and propagated it across all locale ARB files for i18n parity.
**Files Changed:** `lib/features/home/presentation/pages/home_page.dart`, `lib/features/settings/presentation/pages/settings_page.dart`, `lib/app/l10n/app_en.arb`, `lib/app/l10n/app_*.arb` (34 locale files), `AGENT.md`, `CHANGELOG.md`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — Location-aware commute departures + live no-op tap fix
**Scope:** Transit edge proxy and Home live card UX correctness.
**Summary:** Fixed `tfnsw-proxy` to accept live location + commute preferences (`mode`, `route`, `lat`, `lng`), resolve nearest stop via TfNSW `stop_finder`, and return filtered departures for the selected transport mode/route. Corrected the TfNSW auth header interpolation bug in the proxy request and removed Home live-card no-op taps by rendering non-interactive cards without tactile wrappers when no action exists.
**Files Changed:** `supabase/functions/tfnsw-proxy/index.ts`, `lib/features/transit/presentation/providers/tfnsw_provider.dart`, `lib/features/transit/domain/entities/metro_departure.dart`, `lib/features/home/presentation/pages/home_page.dart`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).
**Follow-ups:** Deploy `tfnsw-proxy` after secret sync to make location-aware filtering active in production.

### Raouf: 2026-04-23 (AEST) — Home hero sentence readability hardening
**Scope:** Home hero visual contrast on top of background image.
**Summary:** Improved the visibility of the “Find your way…” hero subtitle by using stronger content tokens in both themes and adding a subtle text shadow shared with the hero title. This keeps the sentence readable over the campus background image without changing copy or layout.
**Files Changed:** `lib/features/home/presentation/pages/home_page.dart`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).
**Follow-ups:** Validate on physical devices under bright-screen and low-brightness conditions.

### Raouf: 2026-04-23 (AEST) — Supabase secret sync fallback for Google routes key
**Scope:** Edge-function secret sync robustness for Google routing.
**Summary:** Updated `scripts/sync_supabase_secrets.sh` so `GOOGLE_ROUTES_API_KEY` is populated from `GOOGLE_MAPS_API_KEY` when a separate routes key is not present in `.env`. Re-synced secrets and verified `maps-routes` returns a successful Google route response (`HTTP 200`) instead of key-related failures.
**Files Changed:** `scripts/sync_supabase_secrets.sh`.
**Verification:** `./scripts/sync_supabase_secrets.sh`; direct `curl` POST to `${SUPABASE_URL}/functions/v1/maps-routes` with `renderer=google` + `travelMode=WALK` returned route payload (`HTTP 200`).
**Follow-ups:** Add `TFNSW_API_KEY` to `.env` if transit APIs should be fully enabled.

### Raouf: 2026-04-23 (AEST) — TfNSW key provisioning + anon access alignment
**Scope:** TfNSW secret setup and edge-function runtime access mode.
**Summary:** Added `TFNSW_API_KEY` to local `.env`, synced secrets to Supabase, and redeployed `tfnsw-proxy` + `maps-routes`. Updated `tfnsw-proxy` deployment to `--no-verify-jwt` so it matches the app’s no-auth architecture and can be called with anon key only.
**Files Changed:** `.env` (local-only, gitignored).
**Verification:** `./scripts/sync_supabase_secrets.sh`; `supabase functions deploy tfnsw-proxy`; `supabase functions deploy maps-routes`; `supabase functions deploy tfnsw-proxy --no-verify-jwt`; direct `curl` GET to `${SUPABASE_URL}/functions/v1/tfnsw-proxy` with anon key returned `HTTP 200`.
**Follow-ups:** If departures remain empty (`[]`) at some times, validate `TFNSW_STOP_ID` against the desired station/platform and peak timetable windows.

### Raouf: 2026-04-23 (AEST) — User-configurable TfNSW stop ID wired to commute settings
**Scope:** Settings personalization and live departure source selection.
**Summary:** Added a persisted `favoriteStopId` preference and exposed it in Settings as a new "Preferred Stop ID" input under Commute Preferences. Wired this value into the TfNSW provider query and edge proxy so user-selected stop ID takes precedence over location-derived/default stops while still honoring selected mode (bus/train/metro) and favorite route filters.
**Files Changed:** `lib/shared/models/user_preferences.dart`, `lib/features/settings/data/repositories/settings_repository.dart`, `lib/features/settings/presentation/controllers/settings_controller.dart`, `lib/features/settings/presentation/pages/settings_page.dart`, `lib/features/transit/presentation/providers/tfnsw_provider.dart`, `supabase/functions/tfnsw-proxy/index.ts`, `lib/app/l10n/app_en.arb`, `lib/app/l10n/app_*.arb` (34 locale files).
**Verification:** `./scripts/check.sh --quick` → 5/5 passed; `supabase functions deploy tfnsw-proxy --no-verify-jwt` succeeded.
**Follow-ups:** Optionally add stop search/autocomplete (via TfNSW `stop_finder`) to avoid manual stop ID entry mistakes.

### Raouf: 2026-04-23 (AEST) — Localization parity fix for newly added Home/Settings keys
**Scope:** Internationalization consistency across all locale ARB files.
**Summary:** Added the 11 newly introduced `app_en.arb` keys to all 34 non-English locale ARB files using English fallback values to restore key parity and eliminate `flutter gen-l10n` untranslated warnings during app launch/run.
**Files Changed:** `lib/app/l10n/app_*.arb` (34 locales excluding English).
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — Supabase CLI secret sync + function deployment setup
**Scope:** Environment/secrets operational setup for TfNSW and routing edge functions.
**Summary:** Added `scripts/sync_supabase_secrets.sh` to map server-side API/env values from local `.env` into Supabase edge secrets, and extended env docs/templates to include TfNSW and routing server keys (`TFNSW_API_KEY`, `TFNSW_STOP_ID`, `GOOGLE_ROUTES_API_KEY`, `ALLOWED_WEB_ORIGINS`). Deployed `maps-routes`, `tfnsw-proxy`, and `maps-places` via Supabase CLI.
**Files Changed:** `.env.example`, `env_inventory.md`, `scripts/sync_supabase_secrets.sh` (and local `.env` for placeholders).
**Verification:** `./scripts/sync_supabase_secrets.sh`, `supabase functions deploy maps-routes`, `supabase functions deploy tfnsw-proxy`, `supabase functions deploy maps-places`, `./scripts/check.sh --quick` (5/5 passed).

### Raouf: 2026-04-23 (AEST) — Transit routing fallback hardening (TfNSW -> Google)
**Scope:** Edge routing resiliency improvement for transit mode.
**Summary:** Added fallback logic in `maps-routes` so transit requests try TfNSW Trip Planner first and automatically fall back to Google transit routes when TfNSW errors or returns no usable journey data, keeping API response shape stable for the Flutter client.
**Files Changed:** `supabase/functions/maps-routes/index.ts`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — TfNSW Trip Planner API integrated into routing proxy
**Scope:** Supabase edge routing logic enhancement for transit mode.
**Summary:** Parsed the provided `tripplanner_v1_swag_efa11_20251002.yml` spec and integrated TfNSW `/trip` API usage into `maps-routes` for transit requests. Added normalization from TfNSW journey legs into existing route payload fields (points/steps/distance/duration), keeping `TFNSW_API_KEY` on the server and preserving the Flutter-side contract.
**Files Changed:** `supabase/functions/maps-routes/index.ts`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — TfNSW + timetable import + offline tiles implementation
**Scope:** Feature expansion across Home, Settings, map fallback renderer, and Supabase Edge Functions.
**Summary:** Implemented the remaining three blueprint features: new `tfnsw-proxy` edge function + Home metro polling card, local `.ics` timetable import and persistence with Home next-class card map jump, and offline tile caching with `flutter_map_tile_caching` including backend initialisation, cached tile provider integration in desktop fallback maps, and Settings controls for enabling/downloading offline campus tiles.
**Files Changed:** `pubspec.yaml`, `pubspec.lock`, `lib/app/bootstrap/bootstrap.dart`, `lib/app/l10n/app_en.arb`, `lib/features/home/presentation/pages/home_page.dart`, `lib/features/map/data/services/offline_maps_service.dart`, `lib/features/map/presentation/widgets/google/desktop_map_fallback_view.dart`, `lib/features/settings/data/repositories/settings_repository.dart`, `lib/features/settings/presentation/controllers/settings_controller.dart`, `lib/features/settings/presentation/pages/settings_page.dart`, `lib/features/timetable/data/repositories/timetable_repository.dart`, `lib/features/timetable/data/services/timetable_import_service.dart`, `lib/features/timetable/domain/entities/timetable_class.dart`, `lib/features/timetable/presentation/providers/timetable_provider.dart`, `lib/features/transit/domain/entities/metro_departure.dart`, `lib/features/transit/presentation/providers/tfnsw_provider.dart`, `lib/shared/models/user_preferences.dart`, `supabase/functions/tfnsw-proxy/index.ts`.
**Verification:** `./scripts/check.sh` → 6/6 passed (format, analyze, 144 tests, gen-l10n, debug APK build).

### Raouf: 2026-04-23 (AEST) — Dark/Light parity audit hardening
**Scope:** Final cross-mode parity and contrast audit for Home + Settings.
**Summary:** Re-audited dark/light branches for all custom Home and Settings surfaces, accents, and interactive cards. Confirmed parity for scaffold backgrounds, radial glow behavior, card border tokens, and section-header accents. Fixed one remaining contrast mismatch in `SettingsPage` Danger Zone subtitle where light mode mistakenly used a dark-mode content token (`contentPrimaryDark`), replacing it with `contentSecondary` for correct light-mode readability.
**Files Changed:** `lib/features/settings/presentation/pages/settings_page.dart`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — Meet Me Here deep-link routing + map share
**Scope:** Deep-link navigation wiring for shared map points.
**Summary:** Implemented `io.mqnavigation://meet` deep-link support with a dedicated `/meet` route, app-level incoming deep-link handling, and campus map long-press sharing. Added meet-point preselection in `MapPage`/`MapController` so incoming shared coordinates open directly as a destination and immediately trigger route loading.
**Files Changed:** `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `lib/app/mq_navigation_app.dart`, `lib/app/router/app_router.dart`, `lib/app/router/route_names.dart`, `lib/features/map/presentation/controllers/map_controller.dart`, `lib/features/map/presentation/pages/map_page.dart`, `lib/features/map/presentation/widgets/campus/campus_map_view.dart`.
**Verification:** `./scripts/check.sh --quick` → 5/5 passed (format, analyze, 144 tests, gen-l10n).

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
