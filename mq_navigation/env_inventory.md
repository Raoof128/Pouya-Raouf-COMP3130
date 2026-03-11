# Environment Variable Inventory

All environment variables used by MQ Navigation, categorised by client/server exposure.

## Client-Side (--dart-define in Flutter)

| Variable | Required | Default | Notes |
|----------|----------|---------|-------|
| `SUPABASE_URL` | Yes | — | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | — | Public anon key (RLS enforced) |
| `GOOGLE_MAPS_API_KEY` | No | — | Client-side Maps SDK key (restricted to app bundle ID; required only for the embedded map) |
| `APP_ENV` | No | `development` | development / staging / production |

## Server-Only (Edge Functions env / Supabase dashboard)

| Variable | Service | Notes |
|----------|---------|-------|
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Functions | Bypasses RLS — never in client code |
| `GOOGLE_ROUTES_API_KEY` | Edge Functions | Google Routes API billing key |
| `GOOGLE_WEATHER_API_KEY` | Edge Functions | Google Weather API |
| `ORS_API_KEY` | Edge Functions | OpenRouteService fallback |
| `RESEND_API_KEY` | Edge Functions | Email delivery |
| `VERIFICATION_EMAIL_FROM` | Edge Functions | From address for verification emails |
| `VERIFICATION_EMAIL_NAME` | Edge Functions | Display name for verification emails |
| `CRON_SECRET` | Edge Functions | Protects cron endpoints |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Edge Functions | Preferred Firebase service account JSON for FCM HTTP v1 |
| `FCM_SERVER_KEY` | Edge Functions | Legacy FCM push delivery fallback |
| `UPSTASH_REDIS_REST_URL` | Edge Functions | Rate limiting (production) |
| `UPSTASH_REDIS_REST_TOKEN` | Edge Functions | Rate limiting (production) |

## Web-Only (Not Needed in Flutter)

| Variable | Reason |
|----------|--------|
| `NEXT_PUBLIC_APP_URL` | Vercel deployment URL |
| `NEXT_PUBLIC_GOOGLE_MAP_ID` | Maps JS API vector maps |
| `WEBAUTHN_RP_ID` | WebAuthn (deferred to v1.1) |
| `WEBAUTHN_ORIGIN` | WebAuthn (deferred to v1.1) |
| `CSRF_VALIDATION_ENABLED` | Browser CSRF (not applicable on mobile) |
| `NEXT_PUBLIC_SENTRY_DSN` | Web Sentry — Flutter will use its own |
| `SENTRY_ORG` / `SENTRY_PROJECT` / `SENTRY_AUTH_TOKEN` | Web CI only |
| `CORS_ALLOWED_ORIGINS` | Browser CORS only |
| `NODE_ENV` / `PORT` / `NEXT_TURBOPACK` | Next.js dev server |

## Firebase (Flutter-specific, not in web app)

| Variable | Location | Notes |
|----------|----------|-------|
| `google-services.json` | `android/app/` | Firebase Android config |
| `GoogleService-Info.plist` | `ios/Runner/` | Firebase iOS config |
| APNs auth key / certificate | Apple Developer + Firebase | Required for iOS push delivery |
