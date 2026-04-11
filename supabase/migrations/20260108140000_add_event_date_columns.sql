-- Migration: Add event_date/event_time columns and seed data
-- Purpose: Ensure events table has correct column names and populate with sample data
-- Date: 2026-01-08

-- ============================================================================
-- STEP 1: Add event_date and event_time columns if they don't exist
-- The remote DB might have 'date' and 'time' instead of 'event_date' and 'event_time'
-- ============================================================================

-- Add event_date column (might already exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'events' 
    AND column_name = 'event_date'
  ) THEN
    -- Check if 'date' column exists to copy data from
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'events' 
      AND column_name = 'date'
    ) THEN
      ALTER TABLE public.events ADD COLUMN event_date date;
      UPDATE public.events SET event_date = date::date WHERE event_date IS NULL;
      ALTER TABLE public.events DROP COLUMN date;
    ELSE
      ALTER TABLE public.events ADD COLUMN event_date date NOT NULL DEFAULT CURRENT_DATE;
    END IF;
  END IF;
END $$;
-- Add event_time column (might already exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'events' 
    AND column_name = 'event_time'
  ) THEN
    -- Check if 'time' column exists to copy data from
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'events' 
      AND column_name = 'time'
    ) THEN
      ALTER TABLE public.events ADD COLUMN event_time text;
      UPDATE public.events SET event_time = time WHERE event_time IS NULL;
      ALTER TABLE public.events DROP COLUMN time;
    ELSE
      ALTER TABLE public.events ADD COLUMN event_time text NOT NULL DEFAULT '12:00 PM';
    END IF;
  END IF;
END $$;
-- ============================================================================
-- STEP 2: Create public/shared events (visible to all authenticated users)
-- Skip this legacy seed when the remote schema now requires non-null user_id.
-- ============================================================================

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'events'
      AND column_name = 'user_id'
      AND is_nullable = 'YES'
  ) THEN
    INSERT INTO public.events (id, user_id, title, description, event_date, event_time, location, building, category, created_at)
    VALUES
      -- Career Events
      ('e0000001-0000-0000-0000-000000000001', NULL, 'Career Fair 2026', 
       'Meet top employers and explore career opportunities across various industries. Bring your resume!', 
       CURRENT_DATE + INTERVAL '2 days', '10:00 AM', 'Campus Hub, Main Hall', 'C7A', 'Career', NOW()),
      
      ('e0000001-0000-0000-0000-000000000002', NULL, 'Tech Networking Night', 
       'Connect with industry professionals and learn about tech careers. Light refreshments provided.', 
       CURRENT_DATE + INTERVAL '5 days', '6:00 PM', 'Engineering Building, Room E101', 'E7A', 'Career', NOW()),
      
      ('e0000001-0000-0000-0000-000000000003', NULL, 'Resume Writing Workshop', 
       'Get expert tips on crafting the perfect resume for your dream job. Limited spots available!', 
       CURRENT_DATE + INTERVAL '7 days', '1:00 PM', 'Careers Centre', 'W3A', 'Career', NOW()),
      
      ('e0000001-0000-0000-0000-000000000004', NULL, 'Alumni Panel: Careers in Data & Policy', 
       'Hear from alumni working in analytics, public policy, and consulting. Q&A plus networking.', 
       CURRENT_DATE + INTERVAL '10 days', '5:30 PM', 'Library Seminar Room', 'C3C', 'Career', NOW()),

      -- Free Food Events
      ('e0000002-0000-0000-0000-000000000001', NULL, 'Free Pizza Friday', 
       'Join us for free pizza and networking with fellow students! First come, first served.', 
       CURRENT_DATE, '12:00 PM', 'Library Courtyard', 'C3C', 'Free Food', NOW()),
      
      ('e0000002-0000-0000-0000-000000000002', NULL, 'International Food Festival', 
       'Celebrate diversity with food from around the world. Free samples from 20+ countries!', 
       CURRENT_DATE + INTERVAL '3 days', '11:00 AM', 'Campus Hub Courtyard', 'C7A', 'Free Food', NOW()),
      
      ('e0000002-0000-0000-0000-000000000003', NULL, 'Free Coffee Morning', 
       'Start your day right with free coffee and pastries! Sponsored by Student Union.', 
       CURRENT_DATE + INTERVAL '1 day', '8:00 AM', 'Library Cafe', 'C3C', 'Free Food', NOW()),
      
      ('e0000002-0000-0000-0000-000000000004', NULL, 'BBQ Welcome Week', 
       'Free BBQ lunch for all students! Meet new friends and enjoy great food.', 
       CURRENT_DATE + INTERVAL '8 days', '12:00 PM', 'Campus Green', 'C7A', 'Free Food', NOW()),

      -- Academic Events  
      ('e0000003-0000-0000-0000-000000000001', NULL, 'Study Skills Workshop', 
       'Learn effective study techniques and time management strategies for exam success.', 
       CURRENT_DATE + INTERVAL '1 day', '2:00 PM', 'Library Room 204', 'C3C', 'Academic', NOW()),
      
      ('e0000003-0000-0000-0000-000000000002', NULL, 'Research Seminar: AI in Healthcare', 
       'Explore cutting-edge research on artificial intelligence applications in medicine.', 
       CURRENT_DATE + INTERVAL '4 days', '3:00 PM', 'Wallumattagal Building, Lecture Hall', 'W6A', 'Academic', NOW()),
      
      ('e0000003-0000-0000-0000-000000000003', NULL, 'Academic Writing Workshop', 
       'Improve your essay writing skills with tips from experienced tutors.', 
       CURRENT_DATE + INTERVAL '6 days', '10:00 AM', 'Library Training Room', 'C3C', 'Academic', NOW()),
      
      ('e0000003-0000-0000-0000-000000000004', NULL, 'Honours Info Session', 
       'Learn about Honours programs across faculties. Meet coordinators and current students.', 
       CURRENT_DATE + INTERVAL '12 days', '4:00 PM', 'Arts Precinct, Room 120', 'W6A', 'Academic', NOW()),

      -- Social Events
      ('e0000004-0000-0000-0000-000000000001', NULL, 'Student Club Welcome Day', 
       'Discover clubs and societies on campus. Over 100 clubs to choose from!', 
       CURRENT_DATE, '10:00 AM', 'Campus Hub', 'C7A', 'Social', NOW()),
      
      ('e0000004-0000-0000-0000-000000000002', NULL, 'Movie Night: Sci-Fi Marathon', 
       'Join us for a night of classic science fiction films with free popcorn!', 
       CURRENT_DATE + INTERVAL '6 days', '7:00 PM', 'Campus Hub Theatre', 'C7A', 'Social', NOW()),
      
      ('e0000004-0000-0000-0000-000000000003', NULL, 'Trivia Night', 
       'Test your knowledge and win prizes! Teams of up to 6 people. Free entry.', 
       CURRENT_DATE + INTERVAL '9 days', '6:30 PM', 'Ubar', 'C7A', 'Social', NOW()),
      
      ('e0000004-0000-0000-0000-000000000004', NULL, 'Board Games Social', 
       'Relax and make friends over board games. All skill levels welcome!', 
       CURRENT_DATE + INTERVAL '4 days', '4:00 PM', 'Student Lounge', 'C7A', 'Social', NOW())

    ON CONFLICT (id) DO UPDATE SET
      title = EXCLUDED.title,
      description = EXCLUDED.description,
      event_date = EXCLUDED.event_date,
      event_time = EXCLUDED.event_time,
      location = EXCLUDED.location,
      building = EXCLUDED.building,
      category = EXCLUDED.category;
  END IF;
END $$;
-- ============================================================================
-- STEP 3: Create function to seed user-specific data on signup
-- ============================================================================

CREATE OR REPLACE FUNCTION public.seed_new_user_data()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert sample units for the new user
  INSERT INTO public.units (id, user_id, code, name, color, location, created_at)
  VALUES
    (gen_random_uuid(), NEW.id, 'COMP2310', 'Networking', '#A6192E', 
     '{"building": "C5C", "room": "204"}'::jsonb, NOW()),
    (gen_random_uuid(), NEW.id, 'MATH1001', 'Foundations of Mathematics', '#002A45', 
     '{"building": "C3C", "room": "112"}'::jsonb, NOW()),
    (gen_random_uuid(), NEW.id, 'HIST2002', 'Modern Europe: 1789-1914', '#FFB81C', 
     '{"building": "W6A", "room": "301"}'::jsonb, NOW()),
    (gen_random_uuid(), NEW.id, 'COMP1010', 'Introduction to Programming', '#10B981', 
     '{"building": "E7A", "room": "105"}'::jsonb, NOW());

  -- Insert sample deadlines for the new user
  INSERT INTO public.deadlines (id, user_id, title, unit_code, due_date, priority, type, completed, created_at)
  VALUES
    (gen_random_uuid(), NEW.id, 'Assignment 1: Network Fundamentals', 'COMP2310', 
     NOW() + INTERVAL '3 days', 'High', 'Assignment', false, NOW()),
    (gen_random_uuid(), NEW.id, 'Quiz 1: Linear Algebra Basics', 'MATH1001', 
     NOW() + INTERVAL '7 days', 'Medium', 'Quiz', false, NOW()),
    (gen_random_uuid(), NEW.id, 'Essay: Revolution & Reform', 'HIST2002', 
     NOW() + INTERVAL '14 days', 'Medium', 'Assignment', false, NOW()),
    (gen_random_uuid(), NEW.id, 'Lab Report 1', 'COMP1010', 
     NOW() + INTERVAL '5 days', 'High', 'Assignment', false, NOW()),
    (gen_random_uuid(), NEW.id, 'Midterm Exam', 'MATH1001', 
     NOW() + INTERVAL '21 days', 'Urgent', 'Exam', false, NOW()),
    (gen_random_uuid(), NEW.id, 'Group Presentation', 'COMP2310', 
     NOW() + INTERVAL '10 days', 'Medium', 'Presentation', false, NOW());

  -- Insert welcome notifications for the new user
  INSERT INTO public.notifications (id, user_id, title, message, type, read, link, created_at)
  VALUES
    (gen_random_uuid(), NEW.id, 'Welcome to Syllabus Sync!', 
     'Get started by exploring your units and deadlines. We have added some samples to help you get started!', 
     'system', false, '/home', NOW()),
    (gen_random_uuid(), NEW.id, 'Check Out the Campus Map', 
     'Navigate campus easily with our interactive map. Find buildings, food, and more!', 
     'system', false, '/map', NOW()),
    (gen_random_uuid(), NEW.id, 'Upcoming Deadline', 
     'You have an assignment due in 3 days. Check your calendar to stay on track!', 
     'deadline', false, '/calendar', NOW()),
    (gen_random_uuid(), NEW.id, 'Career Fair This Week!', 
     'Do not miss the Career Fair 2026 at Campus Hub. Great opportunity to meet employers!', 
     'event', false, '/feed', NOW());

  -- Create user preferences with defaults
  INSERT INTO public.user_preferences (id, user_id, theme, notifications_enabled, email_notifications, created_at)
  VALUES (gen_random_uuid(), NEW.id, 'system', true, false, NOW())
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- ============================================================================
-- STEP 4: Create trigger to run seed function on new user signup
-- ============================================================================

DROP TRIGGER IF EXISTS on_auth_user_created_seed_data ON auth.users;
CREATE TRIGGER on_auth_user_created_seed_data
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.seed_new_user_data();
-- ============================================================================
-- STEP 5: Create function to add class times
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_sample_class_times(p_user_id uuid)
RETURNS void AS $$
DECLARE
  v_unit_id uuid;
BEGIN
  -- Get COMP2310 unit for this user and add class times
  SELECT id INTO v_unit_id FROM public.units WHERE user_id = p_user_id AND code = 'COMP2310' LIMIT 1;
  IF v_unit_id IS NOT NULL THEN
    INSERT INTO public.class_times (id, unit_id, day, start_time, end_time, created_at)
    VALUES 
      (gen_random_uuid(), v_unit_id, 'Monday', '09:00', '11:00', NOW()),
      (gen_random_uuid(), v_unit_id, 'Wednesday', '14:00', '15:00', NOW())
    ON CONFLICT DO NOTHING;
  END IF;

  -- Get MATH1001 unit
  SELECT id INTO v_unit_id FROM public.units WHERE user_id = p_user_id AND code = 'MATH1001' LIMIT 1;
  IF v_unit_id IS NOT NULL THEN
    INSERT INTO public.class_times (id, unit_id, day, start_time, end_time, created_at)
    VALUES 
      (gen_random_uuid(), v_unit_id, 'Tuesday', '10:00', '12:00', NOW()),
      (gen_random_uuid(), v_unit_id, 'Thursday', '13:00', '14:30', NOW())
    ON CONFLICT DO NOTHING;
  END IF;

  -- Get HIST2002 unit
  SELECT id INTO v_unit_id FROM public.units WHERE user_id = p_user_id AND code = 'HIST2002' LIMIT 1;
  IF v_unit_id IS NOT NULL THEN
    INSERT INTO public.class_times (id, unit_id, day, start_time, end_time, created_at)
    VALUES 
      (gen_random_uuid(), v_unit_id, 'Friday', '16:00', '18:00', NOW())
    ON CONFLICT DO NOTHING;
  END IF;

  -- Get COMP1010 unit
  SELECT id INTO v_unit_id FROM public.units WHERE user_id = p_user_id AND code = 'COMP1010' LIMIT 1;
  IF v_unit_id IS NOT NULL THEN
    INSERT INTO public.class_times (id, unit_id, day, start_time, end_time, created_at)
    VALUES 
      (gen_random_uuid(), v_unit_id, 'Monday', '14:00', '16:00', NOW()),
      (gen_random_uuid(), v_unit_id, 'Thursday', '09:00', '11:00', NOW())
    ON CONFLICT DO NOTHING;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- ============================================================================
-- STEP 6: Create profile for new users automatically
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
DROP TRIGGER IF EXISTS on_auth_user_created_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_profile
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user_profile();
-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================;
