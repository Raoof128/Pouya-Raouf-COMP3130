# Map Dependency Inventory

All map-related APIs, services, keys, and data sources used by the campus map subsystem.

## API Keys

| Key | Location | Usage | Flutter Approach |
|-----|----------|-------|-----------------|
| `GOOGLE_MAPS_API_KEY` (client) | --dart-define | Maps SDK rendering | Restricted to app bundle ID |
| `GOOGLE_ROUTES_API_KEY` (server) | Edge Functions env | Google Routes API | Never in client code |
| `GOOGLE_WEATHER_API_KEY` (server) | Edge Functions env | Weather overlay | Never in client code |
| `ORS_API_KEY` (server) | Edge Functions env | OpenRouteService fallback | Never in client code |
| `GOOGLE_MAP_ID` | --dart-define (optional) | Vector maps styling | Cloud-based map styles |

## External Services

| Service | Web Usage | Flutter Usage | Phase |
|---------|-----------|---------------|-------|
| Google Maps JavaScript API | Leaflet + GM JS API | google_maps_flutter (native) | 5 |
| Google Routes API | Via Next.js API proxy | Via `maps-routes` Edge Function proxy | 5 |
| Google Places API | Place search/details | Via Edge Function proxy | 5 |
| Google Weather API | Weather overlay | Via Edge Function proxy | 5 |
| OpenRouteService | Walking directions fallback | Via Edge Function proxy | 5 |

## Building Registry

- **Source**: `features/map/lib/buildings.ts` in web app (153 buildings in the current Flutter asset snapshot)
- **Fields per building**: id, name, position, description, tags, aliases, translationKey, descriptionKey, gridRef, address, category, location (lat/lng), entranceLocation, accessibilityEntranceLocation, googlePlaceId, levels, wheelchair
- **Categories**: academic, services, health, food, sports, venue, research, residential, other
- **Flutter storage**: Bundled JSON asset generated from the web registry, cached in flutter_secure_storage, optional Supabase `app_config` override

## Map Configuration

| Config | Value | Notes |
|--------|-------|-------|
| Map image dimensions | 4678 × 3307 px | Custom campus raster map |
| Campus bounds (north) | -33.769571 | |
| Campus bounds (south) | -33.778124 | |
| Campus bounds (east) | 151.122172 | |
| Campus bounds (west) | 151.103934 | |
| Pixel offset X | 80 | Alignment correction |
| Campus center lat | -33.7738 | Default camera target |
| Campus center lng | 151.1130 | Default camera target |
| Default zoom | 16 | |

## Flutter Map Packages

| Package | Version | Role | Phase |
|---------|---------|------|-------|
| google_maps_flutter | ^2.14.2 | Primary map engine | 5 |
| geolocator | latest | GPS location tracking | 5 |
| permission_handler | ^12.0.1 | Location permission flow | 5 |
| flutter_map | ^8.2.2 | Secondary/fallback engine | 6+ |
| maplibre | ^0.3.3+2 | Vector tiles (future) | v2.0+ |

## Map Feature Migration Order

| Step | Feature | Package | Phase |
|------|---------|---------|-------|
| 1 | Building registry data source + cache | supabase_flutter + secure_storage | 1 |
| 2 | Current location tracking | geolocator + permission_handler | 5 |
| 3 | Google Map widget + camera | google_maps_flutter | 5 |
| 4 | Building markers + info windows | google_maps_flutter | 5 |
| 5 | Building search bottom sheet | custom widget | 5 |
| 6 | Route request via Edge Function | routes-proxy EF | 5 |
| 7 | Route polyline rendering | google_maps_flutter | 5 |
| 8 | Navigation state machine | custom | 6 |
| 9 | Off-route detection | custom | 6 |
| 10 | Arrival detection (30m) | geolocator | 6 |
| 11 | Accessibility route announcer | Semantics + TTS | 6 |
| 12 | Polish: animations, haptics | native APIs | 6 |

## Edge Functions for Maps

| Function | Purpose | Replaces |
|----------|---------|----------|
| `maps-routes` | Authenticated Google Routes API proxy with rate limiting | `/api/maps/routes` |
| `routes-proxy` | Legacy Google Routes API proxy retained for backward compatibility | `/api/navigate` |
| `places-proxy` | Google Places API proxy | `/api/maps/place-search`, `/api/maps/place-details` |
| `weather-proxy` | Google Weather API proxy | `/api/weather` |
