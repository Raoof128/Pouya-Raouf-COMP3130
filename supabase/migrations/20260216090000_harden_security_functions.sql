-- ============================================================================
-- SECURITY HARDENING: SECURITY DEFINER FUNCTIONS & EXECUTE PRIVILEGES
-- ============================================================================
-- This migration hardens function-level security by:
-- 1) Enforcing caller ownership checks with null-safe comparisons
-- 2) Restricting SECURITY DEFINER function execute permissions
-- 3) Preventing untrusted table targeting in dynamic SQL
-- 4) Preventing authenticated users from creating global demo events
-- ============================================================================

-- --------------------------------------------------------------------------
-- restore_deleted: enforce caller ownership + table allowlist
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.restore_deleted(
  p_table_name text,
  p_record_id uuid,
  p_user_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_query text;
  v_result boolean;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized: Cannot restore data for another user';
  END IF;

  IF p_table_name NOT IN ('units', 'deadlines', 'events', 'notifications') THEN
    RAISE EXCEPTION 'Invalid table name';
  END IF;

  v_query := format(
    'UPDATE public.%I SET deleted_at = NULL WHERE id = $1 AND user_id = $2 AND deleted_at IS NOT NULL RETURNING true',
    p_table_name
  );

  EXECUTE v_query INTO v_result USING p_record_id, p_user_id;

  RETURN COALESCE(v_result, false);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.restore_deleted(text, uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.restore_deleted(text, uuid, uuid) TO authenticated;
-- --------------------------------------------------------------------------
-- Demo seed helpers: enforce self-only ownership checks
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.seed_demo_units(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized: Cannot seed data for another user';
  END IF;

  INSERT INTO public.units (id, user_id, code, name, color, building, room, created_at)
  VALUES
    (gen_random_uuid(), p_user_id, 'COMP2310', 'Systems Programming', '#3B82F6', 'E6A', '101', NOW()),
    (gen_random_uuid(), p_user_id, 'COMP3120', 'Web Development', '#10B981', 'C5C', '204', NOW()),
    (gen_random_uuid(), p_user_id, 'COMP2100', 'Software Construction', '#8B5CF6', 'E6B', '305', NOW()),
    (gen_random_uuid(), p_user_id, 'STAT2170', 'Statistical Modelling', '#F59E0B', 'W5A', '102', NOW())
  ON CONFLICT (user_id, code) DO NOTHING;
END;
$$;
CREATE OR REPLACE FUNCTION public.seed_demo_deadlines(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_now timestamptz := NOW();
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized: Cannot seed data for another user';
  END IF;

  INSERT INTO public.deadlines (id, user_id, title, unit_code, due_date, priority, type, completed, created_at)
  VALUES
    (gen_random_uuid(), p_user_id, 'Assignment 1: Memory Management', 'COMP2310', v_now + INTERVAL '3 days', 'High', 'Assignment', false, v_now),
    (gen_random_uuid(), p_user_id, 'React Components Quiz', 'COMP3120', v_now + INTERVAL '5 days', 'Medium', 'Quiz', false, v_now),
    (gen_random_uuid(), p_user_id, 'Design Patterns Essay', 'COMP2100', v_now + INTERVAL '7 days', 'Medium', 'Assignment', false, v_now),
    (gen_random_uuid(), p_user_id, 'Midterm Exam', 'STAT2170', v_now + INTERVAL '10 days', 'Urgent', 'Exam', false, v_now),
    (gen_random_uuid(), p_user_id, 'Lab Report 1', 'COMP2310', v_now - INTERVAL '5 days', 'Low', 'Assignment', true, v_now - INTERVAL '10 days'),
    (gen_random_uuid(), p_user_id, 'HTML/CSS Project', 'COMP3120', v_now - INTERVAL '3 days', 'Medium', 'Assignment', true, v_now - INTERVAL '14 days'),
    (gen_random_uuid(), p_user_id, 'Git Tutorial', 'COMP2100', v_now - INTERVAL '1 day', 'Low', 'Assignment', false, v_now - INTERVAL '7 days')
  ON CONFLICT DO NOTHING;
END;
$$;
CREATE OR REPLACE FUNCTION public.seed_demo_class_times(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_unit_id uuid;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized: Cannot seed data for another user';
  END IF;

  FOR v_unit_id IN
    SELECT id FROM public.units WHERE user_id = p_user_id
  LOOP
    INSERT INTO public.class_times (id, unit_id, day, start_time, end_time, created_at)
    SELECT
      gen_random_uuid(),
      v_unit_id,
      day,
      start_time,
      end_time,
      NOW()
    FROM (
      VALUES
        ('Monday', '09:00', '11:00'),
        ('Wednesday', '14:00', '16:00'),
        ('Friday', '10:00', '12:00')
    ) AS t(day, start_time, end_time)
    ON CONFLICT DO NOTHING;
  END LOOP;
END;
$$;
CREATE OR REPLACE FUNCTION public.seed_demo_notifications(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_now timestamptz := NOW();
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized: Cannot seed data for another user';
  END IF;

  INSERT INTO public.notifications (id, user_id, title, message, type, read, created_at)
  VALUES
    (gen_random_uuid(), p_user_id, 'Welcome to Syllabus Sync!', 'Get started by adding your units and deadlines.', 'system', false, v_now),
    (gen_random_uuid(), p_user_id, 'Assignment Due Soon', 'Memory Management assignment is due in 3 days.', 'deadline', false, v_now - INTERVAL '1 hour'),
    (gen_random_uuid(), p_user_id, 'New Event: Career Fair', 'Don''t miss the Career Fair on campus next week!', 'event', true, v_now - INTERVAL '1 day'),
    (gen_random_uuid(), p_user_id, 'Class Reminder', 'COMP2310 class starts in 30 minutes.', 'class', true, v_now - INTERVAL '2 days')
  ON CONFLICT DO NOTHING;
END;
$$;
-- --------------------------------------------------------------------------
-- Public event seeding: service role only
-- --------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.seed_demo_events() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.seed_demo_events() FROM authenticated;
GRANT EXECUTE ON FUNCTION public.seed_demo_events() TO service_role;
-- --------------------------------------------------------------------------
-- Master seed function: self-only and no global/public event insertion
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.seed_demo_data_for_user(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized: Cannot seed data for another user';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
    RAISE EXCEPTION 'User not found: %', p_user_id;
  END IF;

  PERFORM public.seed_demo_units(p_user_id);
  PERFORM public.seed_demo_class_times(p_user_id);
  PERFORM public.seed_demo_deadlines(p_user_id);
  PERFORM public.seed_demo_notifications(p_user_id);

  UPDATE public.gamification_profiles
  SET xp = 150, streak_days = 3, longest_streak = 5, last_activity_date = CURRENT_DATE
  WHERE user_id = p_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'user_id', p_user_id,
    'message', 'Demo data seeded successfully'
  );
END;
$$;
REVOKE EXECUTE ON FUNCTION public.seed_demo_data_for_user(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.seed_demo_data_for_user(uuid) TO authenticated;
-- Keep low-level seed helpers inaccessible to regular users.
REVOKE EXECUTE ON FUNCTION public.seed_demo_units(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.seed_demo_deadlines(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.seed_demo_class_times(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.seed_demo_notifications(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.seed_demo_units(uuid) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.seed_demo_deadlines(uuid) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.seed_demo_class_times(uuid) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.seed_demo_notifications(uuid) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.seed_demo_units(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.seed_demo_deadlines(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.seed_demo_class_times(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.seed_demo_notifications(uuid) TO service_role;
-- --------------------------------------------------------------------------
-- clear_user_data: null-safe ownership validation
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.clear_user_data(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized: Cannot clear data for another user';
  END IF;

  UPDATE public.units SET deleted_at = NOW() WHERE user_id = p_user_id;
  UPDATE public.deadlines SET deleted_at = NOW() WHERE user_id = p_user_id;
  UPDATE public.events SET deleted_at = NOW() WHERE user_id = p_user_id;
  UPDATE public.notifications SET deleted_at = NOW() WHERE user_id = p_user_id;

  UPDATE public.gamification_profiles
  SET xp = 0, streak_days = 0, last_activity_date = NULL
  WHERE user_id = p_user_id;

  DELETE FROM public.xp_events WHERE user_id = p_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'user_id', p_user_id,
    'message', 'User data cleared (soft deleted)'
  );
END;
$$;
REVOKE EXECUTE ON FUNCTION public.clear_user_data(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.clear_user_data(uuid) TO authenticated;
-- --------------------------------------------------------------------------
-- Existing core SECURITY DEFINER functions: null-safe checks + explicit grants
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_user_profile(
  p_user_id uuid,
  p_email text,
  p_full_name text DEFAULT NULL,
  p_student_id text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized: Cannot create profile for another user';
  END IF;

  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = p_user_id) THEN
    v_result := jsonb_build_object(
      'success', true,
      'profile_id', p_user_id,
      'message', 'Profile already exists'
    );
    RETURN v_result;
  END IF;

  INSERT INTO public.profiles (id, email, full_name, student_id)
  VALUES (p_user_id, p_email, p_full_name, p_student_id);

  v_result := jsonb_build_object(
    'success', true,
    'profile_id', p_user_id,
    'message', 'Profile created successfully'
  );

  RETURN v_result;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.create_user_profile(uuid, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_user_profile(uuid, text, text, text) TO authenticated;
CREATE OR REPLACE FUNCTION public.create_unit_with_schedule(
  p_user_id UUID,
  p_code TEXT,
  p_name TEXT,
  p_color TEXT,
  p_building TEXT,
  p_room TEXT,
  p_description TEXT DEFAULT NULL,
  p_schedule JSONB DEFAULT '[]'::JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_unit_id UUID;
  v_schedule_item JSONB;
  v_result JSONB;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized: Cannot create unit for another user';
  END IF;

  v_unit_id := gen_random_uuid();

  INSERT INTO public.units (id, user_id, code, name, color, building, room, description)
  VALUES (v_unit_id, p_user_id, p_code, p_name, p_color, p_building, p_room, p_description);

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
$$;
REVOKE EXECUTE ON FUNCTION public.create_unit_with_schedule(uuid, text, text, text, text, text, text, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_unit_with_schedule(uuid, text, text, text, text, text, text, jsonb) TO authenticated;
