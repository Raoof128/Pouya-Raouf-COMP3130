-- Migration to clean up schema and fix relationships
-- 1. Drop redundant public.users table (and any FKs pointing to it via CASCADE)
-- 2. Ensure all user_id FKs point to auth.users
-- 3. Connect xp_events to xp_config

BEGIN;
-- 1. Drop the public.users table
-- We use CASCADE to automatically remove any Foreign Keys that might be referencing this table
-- This cleans up the "bad" relationships shown in the diagram
DROP TABLE IF EXISTS public.users CASCADE;
-- 2. Re-establish Foreign Keys to auth.users for all tables
-- We drop first to ensure we don't have duplicates or mismatched constraints, then re-add

-- Table: profiles
ALTER TABLE public.profiles 
  DROP CONSTRAINT IF EXISTS profiles_user_id_fkey, -- potentially old name
  DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_id_fkey 
  FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- Table: units
ALTER TABLE public.units
  DROP CONSTRAINT IF EXISTS units_user_id_fkey;
ALTER TABLE public.units
  ADD CONSTRAINT units_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- Table: deadlines
ALTER TABLE public.deadlines
  DROP CONSTRAINT IF EXISTS deadlines_user_id_fkey;
ALTER TABLE public.deadlines
  ADD CONSTRAINT deadlines_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- Table: events
ALTER TABLE public.events
  DROP CONSTRAINT IF EXISTS events_user_id_fkey;
ALTER TABLE public.events
  ADD CONSTRAINT events_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- Table: notifications
ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;
ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- Table: user_preferences
ALTER TABLE public.user_preferences
  DROP CONSTRAINT IF EXISTS user_preferences_user_id_fkey;
ALTER TABLE public.user_preferences
  ADD CONSTRAINT user_preferences_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- Table: gamification_profiles
ALTER TABLE public.gamification_profiles
  DROP CONSTRAINT IF EXISTS gamification_profiles_user_id_fkey;
ALTER TABLE public.gamification_profiles
  ADD CONSTRAINT gamification_profiles_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- Table: xp_events
ALTER TABLE public.xp_events
  DROP CONSTRAINT IF EXISTS xp_events_user_id_fkey;
ALTER TABLE public.xp_events
  ADD CONSTRAINT xp_events_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- 3. Connect xp_events to xp_config
-- First, ensure all event types in xp_config exist to prevent FK violation
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
-- Now add the FK constraint
ALTER TABLE public.xp_events
  DROP CONSTRAINT IF EXISTS xp_events_event_type_fkey;
ALTER TABLE public.xp_events
  ADD CONSTRAINT xp_events_event_type_fkey 
  FOREIGN KEY (event_type) REFERENCES public.xp_config(event_type) ON DELETE CASCADE;
COMMIT;
