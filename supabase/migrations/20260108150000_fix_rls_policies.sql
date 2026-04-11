-- Migration: Fix RLS Policies and Add Missing Security
-- Purpose: Ensure all tables have proper RLS and fix anonymous access issues
-- Date: 2026-01-08
-- Issue: Units table allows anonymous SELECT, class_times has no RLS

-- ============================================================================
-- STEP 1: Fix units table RLS - ensure it blocks anonymous access
-- The issue is that the anon role can SELECT from units even with RLS enabled
-- We need to explicitly REVOKE anon access and ensure only authenticated users can query
-- ============================================================================

-- First, ensure RLS is enabled (idempotent)
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
-- Drop and recreate the SELECT policy to ensure it's correct
DROP POLICY IF EXISTS "Users can view their own units" ON public.units;
CREATE POLICY "Users can view their own units"
  ON public.units FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
-- Ensure anon role cannot access units at all
REVOKE ALL ON public.units FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.units TO authenticated;
-- ============================================================================
-- STEP 2: Add RLS to class_times table
-- class_times should only be visible for units owned by the current user
-- ============================================================================

ALTER TABLE public.class_times ENABLE ROW LEVEL SECURITY;
-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view class_times for their units" ON public.class_times;
DROP POLICY IF EXISTS "Users can insert class_times for their units" ON public.class_times;
DROP POLICY IF EXISTS "Users can update class_times for their units" ON public.class_times;
DROP POLICY IF EXISTS "Users can delete class_times for their units" ON public.class_times;
-- Create policies that check ownership via the units table
CREATE POLICY "Users can view class_times for their units"
  ON public.class_times FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.units 
      WHERE units.id = class_times.unit_id 
      AND units.user_id = auth.uid()
    )
  );
CREATE POLICY "Users can insert class_times for their units"
  ON public.class_times FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.units 
      WHERE units.id = class_times.unit_id 
      AND units.user_id = auth.uid()
    )
  );
CREATE POLICY "Users can update class_times for their units"
  ON public.class_times FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.units 
      WHERE units.id = class_times.unit_id 
      AND units.user_id = auth.uid()
    )
  );
CREATE POLICY "Users can delete class_times for their units"
  ON public.class_times FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.units 
      WHERE units.id = class_times.unit_id 
      AND units.user_id = auth.uid()
    )
  );
-- Revoke anon access to class_times
REVOKE ALL ON public.class_times FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.class_times TO authenticated;
-- ============================================================================
-- STEP 3: Fix deadlines table - ensure RLS and proper column
-- ============================================================================

ALTER TABLE public.deadlines ENABLE ROW LEVEL SECURITY;
-- Recreate policies with TO authenticated
DROP POLICY IF EXISTS "Users can view their own deadlines" ON public.deadlines;
DROP POLICY IF EXISTS "Users can insert their own deadlines" ON public.deadlines;
DROP POLICY IF EXISTS "Users can update their own deadlines" ON public.deadlines;
DROP POLICY IF EXISTS "Users can delete their own deadlines" ON public.deadlines;
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
-- Revoke anon access
REVOKE ALL ON public.deadlines FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.deadlines TO authenticated;
-- ============================================================================
-- STEP 4: Fix notifications table RLS
-- ============================================================================

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can insert their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;
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
REVOKE ALL ON public.notifications FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;
-- ============================================================================
-- STEP 5: Fix user_preferences table RLS
-- ============================================================================

ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can insert their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can update their own preferences" ON public.user_preferences;
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
REVOKE ALL ON public.user_preferences FROM anon;
GRANT SELECT, INSERT, UPDATE ON public.user_preferences TO authenticated;
-- ============================================================================
-- STEP 6: Fix profiles table RLS
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);
REVOKE ALL ON public.profiles FROM anon;
GRANT SELECT, UPDATE ON public.profiles TO authenticated;
-- ============================================================================
-- STEP 7: Fix events table - keep public events accessible
-- Events with user_id IS NULL should be visible to authenticated users
-- ============================================================================

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view public or their own events" ON public.events;
DROP POLICY IF EXISTS "Users can insert their own events" ON public.events;
DROP POLICY IF EXISTS "Users can update their own events" ON public.events;
DROP POLICY IF EXISTS "Users can delete their own events" ON public.events;
-- Public events (user_id IS NULL) are visible to all authenticated users
-- User's own events are also visible
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
-- Revoke anon, grant to authenticated
REVOKE ALL ON public.events FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.events TO authenticated;
-- ============================================================================
-- STEP 8: Add unit_code column to deadlines if missing
-- The API expects unit_code but the column might not exist
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'deadlines' 
    AND column_name = 'unit_code'
  ) THEN
    -- Check if there's a different column name for unit reference
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'deadlines' 
      AND column_name = 'unit_id'
    ) THEN
      -- There's a unit_id column - we need to add unit_code and populate it
      ALTER TABLE public.deadlines ADD COLUMN unit_code text;
      -- Update from unit_id -> units.code
      UPDATE public.deadlines d
      SET unit_code = u.code
      FROM public.units u
      WHERE d.unit_id = u.id AND d.unit_code IS NULL;
    ELSE
      -- No unit reference at all - add the column
      ALTER TABLE public.deadlines ADD COLUMN unit_code text NOT NULL DEFAULT '';
    END IF;
  END IF;
END $$;
-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- Summary:
-- 1. Fixed units RLS - now blocks anon access
-- 2. Added RLS to class_times - checks ownership via units
-- 3. Fixed all other tables to explicitly use TO authenticated
-- 4. Revoked anon access from all user-scoped tables
-- 5. Added unit_code column to deadlines if missing
-- ============================================================================;
