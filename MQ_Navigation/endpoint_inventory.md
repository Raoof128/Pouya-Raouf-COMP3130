# Endpoint Inventory — API & Service Calls

External services and APIs used by the MQ Navigation Flutter app.

> **Note:** The full web app has 60+ API endpoints. This inventory only lists what the Flutter app actually calls.

## Supabase SDK

| Operation | Flutter Call | Purpose |
|-----------|-------------|---------|
| Session restore | `supabase.auth.currentSession` | Auto-restore auth session on app launch |
| Auth state | `supabase.auth.onAuthStateChange` | Listen for session changes |

## Maps & Directions (Client-Side)

| Service | Method | Flutter Usage | Notes |
|---------|--------|---------------|-------|
| Google Maps SDK | Native widget | `google_maps_flutter` renders the campus map | Requires `GOOGLE_MAPS_API_KEY` |
| OpenRouteService | GET `/v2/directions/foot-walking` | Walking route polylines between two points | Uses `ORS_API_KEY` client-side |

## Not Used by Flutter

The following web-app endpoints are not called by the Flutter app:

- **Auth endpoints** (`/api/auth/*`) — app uses guest mode
- **Content endpoints** (`/api/units`, `/api/deadlines`, `/api/events`, `/api/todos`) — not in scope
- **Gamification** (`/api/gamification/*`) — not in scope
- **Notification** (`/api/notifications/*`) — not in scope
- **Edge Functions** (`routes-proxy`, `places-proxy`, `weather-proxy`) — directions use client-side ORS instead
