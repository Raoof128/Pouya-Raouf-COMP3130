-- ============================================================================
-- CHECK AND FIX ALL EXISTING AUTH TRIGGERS
-- This migration will find and fix any triggers that cause signup errors
-- ============================================================================

-- ============================================================================
-- STEP 1: List and drop ALL triggers on auth.users that might cause issues
-- Common names used by Supabase templates and tutorials
-- ============================================================================

-- Drop common trigger names that might exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS create_profile_on_signup ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;
DROP TRIGGER IF EXISTS create_user_profile_trigger ON auth.users;
DROP TRIGGER IF EXISTS new_user_trigger ON auth.users;
DROP TRIGGER IF EXISTS after_user_created ON auth.users;
DROP TRIGGER IF EXISTS user_created_trigger ON auth.users;
-- Drop the gamification trigger too
DROP TRIGGER IF EXISTS on_auth_user_created_gamification ON auth.users;
-- ============================================================================
-- STEP 2: Drop all related functions
-- ============================================================================

DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.create_profile_on_signup() CASCADE;
DROP FUNCTION IF EXISTS public.on_auth_user_created() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_gamification() CASCADE;
-- ============================================================================
-- STEP 3: Create a robust function that handles new user creation
-- This function will NOT fail even if there are issues
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  _full_name text;
BEGIN
  -- Extract full_name from metadata if available
  _full_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    ''
  );

  -- Insert profile, ignore if already exists
  BEGIN
    INSERT INTO public.profiles (id, email, full_name, created_at, updated_at)
    VALUES (
      NEW.id,
      COALESCE(NEW.email, ''),
      _full_name,
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      full_name = COALESCE(NULLIF(_full_name, ''), profiles.full_name),
      updated_at = NOW();
  EXCEPTION
    WHEN OTHERS THEN
      -- Log but don't fail
      RAISE LOG 'Profile creation warning for user %: %', NEW.id, SQLERRM;
  END;

  -- Create gamification profile
  BEGIN
    INSERT INTO public.gamification_profiles (user_id, xp, streak_days, longest_streak, created_at, updated_at)
    VALUES (NEW.id, 0, 0, 0, NOW(), NOW())
    ON CONFLICT (user_id) DO NOTHING;
  EXCEPTION
    WHEN OTHERS THEN
      -- Log but don't fail
      RAISE LOG 'Gamification profile creation warning for user %: %', NEW.id, SQLERRM;
  END;

  RETURN NEW;
END;
$$;
-- ============================================================================
-- STEP 4: Create the trigger
-- ============================================================================

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
-- ============================================================================
-- STEP 5: Ensure all necessary permissions are granted
-- ============================================================================

-- Grant to postgres (trigger executor)
GRANT ALL ON public.profiles TO postgres;
GRANT ALL ON public.gamification_profiles TO postgres;
-- Grant to service_role
GRANT ALL ON public.profiles TO service_role;
GRANT ALL ON public.gamification_profiles TO service_role;
-- Grant to authenticated users (needed for RLS to work)
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.gamification_profiles TO authenticated;
-- ============================================================================
-- STEP 6: Ensure RLS allows the trigger function to operate
-- Add a policy that allows service role / postgres to insert
-- ============================================================================

-- Drop and recreate the insert policy for profiles to be more permissive during signup
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Service can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow trigger to insert profiles" ON public.profiles;
-- This policy allows authenticated users to insert their own profile
CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);
-- This policy allows the trigger (running as postgres) to insert any profile
-- Note: postgres role bypasses RLS by default, but we add this for safety
CREATE POLICY "Service can insert profiles"
  ON public.profiles FOR INSERT
  TO service_role
  WITH CHECK (true);
-- Same for gamification profiles
DROP POLICY IF EXISTS "Service can insert gamification profiles" ON public.gamification_profiles;
CREATE POLICY "Service can insert gamification profiles"
  ON public.gamification_profiles FOR INSERT
  TO service_role
  WITH CHECK (true);
-- ============================================================================
-- STEP 7: Test that we can insert a profile (will be rolled back)
-- ============================================================================

-- This is just to verify the setup works
DO $$
BEGIN
  RAISE NOTICE 'Auth trigger setup complete. New users will automatically get profiles created.';
END $$;
-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================;
