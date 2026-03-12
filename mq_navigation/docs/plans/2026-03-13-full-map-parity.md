# Full Web-to-Flutter Map Parity Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Achieve ~98% functional parity between the Next.js web map and the Flutter map by adding visual polish (origin dot, accuracy circle), structural decomposition (campus/google subdirectories), overlay layers, Google Places search fallback, and basic Street View integration.

**Architecture:** Decompose the monolithic `campus_map_view.dart` (434 lines) and `google_map_view.dart` (332 lines) into composable layer widgets under `campus/` and `google/` subdirectories. Add overlay layer support as a new domain concept with asset-backed rendering. Add Google Places search as a fallback data source. Keep the existing shared `MapController` as the single state owner.

**Tech Stack:** Flutter 3.11+, flutter_map 8.2, google_maps_flutter 2.15, Riverpod 3.2, Supabase Edge Functions, latlong2, geolocator

---

## Task 1: Campus View — Extract Overlay Layer

**Files:**
- Create: `lib/features/map/presentation/widgets/campus/campus_map_overlay.dart`
- Modify: `lib/features/map/presentation/widgets/campus_map_view.dart` (will be moved in Task 5)

**Step 1: Create the overlay widget**

```dart
// lib/features/map/presentation/widgets/campus/campus_map_overlay.dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mq_navigation/features/map/domain/entities/campus_overlay_meta.dart';

class CampusMapOverlay extends StatelessWidget {
  const CampusMapOverlay({super.key, required this.meta});

  final CampusOverlayMeta meta;

  @override
  Widget build(BuildContext context) {
    final bounds = LatLngBounds(
      latlong.LatLng(meta.mapSouth, meta.mapWest),
      latlong.LatLng(meta.mapNorth, meta.mapEast),
    );

    return OverlayImageLayer(
      overlayImages: [
        OverlayImage(
          bounds: bounds,
          imageProvider: AssetImage(meta.imageAsset),
        ),
      ],
    );
  }
}
```

**Step 2: Verify the file compiles**

Run: `dart analyze lib/features/map/presentation/widgets/campus/campus_map_overlay.dart`
Expected: No issues

**Step 3: Commit**

```bash
git add lib/features/map/presentation/widgets/campus/campus_map_overlay.dart
git commit -m "refactor(map): extract campus overlay into separate widget"
```

---

## Task 2: Campus View — Extract Marker Layer

**Files:**
- Create: `lib/features/map/presentation/widgets/campus/campus_map_marker_layer.dart`

**Step 1: Create the marker layer widget**

Extract the marker-building logic and the `_CampusBuildingMarker` private widget from `campus_map_view.dart` into a standalone widget. The widget receives:
- `visibleBuildings` (list)
- `selectedBuilding` (nullable)
- `projection` (CampusProjection)
- `onSelectBuilding` callback

The existing `_CampusBuildingMarker` becomes `CampusBuildingMarker` (public, in same file).

The `_resolveBuildingPoint` logic moves here as a private helper.

**Step 2: Verify compilation**

Run: `flutter analyze`
Expected: 0 issues

**Step 3: Commit**

```bash
git add lib/features/map/presentation/widgets/campus/campus_map_marker_layer.dart
git commit -m "refactor(map): extract campus marker layer into separate widget"
```

---

## Task 3: Campus View — Extract Route Layer

**Files:**
- Create: `lib/features/map/presentation/widgets/campus/campus_map_route_layer.dart`

**Step 1: Create the route layer widget**

Extract the polyline-building logic (`_buildCampusPolylines`, `_colorFor`) from `campus_map_view.dart`. The widget receives:
- `route` (MapRoute?)
- `routePoints` (List<LatLng> in map space)
- `rawRoutePoints` (List<LocationSample> in GPS space)
- `isNavigating` (bool)
- `currentLocation` (LocationSample?)

Returns a `PolylineLayer` or `SizedBox.shrink()` when no route.

**Step 2: Verify compilation**

Run: `flutter analyze`
Expected: 0 issues

**Step 3: Commit**

```bash
git add lib/features/map/presentation/widgets/campus/campus_map_route_layer.dart
git commit -m "refactor(map): extract campus route layer into separate widget"
```

---

## Task 4: Campus View — Extract Location Layer with Accuracy Circle

**Files:**
- Create: `lib/features/map/presentation/widgets/campus/campus_map_location_layer.dart`

**Step 1: Create the location layer widget**

This is the new feature: extract the current-location marker from campus_map_view.dart AND add an accuracy circle behind the blue dot, matching the web's behavior.

The widget receives:
- `currentLocation` (LocationSample?)
- `projection` (CampusProjection)
- `route` (MapRoute?) — to know if we should show origin dot

Returns a `MarkerLayer` with:
1. An accuracy circle (translucent blue, radius derived from `currentLocation.accuracy`)
2. The existing blue dot with white border and glow
3. A green origin dot at route start when a route is loaded

The accuracy circle radius in map-space must be computed from GPS accuracy metres using an approximate metres-to-pixels conversion from the overlay metadata.

**Step 2: Verify compilation**

Run: `flutter analyze`
Expected: 0 issues

**Step 3: Commit**

```bash
git add lib/features/map/presentation/widgets/campus/campus_map_location_layer.dart
git commit -m "feat(map): extract campus location layer with accuracy circle and origin dot"
```

---

## Task 5: Campus View — Reassemble from Extracted Layers

**Files:**
- Move: `lib/features/map/presentation/widgets/campus_map_view.dart` → `lib/features/map/presentation/widgets/campus/campus_map_view.dart`
- Modify: `lib/features/map/presentation/pages/map_page.dart` (update import)

**Step 1: Rewrite campus_map_view.dart to compose the extracted layer widgets**

The new `campus_map_view.dart` should:
- Keep the `FutureBuilder<CampusOverlayMeta>` scaffolding
- Keep the `FlutterMap` with `MapOptions` (CrsSimple, bounds, zoom)
- Keep `didUpdateWidget` camera logic
- Replace inline overlay/marker/route/location children with the extracted widgets:
  - `CampusMapOverlay(meta: meta)`
  - `CampusMapRouteLayer(...)` (if route)
  - `CampusMapMarkerLayer(...)`
  - `CampusMapLocationLayer(...)`

**Step 2: Update import in map_page.dart**

Change: `import '...campus_map_view.dart'` → `import '...campus/campus_map_view.dart'`

**Step 3: Run tests**

Run: `flutter test`
Expected: All existing tests pass (101/101)

**Step 4: Commit**

```bash
git add lib/features/map/presentation/widgets/campus/
git add lib/features/map/presentation/pages/map_page.dart
git rm lib/features/map/presentation/widgets/campus_map_view.dart
git commit -m "refactor(map): reassemble campus view from extracted layer widgets"
```

---

## Task 6: Google View — Move and Add Origin Dot

**Files:**
- Move: `lib/features/map/presentation/widgets/google_map_view.dart` → `lib/features/map/presentation/widgets/google/google_map_view.dart`
- Modify: `lib/features/map/presentation/pages/map_page.dart` (update import)

**Step 1: Move the file and add origin dot marker**

Move `google_map_view.dart` into `google/` subdirectory. Add a green origin-dot marker at the route start point (first point of the route polyline) when a route is loaded, matching the web's `GoogleMapCanvas` behavior.

Add to the markers set:
```dart
// Origin dot: green marker at route start
if (widget.route != null)
  if (resolveRoutePoints(widget.route!).firstOrNull case final origin?)
    Marker(
      markerId: const MarkerId('route_origin'),
      position: LatLng(origin.latitude, origin.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      alpha: 0.85,
      zIndex: 0,
    ),
```

**Step 2: Update import in map_page.dart**

Change: `import '...google_map_view.dart'` → `import '...google/google_map_view.dart'`

**Step 3: Run tests**

Run: `flutter test`
Expected: All existing tests pass

**Step 4: Commit**

```bash
git add lib/features/map/presentation/widgets/google/google_map_view.dart
git add lib/features/map/presentation/pages/map_page.dart
git rm lib/features/map/presentation/widgets/google_map_view.dart
git commit -m "refactor(map): move google view to subdirectory, add origin dot marker"
```

---

## Task 7: Overlay Layers — Domain Model

**Files:**
- Create: `lib/features/map/domain/entities/map_overlay.dart`

**Step 1: Create the overlay entity**

Port the web's `mapOverlays.ts` concept into a Dart domain model:

```dart
import 'package:flutter/foundation.dart';

@immutable
class MapOverlay {
  const MapOverlay({
    required this.id,
    required this.labelKey,
    required this.descriptionKey,
    required this.imageAsset,
    required this.bounds,
    this.opacity = 0.7,
    this.color,
  });

  final String id;
  final String labelKey;
  final String descriptionKey;
  final String imageAsset;
  final MapOverlayBounds bounds;
  final double opacity;
  final Color? color;
}

@immutable
class MapOverlayBounds {
  const MapOverlayBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;
}
```

**Step 2: Verify compilation**

Run: `flutter analyze`
Expected: 0 issues

**Step 3: Commit**

```bash
git add lib/features/map/domain/entities/map_overlay.dart
git commit -m "feat(map): add MapOverlay domain entity"
```

---

## Task 8: Overlay Layers — Registry and Assets

**Files:**
- Create: `lib/features/map/data/datasources/overlay_registry.dart`
- Create overlay image assets (placeholder PNGs or real assets from web)

**Step 1: Create the overlay registry**

Define the 4 overlay configurations matching the web's `mapOverlays.ts`. Each overlay references a bundled image asset with GPS bounds matching the web's overlay bounds.

The registry is a static list — no API call needed. The web app loads overlays from versioned URLs, but for Flutter we bundle them as assets.

```dart
import 'package:mq_navigation/features/map/domain/entities/map_overlay.dart';

class OverlayRegistry {
  static const overlays = <MapOverlay>[
    MapOverlay(
      id: 'parking',
      labelKey: 'overlayParking',
      descriptionKey: 'overlayParkingDesc',
      imageAsset: 'assets/maps/overlay_parking.png',
      bounds: MapOverlayBounds(
        south: -33.7790, west: 151.1050,
        north: -33.7690, east: 151.1230,
      ),
      opacity: 0.55,
    ),
    MapOverlay(
      id: 'drinking_water',
      labelKey: 'overlayWater',
      descriptionKey: 'overlayWaterDesc',
      imageAsset: 'assets/maps/overlay_water.png',
      bounds: MapOverlayBounds(
        south: -33.7790, west: 151.1050,
        north: -33.7690, east: 151.1230,
      ),
      opacity: 0.6,
    ),
    MapOverlay(
      id: 'accessibility',
      labelKey: 'overlayAccessibility',
      descriptionKey: 'overlayAccessibilityDesc',
      imageAsset: 'assets/maps/overlay_accessibility.png',
      bounds: MapOverlayBounds(
        south: -33.7790, west: 151.1050,
        north: -33.7690, east: 151.1230,
      ),
      opacity: 0.6,
    ),
    MapOverlay(
      id: 'special_permits',
      labelKey: 'overlayPermits',
      descriptionKey: 'overlayPermitsDesc',
      imageAsset: 'assets/maps/overlay_permits.png',
      bounds: MapOverlayBounds(
        south: -33.7790, west: 151.1050,
        north: -33.7690, east: 151.1230,
      ),
      opacity: 0.55,
    ),
  ];
}
```

**Note:** The exact GPS bounds must be read from the web's `mapOverlays.ts` bounds arrays. The image assets must be exported from the web repo or generated. If the web overlay images are not available in the Flutter repo, create placeholder transparent PNGs and document the gap.

**Step 2: Verify compilation**

Run: `flutter analyze`
Expected: 0 issues

**Step 3: Commit**

```bash
git add lib/features/map/data/datasources/overlay_registry.dart
git commit -m "feat(map): add overlay registry with 4 campus overlay configs"
```

---

## Task 9: Overlay Layers — Controller State

**Files:**
- Modify: `lib/features/map/presentation/controllers/map_controller.dart`

**Step 1: Add overlay state to MapState**

Add to `MapState`:
- `activeOverlayIds` (Set<String>, default empty)

Add to `MapController`:
- `toggleOverlay(String id)` — adds/removes overlay ID from the active set
- `clearOverlays()` — clears all active overlays

**Step 2: Write the failing test**

```dart
// test/features/map/map_controller_test.dart — add test
test('toggleOverlay adds and removes overlay IDs', () {
  // After build, activeOverlayIds should be empty
  // toggleOverlay('parking') should add it
  // toggleOverlay('parking') again should remove it
});
```

**Step 3: Run test to verify it fails**

Run: `flutter test test/features/map/map_controller_test.dart`
Expected: FAIL — toggleOverlay not defined

**Step 4: Implement the state change**

Add `activeOverlayIds` to MapState with copyWith support. Add toggle and clear methods to controller.

**Step 5: Run tests**

Run: `flutter test`
Expected: All pass

**Step 6: Commit**

```bash
git add lib/features/map/presentation/controllers/map_controller.dart
git add test/features/map/map_controller_test.dart
git commit -m "feat(map): add overlay toggle state to map controller"
```

---

## Task 10: Overlay Layers — Campus Renderer Integration

**Files:**
- Modify: `lib/features/map/presentation/widgets/campus/campus_map_view.dart`
- Create: `lib/features/map/presentation/widgets/campus/campus_overlay_layers.dart`

**Step 1: Create the overlay layers widget**

A widget that renders additional `OverlayImageLayer`s for each active overlay. Receives:
- `activeOverlayIds` (Set<String>)
- `projection` (CampusProjection) — for GPS-to-map-point conversion of overlay bounds

Each overlay's GPS bounds are converted to map-space coordinates and rendered as an additional `OverlayImage` with the configured opacity.

**Step 2: Wire into campus_map_view.dart**

Add `activeOverlayIds` parameter to `CampusMapView`. Pass through from map_page.dart via controller state. Insert `CampusOverlayLayers` widget after the base overlay but before route/marker layers.

**Step 3: Add overlay toggle button to MapShell**

Add an overlay picker button to the action stack. When tapped, show a bottom sheet with toggle switches for each available overlay.

**Step 4: Run tests**

Run: `flutter test`
Expected: All pass

**Step 5: Commit**

```bash
git add lib/features/map/presentation/widgets/campus/campus_overlay_layers.dart
git add lib/features/map/presentation/widgets/campus/campus_map_view.dart
git add lib/features/map/presentation/widgets/map_shell.dart
git add lib/features/map/presentation/pages/map_page.dart
git commit -m "feat(map): render active overlay layers on campus map"
```

---

## Task 11: Google Places Search Fallback — Edge Function

**Files:**
- Modify: `supabase/functions/maps-routes/index.ts` OR create `supabase/functions/maps-places/index.ts`

**Step 1: Decide approach**

The web app has `/api/maps/place-search` (a Next.js API route) that proxies Google Places autocomplete. For Flutter, create a new Supabase Edge Function `maps-places` that:
- Accepts a `query` string and optional `location` (lat/lng for bias)
- Calls Google Places Autocomplete API with the server-side key
- Returns normalized suggestions: `[{placeId, description, lat?, lng?}]`
- Rate limits by IP

**Step 2: Create the Edge Function**

```typescript
// supabase/functions/maps-places/index.ts
import { corsHeaders, handleCors } from '../_shared/cors.ts';

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return handleCors();
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405, headers: corsHeaders });
  }

  const apiKey = Deno.env.get('GOOGLE_ROUTES_API_KEY');
  if (!apiKey) {
    return new Response(JSON.stringify({ error: 'Places API not configured' }),
      { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const { query, latitude, longitude } = await req.json();
  if (!query || typeof query !== 'string' || query.trim().length < 2) {
    return new Response(JSON.stringify({ suggestions: [] }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const url = new URL('https://maps.googleapis.com/maps/api/place/autocomplete/json');
  url.searchParams.set('input', query);
  url.searchParams.set('key', apiKey);
  url.searchParams.set('components', 'country:au');
  if (latitude && longitude) {
    url.searchParams.set('location', `${latitude},${longitude}`);
    url.searchParams.set('radius', '5000');
  }

  const res = await fetch(url.toString());
  const data = await res.json();

  const suggestions = (data.predictions ?? []).map((p: any) => ({
    placeId: p.place_id,
    description: p.description,
  }));

  return new Response(JSON.stringify({ suggestions }),
    { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
});
```

**Step 3: Register in supabase config.toml**

Add `[functions.maps-places]` section with `verify_jwt = false`.

**Step 4: Commit**

```bash
git add supabase/functions/maps-places/index.ts
git add supabase/config.toml
git commit -m "feat(api): add maps-places Edge Function for Google Places autocomplete proxy"
```

---

## Task 12: Google Places Search Fallback — Flutter Data Source

**Files:**
- Create: `lib/features/map/data/datasources/places_search_source.dart`

**Step 1: Create the data source**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mq_navigation/core/config/env_config.dart';

class PlaceSuggestion {
  const PlaceSuggestion({required this.placeId, required this.description});
  final String placeId;
  final String description;
}

class PlacesSearchSource {
  Future<List<PlaceSuggestion>> search(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    if (query.trim().length < 2) return const [];

    final uri = Uri.parse(
      '${EnvConfig.supabaseUrl}/functions/v1/maps-places',
    );
    final body = {
      'query': query,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'apikey': EnvConfig.supabaseAnonKey,
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return const [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final suggestions = data['suggestions'] as List<dynamic>? ?? [];

    return suggestions
        .map((s) => PlaceSuggestion(
              placeId: s['placeId'] as String,
              description: s['description'] as String,
            ))
        .toList();
  }
}
```

**Step 2: Verify compilation**

Run: `flutter analyze`
Expected: 0 issues

**Step 3: Commit**

```bash
git add lib/features/map/data/datasources/places_search_source.dart
git commit -m "feat(map): add PlacesSearchSource for Google Places fallback"
```

---

## Task 13: Google Places Search Fallback — Search Sheet Integration

**Files:**
- Modify: `lib/features/map/presentation/widgets/building_search_sheet.dart`

**Step 1: Add Places fallback to search sheet**

When the campus search returns no strong matches (score < 100 for all results) and the query has 3+ characters, show a "Search nearby places" section below campus results. This section calls `PlacesSearchSource.search()` with debouncing (300ms) and displays results as ListTiles with a "place" icon instead of "location_on".

When a place suggestion is tapped, we don't have campus building data — instead, navigate to Google Maps mode for that destination. For now, selecting a place suggestion:
1. Switches renderer to Google
2. Shows a snackbar with the place name (future: deep-link to Google Maps directions)

**Step 2: Run tests**

Run: `flutter test`
Expected: All pass

**Step 3: Commit**

```bash
git add lib/features/map/presentation/widgets/building_search_sheet.dart
git commit -m "feat(map): add Google Places fallback to building search sheet"
```

---

## Task 14: Street View — Basic Integration

**Files:**
- Create: `lib/features/map/presentation/widgets/google/street_view_sheet.dart`
- Modify: `lib/features/map/presentation/widgets/route_panel.dart`

**Step 1: Assess flutter Street View support**

The `google_maps_flutter` package does not include a Street View widget. Options:
1. Use `url_launcher` to open Street View in the browser/Google Maps app (simple, reliable)
2. Use a WebView with the Google Street View embed URL (moderate complexity)
3. Use a third-party package (risk of maintenance gaps)

**Recommended approach:** Option 1 — add a "Street View" button to the route panel that deep-links to Google Street View for the selected building's coordinates. This matches the spirit of parity (users can see Street View) without embedding a fragile native view.

**Step 2: Add Street View launcher**

Add a method to `MapController`:
```dart
Future<void> openStreetView() async {
  final building = state.value?.selectedBuilding;
  if (building == null) return;
  final lat = building.routingLatitude ?? building.latitude;
  final lng = building.routingLongitude ?? building.longitude;
  if (lat == null || lng == null) return;

  final uri = Uri.parse(
    'https://www.google.com/maps/@$lat,$lng,3a,75y,0h,90t/data=!3m4!1e1!3m2!1s!2e0',
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
```

**Step 3: Add Street View button to route panel**

Add a Street View icon button next to the "Open in Google Maps" button in `route_panel.dart`. Only visible when renderer is Google mode.

**Step 4: Run tests**

Run: `flutter test`
Expected: All pass

**Step 5: Commit**

```bash
git add lib/features/map/presentation/controllers/map_controller.dart
git add lib/features/map/presentation/widgets/route_panel.dart
git commit -m "feat(map): add Street View deep-link button to route panel"
```

---

## Task 15: Test — Campus Layer Decomposition

**Files:**
- Modify: `test/features/map/campus_projection_test.dart` (verify existing tests still pass)
- Create: `test/features/map/campus_layers_test.dart`

**Step 1: Write widget tests for the extracted layers**

Test:
1. `CampusMapMarkerLayer` renders correct number of markers for given buildings
2. `CampusMapMarkerLayer` highlights selected building with different style
3. `CampusMapLocationLayer` shows accuracy circle when accuracy > 0
4. `CampusMapLocationLayer` shows origin dot when route is provided
5. `CampusMapRouteLayer` renders walked + remaining polylines during navigation
6. `CampusMapRouteLayer` renders single polyline when not navigating

**Step 2: Run the tests**

Run: `flutter test test/features/map/campus_layers_test.dart`
Expected: All pass

**Step 3: Commit**

```bash
git add test/features/map/campus_layers_test.dart
git commit -m "test(map): add widget tests for decomposed campus layers"
```

---

## Task 16: Test — Overlay System

**Files:**
- Create: `test/features/map/overlay_test.dart`

**Step 1: Write tests**

Test:
1. `OverlayRegistry.overlays` contains 4 entries with valid IDs
2. `MapController.toggleOverlay` adds then removes overlay ID
3. `MapController.clearOverlays` resets to empty set
4. Active overlay IDs persist through renderer switch

**Step 2: Run the tests**

Run: `flutter test test/features/map/overlay_test.dart`
Expected: All pass

**Step 3: Commit**

```bash
git add test/features/map/overlay_test.dart
git commit -m "test(map): add overlay toggle and registry tests"
```

---

## Task 17: Test — Full Suite Verification

**Files:** (no new files)

**Step 1: Run format check**

Run: `dart format --set-exit-if-changed lib/ test/`
Expected: 0 changes needed (fix any formatting issues first)

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues

**Step 3: Run full test suite**

Run: `flutter test`
Expected: All tests pass (count should be higher than 101 due to new tests)

**Step 4: Commit any fixes if needed**

---

## Task 18: Documentation — AGENT.md and CHANGELOG.md

**Files:**
- Modify: `AGENT.md`
- Modify: `CHANGELOG.md`

**Step 1: Append Raouf: entry to AGENT.md**

Add entry documenting: structural decomposition of campus/google renderers into layer widgets, accuracy circle + origin dot, overlay layer system, Google Places search fallback, Street View deep-link. List all files created, modified, and deleted.

**Step 2: Append Raouf: entry to CHANGELOG.md**

Add `### Raouf: 2026-03-13 (AEDT) — Full map parity pass` entry under `[Unreleased]` with scope, summary, files changed, verification results, follow-ups.

**Step 3: Commit**

```bash
git add AGENT.md CHANGELOG.md
git commit -m "docs: update AGENT.md and CHANGELOG.md with parity pass entry"
```

---

## Overlay Asset Note

The web app loads overlay images from versioned URLs (`/maps/overlays/mq-campus-parking.png?v=...`). These images need to be:
1. Exported from the web repo into `assets/maps/` in the Flutter repo
2. Or created as placeholder transparent PNGs if the web images aren't available locally

Check the web repo at `/public/maps/overlays/` for the source images. Copy them to `assets/maps/overlay_parking.png`, `overlay_water.png`, `overlay_accessibility.png`, `overlay_permits.png`.

If the overlay images are not available, create 1x1 transparent PNGs as placeholders and document the gap in the CHANGELOG follow-ups.

---

## Acceptance Checklist

After all tasks complete, verify:

- [ ] Campus view decomposed into 5 files under `campus/` subdirectory
- [ ] Google view moved to `google/` subdirectory
- [ ] Origin dot (green) appears at route start in both renderers
- [ ] Accuracy circle appears behind blue location dot in campus mode
- [ ] Overlay toggle UI available in campus mode
- [ ] Overlay layers render when toggled on
- [ ] Google Places fallback appears in search sheet when no campus match
- [ ] Street View button launches Google Street View for selected building
- [ ] All existing tests still pass
- [ ] New tests cover decomposed layers, overlay toggle, and overlay registry
- [ ] `flutter analyze` reports 0 issues
- [ ] `dart format` reports 0 changes needed
- [ ] AGENT.md updated with Raouf: entry
- [ ] CHANGELOG.md updated with Raouf: entry
- [ ] No duplicate controller architecture introduced
- [ ] Same shared MapController drives everything
- [ ] Switching renderer preserves selected building and overlays
