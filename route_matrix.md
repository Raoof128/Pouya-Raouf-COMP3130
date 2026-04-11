# Route Matrix — Flutter Routes

All routes in the MQ Navigation Flutter app.

## Page Routes

| Flutter Route | go_router Name | Description |
|---------------|----------------|-------------|
| `/home` | `home` | Welcome hub (shell tab 0) |
| `/map` | `map` | Campus map with building search (shell tab 1) |
| `/map/building/:buildingId` | `building-detail` | Deep link to a specific building on the map |
| `/settings` | `settings` | Theme, language, notification preferences (shell tab 2) |
| `/notifications` | `notifications` | Notification inbox (pushed on top of shell) |

## Shell Navigation (bottom nav)

| Tab | Index | Route | Icon |
|-----|-------|-------|------|
| Home | 0 | `/home` | home |
| Map | 1 | `/map` | map |
| Settings | 2 | `/settings` | settings |

## Routes NOT Migrated from Web

| Web Route | Reason |
|-----------|--------|
| `/login`, `/signup`, `/verify`, `/reset-password` | Auth removed from Flutter app |
| `/calendar` | Calendar feature removed |
| `/feed` | Event feed feature removed |
| `/manage-profiles` | Profile management removed |
| `/map/position-editor` | Admin-only web tool |
| `/offline` | Flutter uses connectivity banner overlay |
| `/api/*` | API routes → SDK calls or Edge Functions |
