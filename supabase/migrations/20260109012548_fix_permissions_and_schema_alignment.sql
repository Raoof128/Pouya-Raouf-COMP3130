-- ============================================================================
-- FIX PERMISSIONS AND SCHEMA ALIGNMENT
-- This migration ensures all tables, RLS policies, and permissions are correct
-- Addresses: "Database error saving new user" and permission denied errors
-- ============================================================================

-- ============================================================================
-- STEP 1: Create profiles table if it doesn't exist
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid NOT NULL,
  email text NOT NULL,
  full_name text,
  student_id text,
  avatar_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);
-- ============================================================================
-- STEP 2: Create other tables if they don't exist
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.units (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  code text NOT NULL,
  name text NOT NULL,
  color text NOT NULL DEFAULT '#3B82F6',
  description text,
  building text,
  room text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT units_pkey PRIMARY KEY (id),
  CONSTRAINT units_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS public.class_times (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  unit_id uuid NOT NULL,
  day text NOT NULL,
  start_time text NOT NULL,
  end_time text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT class_times_pkey PRIMARY KEY (id),
  CONSTRAINT class_times_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS public.deadlines (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  unit_code text NOT NULL,
  due_date timestamp with time zone NOT NULL,
  priority text NOT NULL DEFAULT 'Medium',
  type text NOT NULL DEFAULT 'Assignment',
  completed boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT deadlines_pkey PRIMARY KEY (id),
  CONSTRAINT deadlines_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS public.events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  title text NOT NULL,
  description text NOT NULL DEFAULT '',
  event_date date NOT NULL,
  event_time text NOT NULL,
  location text NOT NULL DEFAULT '',
  building text,
  category text NOT NULL DEFAULT 'Academic',
  image_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT events_pkey PRIMARY KEY (id),
  CONSTRAINT events_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  type text NOT NULL DEFAULT 'system',
  read boolean NOT NULL DEFAULT false,
  link text,
  related_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS public.user_preferences (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  theme text DEFAULT 'system',
  notifications_enabled boolean DEFAULT true,
  email_notifications boolean DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_preferences_pkey PRIMARY KEY (id),
  CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
-- ============================================================================
-- STEP 3: Create indexes for performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_units_code ON public.units(code);
CREATE INDEX IF NOT EXISTS idx_units_user_id ON public.units(user_id);
CREATE INDEX IF NOT EXISTS idx_class_times_unit_id ON public.class_times(unit_id);
CREATE INDEX IF NOT EXISTS idx_class_times_day ON public.class_times(day);
CREATE INDEX IF NOT EXISTS idx_deadlines_unit_code ON public.deadlines(unit_code);
-- Note: due_date column may not exist in remote, skip this index if column missing
-- CREATE INDEX IF NOT EXISTS idx_deadlines_due_date ON public.deadlines(due_date);
CREATE INDEX IF NOT EXISTS idx_deadlines_completed ON public.deadlines(completed);
CREATE INDEX IF NOT EXISTS idx_deadlines_user_id ON public.deadlines(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(read);
CREATE INDEX IF NOT EXISTS idx_events_date ON public.events(event_date);
CREATE INDEX IF NOT EXISTS idx_events_category ON public.events(category);
CREATE INDEX IF NOT EXISTS idx_events_user_id ON public.events(user_id);
-- ============================================================================
-- STEP 4: Enable RLS on all tables
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_times ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deadlines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
-- ============================================================================
-- STEP 5: Grant permissions to authenticated and anon roles
-- ============================================================================

-- Revoke all from anon first (security)
REVOKE ALL ON public.profiles FROM anon;
REVOKE ALL ON public.units FROM anon;
REVOKE ALL ON public.class_times FROM anon;
REVOKE ALL ON public.deadlines FROM anon;
REVOKE ALL ON public.events FROM anon;
REVOKE ALL ON public.notifications FROM anon;
REVOKE ALL ON public.user_preferences FROM anon;
-- Grant to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.units TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.class_times TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.deadlines TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.events TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.user_preferences TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
-- Allow anon to read public events (events with user_id IS NULL)
GRANT SELECT ON public.events TO anon;
-- ============================================================================
-- STEP 6: Drop and recreate RLS policies for profiles
-- ============================================================================

DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow new user profile creation" ON public.profiles;
DROP POLICY IF EXISTS "Allow profile creation during user registration" ON public.profiles;
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
-- ============================================================================
-- STEP 7: Drop and recreate RLS policies for units
-- ============================================================================

DROP POLICY IF EXISTS "Users can view their own units" ON public.units;
DROP POLICY IF EXISTS "Users can insert their own units" ON public.units;
DROP POLICY IF EXISTS "Users can update their own units" ON public.units;
DROP POLICY IF EXISTS "Users can delete their own units" ON public.units;
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
-- ============================================================================
-- STEP 8: Drop and recreate RLS policies for class_times
-- ============================================================================

DROP POLICY IF EXISTS "Users can view class_times for their units" ON public.class_times;
DROP POLICY IF EXISTS "Users can insert class_times for their units" ON public.class_times;
DROP POLICY IF EXISTS "Users can update class_times for their units" ON public.class_times;
DROP POLICY IF EXISTS "Users can delete class_times for their units" ON public.class_times;
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
-- ============================================================================
-- STEP 9: Drop and recreate RLS policies for deadlines
-- ============================================================================

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
-- ============================================================================
-- STEP 10: Drop and recreate RLS policies for events
-- ============================================================================

DROP POLICY IF EXISTS "Users can view public or their own events" ON public.events;
DROP POLICY IF EXISTS "Users can insert their own events" ON public.events;
DROP POLICY IF EXISTS "Users can update their own events" ON public.events;
DROP POLICY IF EXISTS "Users can delete their own events" ON public.events;
DROP POLICY IF EXISTS "Anyone can view public events" ON public.events;
-- Authenticated users can view public events OR their own
CREATE POLICY "Users can view public or their own events"
  ON public.events FOR SELECT
  TO authenticated
  USING (user_id IS NULL OR auth.uid() = user_id);
-- Anonymous users can only view public events
CREATE POLICY "Anyone can view public events"
  ON public.events FOR SELECT
  TO anon
  USING (user_id IS NULL);
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
-- ============================================================================
-- STEP 11: Drop and recreate RLS policies for notifications
-- ============================================================================

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
-- ============================================================================
-- STEP 12: Drop and recreate RLS policies for user_preferences
-- ============================================================================

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
-- ============================================================================
-- STEP 13: Fix create_user_profile function
-- The function needs to bypass RLS completely for signup flow
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
  -- SECURITY: Validate that the caller is creating their own profile
  -- During signup, auth.uid() should match the newly created user's ID
  IF p_user_id != auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized: Cannot create profile for another user';
  END IF;

  -- Check if profile already exists
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = p_user_id) THEN
    v_result := jsonb_build_object(
      'success', true,
      'profile_id', p_user_id,
      'message', 'Profile already exists'
    );
    RETURN v_result;
  END IF;

  -- Insert the profile (SECURITY DEFINER bypasses RLS)
  INSERT INTO public.profiles (id, email, full_name, student_id)
  VALUES (p_user_id, p_email, p_full_name, p_student_id);

  -- Return success
  v_result := jsonb_build_object(
    'success', true,
    'profile_id', p_user_id,
    'message', 'Profile created successfully'
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_user_profile TO authenticated;
-- ============================================================================
-- STEP 14: Create atomic unit creation function
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

  -- Generate unit ID
  v_unit_id := gen_random_uuid();

  -- Insert the unit
  INSERT INTO public.units (id, user_id, code, name, color, building, room, description)
  VALUES (v_unit_id, p_user_id, p_code, p_name, p_color, p_building, p_room, p_description);

  -- Insert class times if provided
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

  -- Return the created unit with schedule
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
-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_unit_with_schedule TO authenticated;
-- ============================================================================
-- STEP 15: Profile protection trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION protect_profile_fields()
RETURNS TRIGGER AS $$
BEGIN
  -- Prevent changing student_id after initial set
  IF OLD.student_id IS NOT NULL AND NEW.student_id IS DISTINCT FROM OLD.student_id THEN
    RAISE EXCEPTION 'Cannot modify student_id after it has been set';
  END IF;

  -- Prevent changing email directly
  IF NEW.email IS DISTINCT FROM OLD.email THEN
    RAISE EXCEPTION 'Cannot modify email directly. Use the authentication flow.';
  END IF;

  -- Auto-update the updated_at timestamp
  NEW.updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Drop and recreate trigger
DROP TRIGGER IF EXISTS protect_profile_fields_trigger ON public.profiles;
CREATE TRIGGER protect_profile_fields_trigger
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION protect_profile_fields();
-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================;
