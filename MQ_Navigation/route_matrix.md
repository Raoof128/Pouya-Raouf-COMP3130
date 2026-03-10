# Route Matrix

All Flutter routes in the MQ Navigation app.

## Page Routes

| Flutter Route | go_router Name | Description |
|---------------|----------------|-------------|
| `/splash` | `splash` | Splash screen → auto-redirects to `/home` |
| `/home` | `home` | Navigation-focused home screen |
| `/map` | `map` | Interactive campus map with building markers |
| `/map/building` | `building-detail` | Building detail page (pushed via `extra`) |
| `/map/directions` | `directions` | Walking directions to a building |
| `/settings` | `settings` | App settings |

## Shell Navigation (bottom nav)

| Tab | Index | Route | Icon |
|-----|-------|-------|------|
| Home | 0 | `/home` | home |
| Map | 1 | `/map` | map |
| Settings | 2 | `/settings` | settings |

## Auth Flow

The app runs in **guest mode** for Open Day — no login required.

```
App Launch → /splash → /home (automatic redirect)
```

## Routes NOT Migrated (from web app)

| Web Route | Reason |
|-----------|--------|
| `/calendar` | Not needed for Open Day navigation |
| `/feed` | Not needed for Open Day navigation |
| `/login`, `/signup` | Guest mode — no auth required |
| `/map/position-editor` | Admin-only web tool |
| `/offline` | Flutter uses connectivity banner overlay |
| `/api/*` | API routes — not applicable to mobile |
