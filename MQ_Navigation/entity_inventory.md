# Entity Inventory — Supabase Schema

Supabase tables used by the MQ Navigation Flutter app.

> **Note:** The full Supabase schema (shared with the web app) contains 20+ tables. This inventory only lists tables the Flutter app currently accesses.

## Tables Used by Flutter

### buildings (sample data)

Building data is currently loaded from `sample_buildings.dart` rather than live from Supabase. The schema below reflects the Building entity model.

| Field | Type | Notes |
|-------|------|-------|
| id | String | Unique building identifier |
| name | String | Display name |
| description | String? | Building description |
| category | enum | academic, food, health, sports, services, venue, research, residential, other |
| latitude | double? | Map marker position |
| longitude | double? | Map marker position |
| routingLatitude | double? | Entrance position for directions |
| routingLongitude | double? | Entrance position for directions |
| imageUrl | String? | Building photo URL |
| gridRef | String? | Campus grid reference |
| levels | int? | Number of floors |
| wheelchair | bool | Wheelchair accessible |
| aliases | List\<String\> | Alternative names (for search) |
| tags | List\<String\> | Searchable tags |

### profiles

Used for Supabase auth session restoration. The app reads minimal profile data.

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | no | References auth.users |
| email | text | no | |
| full_name | text | yes | |
| avatar_url | text | yes | |

## Tables NOT Used by Flutter

The following web-app tables exist in Supabase but are not accessed by the Flutter app:

`units`, `class_times`, `events`, `todos`, `deadlines`, `notifications`, `user_preferences`, `gamification_profiles`, `xp_events`, `xp_config`, `public_events`, `schedules`, `schedule_members`, and various security/audit tables.
