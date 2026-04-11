# Entity Inventory — Supabase Schema (Shared Backend)

This documents the **shared Supabase backend schema** used by both the web app and the Flutter app.

> **Flutter app scope:** After removing auth, calendar, feed, and profile features, the Flutter app only interacts with `user_fcm_tokens` (push tokens), `notifications` (inbox), and `rate_limits` (map routing throttle). The building registry is loaded from a bundled JSON asset, not from Supabase. All other tables below are used by the web app only.

Source: `lib/supabase/database.types.ts` in the web app.

## Tables

### profiles
| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | no | References auth.users |
| email | text | no | |
| full_name | text | yes | |
| avatar_url | text | yes | |
| student_id | text | yes | |
| faculty | text | yes | |
| course | text | yes | |
| year | text | yes | |
| created_at | timestamptz | yes | |
| updated_at | timestamptz | yes | |

### units
| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | no | |
| user_id | uuid (FK) | yes | → profiles.id |
| code | text | no | e.g. "COMP1010" |
| name | text | no | |
| description | text | yes | |
| color | text | no | Hex colour |
| location | jsonb | yes | Building/room info |
| notification_enabled | boolean | no | |
| created_at | timestamptz | yes | |
| updated_at | timestamptz | yes | |
| deleted_at | timestamptz | yes | Soft delete |

### class_times
| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | no | |
| unit_id | uuid (FK) | no | → units.id |
| day | text | no | Day of week |
| start_time | text | no | |
| end_time | text | no | |
| created_at | timestamptz | yes | |

### events
| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | no | |
| user_id | uuid (FK) | no | → profiles.id |
| schedule_id | uuid (FK) | yes | → schedules.id |
| source_public_event_id | uuid (FK) | yes | → public_events.id |
| title | text | no | |
| description | text | no | |
| location | text | no | |
| building | text | yes | Building code |
| room | text | yes | |
| start_at | timestamptz | no | |
| end_at | timestamptz | yes | |
| all_day | boolean | no | |
| category | text | no | |
| color | text | yes | |
| image_url | text | yes | |
| notification_enabled | boolean | no | |
| version | integer | yes | Optimistic locking |
| last_modified_by | uuid | yes | |
| is_deleted | boolean | yes | |
| created_at | timestamptz | yes | |
| updated_at | timestamptz | yes | |
| deleted_at | timestamptz | yes | |

### todos
| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | no | |
| user_id | uuid (FK) | no | → profiles.id |
| title | text | no | |
| description | text | yes | |
| completed | boolean | no | |
| completed_at | timestamptz | yes | |
| color | text | yes | |
| priority | text | no | high/medium/low |
| due_date | timestamptz | yes | |
| notification_enabled | boolean | no | |
| created_at | timestamptz | no | |
| updated_at | timestamptz | yes | |
| deleted_at | timestamptz | yes | |

### deadlines
| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | no | |
| user_id | uuid (FK) | yes | → profiles.id |
| unit_id | uuid (FK) | yes | → units.id |
| unit_code | text | no | |
| title | text | no | |
| description | text | yes | |
| type | text | no | assignment/exam/quiz/etc. |
| due_date | timestamptz | no | |
| priority | text | no | high/medium/low |
| building | text | yes | |
| room | text | yes | |
| color | text | yes | |
| completed | boolean | yes | |
| notification_enabled | boolean | no | |
| created_at | timestamptz | yes | |
| updated_at | timestamptz | yes | |
| deleted_at | timestamptz | yes | |

### notifications
| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | no | |
| user_id | uuid (FK) | no | → profiles.id |
| type | text | no | |
| title | text | no | |
| message | text | no | |
| link | text | yes | Deep link target |
| related_id | uuid | yes | |
| read | boolean | yes | |
| created_at | timestamptz | yes | |
| deleted_at | timestamptz | yes | |

### user_preferences
| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | no | |
| user_id | uuid (FK) | no | → profiles.id |
| theme | text | yes | light/dark/system |
| notifications_enabled | boolean | yes | |
| email_notifications | boolean | yes | |
| created_at | timestamptz | yes | |
| updated_at | timestamptz | yes | |

### gamification_profiles
| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | no | |
| user_id | uuid (FK) | no | → profiles.id |
| xp | integer | no | |
| streak_days | integer | no | |
| longest_streak | integer | no | |
| last_activity_date | date | yes | |
| created_at | timestamptz | no | |
| updated_at | timestamptz | yes | |

### xp_events
| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | no | |
| user_id | uuid (FK) | no | |
| event_type | text | no | |
| xp_amount | integer | no | |
| reference_id | uuid | yes | |
| metadata | jsonb | yes | |
| created_at | timestamptz | no | |

### xp_config
| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | yes | |
| event_type | text | no | |
| base_xp | integer | no | |
| description | text | yes | |

### public_events
| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | no | |
| title | text | no | |
| description | text | no | |
| location | text | no | |
| building | text | yes | |
| room | text | yes | |
| start_at | timestamptz | no | |
| end_at | timestamptz | yes | |
| all_day | boolean | no | |
| category | text | no | |
| image_url | text | yes | |
| is_featured | boolean | no | |
| priority | integer | no | |
| created_at | timestamptz | no | |
| updated_at | timestamptz | yes | |
| deleted_at | timestamptz | yes | |

### schedules
| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | no | |
| owner_id | uuid (FK) | no | → profiles.id |
| title | text | no | |
| description | text | yes | |
| is_public | boolean | yes | |
| created_at | timestamptz | yes | |
| updated_at | timestamptz | yes | |

### schedule_members
| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid (PK) | no | |
| schedule_id | uuid (FK) | no | → schedules.id |
| user_id | uuid (FK) | no | → profiles.id |
| role | text | no | |
| created_at | timestamptz | yes | |

### Security & Auth Tables

- **email_verifications**: id, user_id, token_hash, expires_at, used, created_at
- **password_resets**: id, user_id, token_hash, expires_at, used, created_at
- **backup_codes**: id, user_id, code, used, used_at, created_at
- **user_sessions**: id, user_id, ip_address, user_agent, device_info, created_at, last_activity_at
- **webauthn_credentials**: id, user_id, credential_id, public_key, counter, device_name, transports, created_at, last_used_at
- **webauthn_challenges**: id, user_id, challenge, type, created_at, expires_at
- **rate_limits**: key (PK), count, reset_time_ms, created_at, updated_at
- **audit_logs**: id, user_id, action, table_name, record_id, severity, old_data, new_data, metadata, ip_address, user_agent, user_email, request_id, created_at
- **auth_audit_logs**: id, event_type, ip_address, user_agent, metadata, created_at
- **app_config**: id, key, value (jsonb), description, updated_at, updated_by

## Views

| View | Purpose | Key Fields |
|------|---------|------------|
| mv_deadline_analytics | Deadline completion stats | week_start, type, priority, total/completed/overdue counts |
| mv_user_activity_summary | User activity aggregation | user_id, unit_count, deadline_count, xp, level, streaks |
| mv_xp_leaderboard | XP-based leaderboard | user_id, rank, full_name, xp, level, streaks |
| user_details | Profile + gamification stats | id, email, full_name, xp, level, streaks |

## RPC Functions

### Gamification
- `award_xp(p_user_id, p_event_type, p_reference_id?, p_metadata?)` → Json
- `calculate_level(p_xp)` → number
- `xp_for_level(p_level)` → number
- `update_streak(p_user_id)` → void

### User & Profile
- `create_user_profile(p_user_id, p_email, p_full_name?, p_student_id?)` → Json
- `get_my_profile()` → user_details[]
- `lookup_user_by_email(lookup_email)` → {user_id, user_email, user_meta}[]
- `clear_user_data(p_user_id)` → Json

### Units & Schedules
- `create_unit_with_schedule(p_user_id, p_code, p_name, p_color, p_building, p_room, p_description?, p_schedule?)` → Json
- `upsert_unit_with_schedule(p_unit, p_schedule)` → Json

### Events
- `add_public_event_to_calendar(p_public_event_id)` → string

### Audit & Security
- `log_audit(p_user_id?, p_action, p_table_name?, ...)` → string
- `get_my_audit_logs(p_limit?, p_offset?, p_action?, p_severity?, p_start_date?, p_end_date?)` → audit_log[]

### Rate Limiting
- `ratelimit_get(rl_key)` → {count, reset_time_ms}[]
- `ratelimit_set(rl_key, rl_count, rl_reset_time_ms, rl_ttl_ms)` → void
- `ratelimit_increment(rl_key, rl_window_ms)` → {count, reset_time_ms}[]

### Cleanup
- `cleanup_expired_email_verifications()` → number
- `cleanup_expired_password_resets()` → number
- `cleanup_expired_rate_limits()` → number
- `purge_deleted_records(p_days_old?)` → Json

### Data Management
- `seed_demo_data_for_user(p_user_id, p_user_name?, p_user_variant?)` → Json
- `restore_deleted(p_user_id, p_table_name, p_record_id)` → boolean
- `refresh_analytics_views()` → void
