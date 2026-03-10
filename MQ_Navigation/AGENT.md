# MQ Navigation Flutter — Agent Rules

## Project Overview
Flutter mobile client for MQ Navigation — an Open Day campus navigation app for Macquarie University.
The app provides interactive maps, building search, walking directions, and campus information.
It shares a Supabase backend with the Next.js web app but only uses building data.

## Architecture
- **Pattern**: Feature-first with data/domain/presentation layers per feature
- **State management**: Riverpod (flutter_riverpod ^3.2.1)
- **Routing**: go_router with StatefulShellRoute for 3-tab bottom nav
- **Backend**: Supabase (building data, auth session restore)
- **Theme**: MQ design tokens (MqColors, MqTypography, MqSpacing) mapped from web app
- **i18n**: Flutter ARB files with 35 locales, RTL support for ar/fa/he/ur

## Non-Negotiable Constraints
1. Supabase is the system of record — no parallel backend
2. Flutter is a presentation layer only — no server logic in app binary
3. Minimise secret exposure — only `ORS_API_KEY` is client-side; all other service keys stay server-side
4. Accessibility from day one — 48x48dp tap targets, semantic labels, RTL

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
  features/auth/    → Splash, login pages
  features/home/    → Navigation-focused home screen
  features/map/     → Campus map, building detail, directions
  features/settings/→ App settings
```

## Key Environment Variables (--dart-define)
- SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_MAPS_API_KEY, ORS_API_KEY, APP_ENV

## Coding Conventions
- Use Riverpod providers (not setState or Bloc)
- Use go_router named routes (RouteNames constants)
- Use MqSpacing/MqColors/MqTypography for all styling — no magic numbers
- Minimum tap target: 48dp
- All interactive elements must have semantic labels
- Use EdgeInsetsDirectional for RTL support

## Phase 0 Inventories
Located in project root:
- `entity_inventory.md` — Supabase tables used by the app
- `endpoint_inventory.md` — API routes / SDK calls used by the app
- `env_inventory.md` — Environment variables (client vs server)
- `auth_matrix.md` — Auth flow (guest mode for Open Day)
- `route_matrix.md` — Flutter routes
- `key_inventory.md` — Translation key inventory (35 locales)
- `map_inventory.md` — Map dependencies, APIs, building registry

## i18n Convention
- Web uses `{{variable}}` (Handlebars). ARB uses `{variable}` (ICU).
- Dart reserved words are prefixed with `k` (e.g. `class` → `kClass`, `continue` → `kContinue`)
- Building translation keys excluded from ARB — loaded from Supabase at runtime
- Run `dart tools/convert_i18n.dart` to regenerate ARB files from web JSON

## Deep Links
- Custom scheme: `io.mqnavigation://callback`
- Android: Intent filters in AndroidManifest.xml
- iOS: URL scheme in Info.plist
