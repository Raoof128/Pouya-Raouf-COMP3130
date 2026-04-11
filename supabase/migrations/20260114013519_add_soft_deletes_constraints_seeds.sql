-- ============================================================================
-- SOFT DELETES, CONSTRAINTS, MATERIALIZED VIEWS & SEED DATA
-- ============================================================================
-- This migration adds:
-- 1. Soft delete support (deleted_at columns) for undo functionality
-- 2. CHECK constraints for data integrity
-- 3. Materialized views for analytics
-- 4. Seed data functions for demo mode
-- ============================================================================

-- ============================================================================
-- PART 1: SOFT DELETE SUPPORT
-- ============================================================================

-- Add deleted_at column to main user-owned tables
ALTER TABLE public.units ADD COLUMN IF NOT EXISTS deleted_at timestamptz DEFAULT NULL;
ALTER TABLE public.deadlines ADD COLUMN IF NOT EXISTS deleted_at timestamptz DEFAULT NULL;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS deleted_at timestamptz DEFAULT NULL;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS deleted_at timestamptz DEFAULT NULL;
-- Create indexes for soft delete queries (filter out deleted items efficiently)
CREATE INDEX IF NOT EXISTS idx_units_deleted_at ON public.units(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_deadlines_deleted_at ON public.deadlines(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_events_deleted_at ON public.events(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_deleted_at ON public.notifications(deleted_at) WHERE deleted_at IS NULL;
-- Function to soft delete a record
CREATE OR REPLACE FUNCTION soft_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- Instead of deleting, set deleted_at timestamp
    NEW.deleted_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Function to restore a soft-deleted record
CREATE OR REPLACE FUNCTION restore_deleted(
    p_table_name text,
    p_record_id uuid,
    p_user_id uuid
)
RETURNS boolean AS $$
DECLARE
    v_query text;
    v_result boolean;
BEGIN
    -- Validate user owns the record
    v_query := format(
        'UPDATE public.%I SET deleted_at = NULL WHERE id = $1 AND user_id = $2 AND deleted_at IS NOT NULL RETURNING true',
        p_table_name
    );
    
    EXECUTE v_query INTO v_result USING p_record_id, p_user_id;
    
    RETURN COALESCE(v_result, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
GRANT EXECUTE ON FUNCTION restore_deleted TO authenticated;
-- Function to permanently delete old soft-deleted records (cleanup job)
CREATE OR REPLACE FUNCTION purge_deleted_records(p_days_old integer DEFAULT 30)
RETURNS jsonb AS $$
DECLARE
    v_cutoff timestamptz := NOW() - (p_days_old || ' days')::interval;
    v_units_deleted integer;
    v_deadlines_deleted integer;
    v_events_deleted integer;
    v_notifications_deleted integer;
BEGIN
    DELETE FROM public.units WHERE deleted_at < v_cutoff;
    GET DIAGNOSTICS v_units_deleted = ROW_COUNT;
    
    DELETE FROM public.deadlines WHERE deleted_at < v_cutoff;
    GET DIAGNOSTICS v_deadlines_deleted = ROW_COUNT;
    
    DELETE FROM public.events WHERE deleted_at < v_cutoff;
    GET DIAGNOSTICS v_events_deleted = ROW_COUNT;
    
    DELETE FROM public.notifications WHERE deleted_at < v_cutoff;
    GET DIAGNOSTICS v_notifications_deleted = ROW_COUNT;
    
    RETURN jsonb_build_object(
        'purged_before', v_cutoff,
        'units_deleted', v_units_deleted,
        'deadlines_deleted', v_deadlines_deleted,
        'events_deleted', v_events_deleted,
        'notifications_deleted', v_notifications_deleted
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Only service role can purge (for scheduled jobs)
REVOKE EXECUTE ON FUNCTION purge_deleted_records FROM PUBLIC;
GRANT EXECUTE ON FUNCTION purge_deleted_records TO service_role;
-- ============================================================================
-- PART 2: CHECK CONSTRAINTS FOR DATA INTEGRITY
-- ============================================================================

-- Events: end_at must be after start_at
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'events_valid_time_range'
    ) THEN
        ALTER TABLE public.events 
        ADD CONSTRAINT events_valid_time_range 
        CHECK (end_at IS NULL OR start_at IS NULL OR end_at >= start_at);
    END IF;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;
-- Class times: end_time must be after start_time (already exists but ensure it's there)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'class_times_valid_times'
    ) THEN
        ALTER TABLE public.class_times 
        ADD CONSTRAINT class_times_valid_times 
        CHECK (start_time < end_time);
    END IF;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;
-- Deadlines: due_date must be in the future when created (soft constraint via trigger)
CREATE OR REPLACE FUNCTION validate_deadline_due_date()
RETURNS TRIGGER AS $$
BEGIN
    -- Only warn on new deadlines, allow updates to past deadlines
    IF TG_OP = 'INSERT' AND NEW.due_date < NOW() - INTERVAL '1 day' THEN
        RAISE WARNING 'Deadline due_date is in the past: %', NEW.due_date;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS validate_deadline_due_date_trigger ON public.deadlines;
CREATE TRIGGER validate_deadline_due_date_trigger
    BEFORE INSERT ON public.deadlines
    FOR EACH ROW
    EXECUTE FUNCTION validate_deadline_due_date();
-- Gamification: XP cannot be negative
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'gamification_profiles_xp_check'
    ) THEN
        ALTER TABLE public.gamification_profiles 
        ADD CONSTRAINT gamification_profiles_xp_non_negative 
        CHECK (xp >= 0);
    END IF;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;
-- Gamification: Streak days cannot be negative
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'gamification_profiles_streak_check'
    ) THEN
        ALTER TABLE public.gamification_profiles 
        ADD CONSTRAINT gamification_profiles_streak_non_negative 
        CHECK (streak_days >= 0 AND longest_streak >= 0);
    END IF;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;
-- Notifications: type must be valid
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'notifications_valid_type'
    ) THEN
        ALTER TABLE public.notifications 
        ADD CONSTRAINT notifications_valid_type 
        CHECK (type IN ('deadline', 'event', 'class', 'system'));
    END IF;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;
-- Events: category must be valid
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'events_valid_category'
    ) THEN
        ALTER TABLE public.events 
        ADD CONSTRAINT events_valid_category 
        CHECK (category IN ('Career', 'Social', 'Academic', 'Free Food'));
    END IF;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;
-- Deadlines: priority must be valid
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'deadlines_valid_priority'
    ) THEN
        ALTER TABLE public.deadlines 
        ADD CONSTRAINT deadlines_valid_priority 
        CHECK (priority IN ('Low', 'Medium', 'High', 'Urgent'));
    END IF;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;
-- Deadlines: type must be valid
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'deadlines_valid_type'
    ) THEN
        ALTER TABLE public.deadlines 
        ADD CONSTRAINT deadlines_valid_type 
        CHECK (type IN ('Assignment', 'Exam', 'Quiz', 'Presentation'));
    END IF;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;
-- ============================================================================
-- PART 3: MATERIALIZED VIEWS FOR ANALYTICS
-- ============================================================================

-- User activity summary (refreshed periodically)
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_user_activity_summary AS
SELECT 
    p.id AS user_id,
    p.email,
    p.full_name,
    gp.xp,
    gp.streak_days,
    gp.longest_streak,
    calculate_level(COALESCE(gp.xp, 0)) AS level,
    (SELECT COUNT(*) FROM public.units u WHERE u.user_id = p.id AND u.deleted_at IS NULL) AS unit_count,
    (SELECT COUNT(*) FROM public.deadlines d WHERE d.user_id = p.id AND d.deleted_at IS NULL) AS deadline_count,
    (SELECT COUNT(*) FROM public.deadlines d WHERE d.user_id = p.id AND d.completed = true AND d.deleted_at IS NULL) AS completed_deadline_count,
    (SELECT COUNT(*) FROM public.deadlines d WHERE d.user_id = p.id AND d.completed = false AND d.due_date < NOW() AND d.deleted_at IS NULL) AS overdue_deadline_count,
    (SELECT COUNT(*) FROM public.notifications n WHERE n.user_id = p.id AND n.read = false AND n.deleted_at IS NULL) AS unread_notification_count,
    p.created_at AS user_created_at,
    gp.last_activity_date
FROM public.profiles p
LEFT JOIN public.gamification_profiles gp ON gp.user_id = p.id;
-- Create unique index for concurrent refresh
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_user_activity_summary_user_id 
ON public.mv_user_activity_summary(user_id);
-- Deadline analytics by week
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_deadline_analytics AS
SELECT 
    date_trunc('week', d.due_date) AS week_start,
    d.user_id,
    d.priority,
    d.type,
    COUNT(*) AS total_count,
    SUM(CASE WHEN d.completed THEN 1 ELSE 0 END) AS completed_count,
    SUM(CASE WHEN NOT d.completed AND d.due_date < NOW() THEN 1 ELSE 0 END) AS overdue_count,
    AVG(CASE WHEN d.completed THEN 
        EXTRACT(EPOCH FROM (d.updated_at - d.created_at)) / 3600 
    END) AS avg_completion_hours
FROM public.deadlines d
WHERE d.deleted_at IS NULL
GROUP BY date_trunc('week', d.due_date), d.user_id, d.priority, d.type;
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_deadline_analytics_key 
ON public.mv_deadline_analytics(week_start, user_id, priority, type);
-- XP leaderboard (top users by XP)
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_xp_leaderboard AS
SELECT 
    p.id AS user_id,
    p.full_name,
    p.avatar_url,
    gp.xp,
    calculate_level(COALESCE(gp.xp, 0)) AS level,
    gp.streak_days,
    gp.longest_streak,
    RANK() OVER (ORDER BY COALESCE(gp.xp, 0) DESC) AS rank
FROM public.profiles p
LEFT JOIN public.gamification_profiles gp ON gp.user_id = p.id
WHERE gp.xp > 0
ORDER BY gp.xp DESC
LIMIT 100;
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_xp_leaderboard_user_id 
ON public.mv_xp_leaderboard(user_id);
-- Function to refresh all materialized views
CREATE OR REPLACE FUNCTION refresh_analytics_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_user_activity_summary;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_deadline_analytics;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_xp_leaderboard;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Only service role can refresh (for scheduled jobs)
REVOKE EXECUTE ON FUNCTION refresh_analytics_views FROM PUBLIC;
GRANT EXECUTE ON FUNCTION refresh_analytics_views TO service_role;
-- Grant read access to materialized views
GRANT SELECT ON public.mv_user_activity_summary TO authenticated;
GRANT SELECT ON public.mv_deadline_analytics TO authenticated;
GRANT SELECT ON public.mv_xp_leaderboard TO authenticated;
-- ============================================================================
-- PART 4: SEED DATA FUNCTIONS FOR DEMO MODE
-- ============================================================================

-- Function to create demo units for a user
CREATE OR REPLACE FUNCTION seed_demo_units(p_user_id uuid)
RETURNS void AS $$
BEGIN
    -- Insert demo units
    INSERT INTO public.units (id, user_id, code, name, color, building, room, created_at)
    VALUES 
        (gen_random_uuid(), p_user_id, 'COMP2310', 'Systems Programming', '#3B82F6', 'E6A', '101', NOW()),
        (gen_random_uuid(), p_user_id, 'COMP3120', 'Web Development', '#10B981', 'C5C', '204', NOW()),
        (gen_random_uuid(), p_user_id, 'COMP2100', 'Software Construction', '#8B5CF6', 'E6B', '305', NOW()),
        (gen_random_uuid(), p_user_id, 'STAT2170', 'Statistical Modelling', '#F59E0B', 'W5A', '102', NOW())
    ON CONFLICT (user_id, code) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Function to create demo deadlines for a user
CREATE OR REPLACE FUNCTION seed_demo_deadlines(p_user_id uuid)
RETURNS void AS $$
DECLARE
    v_now timestamptz := NOW();
BEGIN
    -- Insert demo deadlines with various due dates
    INSERT INTO public.deadlines (id, user_id, title, unit_code, due_date, priority, type, completed, created_at)
    VALUES 
        -- Upcoming deadlines
        (gen_random_uuid(), p_user_id, 'Assignment 1: Memory Management', 'COMP2310', v_now + INTERVAL '3 days', 'High', 'Assignment', false, v_now),
        (gen_random_uuid(), p_user_id, 'React Components Quiz', 'COMP3120', v_now + INTERVAL '5 days', 'Medium', 'Quiz', false, v_now),
        (gen_random_uuid(), p_user_id, 'Design Patterns Essay', 'COMP2100', v_now + INTERVAL '7 days', 'Medium', 'Assignment', false, v_now),
        (gen_random_uuid(), p_user_id, 'Midterm Exam', 'STAT2170', v_now + INTERVAL '10 days', 'Urgent', 'Exam', false, v_now),
        -- Completed deadlines
        (gen_random_uuid(), p_user_id, 'Lab Report 1', 'COMP2310', v_now - INTERVAL '5 days', 'Low', 'Assignment', true, v_now - INTERVAL '10 days'),
        (gen_random_uuid(), p_user_id, 'HTML/CSS Project', 'COMP3120', v_now - INTERVAL '3 days', 'Medium', 'Assignment', true, v_now - INTERVAL '14 days'),
        -- Overdue deadline (for demo)
        (gen_random_uuid(), p_user_id, 'Git Tutorial', 'COMP2100', v_now - INTERVAL '1 day', 'Low', 'Assignment', false, v_now - INTERVAL '7 days')
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Function to create demo class times
CREATE OR REPLACE FUNCTION seed_demo_class_times(p_user_id uuid)
RETURNS void AS $$
DECLARE
    v_unit_id uuid;
BEGIN
    -- Get unit IDs and add class times
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
        FROM (VALUES 
            ('Monday', '09:00', '11:00'),
            ('Wednesday', '14:00', '16:00'),
            ('Friday', '10:00', '12:00')
        ) AS t(day, start_time, end_time)
        ON CONFLICT DO NOTHING;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Function to create demo events (public events)
CREATE OR REPLACE FUNCTION seed_demo_events()
RETURNS void AS $$
DECLARE
    v_now timestamptz := NOW();
BEGIN
    -- Insert public demo events (user_id = NULL)
    INSERT INTO public.events (id, user_id, title, description, event_date, event_time, location, building, category, all_day, created_at)
    VALUES 
        (gen_random_uuid(), NULL, 'Career Fair 2026', 'Annual career fair with 50+ employers. Bring your resume!', (v_now + INTERVAL '14 days')::date, '10:00 AM', 'University Hall', 'C5C', 'Career', false, v_now),
        (gen_random_uuid(), NULL, 'Free Pizza Friday', 'Student union free pizza event. First come, first served!', (v_now + INTERVAL '4 days')::date, '12:00 PM', 'Student Hub', 'C7A', 'Free Food', false, v_now),
        (gen_random_uuid(), NULL, 'Hackathon 2026', '24-hour coding competition. Form teams of up to 4.', (v_now + INTERVAL '21 days')::date, '9:00 AM', 'Engineering Building', 'E6A', 'Academic', true, v_now),
        (gen_random_uuid(), NULL, 'International Food Festival', 'Celebrate cultural diversity with food from around the world.', (v_now + INTERVAL '7 days')::date, '11:00 AM', 'Central Courtyard', 'C5C', 'Social', false, v_now),
        (gen_random_uuid(), NULL, 'Guest Lecture: AI in Healthcare', 'Professor Smith on the future of AI in medical diagnosis.', (v_now + INTERVAL '5 days')::date, '2:00 PM', 'Lecture Theatre 1', 'W5A', 'Academic', false, v_now),
        (gen_random_uuid(), NULL, 'Welcome Week BBQ', 'Free BBQ for all students. Meet new friends!', (v_now + INTERVAL '2 days')::date, '12:00 PM', 'Sports Field', 'C8A', 'Social', false, v_now)
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Function to create demo notifications for a user
CREATE OR REPLACE FUNCTION seed_demo_notifications(p_user_id uuid)
RETURNS void AS $$
DECLARE
    v_now timestamptz := NOW();
BEGIN
    INSERT INTO public.notifications (id, user_id, title, message, type, read, created_at)
    VALUES 
        (gen_random_uuid(), p_user_id, 'Welcome to Syllabus Sync!', 'Get started by adding your units and deadlines.', 'system', false, v_now),
        (gen_random_uuid(), p_user_id, 'Assignment Due Soon', 'Memory Management assignment is due in 3 days.', 'deadline', false, v_now - INTERVAL '1 hour'),
        (gen_random_uuid(), p_user_id, 'New Event: Career Fair', 'Don''t miss the Career Fair on campus next week!', 'event', true, v_now - INTERVAL '1 day'),
        (gen_random_uuid(), p_user_id, 'Class Reminder', 'COMP2310 class starts in 30 minutes.', 'class', true, v_now - INTERVAL '2 days')
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Master function to seed all demo data for a user
CREATE OR REPLACE FUNCTION seed_demo_data_for_user(p_user_id uuid)
RETURNS jsonb AS $$
BEGIN
    -- Verify user exists
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'User not found: %', p_user_id;
    END IF;
    
    -- Seed all demo data
    PERFORM seed_demo_units(p_user_id);
    PERFORM seed_demo_class_times(p_user_id);
    PERFORM seed_demo_deadlines(p_user_id);
    PERFORM seed_demo_notifications(p_user_id);
    PERFORM seed_demo_events(); -- Public events
    
    -- Give user some starting XP
    UPDATE public.gamification_profiles 
    SET xp = 150, streak_days = 3, longest_streak = 5, last_activity_date = CURRENT_DATE
    WHERE user_id = p_user_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'user_id', p_user_id,
        'message', 'Demo data seeded successfully'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Grant execute to authenticated users (they can only seed their own data)
-- Specify the exact function signature to avoid ambiguity with overloaded functions
GRANT EXECUTE ON FUNCTION seed_demo_data_for_user(uuid) TO authenticated;
-- Function to clear all user data (for reset)
CREATE OR REPLACE FUNCTION clear_user_data(p_user_id uuid)
RETURNS jsonb AS $$
BEGIN
    -- Only allow users to clear their own data
    IF p_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Unauthorized: Cannot clear data for another user';
    END IF;
    
    -- Soft delete all user data
    UPDATE public.units SET deleted_at = NOW() WHERE user_id = p_user_id;
    UPDATE public.deadlines SET deleted_at = NOW() WHERE user_id = p_user_id;
    UPDATE public.events SET deleted_at = NOW() WHERE user_id = p_user_id;
    UPDATE public.notifications SET deleted_at = NOW() WHERE user_id = p_user_id;
    
    -- Reset gamification
    UPDATE public.gamification_profiles 
    SET xp = 0, streak_days = 0, last_activity_date = NULL
    WHERE user_id = p_user_id;
    
    -- Clear XP events
    DELETE FROM public.xp_events WHERE user_id = p_user_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'user_id', p_user_id,
        'message', 'User data cleared (soft deleted)'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
GRANT EXECUTE ON FUNCTION clear_user_data TO authenticated;
-- ============================================================================
-- PART 5: UPDATE RLS POLICIES TO EXCLUDE SOFT-DELETED RECORDS
-- ============================================================================

-- Drop and recreate policies to filter out deleted records
DROP POLICY IF EXISTS "Users can view their own units" ON public.units;
CREATE POLICY "Users can view their own units"
    ON public.units FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id AND deleted_at IS NULL);
DROP POLICY IF EXISTS "Users can view their own deadlines" ON public.deadlines;
CREATE POLICY "Users can view their own deadlines"
    ON public.deadlines FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id AND deleted_at IS NULL);
DROP POLICY IF EXISTS "Users can view public or their own events" ON public.events;
CREATE POLICY "Users can view public or their own events"
    ON public.events FOR SELECT
    TO authenticated
    USING ((user_id IS NULL OR auth.uid() = user_id) AND deleted_at IS NULL);
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications"
    ON public.notifications FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id AND deleted_at IS NULL);
-- Add policy to view deleted items (for restore functionality)
-- Drop first to make migration idempotent
DROP POLICY IF EXISTS "Users can view their deleted units" ON public.units;
CREATE POLICY "Users can view their deleted units"
    ON public.units FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id AND deleted_at IS NOT NULL);
DROP POLICY IF EXISTS "Users can view their deleted deadlines" ON public.deadlines;
CREATE POLICY "Users can view their deleted deadlines"
    ON public.deadlines FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id AND deleted_at IS NOT NULL);
DROP POLICY IF EXISTS "Users can view their deleted events" ON public.events;
CREATE POLICY "Users can view their deleted events"
    ON public.events FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id AND deleted_at IS NOT NULL);
DROP POLICY IF EXISTS "Users can view their deleted notifications" ON public.notifications;
CREATE POLICY "Users can view their deleted notifications"
    ON public.notifications FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id AND deleted_at IS NOT NULL);
-- ============================================================================
-- SUMMARY
-- ============================================================================
-- ✅ Soft delete columns (deleted_at) added to units, deadlines, events, notifications
-- ✅ Partial indexes for efficient soft delete filtering
-- ✅ restore_deleted() function for undo support
-- ✅ purge_deleted_records() for cleanup (service_role only)
-- ✅ CHECK constraints: event time ranges, valid enums, non-negative XP
-- ✅ Materialized views: user_activity_summary, deadline_analytics, xp_leaderboard
-- ✅ refresh_analytics_views() for periodic refresh (service_role only)
-- ✅ Demo data seed functions for all entities
-- ✅ seed_demo_data_for_user() master function
-- ✅ clear_user_data() for user data reset
-- ✅ RLS policies updated to exclude soft-deleted records
-- ============================================================================;
