-- ============================================================================
-- MIGRATION: 001_initial_schema
-- CREATED: 2026-01-03
-- DESCRIPTION: Initial database schema for Syllabus Sync application
-- ============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- Create profiles table (must be done after auth setup)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT,
  student_id TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Create units table
CREATE TABLE IF NOT EXISTS public.units (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#3B82F6',
  description TEXT,
  location JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Permissive constraint: just ensure code is not empty
  CONSTRAINT units_code_not_empty CHECK (code IS NOT NULL AND length(trim(code)) > 0),
  CONSTRAINT units_color_format CHECK (color ~ '^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})$')
);
-- Create class_times table
CREATE TABLE IF NOT EXISTS public.class_times (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  unit_id UUID NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
  day TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT class_times_day_enum CHECK (day IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')),
  CONSTRAINT class_times_time_format CHECK (
    start_time ~ '^([01]?[0-9]|2[0-3]):[0-5][0-9]$' AND
    end_time ~ '^([01]?[0-9]|2[0-3]):[0-5][0-9]$'
  ),
  CONSTRAINT class_times_valid_times CHECK (start_time < end_time)
);
-- Create deadlines table
CREATE TABLE IF NOT EXISTS public.deadlines (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  unit_code TEXT NOT NULL,
  due_date TIMESTAMPTZ NOT NULL,
  priority TEXT NOT NULL DEFAULT 'Medium',
  type TEXT NOT NULL DEFAULT 'Assignment',
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT deadlines_priority_enum CHECK (priority IN ('Low', 'Medium', 'High', 'Urgent')),
  CONSTRAINT deadlines_type_enum CHECK (type IN ('Assignment', 'Exam', 'Quiz', 'Presentation'))
);
-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'system',
  read BOOLEAN DEFAULT FALSE,
  link TEXT,
  related_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT notifications_type_enum CHECK (type IN ('deadline', 'event', 'class', 'system'))
);
-- Create events table
CREATE TABLE IF NOT EXISTS public.events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  event_date DATE NOT NULL,
  event_time TEXT NOT NULL,
  location TEXT NOT NULL,
  building TEXT,
  category TEXT NOT NULL DEFAULT 'Academic',
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT events_category_enum CHECK (category IN ('Career', 'Social', 'Academic', 'Free Food')),
  CONSTRAINT events_time_format CHECK (event_time ~ '^([01]?[0-9]|2[0-3]):[0-5][0-9]$|^(1[0-2]|0?[1-9]):[0-5][0-9] [AP]M$')
);
-- Create user_preferences table
CREATE TABLE IF NOT EXISTS public.user_preferences (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  theme TEXT DEFAULT 'system',
  notifications_enabled BOOLEAN DEFAULT TRUE,
  email_notifications BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT user_preferences_theme_enum CHECK (theme IN ('light', 'dark', 'system'))
);
-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_units_code ON public.units(code);
CREATE INDEX IF NOT EXISTS idx_class_times_unit_id ON public.class_times(unit_id);
CREATE INDEX IF NOT EXISTS idx_deadlines_unit_code ON public.deadlines(unit_code);
CREATE INDEX IF NOT EXISTS idx_deadlines_due_date ON public.deadlines(due_date);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
-- Note: idx_events_date removed - will be replaced with start_at index in later migration

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_times ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deadlines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
-- Create RLS Policies (simplified for initial migration)
-- Use DROP IF EXISTS to make this migration idempotent

-- Profiles: Users can view all, manage own
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
DROP POLICY IF EXISTS "profiles_delete" ON public.profiles;
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "profiles_delete" ON public.profiles FOR DELETE USING (auth.uid() = id);
-- Units: Public read, authenticated write
DROP POLICY IF EXISTS "units_select" ON public.units;
DROP POLICY IF EXISTS "units_insert" ON public.units;
DROP POLICY IF EXISTS "units_update" ON public.units;
DROP POLICY IF EXISTS "units_delete" ON public.units;
CREATE POLICY "units_select" ON public.units FOR SELECT USING (true);
CREATE POLICY "units_insert" ON public.units FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "units_update" ON public.units FOR UPDATE TO authenticated USING (true);
CREATE POLICY "units_delete" ON public.units FOR DELETE TO authenticated USING (true);
-- Class Times: Same as units
DROP POLICY IF EXISTS "class_times_select" ON public.class_times;
DROP POLICY IF EXISTS "class_times_insert" ON public.class_times;
DROP POLICY IF EXISTS "class_times_update" ON public.class_times;
DROP POLICY IF EXISTS "class_times_delete" ON public.class_times;
CREATE POLICY "class_times_select" ON public.class_times FOR SELECT USING (true);
CREATE POLICY "class_times_insert" ON public.class_times FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "class_times_update" ON public.class_times FOR UPDATE TO authenticated USING (true);
CREATE POLICY "class_times_delete" ON public.class_times FOR DELETE TO authenticated USING (true);
-- Deadlines: Public read, authenticated write
DROP POLICY IF EXISTS "deadlines_select" ON public.deadlines;
DROP POLICY IF EXISTS "deadlines_insert" ON public.deadlines;
DROP POLICY IF EXISTS "deadlines_update" ON public.deadlines;
DROP POLICY IF EXISTS "deadlines_delete" ON public.deadlines;
CREATE POLICY "deadlines_select" ON public.deadlines FOR SELECT USING (true);
CREATE POLICY "deadlines_insert" ON public.deadlines FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "deadlines_update" ON public.deadlines FOR UPDATE TO authenticated USING (true);
CREATE POLICY "deadlines_delete" ON public.deadlines FOR DELETE TO authenticated USING (true);
-- Notifications: User-specific
DROP POLICY IF EXISTS "notifications_select" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update" ON public.notifications;
DROP POLICY IF EXISTS "notifications_delete" ON public.notifications;
CREATE POLICY "notifications_select" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notifications_insert" ON public.notifications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "notifications_update" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "notifications_delete" ON public.notifications FOR DELETE USING (auth.uid() = user_id);
-- Events: Public read, authenticated write
DROP POLICY IF EXISTS "events_select" ON public.events;
DROP POLICY IF EXISTS "events_insert" ON public.events;
DROP POLICY IF EXISTS "events_update" ON public.events;
DROP POLICY IF EXISTS "events_delete" ON public.events;
CREATE POLICY "events_select" ON public.events FOR SELECT USING (true);
CREATE POLICY "events_insert" ON public.events FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "events_update" ON public.events FOR UPDATE TO authenticated USING (true);
CREATE POLICY "events_delete" ON public.events FOR DELETE TO authenticated USING (true);
-- User Preferences: User-specific
DROP POLICY IF EXISTS "user_preferences_select" ON public.user_preferences;
DROP POLICY IF EXISTS "user_preferences_insert" ON public.user_preferences;
DROP POLICY IF EXISTS "user_preferences_update" ON public.user_preferences;
DROP POLICY IF EXISTS "user_preferences_delete" ON public.user_preferences;
CREATE POLICY "user_preferences_select" ON public.user_preferences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_preferences_insert" ON public.user_preferences FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_preferences_update" ON public.user_preferences FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "user_preferences_delete" ON public.user_preferences FOR DELETE USING (auth.uid() = user_id);
-- Create update trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';
-- Add update triggers (drop first if they exist to make migration idempotent)
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
DROP TRIGGER IF EXISTS update_units_updated_at ON public.units;
CREATE TRIGGER update_units_updated_at BEFORE UPDATE ON public.units
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
DROP TRIGGER IF EXISTS update_deadlines_updated_at ON public.deadlines;
CREATE TRIGGER update_deadlines_updated_at BEFORE UPDATE ON public.deadlines
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
DROP TRIGGER IF EXISTS update_events_updated_at ON public.events;
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON public.user_preferences;
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
