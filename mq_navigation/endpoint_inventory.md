# Endpoint Inventory — API Routes → Flutter Mapping

Maps web API routes to their Flutter equivalents. After auth/calendar/feed removal, the Flutter app primarily uses the Maps & Notifications endpoints.

**Legend:**
- **SDK** = Call directly from Flutter via supabase_flutter (no server proxy needed)
- **EF** = Requires a Supabase Edge Function (server-side logic or secret keys)
- **N/A** = Not used by the Flutter app (web-only)

## Maps & Navigation (Used by Flutter)

| Web Route | Method | Flutter Approach | Notes |
|-----------|--------|-----------------|-------|
| `/api/maps/routes` | POST | **EF: `maps-routes`** | Flutter uses the Supabase Edge Function for both campus and Google routing |

> Flutter now sends a normalized route request to `maps-routes` with
> `renderer`, `origin`, `destination`, and `travelMode`. The Edge Function
> dispatches to Google Routes for Google mode and to the campus walking backend
> for campus mode.

## Notifications (Used by Flutter)

| Web Route | Method | Flutter Approach | Notes |
|-----------|--------|-----------------|-------|
| `/api/notifications` | GET | SDK: `supabase.from('notifications')` | Inbox read/query |
| `/api/notifications` | POST | EF: `notify` | Stores inbox row + dispatches push |
| `/api/notifications/[id]` | GET/PUT/DELETE | SDK: direct table ops | |
| `/api/notifications/mark-all-read` | POST | SDK: `supabase.from('notifications').update({read: true})` | |

## Web-Only Endpoints (Not Used by Flutter)

The following endpoints exist in the web app but are not used by the Flutter app after auth, calendar, feed, and profile features were removed:

| Category | Web Routes | Reason Not Used |
|----------|-----------|-----------------|
| Auth | `/api/auth/*` (signin, signup, signout, password, email, mfa, passkey) | Auth removed from Flutter |
| Content | `/api/units`, `/api/deadlines`, `/api/events`, `/api/todos` | Calendar/content features removed |
| Profiles | `/api/profiles`, `/api/user-preferences` | Profile management removed |
| Gamification | `/api/gamification/*` | Gamification not implemented |
| Places | `/api/maps/place-search`, `/api/maps/place-details` | Not used by current map |
| Weather | `/api/weather` | Not used by current map |
| Security | `/api/security/*`, `/api/audit` | Web-only security tools |
| Sync | `/api/sync` | Realtime not used in current scope |

## Edge Functions (in this repo)

| Edge Function | Purpose |
|---------------|---------|
| `maps-routes` | Shared campus/google route proxy with server-side Google/ORS keys |
| `maps-places` | Google Places autocomplete proxy with rate limiting and caching |
| `notify` | FCM push notification dispatcher |
| `cleanup-cron` | Rate-limit and cache record cleanup |

Web-only functions (`auth-email`, `auth-cleanup`, `routes-proxy`, `places-proxy`, `weather-proxy`, `security-utils`) were removed from this repo.
