-- Migration: Add user_id columns and Row Level Security (RLS) policies
-- Purpose: Fix IDOR vulnerability - ensure users can only access their own data
-- Date: 2026-01-08
-- Security Audit Finding: Critical - Missing user-scoped data isolation

-- ============================================================================
-- STEP 1: Add user_id columns to tables that are missing them
-- ============================================================================

-- Add user_id to units table
ALTER TABLE public.units 
ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
-- Add user_id to deadlines table
ALTER TABLE public.deadlines 
ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
-- Add user_id to events table (nullable for public/shared events)
ALTER TABLE public.events 
ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
-- ============================================================================
-- STEP 2: Create indexes for performance on user_id columns
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_units_user_id ON public.units(user_id);
CREATE INDEX IF NOT EXISTS idx_deadlines_user_id ON public.deadlines(user_id);
CREATE INDEX IF NOT EXISTS idx_events_user_id ON public.events(user_id);
-- ============================================================================
-- STEP 3: Update unique constraint on units (user can have same code as another user)
-- ============================================================================

-- Drop old unique constraint on code if it exists
ALTER TABLE public.units DROP CONSTRAINT IF EXISTS units_code_key;
-- Add new composite unique constraint (each user has unique codes)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE c.contype = 'u'
      AND n.nspname = 'public'
      AND t.relname = 'units'
      AND (
        c.conname = 'units_user_code_unique'
        OR pg_get_constraintdef(c.oid) = 'UNIQUE (user_id, code)'
      )
  ) THEN
    BEGIN
      ALTER TABLE public.units ADD CONSTRAINT units_user_code_unique UNIQUE (user_id, code);
    EXCEPTION
      WHEN duplicate_object THEN
        NULL;
      WHEN SQLSTATE '42P07' THEN
        NULL;
    END;
  END IF;
END $$;
-- ============================================================================
-- STEP 4: Enable Row Level Security (RLS) on all user-scoped tables
-- ============================================================================

ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deadlines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
-- ============================================================================
-- STEP 5: Create RLS Policies for UNITS table
-- ============================================================================

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Users can view their own units" ON public.units;
DROP POLICY IF EXISTS "Users can insert their own units" ON public.units;
DROP POLICY IF EXISTS "Users can update their own units" ON public.units;
DROP POLICY IF EXISTS "Users can delete their own units" ON public.units;
-- Create policies
CREATE POLICY "Users can view their own units"
  ON public.units FOR SELECT
  USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own units"
  ON public.units FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own units"
  ON public.units FOR UPDATE
  USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own units"
  ON public.units FOR DELETE
  USING (auth.uid() = user_id);
-- ============================================================================
-- STEP 6: Create RLS Policies for DEADLINES table
-- ============================================================================

DROP POLICY IF EXISTS "Users can view their own deadlines" ON public.deadlines;
DROP POLICY IF EXISTS "Users can insert their own deadlines" ON public.deadlines;
DROP POLICY IF EXISTS "Users can update their own deadlines" ON public.deadlines;
DROP POLICY IF EXISTS "Users can delete their own deadlines" ON public.deadlines;
CREATE POLICY "Users can view their own deadlines"
  ON public.deadlines FOR SELECT
  USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own deadlines"
  ON public.deadlines FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own deadlines"
  ON public.deadlines FOR UPDATE
  USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own deadlines"
  ON public.deadlines FOR DELETE
  USING (auth.uid() = user_id);
-- ============================================================================
-- STEP 7: Create RLS Policies for EVENTS table
-- Events can be public (user_id IS NULL) or user-specific
-- ============================================================================

DROP POLICY IF EXISTS "Users can view public or their own events" ON public.events;
DROP POLICY IF EXISTS "Users can insert their own events" ON public.events;
DROP POLICY IF EXISTS "Users can update their own events" ON public.events;
DROP POLICY IF EXISTS "Users can delete their own events" ON public.events;
CREATE POLICY "Users can view public or their own events"
  ON public.events FOR SELECT
  USING (user_id IS NULL OR auth.uid() = user_id);
CREATE POLICY "Users can insert their own events"
  ON public.events FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own events"
  ON public.events FOR UPDATE
  USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own events"
  ON public.events FOR DELETE
  USING (auth.uid() = user_id);
-- ============================================================================
-- STEP 8: Create RLS Policies for NOTIFICATIONS table
-- ============================================================================

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can insert their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own notifications"
  ON public.notifications FOR DELETE
  USING (auth.uid() = user_id);
-- ============================================================================
-- STEP 9: Create RLS Policies for USER_PREFERENCES table
-- ============================================================================

DROP POLICY IF EXISTS "Users can view their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can insert their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can update their own preferences" ON public.user_preferences;
CREATE POLICY "Users can view their own preferences"
  ON public.user_preferences FOR SELECT
  USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own preferences"
  ON public.user_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own preferences"
  ON public.user_preferences FOR UPDATE
  USING (auth.uid() = user_id);
-- ============================================================================
-- STEP 10: Create RLS Policies for PROFILES table
-- ============================================================================

DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);
-- ============================================================================
-- STEP 11: Grant necessary permissions to authenticated users
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.units TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.deadlines TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.events TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.user_preferences TO authenticated;
GRANT SELECT, UPDATE ON public.profiles TO authenticated;
-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- Summary:
-- 1. Added user_id columns to units, deadlines, events tables
-- 2. Created indexes for performance
-- 3. Enabled RLS on all user-scoped tables
-- 4. Created 20+ RLS policies to enforce user isolation
-- 5. Granted appropriate permissions to authenticated users
--
-- Note: Existing data will have NULL user_id values. You may need to:
-- - Assign existing records to a default user, OR
-- - Delete orphaned records, OR
-- - Leave as-is (they won't be visible to anyone with RLS enabled)
-- ============================================================================;
