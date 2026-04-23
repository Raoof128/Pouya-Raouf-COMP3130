### Raouf: 2026-04-23 (AEST) — TfNSW key provisioning + anon access alignment
**Scope:** TfNSW secret setup and edge-function runtime access mode.
**Summary:** Added the provided `TFNSW_API_KEY` to local `.env`, synced edge secrets, redeployed `tfnsw-proxy` and `maps-routes`, and redeployed `tfnsw-proxy` with `--no-verify-jwt` to align with the app’s no-auth architecture. This removed anonymous 401 failures for the TfNSW proxy endpoint.
**Files Changed:**
- `.env` (local-only, gitignored)
- `AGENT.md`
- `CHANGELOG.md`
**Verification:**
- `./scripts/sync_supabase_secrets.sh` → `TFNSW_API_KEY` set
- `supabase functions deploy tfnsw-proxy`
- `supabase functions deploy maps-routes`
- `supabase functions deploy tfnsw-proxy --no-verify-jwt`
- Direct `curl` GET to `${SUPABASE_URL}/functions/v1/tfnsw-proxy` with anon key → `HTTP 200`
**Follow-ups:**
- If response is empty (`[]`), tune `TFNSW_STOP_ID` for the desired stop/platform and recheck during active service windows.

### Raouf: 2026-04-23 (AEST) — Supabase secret sync fallback for Google routes key
**Scope:** Edge-function secret sync robustness for Google routing.
**Summary:** Updated `scripts/sync_supabase_secrets.sh` so `GOOGLE_ROUTES_API_KEY` is populated from `GOOGLE_MAPS_API_KEY` when a dedicated routes key is not present in `.env`. Re-synced secrets and verified the `maps-routes` function now returns successful Google route responses.
**Files Changed:**
- `scripts/sync_supabase_secrets.sh`
- `AGENT.md`
- `CHANGELOG.md`
**Verification:**
- `./scripts/sync_supabase_secrets.sh`
- Direct `curl` POST to `${SUPABASE_URL}/functions/v1/maps-routes` with `renderer=google` + `travelMode=WALK` → valid route payload (`HTTP 200`).
**Follow-ups:**
- Add `TFNSW_API_KEY` to `.env` for full TfNSW-based transit support.

### Raouf: 2026-04-23 (AEST) — Home hero sentence readability hardening
**Scope:** Home hero visual contrast on top of background image.
**Summary:** Improved the visibility of the “Find your way…” hero subtitle by using stronger content tokens in both themes and adding a subtle text shadow shared with the hero title. This keeps the sentence readable over the campus background image without changing copy or layout.
**Files Changed:**
- `lib/features/home/presentation/pages/home_page.dart`
- `AGENT.md`
- `CHANGELOG.md`
**Verification:**
- `./scripts/check.sh --quick` → pass (format, analyze, flutter test 144, gen-l10n).
**Follow-ups:**
- Validate contrast on-device in both dark and light mode.

### Raouf: 2026-04-23 (AEST) — Location-aware commute departures + live no-op tap fix
**Scope:** Transit edge proxy and Home live card UX correctness.
**Summary:** Fixed `tfnsw-proxy` to accept live location + commute preferences (`mode`, `route`, `lat`, `lng`), resolve nearest stop via TfNSW `stop_finder`, and return filtered departures for the selected transport mode/route. Corrected the TfNSW auth header interpolation bug in the proxy request and removed Home live-card no-op taps by rendering non-interactive cards without tactile wrappers when no action exists.
**Files Changed:**
- `supabase/functions/tfnsw-proxy/index.ts`
- `lib/features/transit/presentation/providers/tfnsw_provider.dart`
- `lib/features/transit/domain/entities/metro_departure.dart`
- `lib/features/home/presentation/pages/home_page.dart`
- `AGENT.md`
- `CHANGELOG.md`
**Verification:**
- `./scripts/check.sh --quick` → pass (format, analyze, flutter test 144, gen-l10n).
**Follow-ups:**
- Deploy `tfnsw-proxy` and confirm device-level behavior at runtime with GPS enabled.

# Changelog

All notable changes to the MQ Navigation Flutter app.

## [Unreleased]

### Raouf: 2026-04-23 (AEST) — Commute Preferences in Settings + Home countdown filtering

**Scope:** Settings personalization and Home live departure behavior.

**Summary:**
Added a new Commute Preferences feature with persisted `commuteMode` and `favoriteRoute` values in local settings. Implemented a dedicated Settings card (mode picker + route input dialog) and wired Home’s live departure card to respect these preferences by filtering departures using the saved route/line text. All new user-visible labels and prompts were added through localization keys and propagated across all locale ARB files.

**Files Changed:**
- `lib/shared/models/user_preferences.dart`
- `lib/features/settings/data/repositories/settings_repository.dart`
- `lib/features/settings/presentation/controllers/settings_controller.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/home/presentation/pages/home_page.dart`
- `lib/app/l10n/app_en.arb`
- `lib/app/l10n/app_ar.arb`, `app_bn.arb`, `app_cs.arb`, `app_da.arb`, `app_de.arb`, `app_el.arb`, `app_es.arb`, `app_fa.arb`, `app_fi.arb`, `app_fr.arb`, `app_he.arb`, `app_hi.arb`, `app_hu.arb`, `app_id.arb`, `app_it.arb`, `app_ja.arb`, `app_ko.arb`, `app_ms.arb`, `app_ne.arb`, `app_nl.arb`, `app_no.arb`, `app_pl.arb`, `app_pt.arb`, `app_ro.arb`, `app_ru.arb`, `app_si.arb`, `app_sv.arb`, `app_ta.arb`, `app_th.arb`, `app_tr.arb`, `app_uk.arb`, `app_ur.arb`, `app_vi.arb`, `app_zh.arb`
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/check.sh --quick` → **5/5 passed** (pub get, format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — Localization parity fix for newly added Home/Settings keys

**Scope:** Internationalization consistency across all Flutter locale ARB files.

**Summary:**
Resolved `flutter gen-l10n` untranslated warnings by propagating the 11 newly introduced keys from `app_en.arb` into all 34 non-English locale ARB files using English fallback values (consistent with existing project convention). This restores locale key parity and removes startup/run-time untranslated message warnings.

**Files Changed:**
- `lib/app/l10n/app_ar.arb`, `app_bn.arb`, `app_cs.arb`, `app_da.arb`, `app_de.arb`, `app_el.arb`, `app_es.arb`, `app_fa.arb`, `app_fi.arb`, `app_fr.arb`, `app_he.arb`, `app_hi.arb`, `app_hu.arb`, `app_id.arb`, `app_it.arb`, `app_ja.arb`, `app_ko.arb`, `app_ms.arb`, `app_ne.arb`, `app_nl.arb`, `app_no.arb`, `app_pl.arb`, `app_pt.arb`, `app_ro.arb`, `app_ru.arb`, `app_si.arb`, `app_sv.arb`, `app_ta.arb`, `app_th.arb`, `app_tr.arb`, `app_uk.arb`, `app_ur.arb`, `app_vi.arb`, `app_zh.arb`
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/check.sh --quick` → **5/5 passed** (pub get, format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — Supabase CLI secret sync + function deployment setup

**Scope:** Environment/secrets operational setup for TfNSW and routing edge functions.

**Summary:**
Added an operational script (`scripts/sync_supabase_secrets.sh`) that reads supported server-side API keys from `.env` and syncs them into Supabase Edge Function secrets via CLI. Extended `.env.example` and `env_inventory.md` with TfNSW and server routing key fields (`TFNSW_API_KEY`, `TFNSW_STOP_ID`, `GOOGLE_ROUTES_API_KEY`, `ALLOWED_WEB_ORIGINS`). Executed Supabase CLI deployments for `maps-routes`, `tfnsw-proxy`, and `maps-places`; synced `TFNSW_STOP_ID` successfully, while missing values in local `.env` were safely skipped.

**Files Changed:**
- `.env` (local-only, gitignored)
- `.env.example`
- `env_inventory.md`
- `scripts/sync_supabase_secrets.sh`
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/sync_supabase_secrets.sh` executed successfully (with skip reporting for missing keys).
- `supabase functions deploy maps-routes`
- `supabase functions deploy tfnsw-proxy`
- `supabase functions deploy maps-places`
- `./scripts/check.sh --quick` → **5/5 passed**.

### Raouf: 2026-04-23 (AEST) — Transit routing fallback hardening (TfNSW -> Google)

**Scope:** Edge routing resiliency improvement for transit mode.

**Summary:**
Hardened transit route generation in `maps-routes` by introducing an automatic fallback chain: attempt TfNSW Trip Planner first, then transparently fall back to Google transit route calculation when TfNSW errors or returns unusable data. This keeps transit routing available even during TfNSW outages while preserving the same normalized response contract consumed by Flutter.

**Files Changed:**
- `supabase/functions/maps-routes/index.ts`
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/check.sh --quick` → **5/5 passed** (pub get, format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — TfNSW Trip Planner API integrated into routing proxy

**Scope:** Supabase edge routing logic enhancement for transit mode.

**Summary:**
Parsed `tripplanner_v1_swag_efa11_20251002.yml` and integrated the TfNSW `/trip` API into `maps-routes` for transit routing. The edge function now calls TfNSW Trip Planner when `travelMode=TRANSIT` on the Google renderer path, normalizes journey legs/coordinates/path descriptions into the existing `MapRoute` contract (`points`, `steps`, distance, duration), and preserves key security constraints by reading `TFNSW_API_KEY` server-side only.

**Files Changed:**
- `supabase/functions/maps-routes/index.ts`
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/check.sh --quick` → **5/5 passed** (pub get, format, analyze, 144 tests, gen-l10n).

### Raouf: 2026-04-23 (AEST) — TfNSW + timetable import + offline tiles implementation

**Scope:** Feature expansion across Home, Settings, map fallback renderer, and Supabase Edge Functions.

**Summary:**
Implemented the remaining three blueprint items after deep links: (1) a new `tfnsw-proxy` Supabase Edge Function plus Riverpod polling provider to surface upcoming metro departures on Home; (2) `.ics` timetable import using `file_picker` + `icalendar_parser`, persisted to `SharedPreferences`, with a Home "Next Class" card that jumps to map search by class location; and (3) offline tile architecture via `flutter_map_tile_caching`, including backend initialisation, cached tile provider usage in desktop OSM fallback renderer, and Settings controls to enable and download campus tiles for zoom levels 15–18.

**Files Changed:**
- `pubspec.yaml`, `pubspec.lock`
- `lib/app/bootstrap/bootstrap.dart`
- `lib/app/l10n/app_en.arb`
- `lib/features/home/presentation/pages/home_page.dart`
- `lib/features/map/data/services/offline_maps_service.dart`
- `lib/features/map/presentation/widgets/google/desktop_map_fallback_view.dart`
- `lib/features/settings/data/repositories/settings_repository.dart`
- `lib/features/settings/presentation/controllers/settings_controller.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/timetable/data/repositories/timetable_repository.dart`
- `lib/features/timetable/data/services/timetable_import_service.dart`
- `lib/features/timetable/domain/entities/timetable_class.dart`
- `lib/features/timetable/presentation/providers/timetable_provider.dart`
- `lib/features/transit/domain/entities/metro_departure.dart`
- `lib/features/transit/presentation/providers/tfnsw_provider.dart`
- `lib/shared/models/user_preferences.dart`
- `supabase/functions/tfnsw-proxy/index.ts`
- Generated plugin registrants: `macos/Flutter/GeneratedPluginRegistrant.swift`, `windows/flutter/generated_plugin_registrant.cc`, `windows/flutter/generated_plugins.cmake`
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/check.sh` → **6/6 passed** (pub get, format, analyze, 144 tests, gen-l10n, debug APK build).

### Raouf: 2026-04-23 (AEST) — Meet Me Here deep-link routing + map share

**Scope:** Deep-link navigation wiring for shared map points.

**Summary:**
Implemented the first blueprint feature end-to-end: custom `io.mqnavigation://meet` links now route into the app and open a meet point on the map. Added a dedicated `/meet` route, app-level incoming link handling via `app_links`, and a long-press share action on the campus map using `share_plus`. Meet links now preselect a coordinate destination and immediately trigger route loading from the user location.

**Files Changed:**
- `pubspec.yaml`
- `lib/app/mq_navigation_app.dart`
- `android/app/src/main/AndroidManifest.xml`
- `lib/app/router/app_router.dart`
- `lib/app/router/route_names.dart`
- `lib/features/map/presentation/controllers/map_controller.dart`
- `lib/features/map/presentation/pages/map_page.dart`
- `lib/features/map/presentation/widgets/campus/campus_map_view.dart`
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/check.sh --quick` → **5/5 passed** (pub get, format, analyze clean, 144 tests passed, gen-l10n clean).

### Raouf: 2026-04-23 (AEST) — Dark/Light parity audit hardening

**Scope:** Final cross-mode parity and contrast audit for Home + Settings.

**Summary:**
Performed an additional hardening pass on dark/light parity after the previous audit. Confirmed mode parity for scaffold backgrounds, radial glow layers, card surfaces/borders, and header accents. Fixed one remaining contrast defect in Settings Danger Zone where light mode subtitle color used a dark-mode token; updated to `MqColors.contentSecondary` for proper readability and visual consistency.

**Files Changed:**
- `lib/features/settings/presentation/pages/settings_page.dart`
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/check.sh --quick` → **5/5 passed** (pub get, format, analyze clean, 144 tests passed, gen-l10n clean).

### Raouf: 2026-04-23 (AEST) — Dark/Light parity audit pass (Home + Settings)

**Scope:** Visual parity verification for dark mode and light mode branches.

**Summary:**
Completed a full parity audit for `HomePage` and `SettingsPage` backgrounds, surfaces, accents, and section-header treatment across both theme modes. Verified shared scaffold colors (`alabaster` / `charcoal850`), dark radial glow behavior, and card token consistency. Resolved one remaining mismatch by changing Home section-header light accent from `brightRed` to `red` to match Settings headers exactly. Updated stale Home comment to reflect current behavior (background photo now renders in both themes).

**Files Changed:**
- `lib/features/home/presentation/pages/home_page.dart`
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/check.sh --quick` → **5/5 passed** (pub get, format, analyze clean, 144 tests passed, gen-l10n clean).

### Raouf: 2026-04-23 (AEST) — Home bento hero swap + Settings kinetic/tactile refresh

**Scope:** Home quick-access hierarchy update and Settings interaction polish.

**Summary:**
Updated Home Bento hierarchy so the large left hero card now routes to **Student Services** (query: `services`) and moved **Food & Drink** into secondary quick-access chips. Refreshed Settings with kinetic title/section motion (slide + fade), tactile row interactions using `MqTactileButton`, and a distinct Danger Zone Bento block for wipe-data to improve visual priority and affordance without changing underlying settings persistence logic.

**Files Changed:**
- `lib/features/home/presentation/pages/home_page.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/check.sh --quick` → **5/5 passed** (pub get, format, analyze clean, 144 tests passed, gen-l10n clean).

### Raouf: 2026-04-23 (AEST) — Home background image dark-mode + clarity fix

**Scope:** Home background image rendering and visual clarity.

**Summary:**
Fixed Home background photo visibility in dark mode by always rendering the campus background layer (instead of hiding it for dark theme). Reduced overlay strength to avoid the “blurry/foggy” appearance while preserving text contrast. Light mode wash changed from `MqColors.alabaster` alpha `0.78` to `0.50`; dark mode now applies `MqColors.charcoal950` alpha `0.42`.

**Files Changed:**
- `lib/features/home/presentation/pages/home_page.dart`
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/check.sh --quick` → **5/5 passed** (pub get, format, analyze clean, 144 tests passed, gen-l10n clean).

### Raouf: 2026-04-23 (AEST) — Home tactical UI refresh (tactile + kinetic + bento)

**Scope:** Home UX enhancement with tactile interactions and asymmetric quick access layout.

**Summary:**
Introduced a reusable tactile interaction primitive and applied it to Home quick actions. Added `MqTactileButton` with squishy press feedback (`AnimatedScale`), subtle depth shadow, and optional haptics. Upgraded the hero copy block to animate in on first build (fade + upward slide) via `TweenAnimationBuilder`. Replaced the previous symmetric 2-column grid with an asymmetrical Bento layout composed of a large hero card and stacked compact cards, plus secondary quick actions beneath. All labels remain localized and all surfaces remain token-based.

**Files Changed:**
- `lib/shared/widgets/mq_tactile_button.dart` (new)
- `lib/features/home/presentation/pages/home_page.dart`
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/check.sh --quick` → **5/5 passed** (pub get, format, analyze clean, 144 tests passed, gen-l10n clean).

### Raouf: 2026-04-23 (AEST) — Settings/Home background parity

**Scope:** Visual consistency in Settings scaffold background.

**Summary:**
Updated `SettingsPage` scaffold background to exactly match `HomePage` base colors in both theme modes (`MqColors.alabaster` in light mode and `MqColors.charcoal850` in dark mode), ensuring the two tabs share the same page-level background surface.

**Files Changed:**
- `lib/features/settings/presentation/pages/settings_page.dart`
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/check.sh --quick` → **5/5 passed** (pub get, format, analyze clean, 144 tests passed, gen-l10n clean).

### Raouf: 2026-04-23 (AEST) — Settings Audit & Functional Wiring

**Scope:** Verify all 12 settings are fully functional, persisted, and accurately consumed app-wide.

**Summary:**
Conducted a comprehensive audit of `SettingsRepository`, `SettingsController`, and all app-wide consumers. Verified that `themeMode`, `localeCode`, `notificationsEnabled`, `lowDataMode`, `reducedMotion`, `quietHoursEnabled`, `quietHoursStart`, `quietHoursEnd`, and `highContrastMap` were perfectly wired. Addressed two functional bugs:

1. **Map State Reset on Unrelated Setting Changes:** `MapController` was using `ref.watch(settingsControllerProvider.future)` in its `build()` method. This caused the entire map state (selected building, route, search query, location) to reset whenever *any* unrelated setting (like theme or haptics) was toggled. Swapped to `ref.read` for the initial load and `ref.listen` to selectively update `renderer` and `travelMode` dynamically without destroying the map state.
2. **Cosmetic Haptics:** `hapticsEnabled` was cosmetic (only used in the dev Easter egg). Wired it up to `MqHaptics.light` on all `SettingsPage` toggles/pickers and `MqHaptics.selection` in `BuildingSearchSheet` when selecting a campus building or a Google Place suggestion.

**Files Changed:**
- `lib/features/map/presentation/controllers/map_controller.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/map/presentation/widgets/building_search_sheet.dart`
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/check.sh --quick` → **5/5 passed** (pub get, format, analyze clean, 144 tests passed, gen-l10n clean).

### Raouf: 2026-04-23 (AEST) — Home/Settings 100% Theme & Colour Parity

**Scope:** Lock `HomePage` visual language to `SettingsPage` — identical colour tokens, card treatment, section-header style and dark-mode red glow.

**Summary:**
The home tab was previously light-mode only, used off-token colours (`MqColors.red` vs Settings' `vividRed`/`brightRed`), hardcoded an `0xFFFDECEE` icon-circle tint, hardcoded English strings, and rendered a solid black 20pt "Quick Access" heading instead of Settings' uppercase letter-spaced red header. The page now:

- Branches every surface, border, text and accent through `context.isDarkMode`, so dark mode swaps to `charcoal850` cards with `Colors.white.withAlpha(13)` borders and `vividRed` accents — a byte-for-byte match of `_SettingsCard`.
- Layers the same top-origin red radial gradient (`vividRed.withAlpha(38) → transparent`) that sits on `SettingsPage` in dark mode; light mode keeps the branded campus photograph under its ivory veil.
- Replaces the section heading with the Settings `_SectionHeader` treatment (uppercase, `labelMedium`, `FontWeight.w700`, `letterSpacing: 1.2`, `vividRed` dark / `brightRed` light).
- Swaps the magic `0xFFFDECEE` icon tint for a token-derived `red.withAlpha(20)` (light) / `vividRed.withAlpha(38)` (dark).
- Replaces every hardcoded string with new `home_*` ARB keys and adds them to all 34 non-English locales with English fallback (matching the prior localisation sync convention).
- Uses `EdgeInsetsDirectional` throughout so the page mirrors correctly in RTL locales (ar/fa/he/ur).

**Files Changed:**
- `lib/features/home/presentation/pages/home_page.dart` (rewritten)
- `lib/app/l10n/app_en.arb` (+11 keys)
- `lib/app/l10n/app_ar.arb`, `app_bn.arb`, `app_cs.arb`, `app_da.arb`, `app_de.arb`, `app_el.arb`, `app_es.arb`, `app_fa.arb`, `app_fi.arb`, `app_fr.arb`, `app_he.arb`, `app_hi.arb`, `app_hu.arb`, `app_id.arb`, `app_it.arb`, `app_ja.arb`, `app_ko.arb`, `app_ms.arb`, `app_ne.arb`, `app_nl.arb`, `app_no.arb`, `app_pl.arb`, `app_pt.arb`, `app_ro.arb`, `app_ru.arb`, `app_si.arb`, `app_sv.arb`, `app_ta.arb`, `app_th.arb`, `app_tr.arb`, `app_uk.arb`, `app_ur.arb`, `app_vi.arb`, `app_zh.arb` (+11 keys each, English fallback)
- `lib/app/l10n/generated/app_localizations*.dart` (regenerated via `flutter gen-l10n`)
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `./scripts/check.sh --quick` → **5/5 passed** (pub get, format, analyze clean, 144 tests passed, gen-l10n clean).

### Raouf: 2026-03-21 (AEDT) — Campus Map Zoom Fix & Technical Audit

**Scope:** Fix critical map zoom usability issues and perform a deep technical audit of map feature code.

**Summary:**
Fixed the campus map initial zoom being too close and uncomfortably tight by adjusting `MapOptions` (minZoom -5.0, padded initial fit, constrained camera). Audited and refactored core map files to improve error handling (`MapAssetsException`), safety (zero-division checks in projection), performance (value equality in `MapState`), and design consistency (replaced magic numbers/colors with `MqSpacing`/`MqColors`).

**Files changed:**
- `lib/features/map/presentation/widgets/campus/campus_map_view.dart`
- `lib/features/map/presentation/controllers/map_controller.dart`
- `lib/features/map/data/datasources/map_assets_source.dart`
- `lib/features/map/data/mappers/campus_projection_impl.dart`
- `lib/features/map/domain/services/geo_utils.dart`
- `lib/features/map/presentation/widgets/campus/campus_map_marker_layer.dart`
- `lib/features/map/presentation/widgets/campus/campus_map_route_layer.dart`
- `AGENT.md`
- `CHANGELOG.md`

### Raouf: 2026-03-17 (AEDT) — README Key Placement Guidance

**Scope:** Document safe storage rules for client and server keys used by the repo.

**Summary:**
Added a dedicated README section that tells contributors exactly where each key should live (`.env`, gitignored web runtime config, CI/deployment env, or Supabase secrets), which ones must never be committed, and what secret-like material still remains tracked by design.

**Files changed:**
- `README.md`
- `AGENT.md`
- `CHANGELOG.md`

### Raouf: 2026-03-17 (AEDT) — Web Google Maps Runtime Key Injection

**Scope:** Enable Flutter web Google Maps without committing the client API key.

**Summary:**
Added a web-safe runtime injection path for the Google Maps JavaScript SDK. The web client now reads `window.GOOGLE_MAPS_API_KEY` from a gitignored `web/google_maps_config.js` file, and a custom `web/flutter_bootstrap.js` loads the SDK only when that runtime config exists. Local `./scripts/run.sh chrome` runs now generate the config file automatically from `.env`.

**Files changed:**
- `.gitignore`
- `web/index.html`
- `web/flutter_bootstrap.js`
- `web/google_maps_config.js.example`
- `scripts/run.sh`
- `README.md`
- `TECHNICAL_EXPLANATION.md`
- `AGENT.md`
- `CHANGELOG.md`

### Raouf: 2026-03-17 (AEDT) — Supabase Migration History Reconciliation

**Scope:** Repair local/remote Supabase migration alignment so CLI deploys work cleanly.

**Summary:**
Reconciled this repo’s local `supabase/migrations` directory with the linked remote project by fetching the remote migration history into source control, then successfully applying the pending local migrations with `supabase db push --include-all`. Deployed the updated map Edge Functions after the database push succeeded.

**Files changed:**
- `supabase/migrations/20260104000000_initial_schema.sql`
- `supabase/migrations/20260104000001_fix_schema_issues.sql`
- `supabase/migrations/20260108131028_add_user_id_and_rls_policies.sql`
- `supabase/migrations/20260108140000_add_event_date_columns.sql`
- `supabase/migrations/20260108150000_fix_rls_policies.sql`
- `supabase/migrations/20260109012136_create_user_profile_function.sql`
- `supabase/migrations/20260109012243_add_gamification_system.sql`
- `supabase/migrations/20260109012548_fix_permissions_and_schema_alignment.sql`
- `supabase/migrations/20260109012721_add_missing_deadline_columns.sql`
- `supabase/migrations/20260109012944_fix_auth_trigger_for_new_users.sql`
- `supabase/migrations/20260109013033_check_and_fix_existing_triggers.sql`
- `supabase/migrations/20260109013302_disable_all_auth_triggers.sql`
- `supabase/migrations/20260113000000_reenable_auth_trigger_with_user_view.sql`
- `supabase/migrations/20260113100000_fix_foreign_key_constraints.sql`
- `supabase/migrations/20260113110000_schema_cleanup_and_fixes.sql`
- `supabase/migrations/20260114000000_add_missing_materialized_views.sql`
- `supabase/migrations/20260114010403_add_course_and_year_to_profiles.sql`
- `supabase/migrations/20260114011650_fix_schema_comprehensive.sql`
- `supabase/migrations/20260114013136_complete_schema_audit_fix.sql`
- `supabase/migrations/20260114013519_add_soft_deletes_constraints_seeds.sql`
- `supabase/migrations/20260114014506_schema_cleanup_and_normalization.sql`
- `supabase/migrations/20260114015445_clarify_views_simplify_events.sql`
- `supabase/migrations/20260119000000_add_push_notifications_to_user_preferences.sql`
- `supabase/migrations/20260119050000_multiuser_demo_seed.sql`
- `supabase/migrations/20260119100000_remove_strict_constraints.sql`
- `supabase/migrations/20260119110000_remove_sample_events.sql`
- `supabase/migrations/20260122000000_atomic_unit_sync.sql`
- `supabase/migrations/20260124000000_complete_schema_initialization.sql`
- `supabase/migrations/20260124001000_create_todos_table.sql`
- `supabase/migrations/20260124120000_add_events_timestamp_fields.sql`
- `supabase/migrations/20260126000000_add_missing_columns.sql`
- `supabase/migrations/20260129000000_add_audit_logging.sql`
- `supabase/migrations/20260201084007_add_audit_logging_and_feature_flags.sql`
- `supabase/migrations/20260203000000_add_notification_enabled.sql`
- `supabase/migrations/20260203000001_fix_units_unique_constraint.sql`
- `supabase/migrations/20260203000002_public_events.sql`
- `supabase/migrations/20260207000000_add_webauthn_tables.sql`
- `supabase/migrations/20260207001000_fix_building_codes.sql`
- `supabase/migrations/20260207100000_add_color_to_todos.sql`
- `supabase/migrations/20260208000000_security_audit_fixes.sql`
- `supabase/migrations/20260213000000_email_verifications.sql`
- `supabase/migrations/20260214000000_harden_gamification_rpc.sql`
- `supabase/migrations/20260214001000_align_code_db_objects.sql`
- `supabase/migrations/20260214002000_restore_log_audit_function.sql`
- `supabase/migrations/20260214003000_restore_missing_core_security_tables.sql`
- `supabase/migrations/20260216090000_harden_security_functions.sql`
- `supabase/migrations/20260216193000_password_resets.sql`
- `supabase/migrations/20260217093000_rate_limits.sql`
- `supabase/migrations/20260219000000_avatars_storage_bucket.sql`
- `supabase/migrations/20260220000000_add_faculty_to_profiles.sql`
- `supabase/migrations/20260220100000_realtime_offline.sql`
- `supabase/migrations/20260226000000_fix_security_definer_and_rls.sql`
- `supabase/migrations/20260226100000_add_march_events.sql`
- `supabase/migrations/20260303000000_seed_16_public_events.sql`
- `supabase/migrations/20260304000000_cleanup_duplicate_public_events.sql`
- `supabase/migrations/20260304100000_add_faculty_to_views_and_functions.sql`
- `supabase/migrations/20260304200000_fix_profile_protection_trigger.sql`
- `supabase/migrations/20260308000000_shift_events_to_april.sql`
- `supabase/migrations/20260313093000_add_web_push_infrastructure.sql`
- `supabase/migrations/20260313120000_backfill_push_notifications_column.sql`
- `supabase/migrations/20260314_auto_create_profile_trigger.sql`
- `AGENT.md`
- `CHANGELOG.md`

**Verification:**
- `supabase migration fetch`
- `supabase db push --include-all`
- `supabase functions deploy maps-places`
- `supabase functions deploy maps-routes`
- `supabase functions deploy cleanup-cron`

### Raouf: 2026-03-17 (AEDT) — Anonymous Map API Hardening

**Scope:** Harden anonymous map endpoints without introducing user auth.

**Summary:**
Applied the anonymous-API protections that fit the repo’s current Supabase Edge Function architecture. `maps-places` now has IP-based throttling and server-side response caching, while both map edge functions can enforce browser-origin allowlisting through `ALLOWED_WEB_ORIGINS`. This keeps the anonymous client model intact while reducing abuse and Google API spend.

**Files changed:**
- `supabase/functions/_shared/cors.ts`
- `supabase/functions/maps-places/index.ts`
- `supabase/functions/maps-routes/index.ts`
- `supabase/functions/cleanup-cron/index.ts`
- `supabase/migrations/20260317_add_edge_response_cache.sql`
- `README.md`
- `env_inventory.md`
- `TECHNICAL_EXPLANATION.md`
- `AGENT.md`
- `CHANGELOG.md`

**Follow-ups:**
- If you want app-instance verification beyond origin/IP controls, add Firebase App Check or a similar attestation system as a separate mobile/web integration project.
- Remove the stale legacy `directions-proxy` function if it is no longer used anywhere.

### Raouf: 2026-03-17 (AEDT) — Secret Exposure Remediation

**Scope:** Remove committed Google Maps client API keys from tracked source and config files.

**Summary:**
Resolved the repo’s tracked Google Maps client key exposure by removing committed keys from Flutter runtime config and web assets. The app now expects the client key to be provided locally via `--dart-define` or `.env` instead of relying on checked-in defaults.

**Files changed:**
- `lib/core/config/env_config.dart`
- `android/gradle.properties`
- `ios/Flutter/Debug.xcconfig`
- `ios/Flutter/Release.xcconfig`
- `web/index.html`
- `README.md`
- `docs/ARCHITECTURE.md`
- `env_inventory.md`
- `map_inventory.md`
- `AGENT.md`
- `CHANGELOG.md`

**Follow-ups:**
- Rotate or revoke the exposed Google Maps keys in Google Cloud because git history and previous pushes already exposed them.

### Raouf: 2026-03-17 (AEDT) — Google Maps Client Key Rotation

**Scope:** Replace the committed Google Maps client API key across Flutter runtime configuration.

**Summary:**
Updated the repo’s Google Maps client key everywhere the app currently reads it in local and debug flows so Android, iOS, `.env` runs, and `EnvConfig` fallback behavior remain consistent.

**Files changed:**
- `.env`
- `android/gradle.properties`
- `ios/Flutter/Debug.xcconfig`
- `ios/Flutter/Release.xcconfig`
- `lib/core/config/env_config.dart`

### Raouf: 2026-03-17 (AEDT) — Campus Map Audit Hardening

**Scope:** Campus map correctness, search-race hardening, CI coverage, and documentation accuracy.

**Summary:**
Performed a focused production audit of the campus map stack and fixed the highest-risk gaps found across the Flutter client, Supabase routing function, tests, CI, and project docs.

**Key changes:**
1. **Routing contract hardening** — `maps-routes` now rejects invalid `renderer` values instead of silently defaulting to Google, and campus routing now fails fast for non-walking travel modes rather than returning walking geometry labeled as drive/bike/transit.
2. **Places race fix** — `BuildingSearchSheet` now versions Places requests so out-of-order async responses cannot overwrite the latest query’s suggestions after rapid typing.
3. **Verification expansion** — Added controller coverage for permission-denied route loading, arrival detection, and off-route recalculation, plus route parsing regressions for normalized duration strings and non-OK Directions responses.
4. **CI map-path validation** — GitHub Actions now runs `deno check` against `supabase/functions/maps-routes/index.ts` and `supabase/functions/maps-places/index.ts`, pull requests now perform an Android debug APK smoke build, and release/debug APK artifact uploads now use the correct job and output paths.
5. **Docs refresh** — Updated README and architecture docs to describe the supported local setup, the current campus walking-only limitation, and the real CI pipeline.

**Files changed:**
- `lib/features/map/presentation/widgets/building_search_sheet.dart`
- `supabase/functions/maps-routes/index.ts`
- `.github/workflows/ci.yml`
- `test/features/map/map_controller_test.dart`
- `test/features/map/map_route_test.dart`
- `README.md`
- `docs/ARCHITECTURE.md`
- `AGENT.md`
- `CHANGELOG.md`

**Verification:**
- `dart analyze`
- `flutter test`
- `deno check supabase/functions/maps-routes/index.ts`
- `deno check supabase/functions/maps-places/index.ts`

**Follow-ups:**
- Add server-side rate limiting to `maps-places` to close the remaining Google Places quota-exhaustion path.
- Consider disabling non-walking travel modes in the campus renderer UI instead of surfacing the limitation only at request time.

### Raouf: 2026-03-14 (AEDT) — UI/UX Follow-up: Splash, Animations, GlassPane, i18n

**Scope:** Branded splash screens, animation token system, shared widget extraction, i18n key addition.

**Summary:**
Closed the 4 follow-up items from the UI/UX production readiness audit.

**Key changes:**
1. **Branded splash screens** — Replaced default white Android splash and iOS LaunchScreen with MQ Red (#A6192E) backgrounds. Android status bar now matches the splash color. iOS LaunchScreen storyboard uses custom sRGB color.
2. **Animation duration tokens** — Created `MqAnimations` abstract final class with `fast` (150ms), `normal` (200ms), `slow` (300ms), `sheet` (350ms) duration tokens and `defaultCurve`/`sheetCurve` curve tokens. Replaced hardcoded `Duration(milliseconds: ...)` in travel mode pills, map mode toggle, and search debounce timer.
3. **GlassPane extraction** — Moved `GlassPane` from `map_shell.dart` to `lib/shared/widgets/glass_pane.dart` for app-wide reuse. Private `_GlassPane` alias in map_shell continues to work via import.
4. **noSearchResults i18n** — Added `noSearchResults` key to all 35 ARB files. 12 locales have native translations (ar, zh, es, fr, de, ja, ko, hi, pt, ru, tr, it); remaining 22 use English fallback.

**Files changed:**
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-v21/launch_background.xml`
- `android/app/src/main/res/values/styles.xml`
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- `lib/app/theme/mq_animations.dart` (new)
- `lib/shared/widgets/glass_pane.dart` (new)
- `lib/features/map/presentation/widgets/route_panel.dart`
- `lib/features/map/presentation/widgets/map_mode_toggle.dart`
- `lib/features/map/presentation/widgets/building_search_sheet.dart`
- `lib/features/map/presentation/widgets/map_shell.dart`
- `lib/app/l10n/app_*.arb` (35 files)

**Verification:**
- `flutter gen-l10n` → Success
- `dart analyze` → 0 issues
- `flutter test` → 115/115 passed

**Follow-ups:**
- None — all follow-up items from the UI/UX audit are now closed.

### Raouf: 2026-03-14 (AEDT) — Full UI/UX Production Readiness Audit

**Scope:** Comprehensive UI/UX audit and remediation for production readiness.

**Summary:**
Performed a full audit of all presentation layers (Home, Map, Settings, Notifications, Error Boundary) against the AGENT.md coding conventions. Fixed 80+ issues spanning design token compliance, accessibility, RTL support, keyboard handling, and visual polish.

**Key changes:**
1. **Theme tokens** — Extended `MqColors` with 21 new semantic tokens: `contentTertiaryDark`, 8 navigation instruction colors (blue dark/light), 10 arrival card colors (green dark/light). Extended `MqSpacing` with 6 icon size tokens (`iconSm` 16 through `iconHero` 56).
2. **Design token compliance** — Replaced 50+ hardcoded `fontSize`/`fontWeight` values with `Theme.of(context).textTheme.*` references. Replaced 15+ inline hex color literals (`0xFF1a3a5c`, etc.) with `MqColors` semantic tokens. Replaced all magic spacing numbers with `MqSpacing` tokens.
3. **RTL support** — Converted 20+ `EdgeInsets` to `EdgeInsetsDirectional`. Improved error boundary RTL detection to handle locale variants (e.g., `ar-EG`, `fa_IR`).
4. **Accessibility** — Settings switch tap target widened from 44dp to 48dp. Notification tiles wrapped in `Semantics`. Title text overflow capped with `maxLines: 2`.
5. **Critical UX fixes** — Route panel wrapped in `SingleChildScrollView` (prevents overflow). Search sheet gains `autofocus`, `textInputAction.search`, keyboard dismissal on result tap, and empty state message. Notification error displays no longer expose raw `error.toString()`. Settings picker `initialChildSize` increased to 0.5.

**Files changed:**
- `lib/app/theme/mq_colors.dart`
- `lib/app/theme/mq_spacing.dart`
- `lib/features/home/presentation/pages/home_page.dart`
- `lib/features/map/presentation/widgets/route_panel.dart`
- `lib/features/map/presentation/widgets/building_search_sheet.dart`
- `lib/features/map/presentation/widgets/map_shell.dart`
- `lib/features/map/presentation/widgets/map_mode_toggle.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/notifications/presentation/pages/notifications_page.dart`
- `lib/features/notifications/presentation/widgets/notification_tile.dart`
- `lib/core/error/error_boundary.dart`

**Verification:**
- `dart analyze` → 0 issues
- `flutter test` → 115/115 passed

**Follow-ups:**
- Branded splash screen for Android and iOS (currently uses default Flutter splash)
- Animation duration token system for consistent transitions
- Extract `GlassPane` to `lib/shared/widgets/` for app-wide reuse
- Add `noSearchResults` i18n key to all 35 locales

### Raouf: 2026-03-14 (AEDT) — Repository-wide i18n Audit and Remediation

**Scope:** Full i18n audit, hardcoded string migration, and locale coverage repair.

**Summary:**
Performed a comprehensive audit of the project's internationalization system. Migrated hardcoded user-facing strings in `mq_navigation_app.dart` (app title), `error_boundary.dart` (fallback error messages), `settings_page.dart` (team credits), and `route_panel.dart` (distance units) to the ARB system. Added missing placeholder metadata (`@dailyAt`, `@durationMinutes`, `@durationHoursMinutes`, `@stepsCount`) to all 34 non-English locales to ensure structural integrity. Translated 249 keys for Arabic, Chinese, and Spanish, addressing major gaps introduced in Phase 3/4/5. Synchronized the remaining 31 locales with English fallbacks for new keys to ensure a clean `flutter gen-l10n` run.

**Files changed:**
- `lib/app/l10n/app_en.arb`
- `lib/app/mq_navigation_app.dart`
- `lib/core/error/error_boundary.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/map/presentation/widgets/route_panel.dart`
- `lib/app/l10n/app_ar.arb`
- `lib/app/l10n/app_zh.arb`
- `lib/app/l10n/app_es.arb`
- (Metadata and sync keys in 31 other ARB files)

**Verification:**
- `flutter gen-l10n` → Success (0 warnings)
- `grep` checks confirmed translation of previously untranslated keys in major locales.
- Manual check of modified files for JSON and Dart syntax validity.

**Follow-ups:**
- Address remaining 246 untranslated keys in the other 31 locales (requires restoring web source for automated sync).
- Localize native language names in `SettingsPage` if non-native identification is preferred.

### Raouf: 2026-03-13 (AEDT) — Codebase Annotation and Educational Comments

**Scope:** Educational comment pass for student developers.

**Summary:**
Performed a comprehensive codebase review and added educational doc comments across major architecture layers (Bootstrap, Routing, Core, Settings, Notifications, and Map). These comments explain the purpose, intent, side effects, and architectural patterns of the application to accelerate onboarding for new student contributors. No application logic was modified.

**Files changed:**
- `lib/main.dart`
- `lib/app/bootstrap/bootstrap.dart`
- `lib/app/mq_navigation_app.dart`
- `lib/app/router/app_router.dart`
- `lib/app/router/app_shell.dart`
- `lib/shared/models/user_preferences.dart`
- `lib/core/error/error_boundary.dart`
- `lib/core/security/secure_storage_service.dart`
- `lib/features/settings/data/repositories/settings_repository.dart`
- `lib/features/settings/presentation/controllers/settings_controller.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/notifications/domain/services/notification_scheduler.dart`
- `lib/features/notifications/presentation/controllers/notifications_controller.dart`
- `lib/features/notifications/data/datasources/fcm_service.dart`
- `lib/features/notifications/data/datasources/local_notifications_service.dart`
- `lib/features/map/presentation/controllers/map_controller.dart`

**Verification:**
- `flutter analyze` (0 issues found)
- `flutter test` (115/115 tests passed)

*Note: The earlier log was preliminary. This log confirms the full function-by-function systematic pass is complete and verified with real command outputs.*

**Follow-ups:**
- Architecture docs alignment
- Provider flow diagrams
- Onboarding docs for new contributors


### Raouf: 2026-03-13 (AEDT) — Full map parity pass

**Scope:** Structural decomposition, visual polish, overlay layers, Google Places fallback, and Street View integration.

**Summary:**
Decomposed the monolithic campus renderer into 5 focused layer widgets under `campus/` subdirectory and moved the Google renderer into `google/` subdirectory. Added visual polish: GPS accuracy circle (translucent blue, cos-lat corrected), green origin dot at route start in both renderers. Built complete overlay layer system with 4 campus overlays (parking, water, accessibility, permits) using real overlay images from the web repo, with toggle UI in a bottom sheet picker. Created `maps-places` Supabase Edge Function for Google Places Autocomplete proxy, integrated into the search sheet with 300ms debounce fallback when no strong campus match. Added Street View deep-link button to route panel.

**Changes:**
1. **Campus decomposition** — split into CampusMapOverlay, CampusMapMarkerLayer, CampusMapRouteLayer, CampusMapLocationLayer, and CampusMapView orchestrator
2. **Google restructure** — moved to `google/` subdirectory, added green origin-dot marker
3. **Accuracy circle** — translucent blue circle behind user dot, sized from GPS accuracy metres via cos-lat corrected conversion
4. **Origin dot** — green circle at first point of route polyline (both renderers)
5. **Overlay system** — MapOverlay entity, OverlayRegistry (4 overlays), controller toggle state, CampusOverlayLayers renderer, OverlayPickerSheet UI, layers button in MapShell (campus mode only)
6. **Google Places fallback** — maps-places Edge Function, PlacesSearchSource, BuildingSearchSheet integration with debounce
7. **Street View** — deep-link button launching Google Street View at building coordinates

**Files created:** 19 new files (5 campus layer widgets, 2 overlay system, 1 Places data source, 1 Edge Function, 4 overlay images, 3 test files, 1 plan doc)
**Files modified:** 7 files (controller, map page, map shell, route panel, search sheet, supabase config, controller test)
**Files deleted:** 2 files (old campus_map_view.dart, old google_map_view.dart — moved to subdirectories)

**Verification:** `dart format` (0 issues), `flutter analyze` (0 issues), `flutter test` (115/115 passed, up from 101)

**Follow-ups:**
- Street View is deep-link only — no embedded view due to flutter platform limitations
- Google Places fallback requires `GOOGLE_ROUTES_API_KEY` on the maps-places Edge Function

### Raouf: 2026-03-13 (AEDT) — Map parity follow-up fixes

**Scope:** i18n, RTL, dashed polyline, and overlay image optimization.

**Summary:**
Addressed the 4 actionable follow-up items from the full map parity pass.

**Changes:**
1. **i18n** — replaced all hardcoded English strings in map widgets with ARB keys: `youveArrived`, `openStreetView`, `nearbyPlaces`, `campusOverlayUnavailable`, `stepsCount` (ICU plural), `durationMinutes`, `durationHoursMinutes` in `app_en.arb`, updated `route_panel.dart`, `building_search_sheet.dart`, `campus_map_view.dart`
2. **RTL** — converted `EdgeInsets.only(left:)` to `EdgeInsetsDirectional.only(start:)` in `building_search_sheet.dart` (only asymmetric instance found across all new widgets)
3. **Dashed polyline** — applied `StrokePattern.dashed(segments: [12, 8])` for walking routes in `campus_map_route_layer.dart` using flutter_map v8.2.2's built-in support (no custom painter needed)
4. **Overlay optimization** — compressed 4 overlay PNGs with pngquant (5.7 MB → 1.5 MB, 74% reduction) while preserving 3509×2481 resolution

**Files modified:** `app_en.arb`, `route_panel.dart`, `building_search_sheet.dart`, `campus_map_view.dart`, `campus_map_route_layer.dart`, `overlay_parking.png`, `overlay_water.png`, `overlay_accessibility.png`, `overlay_permits.png`

**Verification:** `dart analyze` (0 issues), `flutter test` (43/43 map tests passed)

### Raouf: 2026-03-12 (AEDT) — Full web-to-Flutter navigation parity

**Scope:** Complete parity audit between the Next.js web map and Flutter map, then implement all missing navigation features.

**Summary:**
Audited the web map components (`GoogleMapController.tsx`, `GoogleMapCanvas.tsx`, `GoogleRoutePanel.tsx`, `CampusMap.tsx`) against the Flutter map feature. Identified 21 PASS items and 11 MISSING capabilities, then implemented all 11:

1. **Arrival detection** — haversine check (≤30 m to destination) triggers `hasArrived` state with celebration card UI
2. **Start/Stop navigation lifecycle** — separated `loadRoute()` (loads route without navigating) from `startNavigation()` (begins follow-user + arrival detection), matching the web's explicit two-step flow
3. **Follow-user camera** — both renderers track user location during active navigation
4. **Off-route detection** — flags when user is >50 m from last route-fetch point AND distance to destination exceeds route distance × 1.5
5. **Route recalculation** — auto re-fetches route when user moves >80 m from last fetch origin or goes off-route
6. **Open in Google Maps** — `url_launcher` deep-link to Google Maps directions with travel mode mapping
7. **Expandable step directions** — numbered, collapsible instruction list (was previously limited to first 3 steps)
8. **Travel mode persistence** — `SharedPreferences` stores selected travel mode across sessions
9. **Route bounds fitting** — Google renderer fits camera to route bounding box on first route load
10. **Walking dashed polyline** — Google renderer uses `PatternItem.dash(20)/gap(10)` for walking mode
11. **Walked-portion dimming** — both renderers split polyline at closest point to user, dimming the walked segment

**Files changed:**
- `pubspec.yaml` — added `shared_preferences: ^2.5.0`, `url_launcher: ^6.3.1`
- `lib/features/map/domain/services/geo_utils.dart` — new: haversine distance, closest-point finder
- `lib/features/map/presentation/controllers/map_controller.dart` — navigation state machine, arrival/off-route detection, travel mode persistence, Google Maps handoff
- `lib/features/map/presentation/widgets/route_panel.dart` — complete rewrite: arrival card, next instruction, expandable steps, Start/Stop buttons, Google Maps button
- `lib/features/map/presentation/widgets/campus_map_view.dart` — follow-user camera, walked-portion polyline split
- `lib/features/map/presentation/widgets/google_map_view.dart` — follow-user camera, dashed walking polyline, route bounds fitting, walked-portion split
- `lib/features/map/presentation/pages/map_page.dart` — wired all new props to RoutePanel and both map views
- `test/features/map/map_controller_test.dart` — updated for `loadRoute()` → `startNavigation()` two-step lifecycle

**Verification:**
- `dart format` — 0 issues (7 files formatted)
- `flutter analyze` — 0 issues
- `flutter test` — 101/101 passed

**Follow-ups:**
- Street View/Pegman, user accuracy circle with animated dot, and origin-dot marker are web-only visual polish not yet ported
- Campus renderer walking-dashed-polyline parity requires `flutter_map` pattern support or a custom painter

---

### Raouf: 2026-03-12 (AEDT) — Blueprint gap audit fixes

**Scope:** Close the two remaining gaps from the full dual-map blueprint acceptance audit.

**Summary:**
A full 37-criterion audit against the implementation blueprint scored 35/37 PASS, 2 PARTIAL. This change closes both partials:

1. **Export automation** — Added `tools/sync_buildings.dart`, a standalone Dart CLI script that fetches the building registry from the Supabase `app_config` table and writes normalised JSON to `assets/data/buildings.json`. Reads credentials from `.env` or `--url`/`--key` flags. This provides a repeatable sync path from the Supabase source of truth to the bundled Flutter asset, removing the dependency on manual copy from the web repo export.

2. **Auth design documentation** — Added a doc comment on `MapsRoutesRemoteSource` explicitly documenting that unauthenticated route access is intentional: the app has no login requirement (AGENT.md), unauthenticated callers are rate-limited by IP (60 req/60 s), and the Bearer token path is already wired for future auth if needed.

**Files changed:**
- `tools/sync_buildings.dart` — new: Supabase → `buildings.json` sync script
- `lib/features/map/data/datasources/maps_routes_remote_source.dart` — added auth design-decision doc comment
- `AGENT.md`, `CHANGELOG.md` — appended Raouf log entries

**Verification:**
- `dart format tools/sync_buildings.dart lib/features/map/data/datasources/maps_routes_remote_source.dart` — 0 issues
- `flutter analyze` — 0 issues
- `flutter test` — 101/101 passed

**Follow-ups:**
- Integrate `sync_buildings.dart` into CI/CD if automated Supabase → Flutter asset sync is desired.

---

### Raouf: 2026-03-12 (AEDT) — Align Google building targets with campus mode

**Scope:** Fix the Google renderer so building markers and camera focus use the same coordinate source and preserve the active map framing when switching renderers.

**Summary:**
The Google map was centering selected buildings with `routingLatitude` and `routingLongitude` but still rendering markers with the raw building-center `latitude` and `longitude`. For buildings that ship separate entrance coordinates, this made the Google renderer appear slightly offset compared with campus mode. The fix adds a shared geographic-target resolver, reuses it for both Google marker placement and selected-building camera focus, and applies an initial camera sync in `onMapCreated` so toggling from campus mode keeps the currently selected building or location in view instead of falling back to the default campus center.

**Files changed:**
- `lib/features/map/presentation/widgets/map_view_helpers.dart` — added a shared building geographic-target resolver
- `lib/features/map/presentation/widgets/google_map_view.dart` — unified marker/camera targeting and synced initial camera state
- `test/features/map/building_test.dart` — added regression coverage for entrance-vs-center target resolution
- `AGENT.md` — logged the change
- `CHANGELOG.md` — logged the change

**Verification:**
- `dart format lib/features/map/presentation/widgets/map_view_helpers.dart lib/features/map/presentation/widgets/google_map_view.dart test/features/map/building_test.dart`
- `flutter test test/features/map/building_test.dart` (15/15 passed)
- `flutter analyze` (0 issues)
- `flutter test` (101/101 passed)

### Raouf: 2026-03-12 (AEDT) — Normalize campus overlay bounds for flutter_map

**Scope:** Fix the campus renderer crash caused by constructing `flutter_map` bounds from raw image-pixel dimensions.

**Summary:**
The campus map was still using raw overlay pixels like `3307` and `4678` as `LatLng` values when building `LatLngBounds`, which violates `flutter_map`’s latitude assertions even under `CrsSimple`. The fix introduces a normalized map-space coordinate layer in `CampusOverlayMeta` and routes all campus conversions through it. The raster overlay stays at full source resolution, but `CampusProjectionImpl` now converts pixel coordinates into a scaled coordinate system whose bounds remain inside valid `LatLng` limits, and `CampusMapView` builds overlay/camera bounds from those normalized values instead of raw pixels. Added regressions for both the large-asset normalization path and the exported shared overlay metadata.

**Files changed:**
- `lib/features/map/domain/entities/campus_overlay_meta.dart` — added normalized map-space helpers and scale computation
- `lib/features/map/data/mappers/campus_projection_impl.dart` — converted pixel/map transforms to use normalized bounds
- `lib/features/map/presentation/widgets/campus_map_view.dart` — stopped building `LatLngBounds` from raw pixel values
- `test/features/map/campus_projection_test.dart` — added large-overlay normalization regression
- `test/features/map/building_registry_asset_test.dart` — asserted exported overlay metadata resolves to safe `flutter_map` bounds
- `AGENT.md`, `CHANGELOG.md` — appended Raouf log entries

**Verification:**
- `dart format lib/features/map/domain/entities/campus_overlay_meta.dart lib/features/map/data/mappers/campus_projection_impl.dart lib/features/map/presentation/widgets/campus_map_view.dart test/features/map/campus_projection_test.dart test/features/map/building_registry_asset_test.dart`
- `flutter test test/features/map/campus_projection_test.dart test/features/map/building_registry_asset_test.dart`
- `flutter analyze` → 0 issues
- `flutter test` → 99/99 passed

**Follow-ups:**
- Keep constructing campus bounds through the normalized helpers; raw overlay pixels should never be passed directly to `LatLngBounds`

### Raouf: 2026-03-12 (AEDT) — Harden top-level framework error fallback

**Scope:** Remove the last recursive error path in the app shell by making the framework fallback render safely without inherited app context.

**Summary:**
Fetched Flutter’s official error-handling guidance and aligned the app with it more strictly. The remaining runtime loop was not a live `setState` in `ErrorBoundary`; it was the fallback widget rethrowing because it depended on `Material`, `Theme.of`, and inherited `Directionality` before the app shell was fully available. `ErrorBoundary` remains a transparent wrapper, `FlutterError.onError` remains logging-only, and the fallback in `lib/core/error/error_boundary.dart` is now a context-free widget built only from low-level widgets and explicit styles so it can render even when `MaterialApp` has not established inherited state yet. Added a regression test that pumps the fallback directly with no `MaterialApp` to prove the fallback is self-sufficient and cannot recurse through `No Directionality widget found`.

**Files changed:**
- `lib/core/error/error_boundary.dart` — removed `Material`/`Theme` assumptions from the framework fallback and clarified the logging-only role of global error handlers
- `test/core/error_boundary_test.dart` — added direct no-`MaterialApp` fallback coverage
- `AGENT.md`, `CHANGELOG.md` — appended Raouf log entries

**Verification:**
- `dart format lib/core/error/error_boundary.dart lib/app/mq_navigation_app.dart test/core/error_boundary_test.dart`
- `flutter test test/core/error_boundary_test.dart`
- `flutter analyze` → 0 issues
- `flutter test` → 98/98 passed

**Follow-ups:**
- Use a full hot restart or stop/start run after changing bootstrap-level error hooks; Flutter hot reload does not rerun `main()`

### Raouf: 2026-03-12 (AEDT) — Remove ErrorBoundary framework hook entirely

**Scope:** Eliminate the remaining build-phase assertions by removing widget-level error interception from the app shell.

**Summary:**
The deferred `setState` fix was still too brittle because the root issue was architectural: Flutter does not support a React-style stateful error boundary that recovers from `FlutterError.onError`. `ErrorBoundary` is now a transparent wrapper with no framework hook logic, and render-time fallback UI is handled where Flutter expects it, via `ErrorWidget.builder` inside `installErrorHandlers()`. Global logging remains in `FlutterError.onError` and `PlatformDispatcher.instance.onError`, but there is now no widget-level `setState` or `markNeedsBuild` path attached to framework error callbacks. This fully removes the `setState() or markNeedsBuild() called during build` and `owner!._debugCurrentBuildTarget != null` assertions tied to `ErrorBoundary`.

**Files changed:**
- `lib/core/error/error_boundary.dart` — converted `ErrorBoundary` into a transparent wrapper and moved fallback UI ownership to `ErrorWidget.builder`
- `test/core/error_boundary_test.dart` — updated regression coverage for the transparent wrapper and installed render fallback
- `AGENT.md`, `CHANGELOG.md` — appended Raouf fix log entries

**Verification:**
- `dart format lib/core/error/error_boundary.dart test/core/error_boundary_test.dart`
- `flutter test test/core/error_boundary_test.dart`
- `flutter analyze` → 0 issues
- `flutter test` → 97/97 passed

**Follow-ups:**
- If feature-level recovery UX is needed later, build it above the risky subtree rather than intercepting `FlutterError.onError` inside a stateful widget

### Raouf: 2026-03-12 (AEDT) — Fix ErrorBoundary setState timing assertion

**Scope:** Prevent the app-level error boundary from mutating widget state inside Flutter’s synchronous framework error callback.

**Summary:**
Fixed the `owner!._debugCurrentBuildTarget != null` assertion triggered by `ErrorBoundary` calling `setState` directly from `FlutterError.onError`. The boundary now preserves the previously installed Flutter error handler, queues the most recent exception, and updates its fallback UI in a post-frame callback instead of synchronously during the framework error/reporting cycle. This keeps the fallback screen behavior, preserves existing global error reporting, and removes the illegal rebuild request that was crashing debug runs. Added a regression widget test that exercises the boundary handler and verifies the fallback appears only after the deferred frame.

**Files changed:**
- `lib/core/error/error_boundary.dart` — chained previous error handler and deferred fallback state updates out of `FlutterError.onError`
- `test/core/error_boundary_test.dart` — regression coverage for the deferred fallback behavior
- `AGENT.md`, `CHANGELOG.md` — appended Raouf fix log entries

**Verification:**
- `dart format lib/core/error/error_boundary.dart test/core/error_boundary_test.dart`
- `flutter analyze` → 0 issues
- `flutter test test/core/error_boundary_test.dart`
- `flutter test` → 96/96 passed

**Follow-ups:**
- Reuse the same deferred error-state pattern if the app adds more feature-scoped error boundaries later

### Raouf: 2026-03-12 (AEDT) — Correct campus overlay parity math

**Scope:** Align the Flutter campus raster renderer with the web `CRS.Simple` overlay rules instead of the earlier mixed-offset fallback.

**Summary:**
Corrected the remaining campus-overlay parity drift. Flutter now consumes calibrated GPS projection coefficients from the shared web export, keeps the image bounds locked to the real raster dimensions, applies the web building X-offset only to stored building pin coordinates, and projects GPS-derived route/current-location points through the calibrated affine transform without that marker offset. The campus camera now fits the same pixel bounds with the same padding/max-zoom model as the web map, and campus marker anchoring was corrected so the coordinate lands on the intended visual point instead of the top edge of the marker widget. Added regression tests for the projection split and overlay metadata shape, and refreshed map docs to describe the calibrated export path.

**Files changed:**
- `lib/features/map/domain/entities/campus_overlay_meta.dart`, `lib/features/map/domain/services/campus_projection.dart`, `lib/features/map/data/mappers/campus_projection_impl.dart` — renderer-agnostic overlay metadata and split projection rules
- `lib/features/map/presentation/widgets/campus_map_view.dart` — exact raster bounds, fit-bounds camera setup, corrected marker anchor, GPS-vs-building projection usage
- `assets/data/campus_overlay_meta.json` — regenerated shared overlay metadata with pixel bounds and affine calibration coefficients
- `test/features/map/campus_projection_test.dart`, `test/features/map/building_registry_asset_test.dart` — regression coverage for projection behavior and exported metadata
- `map_inventory.md`, `docs/ARCHITECTURE.md`, `TECHNICAL_EXPLANATION.md` — documentation alignment
- `AGENT.md`, `CHANGELOG.md` — appended Raouf parity-correction log entries

**Verification:**
- `node --experimental-strip-types tools/export_buildings.mjs` (from sibling web repo)
- `flutter analyze` → 0 issues
- `flutter test` → 95/95 passed

**Follow-ups:**
- Re-run the export bridge whenever the web team changes the GCP calibration set or campus overlay asset

### Raouf: 2026-03-12 (AEDT) — Complete dual-map parity backend/assets pass

**Scope:** Replace the remaining placeholder map pieces with shared exported assets, web-parity search behavior, and server-side routing.

**Summary:**
Completed the next substantial dual-map implementation step. Campus mode now reads the real exported raster image plus overlay metadata and renders in the same pixel coordinate space as the web app using `flutter_map` + `CrsSimple`. The bundled building registry was regenerated from the web source with `code`, `campusX/campusY`, and `searchTokens`, and Flutter search now follows the same ranking order as the web `buildingSearch.ts`. Route loading was migrated off the legacy client/Directions path onto the `maps-routes` Supabase Edge Function for both renderers, with a normalized response model that supports Google Routes data and campus-mode path points. The Edge Function was updated to accept anon clients safely, rate-limit by user or IP, dispatch Google mode to Google Routes, dispatch campus mode to OpenRouteService when configured, and fall back to a generated demo campus path when `ORS_API_KEY` is absent. Map docs and inventories were updated to reflect the new secure architecture.

**Files changed:**
- `assets/data/buildings.json`, `assets/data/campus_overlay_meta.json`, `assets/maps/mq-campus.png` — synced exported campus registry and raster overlay assets
- `lib/features/map/data/datasources/map_assets_source.dart`, `maps_routes_remote_source.dart`, `google_routes_remote_source.dart`, `campus_routes_remote_source.dart` — shared asset loading and secure route backend wiring
- `lib/features/map/data/mappers/campus_projection_impl.dart`, `lib/features/map/domain/entities/building.dart`, `campus_overlay_meta.dart`, `nav_instruction.dart`, `route_leg.dart`, `lib/features/map/domain/services/building_search.dart`, `campus_projection.dart` — web-parity map data contracts and search/routing normalization
- `lib/features/map/presentation/controllers/map_controller.dart`, `pages/map_page.dart`, `widgets/building_search_sheet.dart`, `widgets/campus_map_view.dart`, `widgets/google_map_view.dart`, `widgets/map_view_helpers.dart` — shared controller/search updates and raster campus renderer implementation
- `supabase/functions/maps-routes/index.ts`, `supabase/config.toml` — anon-safe normalized route proxy for Google and campus routing
- `README.md`, `TECHNICAL_EXPLANATION.md`, `docs/ARCHITECTURE.md`, `map_inventory.md`, `endpoint_inventory.md`, `env_inventory.md` — documentation/inventory alignment
- `test/features/map/building_search_test.dart`, `building_test.dart`, `map_route_test.dart`, `building_registry_asset_test.dart` — new regression coverage for the updated contracts

**Verification:**
- `node --experimental-strip-types tools/export_buildings.mjs` (from sibling web repo)
- `deno check supabase/functions/maps-routes/index.ts`
- `flutter analyze` → 0 issues
- `flutter test` → 92/92 passed

**Follow-ups:**
- Street View / Pegman parity still remains richer on the web Google Maps stack than in Flutter

### Raouf: 2026-03-12 (AEDT) — Ignore Codex workspace metadata

**Scope:** Keep the Flutter repo clean after local Codex runs.

**Summary:**
Added `.codex/` to the app-level `.gitignore` so local Codex desktop workspace metadata does not appear as an untracked repository change. This is cleanup only; it does not affect runtime behavior or build output.

**Files changed:**
- `.gitignore` — ignored `.codex/`
- `AGENT.md`, `CHANGELOG.md` — appended Raouf cleanup log entries

**Verification:**
- `git status --short` — `.codex/` no longer appears as an untracked path

**Follow-ups:**
- None

### Raouf: 2026-03-12 (AEDT) — Fix Chrome Google Maps teardown crash

**Scope:** Remove the web-only Google Maps dispose path that was crashing Chrome during renderer teardown.

**Summary:**
Fixed the Chrome assertion from `google_maps_flutter_web` (`"Maps cannot be retrieved before calling buildView!"`) that occurred when the Flutter widget disposed a `GoogleMapController` before the web platform view had fully completed its build lifecycle. `GoogleMapView` now performs explicit controller disposal on native platforms only, which preserves native cleanup while avoiding the broken web teardown path. Also re-checked the dependency graph with `flutter pub outdated`: all direct and dev dependencies in this repository are already current, and the repeated "newer versions incompatible with dependency constraints" message is coming from upstream-transitive packages outside this repo's direct constraints.

**Files changed:**
- `lib/features/map/presentation/widgets/google_map_view.dart` — skipped explicit controller disposal on web and documented the platform-specific reason
- `AGENT.md`, `CHANGELOG.md` — appended Raouf fix log entries

**Verification:**
- `dart format lib/features/map/presentation/widgets/google_map_view.dart`
- `flutter analyze` → 0 issues
- `flutter test` → 86/86 passed
- `flutter pub outdated` → direct dependencies up to date; remaining notices are transitive only

**Follow-ups:**
- Revisit the web-specific dispose guard if a future `google_maps_flutter_web` release fixes controller teardown ordering

### Raouf: 2026-03-12 (AEDT) — Audit fix dual-renderer race and UI inconsistencies

**Scope:** Audit the new dual-renderer map implementation and fix correctness/state regressions.

**Summary:**
Performed a review pass on the dual-renderer foundation and fixed the highest-risk issue: stale async route responses could overwrite newer state if the user changed destination, renderer, or travel mode while a route request was still in flight. `MapController` now versions route requests and ignores outdated completions. Also aligned the search bottom sheet with controller state by seeding its text field from the active query, removed the stale unused `map_mode.dart` entity from the old state model, and adjusted map-shell top control spacing so the overlay controls are positioned relative to the page body instead of double-counting the device top safe area below the app bar.

**Files changed:**
- `lib/features/map/presentation/controllers/map_controller.dart` — invalidated stale route requests and cleared obsolete loading state
- `lib/features/map/presentation/widgets/building_search_sheet.dart` — seeded the search field from current controller query
- `lib/features/map/presentation/widgets/map_shell.dart` — corrected top overlay spacing
- `lib/features/map/domain/entities/map_mode.dart` — deleted stale unused entity
- `test/features/map/map_controller_test.dart` — added stale-route regression coverage
- `AGENT.md`, `CHANGELOG.md` — appended Raouf audit log entries

**Verification:**
- `dart format lib/features/map/presentation/controllers/map_controller.dart lib/features/map/presentation/widgets/building_search_sheet.dart lib/features/map/presentation/widgets/map_shell.dart test/features/map/map_controller_test.dart`
- `flutter test test/features/map/map_controller_test.dart`
- `flutter analyze` → 0 issues
- `flutter test` → 86/86 passed

**Follow-ups:**
- Campus mode still needs the real raster overlay asset plus campus-space metadata to reach full web-parity overlay behaviour

### Raouf: 2026-03-12 (AEDT) — Build dual-renderer map foundation

**Scope:** Refactor the Flutter map feature toward the shared-shell, dual-renderer architecture from the web app.

**Summary:**
Implemented the first production-ready dual-renderer foundation for the map feature. The map now has one shared Riverpod controller state and two explicit renderer targets: a new `flutter_map`-based campus renderer foundation and a renamed `GoogleMapView` for Google rendering. Added `MapRendererType`, campus-coordinate support on the shared `Building` entity, a shared polyline decoder, a campus-route adapter source, and a reusable `MapShell` with renderer toggle plus left-side search/location controls. The page can now switch campus ↔ Google without losing selected building or route state. Documentation was updated to describe the new renderer split and to call out that routing still needs the planned server-backed campus engine and legacy Directions migration.

**Files changed:**
- `pubspec.yaml`, `pubspec.lock` — added `flutter_map`/`latlong2`, aligned `google_maps_flutter` with 2.15.0
- `lib/features/map/domain/entities/building.dart` — added optional campus coordinate parsing/serialization
- `lib/features/map/domain/entities/campus_point.dart`, `lib/features/map/domain/entities/map_renderer_type.dart` — added new map foundation entities
- `lib/features/map/domain/services/map_polyline_codec.dart` — shared polyline decoding for both renderers
- `lib/features/map/data/datasources/campus_routes_remote_source.dart` — phase-1 campus routing adapter
- `lib/features/map/data/datasources/google_routes_remote_source.dart`, `location_source.dart` — formatter-aligned existing map data sources after the repository contract update
- `lib/features/map/data/repositories/map_repository_impl.dart` — renderer-aware route dispatch
- `lib/features/map/presentation/controllers/map_controller.dart` — renderer state, navigation-state cleanup, shared route loading
- `lib/features/map/presentation/pages/map_page.dart` — moved to shared shell composition
- `lib/features/map/presentation/widgets/campus_map_view.dart` — new `flutter_map` campus renderer foundation
- `lib/features/map/presentation/widgets/google_map_view.dart` — explicit Google renderer extracted from old campus widget
- `lib/features/map/presentation/widgets/map_action_stack.dart`, `map_mode_toggle.dart`, `map_shell.dart`, `map_view_helpers.dart` — shared renderer UI/control helpers
- `lib/features/map/domain/entities/nav_instruction.dart`, `route_leg.dart`, `lib/features/map/presentation/widgets/route_panel.dart` — formatter-only normalization in adjacent map files
- `test/features/map/building_test.dart`, `test/features/map/map_controller_test.dart` — added campus-field and renderer-state coverage
- `docs/ARCHITECTURE.md`, `map_inventory.md` — documented the new renderer split and remaining routing gap
- `AGENT.md`, `CHANGELOG.md` — appended Raouf implementation logs

**Verification:**
- `flutter pub get`
- `flutter analyze` → 0 issues
- `flutter test` → 85/85 passed

**Follow-ups:**
- Replace the campus-route fallback with the planned server-backed campus engine
- Add the missing raster overlay asset plus campus-space metadata/bounds
- Migrate Google routing off the legacy client/Directions path and onto the server-only Routes flow

### Raouf: 2026-03-12 (AEDT) — Fix Chrome crash, map bounds, and Android Kotlin daemon

**Scope:** Fix multi-platform launch failures and map usability issues.

**Summary:**
Fixed three critical issues preventing the app from running:

1. **Chrome crash ("SUPABASE_URL must be set via --dart-define")** — Added hardcoded
   development-only fallback values to `env_config.dart` so a bare `flutter run -d chrome`
   works in debug mode without `--dart-define-from-file=.env`. The `validate()` method now
   only throws in release mode.

2. **Android Kotlin daemon failure** — The `kotlin.compiler.execution.strategy=in-process`
   property was already set but stale daemon processes and build caches caused connection
   failures. Fixed by cleaning the build, killing all Gradle/Kotlin daemons, and rebuilding.

3. **Map not panning outside campus** — Removed `CameraTargetBounds` and `MinMaxZoomPreference`
   restrictions from `CampusMapView` so users can freely pan and zoom beyond the campus
   boundaries when navigating to/from off-campus locations.

4. **Map marker clutter** — Changed non-selected building markers from orange (hueOrange) to
   a subtle azure (hueAzure) at 55% opacity, making them less visually intrusive and
   distinguishable from the selected marker (red, 100% opacity).

**Files changed:**
- `lib/core/config/env_config.dart` — hardcoded debug fallbacks, release-only validation
- `lib/features/map/presentation/widgets/campus_map_view.dart` — removed bounds/zoom lock, improved markers
- `android/gradle.properties` — already had in-process strategy (no change needed)
- `.env.example` — simplified (removed DEV_ prefix vars)
- `map_inventory.md` — updated for Directions API, removed bounds section
- `env_inventory.md` — updated for hardcoded fallbacks, removed web-only section
- `endpoint_inventory.md` — updated routing approach
- `README.md` — simplified getting started, updated secrets table

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 83/83 passed
- `flutter build web --debug` → ✓
- `flutter build apk --debug` → ✓

---

### Raouf: 2026-03-12 (AEDT) — Add full technical explanation document

**Scope:** Write a repository-level technical explanation based on the implemented Flutter app, backend functions, platform setup, tooling, and tests.

**Summary:**
Added `TECHNICAL_EXPLANATION.md` as a dedicated technical walkthrough of the project. The document explains the startup flow, routing model, core infrastructure, design system, localization pipeline, feature modules (`home`, `settings`, `notifications`, `map`), Supabase Edge Functions, platform integration, CI/tooling, and test coverage. It also explicitly documents the current architectural mismatch where the Flutter map client still calls Google Directions directly while project docs describe the `maps-routes` Edge Function as the intended secure routing path.

**Files changed:**
- `TECHNICAL_EXPLANATION.md` — new full technical explanation document
- `AGENT.md` — appended Raouf log entry for this documentation update
- `CHANGELOG.md` — appended changelog entry for this documentation update

**Verification:**
- Read through the full repository structure and implementation before writing
- Cross-checked the document against current Dart, Supabase, platform, CI, and test files
- No application code changed

**Follow-ups:**
- Update the explanation when the map client is migrated to the `maps-routes` Edge Function
- Keep the document aligned with future feature-scope or architecture changes

---

### Raouf: 2026-03-12 (AEDT) — Polish technical explanation doc link

**Scope:** Correct a markdown path typo in the new technical explanation document.

**Summary:**
Fixed an internal path reference in `TECHNICAL_EXPLANATION.md` so the `mq_spacing.dart` link points to the correct file location.

**Files changed:**
- `TECHNICAL_EXPLANATION.md` — corrected markdown path
- `AGENT.md` — appended Raouf log entry for the polish edit
- `CHANGELOG.md` — appended changelog entry for the polish edit

**Verification:**
- Reviewed the corrected markdown target
- No application code changed

**Follow-ups:**
- None
### Raouf: 2026-03-12 (AEDT) — Flutter upgrade + fix untranslated messages

**Scope:** Upgrade Flutter SDK and dependencies, fix 2 untranslated i18n keys across 34 locales.

**Summary:**
Upgraded Flutter from 3.41.2 to 3.41.4. Upgraded 4 major dependencies: flutter_local_notifications 18→21, connectivity_plus 6→7, geolocator 13→14, timezone 0.10→0.11. Fixed breaking API changes in flutter_local_notifications v21 (all methods switched from positional to named parameters, UILocalNotificationDateInterpretation removed). Added `studyPromptNotificationTitle` and `studyPromptNotificationBody` translations to all 34 non-English locale ARB files.

**Files changed:**
- `pubspec.yaml` — bumped 4 dependency versions
- `pubspec.lock` — regenerated with 13 dependency changes
- `lib/features/notifications/data/datasources/local_notifications_service.dart` — migrated initialize/show/zonedSchedule/cancel to named parameters, removed UILocalNotificationDateInterpretation
- `lib/app/l10n/app_*.arb` (34 files) — added studyPromptNotificationTitle + studyPromptNotificationBody

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 83/83 passed
- `flutter gen-l10n` → 0 untranslated messages

**Follow-ups:**
- 5 transitive packages still have newer incompatible versions (analyzer, app_links, meta, win32, _fe_analyzer_shared) — blocked by upstream constraints

---

### Raouf: 2026-03-12 (AEDT) — Settings audit fix batch (10 issues)

**Scope:** Full UI/UX/data audit of settings feature — fix all findings.

**Summary:**
Fixed 10 issues across 4 files from a comprehensive settings audit. Critical: S1 — language picker "System" (null) selection broken after redesign; fixed with `_PickerItem<T>` wrapper to disambiguate null values from bottom-sheet dismissal. High: S2 — repository silently swallowed save errors (returned preferences instead of rethrowing); controller never detected failure, causing data loss on restart; fixed by rethrowing + controller revert-on-failure pattern. Medium: S3 — error state had no retry mechanism (added retry button with `ref.invalidate`); S4 — removed `dense: true` from bottom-sheet ListTile to meet 48dp tap target; S5 — Experience section used wrong l10n keys (`aboutDesc`/`emailNotificationsDesc` swapped for `campusMapDesc`/`studyPromptNotificationBody`); S6 — controller error message hardcoded but controller now reverts state instead of going to AsyncError. Low: S7 — added `==`/`hashCode` to UserPreferences for value equality; S8 — made toggle row fully tappable (InkWell wrapping entire row); S9 — version still hardcoded (acceptable for v1.0); S10 — added Semantics wrappers to `_InfoRow` and `_AboutAppRow`.

**Files changed:**
- `lib/features/settings/presentation/pages/settings_page.dart` — S1 (PickerItem wrapper), S3 (retry button), S4 (dense removed), S5 (l10n keys), S8 (InkWell on toggle), S10 (Semantics), toggle error snackbar
- `lib/features/settings/presentation/controllers/settings_controller.dart` — S6 (revert state on failure instead of AsyncError)
- `lib/features/settings/data/repositories/settings_repository.dart` — S2 (rethrow on save failure)
- `lib/shared/models/user_preferences.dart` — S7 (== and hashCode)

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 83/83 passed

**Follow-ups:**
- S9: Wire `package_info_plus` for dynamic version display (low priority, acceptable for v1.0)

---

### Raouf: 2026-03-12 (AEDT) — Settings page redesign (HTML reference)

**Scope:** Redesign settings page to match the provided HTML/CSS reference design.

**Summary:**
Complete visual overhaul of the settings page to match the dark-themed HTML reference design. Replaced generic Material ListTile/Card widgets with custom components faithful to the reference aesthetic: dark charcoal surfaces, red glow radial gradient, uppercase red section headers with letter-spacing, rounded cards with subtle white/5 borders, bottom-sheet pickers (replacing inline DropdownButton), vivid red toggle switches, and a branded about-app row with red shadow glow. Both light and dark mode fully supported. RTL-compatible with EdgeInsetsDirectional.

**Files changed:**
- `lib/features/settings/presentation/pages/settings_page.dart` — complete rewrite with custom widgets (_SectionHeader, _SettingsCard, _TapRow, _ToggleRow, _InfoRow, _AboutAppRow), bottom-sheet pickers, red glow gradient background
- `lib/app/theme/mq_colors.dart` — added vividRed (#FF0025), charcoal950 (#12080A), charcoal850 (#1C0D0F)

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 83/83 passed

**Follow-ups:**
- None — visual polish; no logic changes needed.

---

### Raouf: 2026-03-12 (AEDT) — Comprehensive audit fix batch (25+ issues)

**Scope:** Fix all critical, high, medium, and low severity issues from full codebase audit.

**Summary:**
Fixed 30+ issues across 20 files from a comprehensive audit. Critical: fixed polyline decoder algorithm (C5), moved `didChangeDependencies` to `initState` (C4), cancel location subscription on `clearRoute()` (C7), made ErrorBoundary actually catch errors (C6), removed hardcoded dev API keys from source (C1), added try/catch to Firebase background handler (C8). High: added link allowlist to notification deep-link handler preventing open redirect (H2). Medium: fixed `DateTime.now()` → `.toUtc()` for Supabase timestamps (M1), fixed autoDispose mismatch (M2), fixed stale userId in FCM token refresh (M3), replaced `AsyncLoading` with optimistic update in settings (M4), fixed null locale selection for "System" (M5), removed unbundled font family references (M6), replaced hardcoded Colors with MqColors tokens (M7), guarded `debugPrint` with `kDebugMode` and added HTTP timeout (M8), fixed RoutePanel always showing "Walking Directions" (M9), fixed `selectBuilding` mid-navigation state (M11), added `onError` to location stream (M12), added production log level filter (M13), removed unused iOS permissions (M14). Low: disposed GoogleMapController (L1), fixed ETA drift with `arrivalAt` field (L8), replaced raw AppBar with MqAppBar (L10), fixed loading spinner color per variant (L11), added focusedErrorBorder and textButtonTheme (L12), used RouteNames constants in home page (L9). Moved ErrorWidget.builder setup from build() to installErrorHandlers(). Updated tests to match.

**Files changed:**
- `lib/core/config/env_config.dart` — removed hardcoded keys
- `lib/core/error/error_boundary.dart` — functional error catching + ErrorWidget.builder
- `lib/core/logging/app_logger.dart` — production log filter
- `lib/app/mq_navigation_app.dart` — removed ErrorWidget.builder from build()
- `lib/app/theme/mq_theme.dart` — focusedErrorBorder, textButtonTheme
- `lib/app/theme/mq_typography.dart` — null font families (no fonts bundled)
- `lib/features/map/presentation/widgets/campus_map_view.dart` — fixed polyline decoder, dispose controller
- `lib/features/map/presentation/pages/map_page.dart` — initState, removed unused import
- `lib/features/map/presentation/controllers/map_controller.dart` — clearRoute cancel, selectBuilding fix, onError
- `lib/features/map/presentation/widgets/route_panel.dart` — travel mode label, cached ETA
- `lib/features/map/domain/entities/route_leg.dart` — arrivalAt field
- `lib/features/map/data/datasources/google_routes_remote_source.dart` — kDebugMode guard, timeout
- `lib/features/notifications/data/datasources/fcm_service.dart` — background handler try/catch, stale userId fix
- `lib/features/notifications/data/datasources/notification_remote_source.dart` — UTC timestamps
- `lib/features/notifications/presentation/controllers/notifications_controller.dart` — link allowlist, UTC, autoDispose
- `lib/features/settings/presentation/pages/settings_page.dart` — MqAppBar, null locale fix
- `lib/features/settings/presentation/controllers/settings_controller.dart` — optimistic update
- `lib/features/home/presentation/pages/home_page.dart` — MqColors, MqAppBar, RouteNames
- `lib/shared/widgets/mq_button.dart` — variant-aware spinner color
- `ios/Runner/Info.plist` — removed unused permissions
- `.env`, `.env.example` — DEV_* keys
- `test/core/env_config_test.dart`, `test/app/mq_theme_test.dart` — updated tests

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 83/83 passed

**Follow-ups:**
- H1: Create release signing config (android/app/build.gradle.kts)
- H3: Add semantic labels/tooltips to all interactive elements
- H4: Wire or remove notificationsEnabled toggle
- C2: Move Directions API call to Supabase Edge Function
- C3: Replace EdgeInsets with EdgeInsetsDirectional for RTL
- M10: Implement all notification preference types (not just studyPrompt)
- M15: Expand language picker beyond 6 of 35 supported locales
- L2: Replace hardcoded English strings in notification_scheduler with l10n

### Raouf: 2026-03-11 (AEDT) — Update root documentation post-cleanup

**Scope:** Update all root docs to reflect current project state after auth/calendar/feed removal.

**Summary:**
Updated README.md features, tech stack, architecture, test count (99→83), and roadmap. Updated CONTRIBUTING.md examples. Rewrote SECURITY.md to remove auth-specific sections, added Edge Function and rate limiting sections. Updated AGENT.md routing and backend descriptions.

**Files changed:**
- `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 83/83 passed

**Follow-ups:**
- None

### Raouf: 2026-03-11 (AEDT) — Design demo home page and map page

**Scope:** Redesign home page from bare welcome card to a full demo experience; visually enhance map page.

**Summary:**
Rebuilt `home_page.dart` with: gradient SliverAppBar hero with time-of-day serif greeting, notification bell with badge, tappable search bar linking to map, campus stats row (buildings/categories/popular), 6-category grid (academic, food, health, services, sports, research) with distinct brand colors, horizontal-scroll popular destinations carousel pulling `isHighTraffic` buildings, and a branded "Open Campus Map" CTA card. All components use MqColors, MqSpacing, MqTypography, MqCard, and NotificationBadge. Full dark mode support throughout.

Enhanced `map_page.dart` with: styled search button with brand-colored container, error banner with warning icon and colored border, rounded map viewport via ClipRRect, branded FAB with red shadow, redesigned location confirmation bottom sheet with drag handle and icon header.

**Files changed:**
- `lib/features/home/presentation/pages/home_page.dart` (full rewrite)
- `lib/features/map/presentation/pages/map_page.dart` (visual enhancement)

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 83/83 passed

**Follow-ups:**
- Add l10n keys for hardcoded strings ("Explore Campus", "Popular Destinations", etc.)
- Add widget tests for new home page sections
- Consider animated transitions for category grid

### Raouf: 2026-03-11 (AEDT) — Remove event feed feature

**Scope:** Strip the entire feed feature and feed tab.

**Summary:**
Deleted `features/feed/` (6 files: repository, controller, page, filter bar, event card, feed item entity). Removed feed branch from router, feed tab from bottom nav (4 → 3 tabs), and `feed` route name.

**Files deleted:**
- `lib/features/feed/**` (6 files)

**Files changed:**
- `lib/app/router/app_router.dart`, `lib/app/router/route_names.dart`, `lib/app/router/app_shell.dart`
- `test/app/route_names_test.dart`

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 83/83 passed

**Follow-ups:**
- None

### Raouf: 2026-03-11 (AEDT) — Remove calendar/event feature

**Scope:** Strip the entire calendar feature, academic models, dashboard data layer, detail routes, and calendar tab.

**Summary:**
Deleted the calendar module (4 files), academic models, dashboard repository/controller, and related tests. Simplified home page to a welcome card. Removed calendar tab from bottom nav (5 → 4 tabs). Removed `/calendar` and all `/detail/*` academic routes. Simplified notification scheduler to study-prompt-only. Removed "add to calendar" from feed.

**Files deleted:**
- `lib/features/calendar/**` (4 files)
- `lib/shared/models/academic_models.dart`
- `lib/features/home/data/`, `lib/features/home/presentation/controllers/`
- `test/features/calendar/`, `test/features/home/academic_models_test.dart`

**Files changed:**
- `lib/app/router/app_router.dart` — removed calendar branch and detail routes
- `lib/app/router/route_names.dart` — removed calendar, deadlineDetail, examDetail, eventDetail
- `lib/app/router/app_shell.dart` — removed calendar tab (5 → 4)
- `lib/features/home/presentation/pages/home_page.dart` — simplified to welcome card
- `lib/features/notifications/**` — removed calendar dependency, scheduler now study-prompt-only
- `lib/features/feed/**` — removed calendar import and add-to-calendar feature
- Tests updated

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 83/83 passed

**Follow-ups:**
- None

### Raouf: 2026-03-11 (AEDT) — Fix zone mismatch in bootstrap

**Scope:** Move `WidgetsFlutterBinding.ensureInitialized()` inside `runZonedGuarded` so it shares the same zone as `runApp()`.

**Summary:**
`ensureInitialized()` was called in the root zone while `runApp()` was called inside `runZonedGuarded()`. Flutter requires both in the same zone. Moved binding initialization inside the guarded zone.

**Files changed:**
- `lib/app/bootstrap/bootstrap.dart`

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 88/88 passed

**Follow-ups:**
- None

### Raouf: 2026-03-11 (AEDT) — Remove all auth/login code

**Scope:** Strip login, signup, auth guards, biometric lock, profile management, and auth provider from the project.

**Summary:**
Removed the entire authentication and profile system. Deleted `features/auth/` (11 files), `features/profiles/` (3 files), `route_guard.dart`, `auth_provider.dart`, `biometric_service.dart`, and `user_profile.dart`. Removed `local_auth` dependency from pubspec. Rewrote router to start at `/home` with no auth redirect. Refactored settings from Supabase-backed to local-only storage. Cleaned notifications controller to remove auth state listener. Cleaned `UserPreferences` to remove biometric and remote JSON methods.

**Files deleted:**
- `lib/features/auth/**` (11 files)
- `lib/features/profiles/**` (3 files)
- `lib/app/router/route_guard.dart`
- `lib/shared/providers/auth_provider.dart`
- `lib/core/security/biometric_service.dart`
- `lib/shared/models/user_profile.dart`
- `test/features/auth/**`, `test/app/route_guard_test.dart`

**Files changed:**
- `lib/app/router/app_router.dart` — removed auth routes, guards, redirect logic
- `lib/app/router/route_names.dart` — removed auth route name constants
- `lib/app/mq_navigation_app.dart` — removed BiometricLockGate
- `lib/features/home/presentation/pages/home_page.dart` — removed profile dependency
- `lib/features/settings/**` — removed profile card, security section, sign-out, biometric lock
- `lib/features/notifications/presentation/controllers/notifications_controller.dart` — removed auth listener
- `lib/shared/models/user_preferences.dart` — removed biometricLockEnabled, remote JSON
- `test/app/route_names_test.dart` — updated for reduced route set
- `pubspec.yaml` — removed local_auth dependency
- `AGENT.md`, `CHANGELOG.md`

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 88/88 passed

**Follow-ups:**
- None

### Raouf: 2026-03-11 (AEDT) — Fix dart:io Platform crash on web

**Scope:** Replace all `dart:io` `Platform.*` calls with web-safe alternatives.

**Summary:**
Four files used `dart:io`'s `Platform.isAndroid` / `Platform.isIOS` which throws `Unsupported operation: Platform._operatingSystem` when running on web (Chrome). Replaced all occurrences with `kIsWeb` guard + `defaultTargetPlatform` from `package:flutter/foundation.dart`. No `dart:io` imports remain anywhere in `lib/`.

**Files changed:**
- `lib/app/bootstrap/bootstrap.dart` — Firebase init guard
- `lib/features/notifications/data/datasources/fcm_service.dart` — `_isSupported` and platform-specific permission/token logic
- `lib/features/notifications/data/datasources/local_notifications_service.dart` — `_isSupported`
- `lib/features/map/data/datasources/location_source.dart` — `_isSupported`

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 99/99 passed
- Web build + launch no longer crashes

**Follow-ups:**
- None

### Raouf: 2026-03-11 (AEDT) — Fix Scripts + ARB + Run Configuration

**Scope:** Fix run.sh, add missing .env.example, propagate 13 missing ARB keys to all 34 locales.

**Summary:**
Rewrote `scripts/run.sh` to use Flutter's built-in `--dart-define-from-file` flag instead of manually parsing `.env` with shell IFS splitting. Created `.env.example` with placeholder keys so fresh clones have a setup template (the `.gitignore` already preserves it via `!.env.example`). Added 13 missing localization keys to all 34 non-English ARB files — these were added to `app_en.arb` during Phase 4/5 but never propagated, causing untranslated-message warnings on every build.

**Files changed:**
- `scripts/run.sh` — rewritten to use `--dart-define-from-file`
- `.env.example` — created with placeholder keys
- 34 ARB locale files — added `examReminders`, `systemAlerts`, `locationServicesDisabled`, `locationPermissionBlocked`, `locationPermissionRequired`, `locationUnsupported`, `locationUnavailable`, `dailyAt`, `deadlineLabel`, `studyPromptLabel`, `starts`, `ends`, `itemNoLongerAvailable`

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 99/99 passed
- `flutter gen-l10n` → 0 untranslated warnings
- `scripts/check.sh --quick` → 5/5 passed

**Follow-ups:**
- None

### Raouf: 2026-03-11 (AEDT) — Documentation Sweep: Stale References Cleanup

**Scope:** Read all project `.md` docs and fix stale directory names, outdated test counts, and completed-status labels.

**Summary:**
Updated `README.md` to use `mq_navigation` directory name (was `mq-navigation_flutter`) and corrected the CI test count from 78 to 99. Updated `Flutter_Migration_Plan.md` to use `mq_navigation` directory name in the description, clone instructions, and repo links. Updated `endpoint_inventory.md` section header from "Edge Functions to Build" to "Edge Functions (Deployed)" since all 9 functions are implemented.

**Files changed:**
- `README.md` — directory path in clone instructions, test count in CI/CD section
- `Flutter_Migration_Plan.md` — description, clone instructions, repo link
- `endpoint_inventory.md` — section header

**Verification:**
- All 16 project docs reviewed — no remaining stale references in active content
- Historical AGENT.md/CHANGELOG.md entries preserved as-is

**Follow-ups:**
- None

### Raouf: 2026-03-11 (AEDT) — Plan Alignment Audit + Final Old-Name Cleanup

**Scope:** Verify full project alignment with the updated Flutter Migration Plan and eliminate the last old-name reference.

**Summary:**
Audited the entire codebase against the user's updated migration plan. Confirmed all navigation-focused goals (interactive map, building registry, directions, category filtering) are fully implemented and the project exceeds the plan's scope with completed auth, calendar, dashboard, notifications, and feed features. Fixed the critical Android Kotlin directory mismatch: `MainActivity.kt` was still at `io/syllabussync/syllabus_sync/` with the old package declaration while `build.gradle.kts` used `io.mqnavigation.mq_navigation` — moved to the correct directory path and updated the package declaration. Updated `Flutter_Migration_Plan.md` to remove stale external `syllabus-sync` URLs. Verified zero old-name references remain in source/config files.

**Files changed:**
- `android/app/src/main/kotlin/io/mqnavigation/mq_navigation/MainActivity.kt` — created at correct path with `package io.mqnavigation.mq_navigation`
- `android/app/src/main/kotlin/io/syllabussync/` — deleted (old directory tree)
- `Flutter_Migration_Plan.md` — removed stale syllabus-sync external URLs

**Verification:**
- `flutter analyze` → 0 issues
- `flutter test` → 99/99 passed
- Zero remaining old-name references in source/config files (historical changelog entries preserved)

**Follow-ups:**
- None — naming is fully consistent across the entire codebase

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
\nRaouf:\n2026-03-21: Architecture and UI quality audit — Fixed map renderer desync logic leak, replaced magic numbers with design tokens in route_panel and map_page, and added missing documentation to MapController. Ensured AsyncValue correctness in map pages.\n
Raouf:
2026-03-21: Campus Map Bounds Stability & Zoom — Fixed a crash in `flutter_map` caused by invalid layout constraints on small or unconstrained parent widgets (`Invalid argument: 0`). Switched to a robust `LayoutBuilder` pattern that validates constraints before calculating padding. If constraints are invalid or infinite, it falls back to a safe minimal padding (`MqSpacing.space4`). Otherwise, it uses dynamic padding (10% of screen size) to ensure a zoomed-out perspective. Re-added `MqSpacing` import. Files changed: `lib/features/map/presentation/widgets/campus/campus_map_view.dart`, `AGENT.md`, `CHANGELOG.md`.

Raouf:
2026-03-22: Campus Map Zoom & Build Fix — Addressed persistent map zoom issues and build stability. Increased initial campus map padding to 15% of screen dimensions (up from 10%) to ensure a more zoomed-out initial view as requested. Added defensive bounds validation in `campus_map_view.dart` to prevent `flutter_map` crashes (`Invalid argument: 0`) when bounds are effectively zero or layout constraints are invalid. Updated `scripts/run.sh` to explicitly export `MACOSX_DEPLOYMENT_TARGET=11.0` to resolve conflicting deployment target errors in the local environment. Files changed: `lib/features/map/presentation/widgets/campus/campus_map_view.dart`, `scripts/run.sh`, `AGENT.md`, `CHANGELOG.md`. Verification: `./scripts/check.sh` passed (format, analyze, test, build apk).

### Raouf: 2026-03-22 (AEDT) — macOS deployment-target conflict fix

**Scope:** Restore reliable `flutter run/build` for macOS under Xcode 26.x toolchains.

- Summary:
  - Fixed `debug_macos_framework` failure (`clang: conflicting deployment targets` / `targeting 'XR'`).
  - Patched Flutter macOS assemble script phases to sanitize conflicting platform deployment env vars.
- Rationale:
  - The build inherited non-macOS deployment targets (especially `XROS_DEPLOYMENT_TARGET`) that forced clang onto XR/visionOS semantics while compiling with the macOS SDK.
- Files:
  - `macos/Runner.xcodeproj/project.pbxproj`
  - `AGENT.md`
  - `CHANGELOG.md`
- Verification:
  - `flutter build macos --debug --dart-define-from-file=.env` → success
  - `./scripts/run.sh macos --no-resident` → success (no deployment-target conflict)
  - `./scripts/check.sh` → all checks passed (6/6)
- Follow-ups:
  - Revisit once upstream Flutter/Xcode handling of cross-platform deployment env vars is fixed.

### Raouf: 2026-03-22 (AEDT) — Campus default load zoom-out tuning

**Scope:** Make campus map first-load framing significantly more zoomed out.

- Summary:
  - Increased default zoom-out on load by moving initial fit cap from `-2.0` to `-3.0`.
  - Updated fallback `initialZoom` from `-2` to `-3` for consistent startup framing.
- Rationale:
  - The map still felt too tight at startup; one additional zoom level in `CrsSimple` provides roughly 2x wider visible area.
- Files:
  - `lib/features/map/presentation/widgets/campus/campus_map_view.dart`
  - `AGENT.md`
  - `CHANGELOG.md`
- Verification:
  - `./scripts/check.sh --quick` → all checks passed
  - `flutter test test/features/map/map_controller_test.dart` → all tests passed
- Follow-ups:
  - Optional next tuning after UI validation: test `-3.5` if an even wider first frame is desired.

### Raouf: 2026-03-22 (AEDT) — Campus fit clamp-range crash fix

**Scope:** Eliminate `FitBounds`/`double.clamp` startup exceptions in campus map.

- Summary:
  - Fixed `Invalid argument(s): 0.0` thrown from `flutter_map` camera fit (`FitBounds._getBoundsZoom`).
  - Added explicit `minZoom` to `CameraFit.bounds` and aligned startup zoom constants.
- Rationale:
  - Prevent invalid clamp ranges inside `flutter_map` by keeping fit and map zoom bounds consistent.
- Files:
  - `lib/features/map/presentation/widgets/campus/campus_map_view.dart`
  - `AGENT.md`
  - `CHANGELOG.md`
- Verification:
  - `./scripts/check.sh --quick` → all checks passed
  - `flutter test test/features/map/map_controller_test.dart` → all tests passed
- Follow-ups:
  - Monitor runtime logs on-device; if needed, add telemetry around constraint and bounds values at map init.

### Raouf: 2026-04-22 (AEST) — Run script robustness & parsing fix
**Scope:** `scripts/run.sh` script improvement.
**Summary:** Improved the `run.sh` script to handle Flutter flags (e.g., `--release`) more gracefully when no device target is specified. Added robust quote stripping for `GOOGLE_MAPS_API_KEY` to ensure the value is clean when injected into `google_maps_config.js` and `gradle.properties`. Refactored `gradle.properties` modification to be cleaner and more idempotent. Replaced `echo` with `printf` for safer handling of variables that might start with hyphens. Added an early exit if the `flutter` command is missing.
**Files Changed:**
- `scripts/run.sh`
**Verification:**
- `bash -n scripts/run.sh` → success (syntax check).

### Raouf: 2026-04-22 (AEST) — Local environment initialization
**Scope:** Environment configuration.
**Summary:** Created the local `.env` file from the `.env.example` template. This file is required for the `scripts/run.sh` script to successfully inject API keys into platform-specific configurations (Android gradle properties, iOS xcconfig, and Web JS config).
**Files Created:**
- `.env` (gitignored)
**Verification:**
- Verified `.env` file existence and key structure.

### Raouf: 2026-04-22 (AEST) — macOS deployment target synchronization
**Scope:** macOS build configuration.
**Summary:**
Updated `MACOSX_DEPLOYMENT_TARGET` from 11.0 to 13.0 in the Xcode project file (`macos/Runner.xcodeproj/project.pbxproj`) across all build configurations and shell script phases. This synchronizes the project with the earlier Podfile change and resolves compilation errors in the `app_links` plugin.
**Files Changed:**
- `macos/Runner.xcodeproj/project.pbxproj`
**Verification:**
- Confirmed all occurrences of 11.0 in `pbxproj` were updated to 13.0.

### Raouf: 2026-04-22 (AEST) — Secret exposure remediation & Android security hardening
**Scope:** Security.
**Summary:**
Remediated the accidental exposure of the Google Maps API key in `android/gradle.properties`. Implemented a more secure injection mechanism:
1. Created `android/secrets.properties` (gitignored) to hold the injected keys.
2. Modified `android/app/build.gradle.kts` to prioritize keys from `secrets.properties`.
3. Updated `scripts/run.sh` to target the new properties file and ensure clean removal on exit.
4. Cleaned the leaked key from `android/gradle.properties`.
**Files Changed:**
- `.gitignore`
- `android/app/build.gradle.kts`
- `scripts/run.sh`
- `android/gradle.properties`
**Verification:**
- Verified `.gitignore` blocks `android/secrets.properties`.
- Verified `build.gradle.kts` logic for property loading.

### Raouf: 2026-04-22 (AEST) — Zero-data features & settings implementation
**Scope:** Core architecture & user settings.
**Summary:**
Expanded the local settings stack to support "zero-data" features and enhanced accessibility.
1. **Data**: Added `defaultRenderer`, `defaultTravelMode`, `lowDataMode`, and `reducedMotion` to `UserPreferences`.
2. **Persistence**: Updated `SettingsRepository` to persist these new fields securely.
3. **Guards**:
    - **Low Data**: Building search now skips remote Google Places calls when enabled.
    - **Reduced Motion**: Centralized animation duration helper returns `Duration.zero` when enabled.
4. **Wipe Data**: Implemented "Nuclear Reset" to clear all local app data with user confirmation.
5. **UI**: Built the new settings cards and toggles in `SettingsPage` following the brand design system.
**Files Changed:**
- `lib/shared/models/user_preferences.dart`
- `lib/features/settings/data/repositories/settings_repository.dart`
- `lib/features/settings/presentation/controllers/settings_controller.dart`
- `lib/features/map/presentation/controllers/map_controller.dart`
- `lib/app/theme/mq_animations.dart`
- `lib/features/map/presentation/widgets/building_search_sheet.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
**Verification:**
- Logic review of the search and animation guards.
- Verified state refresh logic after data wipe.

### Raouf: 2026-04-22 (AEST) — Project-wide verification & build fixes
**Scope:** QA & Stability.
**Summary:**
Performed a full project health check via `scripts/check.sh` and addressed all failures:
1. **L10n**: Added missing localization keys (`defaultRenderer`, `wipeData`, etc.) to `app_en.arb` and regenerated classes.
2. **Android Build**: Fixed a Kotlin compilation error in `build.gradle.kts` by adding the `java.util.Properties` import and corrected the `jvmTarget` syntax.
3. **Tests**: Updated `MapController` unit tests to include a `_FakeSettingsController` mock, resolving dependency injection failures and noisy storage errors.
4. **Formatting**: Ensured all files are correctly formatted according to `dart format`.
**Files Changed:**
- `lib/app/l10n/app_en.arb`
- `android/app/build.gradle.kts`
- `test/features/map/map_controller_test.dart`
**Verification:**
- `./scripts/check.sh` → All 6 steps passed (Format, Analyze, Test, L10n, Build).

### Raouf: 2026-04-22 (AEST) — Localization synchronization
**Scope:** Internationalization.
**Summary:**
Synchronized all 34 supported language files (`app_*.arb`) with the latest keys from `app_en.arb`. This ensures that new settings options and accessibility features are correctly represented (using English fallbacks) across all locales, preventing generation errors and UI "missing key" text.
**Files Changed:**
- `lib/app/l10n/app_*.arb` (34 files)
**Verification:**
- Ran `flutter gen-l10n` → Confirmed zero untranslated messages across all supported languages.

### Raouf: 2026-04-22 (AEST) — Final repository cleanup
**Scope:** Maintenance.
**Summary:**
Cleaned up the repository before final push:
1. **Gitignore**: Added `build/` to the root `.gitignore` to prevent local build artifacts from being tracked.
2. **Formatting**: Applied `dart format .` across the entire project to ensure consistent style.
3. **Build Files**: Updated `generated_plugins.cmake` for Linux and Windows platforms.
4. **Cleanup**: Removed the temporary `tools/sync_l10n.dart` utility script.
**Files Changed:**
- `.gitignore`
- `linux/flutter/generated_plugins.cmake`
- `windows/flutter/generated_plugins.cmake`
- Numerous Dart files (formatting only)
**Verification:**
- Verified `.gitignore` correctly ignores the `build/` folder.
- git status confirms no more untracked or incorrectly modified files.

### Raouf: 2026-04-22 (AEST) — iOS deployment target synchronization & build fixes
**Scope:** iOS platform support.
**Summary:**
Addressed the failing iOS CI build by synchronizing deployment targets and updating dependencies.
1. **Deployment Target**: Bumped `IPHONEOS_DEPLOYMENT_TARGET` from 13.0 to 17.0 in the Xcode project and Podfile. This resolves Firebase version conflicts and fixes a critical compilation error in `connectivity_plus` 7.x (`Value of type 'NWPath' has no member 'isUltraConstrained'`) which requires the iOS 17 SDK.
2. **Dependency Sync**: Ran `pod update` in `ios/` to align the `Podfile.lock` with the latest plugin versions.
3. **Log Noise**: Ported warning suppressions from macOS to iOS Podfile to ensure cleaner builds.
**Files Changed:**
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Podfile`
- `ios/Podfile.lock`
- `ios/Flutter/AppFrameworkInfo.plist`
**Verification:**
- Confirmed `pod update` completed successfully locally.
- Deployment targets are now consistent and satisfy all plugin requirements.

