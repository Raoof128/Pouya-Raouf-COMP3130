# Environment Variable Inventory

All environment variables used by the MQ Navigation Flutter app.

## Client-Side (--dart-define in Flutter)

| Variable | Required | Default | Notes |
|----------|----------|---------|-------|
| `SUPABASE_URL` | Yes | — | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | — | Public anon key (RLS enforced) |
| `GOOGLE_MAPS_API_KEY` | No | — | Client-side Maps SDK key (restricted to app bundle ID) |
| `ORS_API_KEY` | No | — | OpenRouteService API key for walking directions |
| `APP_ENV` | No | `development` | development / staging / production |

## Server-Only (Edge Functions / Supabase dashboard)

These variables exist in the Supabase backend but are **not** used by the Flutter app:

| Variable | Service | Notes |
|----------|---------|-------|
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Functions | Bypasses RLS — never in client code |
| `GOOGLE_ROUTES_API_KEY` | Edge Functions | Google Routes API (web app only) |
| `GOOGLE_WEATHER_API_KEY` | Edge Functions | Google Weather API (web app only) |
| `RESEND_API_KEY` | Edge Functions | Email delivery (web app only) |

## Web-Only (Not Needed in Flutter)

| Variable | Reason |
|----------|--------|
| `NEXT_PUBLIC_APP_URL` | Vercel deployment URL |
| `NEXT_PUBLIC_GOOGLE_MAP_ID` | Maps JS API vector maps |
| `WEBAUTHN_RP_ID` / `WEBAUTHN_ORIGIN` | WebAuthn (web only) |
| `NODE_ENV` / `PORT` / `NEXT_TURBOPACK` | Next.js dev server |

