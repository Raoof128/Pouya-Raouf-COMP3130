# Map Dependency Inventory

All map-related APIs, services, keys, and data sources used by the campus map.

## API Keys

| Key | Location | Usage |
|-----|----------|-------|
| `GOOGLE_MAPS_API_KEY` | --dart-define (client) | Maps SDK rendering (restricted to app bundle ID) |
| `ORS_API_KEY` | --dart-define (client) | OpenRouteService walking directions |

## External Services

| Service | Flutter Usage | Notes |
|---------|---------------|-------|
| Google Maps SDK | `google_maps_flutter` (native) | Campus map with markers |
| OpenRouteService | Client-side HTTP call | Walking route polylines |
| Geolocator | `geolocator` plugin | GPS positioning |

## Building Registry

- **Source**: Sample data in `features/map/data/datasources/sample_buildings.dart`
- **Fields per building**: id, name, description, category, latitude, longitude, routingLatitude, routingLongitude, imageUrl, gridRef, levels, wheelchair, aliases, tags
- **Categories**: academic, services, health, food, sports, venue, research, residential, other

## Map Configuration

| Config | Value | Notes |
|--------|-------|-------|
| Campus center lat | -33.7738 | Default camera target |
| Campus center lng | 151.1130 | Default camera target |
| Default zoom | 16 | |

## Flutter Map Packages

| Package | Version | Role |
|---------|---------|------|
| google_maps_flutter | ^2.14.2 | Primary map engine |
| geolocator | ^13.0.0 | GPS location tracking |
| permission_handler | ^12.0.1 | Location permission flow |

## Implemented Features

| Feature | Package | Status |
|---------|---------|--------|
| Google Map widget + camera | google_maps_flutter | Done |
| Building markers + info windows | google_maps_flutter | Done |
| Building search + category filter | custom widgets | Done |
| Current location tracking | geolocator | Done |
| Walking route polylines | google_maps_flutter + ORS | Done |
| Building detail page | custom (SliverAppBar) | Done |
