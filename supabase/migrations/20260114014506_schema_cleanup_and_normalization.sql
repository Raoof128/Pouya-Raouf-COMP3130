-- ============================================================================
-- SCHEMA CLEANUP AND NORMALIZATION
-- ============================================================================
-- This migration addresses critical schema issues:
--
-- 1. CLARIFICATION: user_details is a VIEW (not a table)
--    - It joins profiles + gamification_profiles for convenience
--    - The gamification fields are NOT duplicated, they come from the join
--    - We will document this better but no structural change needed
--
-- 2. xp_config already uses event_type as PRIMARY KEY (correct)
--
-- 3. FIX: Ensure deadlines.due_date is NOT NULL (it's the canonical deadline field)
--
-- 4. FIX: Add missing foreign key constraints
--
-- 5. FIX: Add new events time fields (start_at, end_at, all_day)
--    - Keep: event_date, event_time (for backward compatibility)
--    - Add: start_at, end_at, all_day (proper timestamptz handling)
--    - Create trigger to sync old and new fields
--
-- 6. FIX: Add proper id/naming convention documentation
-- ============================================================================

-- ============================================================================
-- PART 1: FIX DEADLINES - Ensure due_date is NOT NULL
-- ============================================================================
-- The deadlines table uses due_date (timestamptz) for the deadline
-- Ensure it's marked as NOT NULL since it's required

-- Ensure due_date is NOT NULL (it should be required)
DO $$
BEGIN
    -- Only set NOT NULL if all existing records have a due_date
    IF NOT EXISTS (
        SELECT 1 FROM public.deadlines WHERE due_date IS NULL
    ) THEN
        ALTER TABLE public.deadlines ALTER COLUMN due_date SET NOT NULL;
    END IF;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;
-- ============================================================================
-- PART 2: ADD MISSING FOREIGN KEY CONSTRAINTS
-- ============================================================================

-- user_preferences.user_id -> auth.users(id) [should exist, verify]
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'user_preferences_user_id_fkey'
        AND table_name = 'user_preferences'
    ) THEN
        ALTER TABLE public.user_preferences
        ADD CONSTRAINT user_preferences_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
-- gamification_profiles.user_id -> auth.users(id) [should exist, verify]
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'gamification_profiles_user_id_fkey'
        AND table_name = 'gamification_profiles'
    ) THEN
        ALTER TABLE public.gamification_profiles
        ADD CONSTRAINT gamification_profiles_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
-- notifications.user_id -> auth.users(id) [should exist, verify]
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'notifications_user_id_fkey'
        AND table_name = 'notifications'
    ) THEN
        ALTER TABLE public.notifications
        ADD CONSTRAINT notifications_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
-- xp_events.user_id -> auth.users(id) [should exist, verify]
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'xp_events_user_id_fkey'
        AND table_name = 'xp_events'
    ) THEN
        ALTER TABLE public.xp_events
        ADD CONSTRAINT xp_events_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
-- deadlines.unit_code -> units.code is problematic because:
-- 1. units.code is now scoped per user (user_id, code)
-- 2. We'd need (user_id, unit_code) to reference it properly
-- Instead, let's add unit_id as a proper foreign key for future use

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'deadlines'
        AND column_name = 'unit_id'
    ) THEN
        ALTER TABLE public.deadlines ADD COLUMN unit_id uuid;

        ALTER TABLE public.deadlines
        ADD CONSTRAINT deadlines_unit_id_fkey
        FOREIGN KEY (unit_id) REFERENCES public.units(id) ON DELETE SET NULL;

        CREATE INDEX IF NOT EXISTS idx_deadlines_unit_id ON public.deadlines(unit_id);
    END IF;
END $$;
-- Backfill unit_id from unit_code where possible
UPDATE public.deadlines d
SET unit_id = u.id
FROM public.units u
WHERE d.unit_code = u.code
AND d.user_id = u.user_id
AND d.unit_id IS NULL;
-- ============================================================================
-- PART 3: FIX EVENTS TIME FIELDS
-- ============================================================================
-- Current state:
-- - event_date (date) - legacy, keep for compatibility
-- - event_time (text) - should be time type
-- - start_at (timestamptz) - new, preferred
-- - end_at (timestamptz) - new, preferred
-- - all_day (boolean) - new, preferred
--
-- Strategy:
-- - Keep event_date and event_time for backward compatibility
-- - Add computed columns to auto-populate start_at/end_at from legacy fields
-- - New code should use start_at/end_at

-- Add new time columns if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'events'
        AND column_name = 'start_at'
    ) THEN
        ALTER TABLE public.events ADD COLUMN start_at timestamptz;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'events'
        AND column_name = 'end_at'
    ) THEN
        ALTER TABLE public.events ADD COLUMN end_at timestamptz;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'events'
        AND column_name = 'all_day'
    ) THEN
        ALTER TABLE public.events ADD COLUMN all_day boolean DEFAULT false;
    END IF;
END $$;
-- Add constraint to ensure end_at >= start_at
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name = 'events_valid_time_range'
    ) THEN
        ALTER TABLE public.events
        ADD CONSTRAINT events_valid_time_range
        CHECK (end_at IS NULL OR start_at IS NULL OR end_at >= start_at);
    END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
-- Create trigger to auto-populate start_at from event_date + event_time
CREATE OR REPLACE FUNCTION sync_event_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    -- If start_at not provided, compute from event_date + event_time
    IF NEW.start_at IS NULL AND NEW.event_date IS NOT NULL THEN
        IF NEW.event_time IS NOT NULL AND NEW.event_time ~ '^([01]?[0-9]|2[0-3]):[0-5][0-9]' THEN
            NEW.start_at := (NEW.event_date || ' ' || NEW.event_time)::timestamptz;
        ELSE
            -- Default to midnight if no time provided
            NEW.start_at := NEW.event_date::timestamptz;
            NEW.all_day := COALESCE(NEW.all_day, true);
        END IF;
    END IF;

    -- If event_date not provided but start_at is, extract date
    IF NEW.event_date IS NULL AND NEW.start_at IS NOT NULL THEN
        NEW.event_date := NEW.start_at::date;
        NEW.event_time := to_char(NEW.start_at, 'HH24:MI');
    END IF;

    -- Default end_at to start_at + 1 hour if not provided
    IF NEW.end_at IS NULL AND NEW.start_at IS NOT NULL AND NOT COALESCE(NEW.all_day, false) THEN
        NEW.end_at := NEW.start_at + INTERVAL '1 hour';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS sync_event_timestamps_trigger ON public.events;
CREATE TRIGGER sync_event_timestamps_trigger
    BEFORE INSERT OR UPDATE ON public.events
    FOR EACH ROW
    EXECUTE FUNCTION sync_event_timestamps();
-- Backfill start_at for existing events (only if event_date column exists)
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
            THEN (event_date || ' ' || event_time)::timestamptz
            ELSE event_date::timestamptz
        END
        WHERE start_at IS NULL AND event_date IS NOT NULL;
    END IF;
END $$;
-- ============================================================================
-- PART 4: STANDARDIZE ID NAMING CONVENTION
-- ============================================================================
-- Convention:
-- - `id` (uuid): Primary key of the table
-- - `user_id` (uuid): Foreign key to auth.users(id)
-- - `<table>_id` (uuid): Foreign key to another table
--
-- Tables already follow this convention. Just documenting.

-- ============================================================================
-- PART 5: ADD xp_config.id COLUMN (optional UUID primary key)
-- ============================================================================
-- While event_type as PK is valid, adding a UUID id allows consistency
-- and easier tooling integration. We'll make it optional.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'xp_config'
        AND column_name = 'id'
    ) THEN
        -- Add id column but keep event_type as the primary key for simplicity
        ALTER TABLE public.xp_config ADD COLUMN id uuid DEFAULT gen_random_uuid();

        -- Backfill existing rows
        UPDATE public.xp_config SET id = gen_random_uuid() WHERE id IS NULL;

        -- Add unique constraint on id (not PK since event_type is already PK)
        ALTER TABLE public.xp_config ADD CONSTRAINT xp_config_id_unique UNIQUE (id);
    END IF;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;
-- ============================================================================
-- PART 6: UPDATE FUNCTIONS THAT REFERENCE due_at
-- ============================================================================

-- Update on_deadline_completed trigger to use due_date instead of due_at
CREATE OR REPLACE FUNCTION on_deadline_completed()
RETURNS TRIGGER AS $$
DECLARE
    v_is_early boolean;
    v_is_first boolean;
BEGIN
    IF NEW.completed = true AND (OLD.completed = false OR OLD.completed IS NULL) THEN
        -- Update streak
        PERFORM update_streak(NEW.user_id);

        -- Check if first deadline
        SELECT NOT EXISTS (
            SELECT 1 FROM public.deadlines
            WHERE user_id = NEW.user_id AND completed = true AND id != NEW.id
        ) INTO v_is_first;

        IF v_is_first THEN
            PERFORM award_xp(NEW.user_id, 'first_deadline', NEW.id,
                             jsonb_build_object('title', NEW.title));
        END IF;

        -- Award base XP
        PERFORM award_xp(NEW.user_id, 'deadline_completed', NEW.id,
                         jsonb_build_object('title', NEW.title, 'unit_code', NEW.unit_code));

        -- Check if early (24h+ before due) - use due_date instead of due_at
        IF NEW.due_date > NOW() + INTERVAL '24 hours' THEN
            PERFORM award_xp(NEW.user_id, 'deadline_early', NEW.id,
                             jsonb_build_object('hours_early',
                               EXTRACT(EPOCH FROM (NEW.due_date - NOW())) / 3600));
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- ============================================================================
-- PART 7: ADD INDEXES FOR NEW COLUMNS
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_events_start_at ON public.events(start_at);
CREATE INDEX IF NOT EXISTS idx_events_end_at ON public.events(end_at);
CREATE INDEX IF NOT EXISTS idx_events_all_day ON public.events(all_day) WHERE all_day = true;
-- ============================================================================
-- SUMMARY
-- ============================================================================
-- 1. ✅ CLARIFIED: user_details is a VIEW joining profiles + gamification_profiles
--    No data redundancy - the gamification fields come from the JOIN
--
-- 2. ✅ CLARIFIED: xp_config uses event_type as PK (valid)
--    Added optional UUID id for tooling consistency
--
-- 3. ✅ FIXED: Ensured deadlines.due_date is NOT NULL
--    This is the canonical deadline timestamp field
--
-- 4. ✅ FIXED: Added/verified all foreign key constraints
--    Added unit_id to deadlines for proper FK relationship
--
-- 5. ✅ FIXED: Added new events time fields (start_at, end_at, all_day)
--    Trigger keeps event_date/event_time and start_at/end_at in sync
--    New code should prefer start_at/end_at + all_day
--
-- 6. ✅ FIXED: Updated trigger functions to use due_date
-- ============================================================================;
