-- ============================================================================
-- DISABLE ALL AUTH USER TRIGGERS AND FIX PROFILE CREATION
-- The error "Database error saving new user" comes from a trigger failing
-- We need to either fix or remove the trigger completely
-- ============================================================================

-- ============================================================================
-- STEP 1: Drop ALL possible triggers on auth.users
-- This is aggressive but necessary to fix the signup issue
-- ============================================================================

DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    -- Find and drop all triggers on auth.users
    FOR trigger_record IN 
        SELECT tgname 
        FROM pg_trigger 
        WHERE tgrelid = 'auth.users'::regclass 
        AND tgisinternal = false
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON auth.users', trigger_record.tgname);
        RAISE NOTICE 'Dropped trigger: %', trigger_record.tgname;
    END LOOP;
END $$;
-- ============================================================================
-- STEP 2: Drop all custom functions that might be called by triggers
-- ============================================================================

DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_gamification() CASCADE;
DROP FUNCTION IF EXISTS public.create_profile_for_user() CASCADE;
DROP FUNCTION IF EXISTS public.on_auth_user_created() CASCADE;
-- ============================================================================
-- STEP 3: DO NOT create any new trigger on auth.users
-- Instead, we'll handle profile creation in the application layer
-- ============================================================================

-- The signup flow will now work without any trigger
-- Profile creation will happen via:
-- 1. API route after successful signup
-- 2. Or on first login if profile doesn't exist

-- ============================================================================
-- STEP 4: Create a function that can be called manually to create profiles
-- This is safer than a trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION public.ensure_user_profile(p_user_id uuid, p_email text, p_full_name text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Insert profile if it doesn't exist
    INSERT INTO public.profiles (id, email, full_name, created_at, updated_at)
    VALUES (p_user_id, p_email, COALESCE(p_full_name, ''), NOW(), NOW())
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        updated_at = NOW();
        
    -- Insert gamification profile if it doesn't exist
    INSERT INTO public.gamification_profiles (user_id, xp, streak_days, longest_streak, created_at, updated_at)
    VALUES (p_user_id, 0, 0, 0, NOW(), NOW())
    ON CONFLICT (user_id) DO NOTHING;
END;
$$;
-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.ensure_user_profile(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_user_profile(uuid, text, text) TO service_role;
-- ============================================================================
-- STEP 5: Make sure profiles table has correct structure and permissions
-- ============================================================================

-- Ensure the profiles table primary key constraint exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'profiles_pkey'
    ) THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);
    END IF;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
-- Ensure foreign key to auth.users exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'profiles_id_fkey'
    ) THEN
        ALTER TABLE public.profiles 
        ADD CONSTRAINT profiles_id_fkey 
        FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
-- ============================================================================
-- MIGRATION COMPLETE - NO TRIGGER ON AUTH.USERS
-- ============================================================================
-- Profile creation will now be handled by the application:
-- 1. After signup succeeds, call ensure_user_profile() 
-- 2. Or create profile on first authenticated request
-- ============================================================================;
