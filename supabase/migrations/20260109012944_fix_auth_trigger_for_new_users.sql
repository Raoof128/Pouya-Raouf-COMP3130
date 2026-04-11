-- ============================================================================
-- FIX AUTH TRIGGER FOR NEW USER SIGNUP
-- The "Database error saving new user" comes from Supabase's auth.users trigger
-- that tries to create a profile but fails due to RLS policies
-- ============================================================================

-- ============================================================================
-- STEP 1: Drop existing trigger that may be causing issues
-- ============================================================================

-- Drop any existing trigger on auth.users that creates profiles
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
-- ============================================================================
-- STEP 2: Create a new SECURITY DEFINER function to handle new users
-- This bypasses RLS and can insert into profiles table
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert profile for the new user
  -- Using SECURITY DEFINER to bypass RLS policies
  INSERT INTO public.profiles (id, email, full_name, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING; -- Prevent duplicate errors if profile already exists

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the signup
    RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- ============================================================================
-- STEP 3: Create the trigger on auth.users
-- ============================================================================

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
-- ============================================================================
-- STEP 4: Ensure profiles table allows the trigger to insert
-- We need to grant INSERT to the postgres role (used by triggers)
-- ============================================================================

-- Grant permissions to allow the trigger function to insert
GRANT INSERT ON public.profiles TO postgres;
GRANT USAGE ON SCHEMA public TO postgres;
-- Also ensure service_role can insert (used by admin operations)
GRANT INSERT, SELECT, UPDATE, DELETE ON public.profiles TO service_role;
-- ============================================================================
-- STEP 5: Create gamification profile for new users too
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user_gamification()
RETURNS TRIGGER AS $$
BEGIN
  -- Create gamification profile for the new user
  INSERT INTO public.gamification_profiles (user_id, xp, streak_days, longest_streak, created_at, updated_at)
  VALUES (NEW.id, 0, 0, 0, NOW(), NOW())
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to create gamification profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Create trigger for gamification profile
DROP TRIGGER IF EXISTS on_auth_user_created_gamification ON auth.users;
CREATE TRIGGER on_auth_user_created_gamification
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user_gamification();
-- Grant permissions for gamification tables
GRANT INSERT ON public.gamification_profiles TO postgres;
GRANT INSERT, SELECT, UPDATE, DELETE ON public.gamification_profiles TO service_role;
-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================;
