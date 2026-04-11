-- ============================================================================
-- COMPREHENSIVE SCHEMA FIX MIGRATION
-- ============================================================================
-- This migration fixes:
-- 1. Missing user_id columns in units, deadlines, events
-- 2. Missing gamification tables
-- 3. RLS policy security issues
-- 4. Missing triggers and functions
-- 5. Missing indexes
-- 6. Constraint fixes
-- ============================================================================

-- ============================================================================
-- PART 1: ADD MISSING user_id COLUMNS
-- ============================================================================

-- Add user_id to units if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'units'
        AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.units ADD COLUMN user_id uuid;

        -- Add foreign key constraint
        ALTER TABLE public.units
        ADD CONSTRAINT units_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;
-- Add user_id to deadlines if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'deadlines'
        AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.deadlines ADD COLUMN user_id uuid;

        ALTER TABLE public.deadlines
        ADD CONSTRAINT deadlines_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;
-- Add user_id to events if not exists (nullable for public events)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'events'
        AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.events ADD COLUMN user_id uuid;

        ALTER TABLE public.events
        ADD CONSTRAINT events_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;
-- ============================================================================
-- PART 2: FIX UNIQUE CONSTRAINTS
-- ============================================================================

-- Drop global unique constraint on units.code and add user-scoped unique constraint
DO $$
BEGIN
    -- Drop old global unique constraint if exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'public'
        AND table_name = 'units'
        AND constraint_name = 'units_code_key'
    ) THEN
        ALTER TABLE public.units DROP CONSTRAINT units_code_key;
    END IF;

    -- Add user-scoped unique constraint if not exists.
    -- Guard both constraint and relation name because a prior index with the
    -- same name can exist and cause "relation already exists" on ADD CONSTRAINT.
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'public'
        AND table_name = 'units'
        AND constraint_name = 'units_user_code_unique'
    ) AND NOT EXISTS (
        SELECT 1
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
        AND c.relname = 'units_user_code_unique'
    ) THEN
        ALTER TABLE public.units
        ADD CONSTRAINT units_user_code_unique UNIQUE (user_id, code);
    END IF;
END $$;
-- ============================================================================
-- PART 3: CREATE GAMIFICATION TABLES
-- ============================================================================

-- Create gamification_profiles table
CREATE TABLE IF NOT EXISTS public.gamification_profiles (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL UNIQUE,
    xp integer NOT NULL DEFAULT 0 CHECK (xp >= 0),
    streak_days integer NOT NULL DEFAULT 0 CHECK (streak_days >= 0),
    longest_streak integer NOT NULL DEFAULT 0 CHECK (longest_streak >= 0),
    last_activity_date date,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT gamification_profiles_pkey PRIMARY KEY (id),
    CONSTRAINT gamification_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
-- Create xp_events table (audit log)
CREATE TABLE IF NOT EXISTS public.xp_events (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    event_type text NOT NULL CHECK (event_type = ANY (ARRAY[
        'deadline_completed'::text,
        'deadline_early'::text,
        'daily_login'::text,
        'streak_bonus'::text,
        'unit_added'::text,
        'event_attended'::text,
        'profile_completed'::text,
        'first_deadline'::text,
        'weekly_goal'::text,
        'level_up_bonus'::text
    ])),
    xp_amount integer NOT NULL CHECK (xp_amount > 0),
    reference_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT xp_events_pkey PRIMARY KEY (id),
    CONSTRAINT xp_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
-- Create xp_config table
CREATE TABLE IF NOT EXISTS public.xp_config (
    event_type text PRIMARY KEY,
    base_xp integer NOT NULL CHECK (base_xp > 0),
    description text
);
-- Insert default XP values
INSERT INTO public.xp_config (event_type, base_xp, description) VALUES
    ('deadline_completed', 25, 'Completing any deadline'),
    ('deadline_early', 10, 'Bonus for completing 24h+ before due date'),
    ('daily_login', 5, 'First activity of the day'),
    ('streak_bonus', 5, 'Per day of streak (multiplied by streak_days)'),
    ('unit_added', 15, 'Adding a new unit to schedule'),
    ('event_attended', 10, 'Marking a campus event as attended'),
    ('profile_completed', 50, 'One-time bonus for completing profile'),
    ('first_deadline', 25, 'One-time bonus for first deadline completed'),
    ('weekly_goal', 50, 'Completing 5+ deadlines in a week'),
    ('level_up_bonus', 10, 'Bonus XP on level up (multiplied by new level)')
ON CONFLICT (event_type) DO NOTHING;
-- ============================================================================
-- PART 4: ADD MISSING INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_units_user_id ON public.units(user_id);
CREATE INDEX IF NOT EXISTS idx_deadlines_user_id ON public.deadlines(user_id);
CREATE INDEX IF NOT EXISTS idx_events_user_id ON public.events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_building ON public.events(building);
CREATE INDEX IF NOT EXISTS idx_deadlines_priority ON public.deadlines(priority);
CREATE INDEX IF NOT EXISTS idx_gamification_profiles_user_id ON public.gamification_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_xp_events_user_id ON public.xp_events(user_id);
CREATE INDEX IF NOT EXISTS idx_xp_events_created_at ON public.xp_events(created_at);
CREATE INDEX IF NOT EXISTS idx_xp_events_event_type ON public.xp_events(event_type);
CREATE INDEX IF NOT EXISTS idx_xp_events_reference_id ON public.xp_events(reference_id);
CREATE INDEX IF NOT EXISTS idx_xp_events_user_event_ref ON public.xp_events(user_id, event_type, reference_id);
-- ============================================================================
-- PART 5: ENABLE RLS AND FIX POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_times ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deadlines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gamification_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xp_events ENABLE ROW LEVEL SECURITY;
-- Revoke anonymous access from all user-scoped tables
REVOKE ALL ON public.units FROM anon;
REVOKE ALL ON public.class_times FROM anon;
REVOKE ALL ON public.deadlines FROM anon;
REVOKE ALL ON public.events FROM anon;
REVOKE ALL ON public.notifications FROM anon;
REVOKE ALL ON public.user_preferences FROM anon;
REVOKE ALL ON public.profiles FROM anon;
REVOKE ALL ON public.gamification_profiles FROM anon;
REVOKE ALL ON public.xp_events FROM anon;
REVOKE ALL ON public.xp_config FROM anon;
-- Grant to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.units TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.class_times TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.deadlines TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.events TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.user_preferences TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.gamification_profiles TO authenticated;
GRANT SELECT, INSERT ON public.xp_events TO authenticated;
GRANT SELECT ON public.xp_config TO authenticated;
-- Drop existing insecure policies (from initial migration)
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;
DROP POLICY IF EXISTS "units_select" ON public.units;
DROP POLICY IF EXISTS "units_insert" ON public.units;
DROP POLICY IF EXISTS "units_update" ON public.units;
DROP POLICY IF EXISTS "units_delete" ON public.units;
DROP POLICY IF EXISTS "class_times_select" ON public.class_times;
DROP POLICY IF EXISTS "class_times_insert" ON public.class_times;
DROP POLICY IF EXISTS "class_times_update" ON public.class_times;
DROP POLICY IF EXISTS "class_times_delete" ON public.class_times;
DROP POLICY IF EXISTS "deadlines_select" ON public.deadlines;
DROP POLICY IF EXISTS "deadlines_insert" ON public.deadlines;
DROP POLICY IF EXISTS "deadlines_update" ON public.deadlines;
DROP POLICY IF EXISTS "deadlines_delete" ON public.deadlines;
DROP POLICY IF EXISTS "notifications_select" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update" ON public.notifications;
DROP POLICY IF EXISTS "notifications_delete" ON public.notifications;
DROP POLICY IF EXISTS "events_select" ON public.events;
DROP POLICY IF EXISTS "events_insert" ON public.events;
DROP POLICY IF EXISTS "events_update" ON public.events;
DROP POLICY IF EXISTS "events_delete" ON public.events;
DROP POLICY IF EXISTS "user_preferences_select" ON public.user_preferences;
DROP POLICY IF EXISTS "user_preferences_insert" ON public.user_preferences;
DROP POLICY IF EXISTS "user_preferences_update" ON public.user_preferences;
-- Drop existing secure policies (in case they exist from reference schema)
DROP POLICY IF EXISTS "Users can view their own units" ON public.units;
DROP POLICY IF EXISTS "Users can insert their own units" ON public.units;
DROP POLICY IF EXISTS "Users can update their own units" ON public.units;
DROP POLICY IF EXISTS "Users can delete their own units" ON public.units;
DROP POLICY IF EXISTS "Users can view class_times for their units" ON public.class_times;
DROP POLICY IF EXISTS "Users can insert class_times for their units" ON public.class_times;
DROP POLICY IF EXISTS "Users can update class_times for their units" ON public.class_times;
DROP POLICY IF EXISTS "Users can delete class_times for their units" ON public.class_times;
DROP POLICY IF EXISTS "Users can view their own deadlines" ON public.deadlines;
DROP POLICY IF EXISTS "Users can insert their own deadlines" ON public.deadlines;
DROP POLICY IF EXISTS "Users can update their own deadlines" ON public.deadlines;
DROP POLICY IF EXISTS "Users can delete their own deadlines" ON public.deadlines;
DROP POLICY IF EXISTS "Users can view public or their own events" ON public.events;
DROP POLICY IF EXISTS "Users can insert their own events" ON public.events;
DROP POLICY IF EXISTS "Users can update their own events" ON public.events;
DROP POLICY IF EXISTS "Users can delete their own events" ON public.events;
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can insert their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can view their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can insert their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can update their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own gamification profile" ON public.gamification_profiles;
DROP POLICY IF EXISTS "Users can insert their own gamification profile" ON public.gamification_profiles;
DROP POLICY IF EXISTS "Users can update their own gamification profile" ON public.gamification_profiles;
DROP POLICY IF EXISTS "Users can view their own xp events" ON public.xp_events;
-- Create secure RLS policies

-- Units: Users can only access their own units
CREATE POLICY "Users can view their own units"
    ON public.units FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own units"
    ON public.units FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own units"
    ON public.units FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own units"
    ON public.units FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
-- Class Times: Users can only access class_times for their own units
CREATE POLICY "Users can view class_times for their units"
    ON public.class_times FOR SELECT
    TO authenticated
    USING (EXISTS (SELECT 1 FROM public.units WHERE units.id = class_times.unit_id AND units.user_id = auth.uid()));
CREATE POLICY "Users can insert class_times for their units"
    ON public.class_times FOR INSERT
    TO authenticated
    WITH CHECK (EXISTS (SELECT 1 FROM public.units WHERE units.id = class_times.unit_id AND units.user_id = auth.uid()));
CREATE POLICY "Users can update class_times for their units"
    ON public.class_times FOR UPDATE
    TO authenticated
    USING (EXISTS (SELECT 1 FROM public.units WHERE units.id = class_times.unit_id AND units.user_id = auth.uid()));
CREATE POLICY "Users can delete class_times for their units"
    ON public.class_times FOR DELETE
    TO authenticated
    USING (EXISTS (SELECT 1 FROM public.units WHERE units.id = class_times.unit_id AND units.user_id = auth.uid()));
-- Deadlines: Users can only access their own deadlines
CREATE POLICY "Users can view their own deadlines"
    ON public.deadlines FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own deadlines"
    ON public.deadlines FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own deadlines"
    ON public.deadlines FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own deadlines"
    ON public.deadlines FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
-- Events: Users can view public events (user_id IS NULL) or their own events
CREATE POLICY "Users can view public or their own events"
    ON public.events FOR SELECT
    TO authenticated
    USING (user_id IS NULL OR auth.uid() = user_id);
CREATE POLICY "Users can insert their own events"
    ON public.events FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own events"
    ON public.events FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own events"
    ON public.events FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
-- Notifications: Users can only access their own notifications
CREATE POLICY "Users can view their own notifications"
    ON public.notifications FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own notifications"
    ON public.notifications FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own notifications"
    ON public.notifications FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own notifications"
    ON public.notifications FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
-- User Preferences: Users can only access their own preferences
CREATE POLICY "Users can view their own preferences"
    ON public.user_preferences FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own preferences"
    ON public.user_preferences FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own preferences"
    ON public.user_preferences FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);
-- Profiles: Users can only access their own profile
CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id);
CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);
-- Gamification Profiles: Users can only access their own
CREATE POLICY "Users can view their own gamification profile"
    ON public.gamification_profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own gamification profile"
    ON public.gamification_profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own gamification profile"
    ON public.gamification_profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);
-- XP Events: Users can only view their own (inserts via SECURITY DEFINER functions)
CREATE POLICY "Users can view their own xp events"
    ON public.xp_events FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);
-- ============================================================================
-- PART 6: CREATE HELPER FUNCTIONS
-- ============================================================================

-- Calculate level from XP
CREATE OR REPLACE FUNCTION calculate_level(p_xp integer)
RETURNS integer AS $$
BEGIN
    IF p_xp < 0 THEN
        RETURN 1;
    END IF;
    RETURN LEAST(100, FLOOR(SQRT(p_xp::float / 25)) + 1)::integer;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
-- Calculate XP required for a level
CREATE OR REPLACE FUNCTION xp_for_level(p_level integer)
RETURNS integer AS $$
BEGIN
    IF p_level <= 1 THEN
        RETURN 0;
    END IF;
    RETURN ((p_level - 1) * (p_level - 1) * 25)::integer;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
GRANT EXECUTE ON FUNCTION calculate_level TO authenticated;
GRANT EXECUTE ON FUNCTION xp_for_level TO authenticated;
-- ============================================================================
-- PART 7: PROTECT PROFILE FIELDS TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION protect_profile_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent changing student_id after initial set
    IF OLD.student_id IS NOT NULL AND NEW.student_id IS DISTINCT FROM OLD.student_id THEN
        RAISE EXCEPTION 'Cannot modify student_id after it has been set';
    END IF;

    -- Prevent changing email (should only change via auth flow)
    IF NEW.email IS DISTINCT FROM OLD.email THEN
        RAISE EXCEPTION 'Cannot modify email directly. Use the authentication flow.';
    END IF;

    -- Auto-update timestamp
    NEW.updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
DROP TRIGGER IF EXISTS protect_profile_fields_trigger ON public.profiles;
CREATE TRIGGER protect_profile_fields_trigger
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION protect_profile_fields();
-- ============================================================================
-- PART 8: GAMIFICATION FUNCTIONS
-- ============================================================================

-- Award XP function (SECURITY DEFINER to bypass RLS for XP events)
CREATE OR REPLACE FUNCTION award_xp(
    p_user_id uuid,
    p_event_type text,
    p_reference_id uuid DEFAULT NULL,
    p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb AS $$
DECLARE
    v_base_xp integer;
    v_xp_amount integer;
    v_old_xp integer;
    v_new_xp integer;
    v_old_level integer;
    v_new_level integer;
    v_streak_days integer;
    v_level_up_bonus integer;
BEGIN
    -- Get base XP for this event type
    SELECT base_xp INTO v_base_xp FROM public.xp_config WHERE event_type = p_event_type;
    IF v_base_xp IS NULL THEN
        RAISE EXCEPTION 'Unknown XP event type: %', p_event_type;
    END IF;

    v_xp_amount := v_base_xp;

    -- Ensure gamification profile exists
    INSERT INTO public.gamification_profiles (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;

    SELECT xp, streak_days INTO v_old_xp, v_streak_days
    FROM public.gamification_profiles
    WHERE user_id = p_user_id;

    v_old_level := calculate_level(v_old_xp);

    -- Apply streak multiplier for streak_bonus
    IF p_event_type = 'streak_bonus' AND v_streak_days > 0 THEN
        v_xp_amount := v_base_xp * v_streak_days;
    END IF;

    v_new_xp := v_old_xp + v_xp_amount;
    v_new_level := calculate_level(v_new_xp);

    -- Record the XP event
    INSERT INTO public.xp_events (user_id, event_type, xp_amount, reference_id, metadata)
    VALUES (p_user_id, p_event_type, v_xp_amount, p_reference_id, p_metadata);

    -- Update user's total XP
    UPDATE public.gamification_profiles
    SET xp = v_new_xp, updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Award level up bonus if leveled up
    IF v_new_level > v_old_level THEN
        v_level_up_bonus := 10 * v_new_level;

        INSERT INTO public.xp_events (user_id, event_type, xp_amount, metadata)
        VALUES (p_user_id, 'level_up_bonus', v_level_up_bonus,
                jsonb_build_object('old_level', v_old_level, 'new_level', v_new_level));

        UPDATE public.gamification_profiles
        SET xp = xp + v_level_up_bonus, updated_at = NOW()
        WHERE user_id = p_user_id;

        v_new_xp := v_new_xp + v_level_up_bonus;
    END IF;

    RETURN jsonb_build_object(
        'xp_awarded', v_xp_amount,
        'old_xp', v_old_xp,
        'new_xp', v_new_xp,
        'old_level', v_old_level,
        'new_level', v_new_level,
        'leveled_up', v_new_level > v_old_level
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Update streak function
CREATE OR REPLACE FUNCTION update_streak(p_user_id uuid)
RETURNS void AS $$
DECLARE
    v_last_date date;
    v_today date := CURRENT_DATE;
    v_streak integer;
    v_longest integer;
BEGIN
    -- Ensure profile exists
    INSERT INTO public.gamification_profiles (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;

    SELECT last_activity_date, streak_days, longest_streak
    INTO v_last_date, v_streak, v_longest
    FROM public.gamification_profiles
    WHERE user_id = p_user_id;

    IF v_last_date IS NULL THEN
        -- First activity ever
        UPDATE public.gamification_profiles
        SET streak_days = 1, last_activity_date = v_today, updated_at = NOW()
        WHERE user_id = p_user_id;
        PERFORM award_xp(p_user_id, 'daily_login');

    ELSIF v_last_date = v_today THEN
        -- Already active today
        NULL;

    ELSIF v_last_date = v_today - 1 THEN
        -- Consecutive day
        UPDATE public.gamification_profiles
        SET streak_days = streak_days + 1,
            longest_streak = GREATEST(longest_streak, streak_days + 1),
            last_activity_date = v_today,
            updated_at = NOW()
        WHERE user_id = p_user_id;
        PERFORM award_xp(p_user_id, 'daily_login');
        PERFORM award_xp(p_user_id, 'streak_bonus');

    ELSE
        -- Streak broken
        UPDATE public.gamification_profiles
        SET streak_days = 1, last_activity_date = v_today, updated_at = NOW()
        WHERE user_id = p_user_id;
        PERFORM award_xp(p_user_id, 'daily_login');
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- ============================================================================
-- PART 9: GAMIFICATION TRIGGERS
-- ============================================================================

-- Trigger: Award XP when deadline completed
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

        -- Check if early (24h+ before due)
        IF NEW.due_date > NOW() + INTERVAL '24 hours' THEN
            PERFORM award_xp(NEW.user_id, 'deadline_early', NEW.id,
                             jsonb_build_object('hours_early',
                               EXTRACT(EPOCH FROM (NEW.due_date - NOW())) / 3600));
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
DROP TRIGGER IF EXISTS deadline_completed_trigger ON public.deadlines;
CREATE TRIGGER deadline_completed_trigger
    AFTER UPDATE OF completed ON public.deadlines
    FOR EACH ROW
    EXECUTE FUNCTION on_deadline_completed();
-- Trigger: Award XP when unit created
CREATE OR REPLACE FUNCTION on_unit_created()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id IS NOT NULL THEN
        PERFORM update_streak(NEW.user_id);
        PERFORM award_xp(NEW.user_id, 'unit_added', NEW.id,
                         jsonb_build_object('code', NEW.code, 'name', NEW.name));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
DROP TRIGGER IF EXISTS unit_created_trigger ON public.units;
CREATE TRIGGER unit_created_trigger
    AFTER INSERT ON public.units
    FOR EACH ROW
    EXECUTE FUNCTION on_unit_created();
-- ============================================================================
-- PART 10: AUTH USER TRIGGER (Safe profile creation)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user_safe()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Create profile
    INSERT INTO public.profiles (id, email, full_name, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        updated_at = NOW();

    -- Create gamification profile
    INSERT INTO public.gamification_profiles (user_id, xp, streak_days, longest_streak, created_at, updated_at)
    VALUES (NEW.id, 0, 0, 0, NOW(), NOW())
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'handle_new_user_safe failed for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;
GRANT EXECUTE ON FUNCTION public.handle_new_user_safe() TO service_role;
-- Create trigger on auth.users (may fail if already exists, that's ok)
DO $$
BEGIN
    DROP TRIGGER IF EXISTS on_auth_user_created_safe ON auth.users;
    CREATE TRIGGER on_auth_user_created_safe
        AFTER INSERT ON auth.users
        FOR EACH ROW
        EXECUTE FUNCTION public.handle_new_user_safe();
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE WARNING 'Cannot create trigger on auth.users - insufficient privileges. Profile creation will rely on API.';
END $$;
-- ============================================================================
-- PART 11: ATOMIC UNIT CREATION FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION create_unit_with_schedule(
    p_user_id UUID,
    p_code TEXT,
    p_name TEXT,
    p_color TEXT,
    p_building TEXT,
    p_room TEXT,
    p_description TEXT DEFAULT NULL,
    p_schedule JSONB DEFAULT '[]'::JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_unit_id UUID;
    v_schedule_item JSONB;
    v_result JSONB;
BEGIN
    -- Validate user owns this request
    IF p_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Unauthorized: Cannot create unit for another user';
    END IF;

    v_unit_id := gen_random_uuid();

    INSERT INTO public.units (id, user_id, code, name, color, building, room, description)
    VALUES (v_unit_id, p_user_id, p_code, p_name, p_color, p_building, p_room, p_description);

    FOR v_schedule_item IN SELECT * FROM jsonb_array_elements(p_schedule)
    LOOP
        INSERT INTO public.class_times (unit_id, day, start_time, end_time)
        VALUES (
            v_unit_id,
            v_schedule_item->>'day',
            v_schedule_item->>'startTime',
            v_schedule_item->>'endTime'
        );
    END LOOP;

    SELECT jsonb_build_object(
        'id', u.id,
        'code', u.code,
        'name', u.name,
        'color', u.color,
        'building', u.building,
        'room', u.room,
        'description', u.description,
        'schedule', COALESCE(
            (SELECT jsonb_agg(jsonb_build_object(
                'id', ct.id,
                'day', ct.day,
                'startTime', ct.start_time,
                'endTime', ct.end_time
            )) FROM public.class_times ct WHERE ct.unit_id = u.id),
            '[]'::JSONB
        )
    ) INTO v_result
    FROM public.units u
    WHERE u.id = v_unit_id;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
GRANT EXECUTE ON FUNCTION create_unit_with_schedule TO authenticated;
-- ============================================================================
-- PART 12: CREATE USER PROFILE FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION create_user_profile(
    p_user_id uuid,
    p_email text,
    p_full_name text DEFAULT NULL,
    p_student_id text DEFAULT NULL
)
RETURNS jsonb AS $$
DECLARE
    v_result jsonb;
BEGIN
    IF p_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Unauthorized: Cannot create profile for another user';
    END IF;

    INSERT INTO public.profiles (id, email, full_name, student_id)
    VALUES (p_user_id, p_email, p_full_name, p_student_id);

    v_result := jsonb_build_object(
        'success', true,
        'profile_id', p_user_id,
        'message', 'Profile created successfully'
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
GRANT EXECUTE ON FUNCTION create_user_profile TO authenticated;
-- ============================================================================
-- PART 13: RECREATE USER_DETAILS VIEW WITH GAMIFICATION DATA
-- ============================================================================
-- Now that gamification_profiles exists, recreate the user_details view
-- to properly join with gamification data

DROP VIEW IF EXISTS public.user_details;
CREATE VIEW public.user_details AS
SELECT
    p.id,
    p.email,
    p.full_name,
    p.student_id,
    p.course,
    p.year,
    p.avatar_url,
    p.created_at,
    p.updated_at,
    COALESCE(gp.xp, 0) AS xp,
    COALESCE(gp.streak_days, 0) AS streak_days,
    COALESCE(gp.longest_streak, 0) AS longest_streak,
    gp.last_activity_date,
    CASE
        WHEN gp.xp IS NULL OR gp.xp < 0 THEN 1
        ELSE LEAST(100, FLOOR(SQRT(gp.xp::float / 25)) + 1)::integer
    END AS level
FROM public.profiles p
LEFT JOIN public.gamification_profiles gp ON p.id = gp.user_id;
-- Ensure authenticated users can still select from the view
GRANT SELECT ON public.user_details TO authenticated;
