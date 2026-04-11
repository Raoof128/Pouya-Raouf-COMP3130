-- ============================================================================
-- MIGRATION: Remove sample/public events - all events must be user-owned
-- CREATED: 2026-01-19
-- DESCRIPTION:
--   - Delete all public events (user_id = NULL)
--   - Events should work like units - each user creates their own
--   - No sample data, no public events
-- ============================================================================

-- Delete all public/sample events
DELETE FROM public.events WHERE user_id IS NULL;
-- Make user_id NOT NULL to enforce user ownership (idempotent)
DO $$
BEGIN
    -- Check if column is already NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'events' AND column_name = 'user_id'
        AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE public.events ALTER COLUMN user_id SET NOT NULL;
        RAISE NOTICE '✅ Set user_id to NOT NULL';
    ELSE
        RAISE NOTICE 'ℹ️ user_id is already NOT NULL';
    END IF;
END $$;
-- Update RLS policies to reflect user-only events
DROP POLICY IF EXISTS "Users can view public or their own events" ON public.events;
DROP POLICY IF EXISTS "Users can view their own events" ON public.events;
-- Create simple user-scoped policies (no more public events)
CREATE POLICY "Users can view their own events"
    ON public.events FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);
-- Verify policies exist for other operations
DO $$
BEGIN
    -- Drop and recreate to ensure correct definition
    DROP POLICY IF EXISTS "Users can insert their own events" ON public.events;
    CREATE POLICY "Users can insert their own events"
        ON public.events FOR INSERT
        TO authenticated
        WITH CHECK (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can update their own events" ON public.events;
    CREATE POLICY "Users can update their own events"
        ON public.events FOR UPDATE
        TO authenticated
        USING (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can delete their own events" ON public.events;
    CREATE POLICY "Users can delete their own events"
        ON public.events FOR DELETE
        TO authenticated
        USING (auth.uid() = user_id);
END $$;
-- Log completion
DO $$
BEGIN
    RAISE NOTICE '✅ Removed all public/sample events';
    RAISE NOTICE '✅ Events are now user-scoped only (like units)';
    RAISE NOTICE 'Events count: %', (SELECT COUNT(*) FROM public.events);
END $$;
