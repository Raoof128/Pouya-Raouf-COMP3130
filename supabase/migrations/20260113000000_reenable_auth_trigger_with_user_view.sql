-- ============================================================================
-- RE-ENABLE AUTO PROFILE CREATION WITH IMPROVED TRIGGER
-- This migration creates a robust trigger on auth.users that:
-- 1. Creates a profile for every new user
-- 2. Creates a gamification_profile for every new user
-- 3. Uses proper error handling to not break signup
-- ============================================================================

-- ============================================================================
-- STEP 1: Create a safe trigger function that won't break signup
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user_safe()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Create profile for new user
    -- Use INSERT ... ON CONFLICT to handle race conditions
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

    -- Create gamification profile for new user
    INSERT INTO public.gamification_profiles (user_id, xp, streak_days, longest_streak, created_at, updated_at)
    VALUES (NEW.id, 0, 0, 0, NOW(), NOW())
    ON CONFLICT (user_id) DO NOTHING;

    -- Always return NEW to allow the user creation to proceed
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the user creation
        RAISE WARNING 'handle_new_user_safe failed for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;
-- Grant permissions
GRANT EXECUTE ON FUNCTION public.handle_new_user_safe() TO service_role;
-- ============================================================================
-- STEP 2: Create the trigger on auth.users
-- ============================================================================

-- Drop existing trigger if any
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_safe ON auth.users;
-- Create new trigger
CREATE TRIGGER on_auth_user_created_safe
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_safe();
-- ============================================================================
-- STEP 3: Create a VIEW that combines auth.users and profiles for easy querying
-- This gives you a "users" table-like experience with all data in one place
-- ============================================================================

-- Drop existing view if any
DROP VIEW IF EXISTS public.user_details;
-- Create view that joins auth.users with profiles and gamification
CREATE OR REPLACE VIEW public.user_details AS
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.student_id,
    p.avatar_url,
    p.created_at,
    p.updated_at,
    gp.xp,
    gp.streak_days,
    gp.longest_streak,
    gp.last_activity_date,
    -- Calculate level from XP
    CASE 
        WHEN gp.xp IS NULL OR gp.xp < 0 THEN 1
        ELSE LEAST(100, FLOOR(SQRT(gp.xp::float / 25)) + 1)::integer
    END AS level
FROM public.profiles p
LEFT JOIN public.gamification_profiles gp ON p.id = gp.user_id;
-- Grant select on the view to authenticated users
GRANT SELECT ON public.user_details TO authenticated;
-- ============================================================================
-- STEP 4: Create RLS policy for user_details view
-- Users can only see their own data
-- ============================================================================

ALTER VIEW public.user_details SET (security_invoker = true);
-- Note: Views inherit RLS from underlying tables (profiles, gamification_profiles)
-- Both tables already have RLS policies that restrict access to own data

-- ============================================================================
-- STEP 5: Create helper function to get current user's details
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_my_profile()
RETURNS TABLE (
    id uuid,
    email text,
    full_name text,
    student_id text,
    avatar_url text,
    created_at timestamptz,
    updated_at timestamptz,
    xp integer,
    streak_days integer,
    longest_streak integer,
    last_activity_date date,
    level integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ud.id,
        ud.email,
        ud.full_name,
        ud.student_id,
        ud.avatar_url,
        ud.created_at,
        ud.updated_at,
        ud.xp,
        ud.streak_days,
        ud.longest_streak,
        ud.last_activity_date,
        ud.level
    FROM public.user_details ud
    WHERE ud.id = auth.uid();
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_my_profile() TO authenticated;
-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- 
-- What changed:
-- 1. Created handle_new_user_safe() - a trigger function that won't break signup
-- 2. Created on_auth_user_created_safe trigger on auth.users
-- 3. Created user_details VIEW that combines profiles + gamification_profiles
-- 4. Created get_my_profile() function for easy access to current user data
--
-- How it works now:
-- - When a user signs up via auth.users, the trigger automatically creates:
--   - profiles row
--   - gamification_profiles row
-- - The signup API also creates these as a backup
-- - Query user_details or call get_my_profile() for combined user data
-- ============================================================================;
