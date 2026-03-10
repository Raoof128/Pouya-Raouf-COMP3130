# Route Matrix — Web Routes → Flutter Routes

Maps every web route to its Flutter equivalent.

## Page Routes

| Web Route | Flutter Route | go_router Name | Status | Phase |
|-----------|--------------|----------------|--------|-------|
| `/` | `/splash` → redirect | `splash` | Done | 1 |
| `/login` | `/login` | `login` | Done (placeholder) | 2 |
| `/signup` | `/signup` | `signup` | Planned | 2 |
| `/verify` | `/verify-email` | `verify-email` | Planned | 2 |
| `/reset-password` | `/reset-password` | `reset-password` | Planned | 2 |
| `/onboarding` | `/onboarding` | `onboarding` | Planned | 2 |
| `/home` | `/home` | `home` | Done (placeholder) | 3 |
| `/calendar` | `/calendar` | `calendar` | Done (placeholder) | 3 |
| `/map` | `/map` | `map` | Done (placeholder) | 5 |
| `/feed` | `/feed` | `feed` | Done (placeholder) | 4 |
| `/settings` | `/settings` | `settings` | Done (placeholder) | 2 |
| `/settings/general` | `/settings` (section) | — | Planned | 2 |
| `/settings/appearance` | `/settings` (section) | — | Planned | 2 |
| `/settings/experience` | `/settings` (section) | — | Planned | 2 |
| `/settings/security` | `/settings` (section) | — | Planned | 2 |
| `/settings/about` | `/settings` (section) | — | Planned | 2 |
| `/manage-profiles` | `/profile/edit` | `profile-edit` | Planned | 2 |
| `/about` | In settings | — | Planned | 2 |
| `/contact` | In settings | — | Planned | 2 |
| `/privacy` | In settings (webview) | — | Planned | 6 |
| `/terms` | In settings (webview) | — | Planned | 6 |
| `/offline` | N/A | — | — | Handled by connectivity banner |
| `/map/position-editor` | N/A | — | — | Admin-only web tool |

## Auth Callback Routes

| Web Route | Flutter Equivalent | Notes |
|-----------|--------------------|-------|
| `/auth/callback` | `io.mqnavigation://callback` | OAuth return deep link |
| `/auth/callback/recovery` | `io.mqnavigation://reset-password` | Password recovery deep link |
| `/auth/confirm` | `io.mqnavigation://verify` | Email confirmation deep link |

## Detail Routes (pushed on top of shell)

| Flutter Route | go_router Name | Phase |
|---------------|----------------|-------|
| `/unit/:unitId` | `unit-detail` | 3 |
| `/deadline/:deadlineId` | `deadline-detail` | 3 |
| `/exam/:examId` | `exam-detail` | 3 |
| `/event/:eventId` | `event-detail` | 3 |
| `/building/:buildingId` | `building-detail` | 5 |
| `/profile/edit` | `profile-edit` | 2 |

## Shell Navigation (bottom nav)

| Tab | Index | Route | Icon |
|-----|-------|-------|------|
| Home | 0 | `/home` | home |
| Calendar | 1 | `/calendar` | calendar_month |
| Map | 2 | `/map` | map |
| Feed | 3 | `/feed` | feed |
| Settings | 4 | `/settings` | settings |

## Routes NOT Migrated

| Web Route | Reason |
|-----------|--------|
| `/map/position-editor` | Admin-only web tool |
| `/offline` | Flutter uses connectivity banner overlay |
| `/api/*` | API routes → SDK calls or Edge Functions |
