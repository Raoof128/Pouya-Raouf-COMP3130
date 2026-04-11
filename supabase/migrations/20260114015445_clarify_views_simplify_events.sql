-- ============================================================================
-- SCHEMA CLARIFICATION AND EVENTS SIMPLIFICATION
-- ============================================================================
-- This migration:
-- 1. Adds COMMENT ON statements to help diagram tools identify VIEWs
-- 2. Removes legacy event_date/event_time columns (use start_at/end_at instead)
-- 3. Documents all foreign key relationships clearly
-- ============================================================================

-- ============================================================================
-- PART 1: ADD COMMENTS TO CLARIFY VIEWS vs TABLES
-- ============================================================================

-- Document that user_details is a VIEW, not a TABLE
COMMENT ON VIEW public.user_details IS
'READ-ONLY VIEW: Joins profiles + gamification_profiles for convenience.
This is NOT a table - no data is stored here.
Query: SELECT ... FROM profiles p LEFT JOIN gamification_profiles gp ON p.id = gp.user_id
The gamification fields (xp, streak_days, etc.) come from the JOIN, not duplicated storage.';
-- Document materialized views (only if they exist)
DO $$
BEGIN
    -- Check if mv_user_activity_summary exists before adding comment
    IF EXISTS (
        SELECT 1 FROM pg_matviews
        WHERE schemaname = 'public' AND matviewname = 'mv_user_activity_summary'
    ) THEN
        COMMENT ON MATERIALIZED VIEW public.mv_user_activity_summary IS
        'MATERIALIZED VIEW: Cached aggregation of user activity. Refresh with refresh_analytics_views().
        Source: profiles, deadlines, events, xp_events';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_matviews
        WHERE schemaname = 'public' AND matviewname = 'mv_deadline_analytics'
    ) THEN
        COMMENT ON MATERIALIZED VIEW public.mv_deadline_analytics IS
        'MATERIALIZED VIEW: Cached deadline completion analytics. Refresh with refresh_analytics_views().
        Source: deadlines table aggregated by user_id';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_matviews
        WHERE schemaname = 'public' AND matviewname = 'mv_xp_leaderboard'
    ) THEN
        COMMENT ON MATERIALIZED VIEW public.mv_xp_leaderboard IS
        'MATERIALIZED VIEW: Cached XP leaderboard. Refresh with refresh_analytics_views().
        Source: gamification_profiles, profiles';
    END IF;
END $$;
-- Document actual tables
COMMENT ON TABLE public.profiles IS
'TABLE: User profile data (1:1 with auth.users). Contains: email, full_name, student_id, course, year, avatar_url.
Primary Key: id (references auth.users.id)';
COMMENT ON TABLE public.gamification_profiles IS
'TABLE: User gamification data (1:1 with auth.users). Contains: xp, streak_days, longest_streak.
Foreign Key: user_id → auth.users.id';
COMMENT ON TABLE public.units IS
'TABLE: Academic units/courses. Each user has their own units.
Foreign Key: user_id → auth.users.id
Related: class_times (via unit_id), deadlines (via unit_id or unit_code)';
COMMENT ON TABLE public.deadlines IS
'TABLE: User deadlines/assignments.
Foreign Keys: user_id → auth.users.id, unit_id → units.id (optional)';
COMMENT ON TABLE public.events IS
'TABLE: Campus events (public or user-owned).
Foreign Key: user_id → auth.users.id (NULL for public events)';
COMMENT ON TABLE public.notifications IS
'TABLE: User notifications.
Foreign Key: user_id → auth.users.id
Note: related_id is polymorphic - use type column to determine what it references';
COMMENT ON TABLE public.class_times IS
'TABLE: Class schedule times for units.
Foreign Key: unit_id → units.id';
COMMENT ON TABLE public.user_preferences IS
'TABLE: User preference settings.
Foreign Key: user_id → auth.users.id';
COMMENT ON TABLE public.xp_events IS
'TABLE: XP transaction audit log.
Foreign Key: user_id → auth.users.id';
COMMENT ON TABLE public.xp_config IS
'TABLE: XP configuration values.
Primary Key: event_type (text)';
-- ============================================================================
-- PART 2: SIMPLIFY EVENTS TABLE - REMOVE LEGACY TIME FIELDS
-- ============================================================================
-- Current state: event_date, event_time, start_at, end_at, all_day
-- Target state: start_at, end_at, all_day only
--
-- IMPORTANT: First ensure all data is migrated to start_at/end_at

-- Step 1: Ensure start_at is populated for all existing events (only if event_date exists)
DO $$
BEGIN
    -- Check if event_date column exists before trying to use it
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'events' AND column_name = 'event_date' AND table_schema = 'public'
    ) THEN
        UPDATE public.events
        SET start_at = CASE
            WHEN event_time ~ '^([01]?[0-9]|2[0-3]):[0-5][0-9]'
            THEN (event_date::text || ' ' || event_time)::timestamptz
            ELSE event_date::timestamptz
        END
        WHERE start_at IS NULL AND event_date IS NOT NULL;
    END IF;
END $$;
-- Step 2: Set all_day for events without proper time (only if event_time exists)
DO $$
BEGIN
    -- Check if event_time column exists before trying to use it
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'events' AND column_name = 'event_time' AND table_schema = 'public'
    ) THEN
        UPDATE public.events
        SET all_day = true
        WHERE start_at IS NOT NULL
        AND (event_time IS NULL OR event_time !~ '^([01]?[0-9]|2[0-3]):[0-5][0-9]')
        AND all_day IS NOT true;
    END IF;
END $$;
-- Step 3: Drop the sync trigger first (before any more updates that might trigger it)
DROP TRIGGER IF EXISTS sync_event_timestamps_trigger ON public.events;
DROP FUNCTION IF EXISTS sync_event_timestamps();
-- Step 4: Set default end_at for non-all-day events
UPDATE public.events
SET end_at = start_at + INTERVAL '1 hour'
WHERE end_at IS NULL AND start_at IS NOT NULL AND all_day IS NOT true;
-- Step 5: Drop legacy columns
ALTER TABLE public.events DROP COLUMN IF EXISTS event_date;
ALTER TABLE public.events DROP COLUMN IF EXISTS event_time;
-- Step 6: Drop the legacy time format constraint
ALTER TABLE public.events DROP CONSTRAINT IF EXISTS events_time_format;
-- Step 7: Make start_at required (NOT NULL) - only if column exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'events' AND column_name = 'start_at' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.events ALTER COLUMN start_at SET NOT NULL;
    END IF;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;
-- Step 8: Ensure all_day has a default - only if column exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'events' AND column_name = 'all_day' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.events ALTER COLUMN all_day SET DEFAULT false;
        ALTER TABLE public.events ALTER COLUMN all_day SET NOT NULL;
    END IF;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;
-- Step 9: Add helpful comments
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'events' AND column_name = 'start_at' AND table_schema = 'public'
    ) THEN
        COMMENT ON COLUMN public.events.start_at IS 'Event start timestamp (required). For all-day events, this is midnight of the event date.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'events' AND column_name = 'end_at' AND table_schema = 'public'
    ) THEN
        COMMENT ON COLUMN public.events.end_at IS 'Event end timestamp (optional). NULL for all-day events or single-point-in-time events.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'events' AND column_name = 'all_day' AND table_schema = 'public'
    ) THEN
        COMMENT ON COLUMN public.events.all_day IS 'True for all-day events (no specific time).';
    END IF;
END $$;
-- Step 10: Create index on start_at for performance (replaces old event_date index)
CREATE INDEX IF NOT EXISTS idx_events_start_at ON public.events(start_at);
-- ============================================================================
-- PART 3: DOCUMENT FOREIGN KEY RELATIONSHIPS
-- ============================================================================
-- All FKs that should exist (verify they do):

-- profiles.id → auth.users.id (via profiles_id_fkey)
-- gamification_profiles.user_id → auth.users.id (via gamification_profiles_user_id_fkey)
-- units.user_id → auth.users.id (via units_user_id_fkey)
-- class_times.unit_id → units.id (via class_times_unit_id_fkey)
-- deadlines.user_id → auth.users.id (via deadlines_user_id_fkey)
-- deadlines.unit_id → units.id (via deadlines_unit_id_fkey)
-- events.user_id → auth.users.id (via events_user_id_fkey)
-- notifications.user_id → auth.users.id (via notifications_user_id_fkey)
-- user_preferences.user_id → auth.users.id (via user_preferences_user_id_fkey)
-- xp_events.user_id → auth.users.id (via xp_events_user_id_fkey)

-- Note: The following relationships are intentionally NOT enforced as FKs:
-- - deadlines.unit_code → units.code (soft reference for flexibility)
-- - notifications.related_id → various (polymorphic based on type)

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- After this migration:
--
-- VIEWS (no data storage):
--   - user_details: JOIN of profiles + gamification_profiles
--   - mv_user_activity_summary: Materialized aggregation
--   - mv_deadline_analytics: Materialized aggregation
--   - mv_xp_leaderboard: Materialized aggregation
--
-- TABLES (actual data):
--   - profiles: User info (1:1 with auth.users via id)
--   - gamification_profiles: XP/streaks (1:1 with auth.users via user_id)
--   - units: Academic units (many per user)
--   - class_times: Class schedules (many per unit)
--   - deadlines: User deadlines (many per user)
--   - events: Campus events (public or per-user)
--   - notifications: User notifications (many per user)
--   - user_preferences: User settings (1:1 with auth.users)
--   - xp_events: XP audit log (many per user)
--   - xp_config: XP configuration (standalone)
--
-- Events now use:
--   - start_at (timestamptz, required): Event start time
--   - end_at (timestamptz, optional): Event end time
--   - all_day (boolean, required): Whether event is all-day
-- ============================================================================;
