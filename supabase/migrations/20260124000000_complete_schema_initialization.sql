-- Migration: Complete Database Schema Initialization
-- Purpose: Initialize the complete database schema for production deployment
-- Date: 2026-01-24
-- Description: This migration consolidates all schema changes into a single comprehensive migration

-- ============================================================================
-- USER-CENTRIC ARCHITECTURE:
-- =========================
-- This database follows a strict user-centric design where:
-- 1. auth.users.id is the SINGLE source of truth for user identity
-- 2. profiles.id = auth.users.id (1:1 relationship, same UUID)
-- 3. All domain data is OWNED by exactly one user via user_id FK
-- 4. RLS policies enforce complete data isolation between users
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- ============================================================================
-- CORE USER TABLES
-- ============================================================================

-- Profiles table - 1:1 with auth.users
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  email text NOT NULL,
  full_name text,
  student_id text,
  course text,
  year text,
  avatar_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);
-- User preferences - one per user
CREATE TABLE IF NOT EXISTS public.user_preferences (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  theme text DEFAULT 'system' CHECK (theme = ANY (ARRAY['light'::text, 'dark'::text, 'system'::text])),
  notifications_enabled boolean DEFAULT true,
  email_notifications boolean DEFAULT false,
  push_notifications boolean DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_preferences_pkey PRIMARY KEY (id),
  CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
-- ============================================================================
-- ACADEMIC DOMAIN TABLES
-- ============================================================================

-- Units table - user-scoped course units
CREATE TABLE IF NOT EXISTS public.units (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  code text NOT NULL,
  name text NOT NULL,
  color text NOT NULL DEFAULT '#3B82F6',
  description text,
  location jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  deleted_at timestamp with time zone,
  CONSTRAINT units_pkey PRIMARY KEY (id),
  CONSTRAINT units_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT units_user_code_unique UNIQUE (user_id, code)
);
-- Class times linked to units
CREATE TABLE IF NOT EXISTS public.class_times (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  unit_id uuid NOT NULL,
  day text NOT NULL CHECK (day = ANY (ARRAY['Monday'::text, 'Tuesday'::text, 'Wednesday'::text, 'Thursday'::text, 'Friday'::text, 'Saturday'::text, 'Sunday'::text])),
  start_time text NOT NULL,
  end_time text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT class_times_pkey PRIMARY KEY (id),
  CONSTRAINT class_times_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id) ON DELETE CASCADE,
  CONSTRAINT class_times_time_format CHECK (
    start_time ~ '^([01]?[0-9]|2[0-3]):[0-5][0-9]$' AND
    end_time ~ '^([01]?[0-9]|2[0-3]):[0-5][0-9]$'
  ),
  CONSTRAINT class_times_valid_times CHECK (start_time < end_time)
);
-- Deadlines table - user-scoped assignments and exams
CREATE TABLE IF NOT EXISTS public.deadlines (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  unit_code text NOT NULL,
  unit_id uuid,
  due_date timestamp with time zone NOT NULL,
  priority text NOT NULL DEFAULT 'Medium' CHECK (priority = ANY (ARRAY['Low'::text, 'Medium'::text, 'High'::text, 'Urgent'::text])),
  type text NOT NULL DEFAULT 'Assignment' CHECK (type = ANY (ARRAY['Assignment'::text, 'Exam'::text, 'Quiz'::text, 'Presentation'::text])),
  completed boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  deleted_at timestamp with time zone,
  CONSTRAINT deadlines_pkey PRIMARY KEY (id),
  CONSTRAINT deadlines_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT deadlines_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id) ON DELETE SET NULL
);
-- Events table - campus events (public and private)
CREATE TABLE IF NOT EXISTS public.events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  title text NOT NULL,
  description text NOT NULL,
  start_at timestamp with time zone NOT NULL,
  end_at timestamp with time zone,
  all_day boolean NOT NULL DEFAULT false,
  location text NOT NULL,
  building text,
  category text NOT NULL DEFAULT 'Academic' CHECK (category = ANY (ARRAY['Career'::text, 'Social'::text, 'Academic'::text, 'Free Food'::text])),
  image_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  deleted_at timestamp with time zone,
  CONSTRAINT events_pkey PRIMARY KEY (id),
  CONSTRAINT events_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT events_valid_time_range CHECK (end_at IS NULL OR end_at >= start_at)
);
-- Notifications table - user notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  type text NOT NULL DEFAULT 'system' CHECK (type = ANY (ARRAY['deadline'::text, 'event'::text, 'class'::text, 'system'::text])),
  read boolean NOT NULL DEFAULT false,
  link text,
  related_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  deleted_at timestamp with time zone,
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
-- ============================================================================
-- GAMIFICATION SYSTEM
-- ============================================================================

-- Gamification profiles - XP and progress tracking
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
-- XP events - track all XP-earning activities
CREATE TABLE IF NOT EXISTS public.xp_events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  event_type text NOT NULL CHECK (event_type = ANY (ARRAY[
    'deadline_completed'::text, 'deadline_early'::text, 'daily_login'::text,
    'streak_bonus'::text, 'unit_added'::text, 'event_attended'::text,
    'profile_completed'::text, 'first_deadline'::text, 'weekly_goal'::text, 'level_up_bonus'::text
  ])),
  xp_amount integer NOT NULL CHECK (xp_amount > 0),
  reference_id uuid,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT xp_events_pkey PRIMARY KEY (id),
  CONSTRAINT xp_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
-- XP configuration - define XP values for different activities
CREATE TABLE IF NOT EXISTS public.xp_config (
  id uuid DEFAULT gen_random_uuid() UNIQUE,
  event_type text PRIMARY KEY,
  base_xp integer NOT NULL CHECK (base_xp > 0),
  description text
);
-- Insert default XP configuration
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
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Core user table indexes
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_student_id ON public.profiles(student_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON public.user_preferences(user_id);
-- Academic table indexes
CREATE INDEX IF NOT EXISTS idx_units_code ON public.units(code);
CREATE INDEX IF NOT EXISTS idx_units_user_id ON public.units(user_id);
CREATE INDEX IF NOT EXISTS idx_units_deleted_at ON public.units(deleted_at);
CREATE INDEX IF NOT EXISTS idx_class_times_unit_id ON public.class_times(unit_id);
CREATE INDEX IF NOT EXISTS idx_class_times_day ON public.class_times(day);
CREATE INDEX IF NOT EXISTS idx_deadlines_unit_code ON public.deadlines(unit_code);
CREATE INDEX IF NOT EXISTS idx_deadlines_unit_id ON public.deadlines(unit_id);
CREATE INDEX IF NOT EXISTS idx_deadlines_due_date ON public.deadlines(due_date);
CREATE INDEX IF NOT EXISTS idx_deadlines_completed ON public.deadlines(completed);
CREATE INDEX IF NOT EXISTS idx_deadlines_user_id ON public.deadlines(user_id);
CREATE INDEX IF NOT EXISTS idx_deadlines_deleted_at ON public.deadlines(deleted_at);
CREATE INDEX IF NOT EXISTS idx_events_start_at ON public.events(start_at);
CREATE INDEX IF NOT EXISTS idx_events_end_at ON public.events(end_at);
CREATE INDEX IF NOT EXISTS idx_events_category ON public.events(category);
CREATE INDEX IF NOT EXISTS idx_events_user_id ON public.events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_deleted_at ON public.events(deleted_at);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(read);
CREATE INDEX IF NOT EXISTS idx_notifications_deleted_at ON public.notifications(deleted_at);
-- Gamification indexes
CREATE INDEX IF NOT EXISTS idx_gamification_profiles_user_id ON public.gamification_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_xp_events_user_id ON public.xp_events(user_id);
CREATE INDEX IF NOT EXISTS idx_xp_events_created_at ON public.xp_events(created_at);
CREATE INDEX IF NOT EXISTS idx_xp_events_event_type ON public.xp_events(event_type);
CREATE INDEX IF NOT EXISTS idx_xp_events_reference_id ON public.xp_events(reference_id);
-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_times ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deadlines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gamification_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xp_events ENABLE ROW LEVEL SECURITY;
-- Revoke anonymous access
REVOKE ALL ON public.profiles FROM anon;
REVOKE ALL ON public.units FROM anon;
REVOKE ALL ON public.class_times FROM anon;
REVOKE ALL ON public.deadlines FROM anon;
REVOKE ALL ON public.events FROM anon;
REVOKE ALL ON public.notifications FROM anon;
REVOKE ALL ON public.user_preferences FROM anon;
REVOKE ALL ON public.gamification_profiles FROM anon;
REVOKE ALL ON public.xp_events FROM anon;
REVOKE ALL ON public.xp_config FROM anon;
-- Grant to authenticated users
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.units TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.class_times TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.deadlines TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.events TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.user_preferences TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.gamification_profiles TO authenticated;
GRANT SELECT, INSERT ON public.xp_events TO authenticated;
GRANT SELECT ON public.xp_config TO authenticated;
-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Profiles policies (user can only access their own profile)
CREATE POLICY "Users can view their own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
-- User preferences policies
CREATE POLICY "Users can view their own preferences" ON public.user_preferences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own preferences" ON public.user_preferences FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own preferences" ON public.user_preferences FOR UPDATE USING (auth.uid() = user_id);
-- Units policies
CREATE POLICY "Users can view their own units" ON public.units FOR SELECT USING (auth.uid() = user_id AND deleted_at IS NULL);
CREATE POLICY "Users can insert their own units" ON public.units FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own units" ON public.units FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own units" ON public.units FOR DELETE USING (auth.uid() = user_id);
-- Class times policies (inherited from units ownership)
CREATE POLICY "Users can view class times for their units" ON public.class_times FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.units WHERE units.id = class_times.unit_id AND units.user_id = auth.uid() AND units.deleted_at IS NULL)
);
CREATE POLICY "Users can insert class times for their units" ON public.class_times FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.units WHERE units.id = class_times.unit_id AND units.user_id = auth.uid() AND units.deleted_at IS NULL)
);
CREATE POLICY "Users can update class times for their units" ON public.class_times FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.units WHERE units.id = class_times.unit_id AND units.user_id = auth.uid() AND units.deleted_at IS NULL)
);
CREATE POLICY "Users can delete class times for their units" ON public.class_times FOR DELETE USING (
  EXISTS (SELECT 1 FROM public.units WHERE units.id = class_times.unit_id AND units.user_id = auth.uid() AND units.deleted_at IS NULL)
);
-- Deadlines policies
CREATE POLICY "Users can view their own deadlines" ON public.deadlines FOR SELECT USING (auth.uid() = user_id AND deleted_at IS NULL);
CREATE POLICY "Users can insert their own deadlines" ON public.deadlines FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own deadlines" ON public.deadlines FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own deadlines" ON public.deadlines FOR DELETE USING (auth.uid() = user_id);
-- Events policies (public + private events)
CREATE POLICY "Users can view public or their own events" ON public.events FOR SELECT USING ((user_id IS NULL OR auth.uid() = user_id) AND deleted_at IS NULL);
CREATE POLICY "Users can insert their own events" ON public.events FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own events" ON public.events FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own events" ON public.events FOR DELETE USING (auth.uid() = user_id);
-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id AND deleted_at IS NULL);
CREATE POLICY "Users can insert their own notifications" ON public.notifications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own notifications" ON public.notifications FOR DELETE USING (auth.uid() = user_id);
-- Gamification profiles policies
CREATE POLICY "Users can view their own gamification profile" ON public.gamification_profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own gamification profile" ON public.gamification_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own gamification profile" ON public.gamification_profiles FOR UPDATE USING (auth.uid() = user_id);
-- XP events policies
CREATE POLICY "Users can view their own XP events" ON public.xp_events FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own XP events" ON public.xp_events FOR INSERT WITH CHECK (auth.uid() = user_id);
-- ============================================================================
-- VIEWS AND FUNCTIONS
-- ============================================================================

-- User details view (joins profiles + gamification)
CREATE OR REPLACE VIEW public.user_details AS
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
    gp.xp,
    gp.streak_days,
    gp.longest_streak,
    gp.last_activity_date,
    CASE
        WHEN gp.xp IS NULL OR gp.xp < 0 THEN 1
        ELSE LEAST(100, FLOOR(SQRT(gp.xp::float / 25)) + 1)::integer
    END AS level
FROM public.profiles p
LEFT JOIN public.gamification_profiles gp ON p.id = gp.user_id;
GRANT SELECT ON public.user_details TO authenticated;
-- Materialized views for analytics
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_deadline_analytics AS
SELECT
    d.user_id,
    COUNT(*) AS total_deadlines,
    COUNT(*) FILTER (WHERE d.completed = true) AS completed_count,
    COUNT(*) FILTER (WHERE d.completed = false) AS pending_count,
    COUNT(*) FILTER (WHERE d.completed = false AND d.due_date < NOW()) AS overdue_count,
    MIN(d.due_date) FILTER (WHERE d.completed = false AND d.due_date > NOW()) AS next_deadline_date
FROM public.deadlines d
WHERE d.deleted_at IS NULL
GROUP BY d.user_id;
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_deadline_analytics_key ON public.mv_deadline_analytics(user_id);
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_xp_leaderboard AS
SELECT
    gp.user_id,
    p.full_name,
    p.avatar_url,
    gp.xp,
    gp.streak_days,
    LEAST(100, FLOOR(SQRT(gp.xp::float / 25)) + 1)::integer AS level,
    RANK() OVER (ORDER BY gp.xp DESC) AS rank
FROM public.gamification_profiles gp
JOIN public.profiles p ON gp.user_id = p.id;
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_xp_leaderboard_user_id ON public.mv_xp_leaderboard(user_id);
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_user_activity_summary AS
SELECT
    gp.user_id,
    gp.last_activity_date,
    gp.streak_days,
    gp.longest_streak,
    (SELECT COUNT(*) FROM public.xp_events xe WHERE xe.user_id = gp.user_id) AS total_actions,
    (SELECT MAX(created_at) FROM public.xp_events xe WHERE xe.user_id = gp.user_id) AS last_action_at
FROM public.gamification_profiles gp;
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_user_activity_summary_user_id ON public.mv_user_activity_summary(user_id);
GRANT SELECT ON public.mv_deadline_analytics TO authenticated;
GRANT SELECT ON public.mv_xp_leaderboard TO authenticated;
GRANT SELECT ON public.mv_user_activity_summary TO authenticated;
-- Helper functions
CREATE OR REPLACE FUNCTION calculate_level(p_xp integer)
RETURNS integer AS $$
BEGIN
    IF p_xp < 0 THEN RETURN 1; END IF;
    RETURN LEAST(100, FLOOR(SQRT(p_xp::float / 25)) + 1)::integer;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
CREATE OR REPLACE FUNCTION xp_for_level(p_level integer)
RETURNS integer AS $$
BEGIN
    IF p_level <= 1 THEN RETURN 0; END IF;
    RETURN ((p_level - 1) * (p_level - 1) * 25)::integer;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
CREATE OR REPLACE FUNCTION public.get_my_profile()
RETURNS TABLE (
    id uuid, email text, full_name text, student_id text, course text, year text,
    avatar_url text, created_at timestamptz, updated_at timestamptz,
    xp integer, streak_days integer, longest_streak integer, last_activity_date date, level integer
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    RETURN QUERY SELECT * FROM public.user_details ud WHERE ud.id = auth.uid();
END;
$$;
GRANT EXECUTE ON FUNCTION calculate_level TO authenticated;
GRANT EXECUTE ON FUNCTION xp_for_level TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_profile() TO authenticated;
-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- This migration creates the complete production-ready database schema with:
-- 1. All core user and academic tables
-- 2. Comprehensive gamification system  
-- 3. Performance indexes
-- 4. Row Level Security policies
-- 5. Materialized views for analytics
-- 6. Helper functions for calculations
-- 7. Proper foreign key constraints and data validation
-- ============================================================================;
