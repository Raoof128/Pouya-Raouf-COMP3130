# Route Matrix — Web Routes → Flutter Routes

Maps every web route to its Flutter equivalent.

## Page Routes

| Web Route | Flutter Route | go_router Name | Status | Phase |
|-----------|--------------|----------------|--------|-------|
| `/` | `/splash` → redirect | `splash` | Done | 1 |
| `/login` | `/login` | `login` | Done | 2 |
| `/signup` | `/signup` | `signup` | Done | 2 |
| `/verify` | `/verify-email` | `verify-email` | Done | 2 |
| `/reset-password` | `/reset-password` | `reset-password` | Done | 2 |
| `/onboarding` | `/onboarding` | `onboarding` | Done | 2 |
| `/notifications` | `/notifications` | `notifications` | Done | 4 |
| `/home` | `/home` | `home` | Done | 3 |
| `/calendar` | `/calendar` | `calendar` | Done | 3 |
| `/map` | `/map` | `map` | Done | 5 |
| `/feed` | `/feed` | `feed` | Done | 4 |
| `/settings` | `/settings` | `settings` | Done | 2 |
| `/settings/general` | `/settings` (section) | — | Done | 2 |
| `/settings/appearance` | `/settings` (section) | — | Done | 2 |
| `/settings/experience` | `/settings` (section) | — | Done | 2 |
| `/settings/security` | `/settings` (section) | — | Done | 2 |
| `/settings/about` | `/settings` (section) | — | Done | 2 |
| `/manage-profiles` | `/profile/edit` | `profile-edit` | Done | 2 |
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
| `/detail/deadline/:deadlineId` | `deadline-detail` | 4 |
| `/detail/exam/:examId` | `exam-detail` | 4 |
| `/detail/event/:eventId` | `event-detail` | 4 |
| `/map/building/:buildingId` | `building-detail` | 5 |
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
