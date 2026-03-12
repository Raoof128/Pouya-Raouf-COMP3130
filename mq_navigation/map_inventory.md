# Map Dependency Inventory

All map-related APIs, services, keys, and data sources used by the campus map subsystem.

## API Keys

| Key | Location | Usage | Flutter Approach |
|-----|----------|-------|-----------------|
| `GOOGLE_MAPS_API_KEY` (client) | `--dart-define` / hardcoded debug fallback | Maps SDK rendering + Directions API | Restricted to app bundle ID in production |

## External Services

| Service | Web Usage | Flutter Usage |
|---------|-----------|---------------|
| Google Maps JavaScript API | Leaflet + GM JS API | google_maps_flutter (native SDK on Android/iOS, JS API on web) |
| Google Directions API | Via Next.js API proxy | Direct HTTP on mobile; Supabase `directions-proxy` edge function on web (CORS) |

> **Note:** On **mobile** (Android/iOS), the app calls the Google Directions API directly.
> On **web**, direct calls are blocked by CORS, so the app routes through the
> `directions-proxy` Supabase Edge Function which proxies the request server-side.
> The older `maps-routes` edge function (Routes API v2) is kept in
> `supabase/functions/maps-routes/` but is unused by the Flutter app.

## Building Registry

- **Source**: `features/map/lib/buildings.ts` in web app (153 buildings in the current Flutter asset snapshot)
- **Fields per building**: id, name, position, description, tags, aliases, translationKey, descriptionKey, gridRef, address, category, location (lat/lng), entranceLocation, accessibilityEntranceLocation, googlePlaceId, levels, wheelchair
- **Categories**: academic, services, health, food, sports, venue, research, residential, other
- **Flutter storage**: Bundled JSON asset at `assets/data/buildings.json`

## Map Configuration

| Config | Value | Notes |
|--------|-------|-------|
| Campus center lat | -33.7738 | Default camera target |
| Campus center lng | 151.1130 | Default camera target |
| Fallback location lat | -33.77388 | 18 Wally's Walk entrance — used when GPS unavailable |
| Fallback location lng | 151.11275 | 18 Wally's Walk entrance — used when GPS unavailable |
| Default zoom | 15.5 | |

> Camera bounds and min/max zoom restrictions were removed so users can freely
> pan and zoom outside the campus when navigating to/from off-campus locations.

## Flutter Map Packages

| Package | Version | Role |
|---------|---------|------|
| google_maps_flutter | ^2.14.2 | Primary map engine (Android, iOS, web) |
| geolocator | ^14.0.2 | GPS location tracking |
| permission_handler | ^12.0.1 | Location permission flow |
| http | ^1.4.0 | Google Directions API HTTP calls |

## Map Features (Implemented)

| Feature | Package / Source |
|---------|-----------------|
| Building registry data source + bundled JSON asset | flutter assets |
| Current location tracking (fallback to campus centre on web/emulator) | geolocator + permission_handler |
| Google Map widget (no camera bounds) | google_maps_flutter |
| Building markers (azure for unselected, red for selected) | google_maps_flutter |
| Building search bottom sheet | custom widget |
| Route request via Google Directions API (HTTP) | http |
| Route polyline rendering | google_maps_flutter |
| Travel mode switching (walk/drive/bike/transit) | Directions API `mode` param |
