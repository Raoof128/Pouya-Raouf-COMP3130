-- Migration: Add notification_enabled column to deadlines, events, and todos tables
-- This enables per-item notification preferences that persist in the database

-- ============================================================================
-- ADD notification_enabled TO DEADLINES TABLE
-- ============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'deadlines'
    AND column_name = 'notification_enabled'
  ) THEN
    ALTER TABLE public.deadlines ADD COLUMN notification_enabled BOOLEAN NOT NULL DEFAULT false;
    COMMENT ON COLUMN public.deadlines.notification_enabled IS 'Whether notifications are enabled for this deadline';
  END IF;
END $$;
-- ============================================================================
-- ADD notification_enabled TO EVENTS TABLE
-- ============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'events'
    AND column_name = 'notification_enabled'
  ) THEN
    ALTER TABLE public.events ADD COLUMN notification_enabled BOOLEAN NOT NULL DEFAULT false;
    COMMENT ON COLUMN public.events.notification_enabled IS 'Whether notifications are enabled for this event';
  END IF;
END $$;
-- ============================================================================
-- ADD notification_enabled TO TODOS TABLE
-- ============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'todos'
    AND column_name = 'notification_enabled'
  ) THEN
    ALTER TABLE public.todos ADD COLUMN notification_enabled BOOLEAN NOT NULL DEFAULT false;
    COMMENT ON COLUMN public.todos.notification_enabled IS 'Whether notifications are enabled for this todo';
  END IF;
END $$;
-- ============================================================================
-- ADD notification_enabled TO UNITS TABLE
-- ============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'units'
    AND column_name = 'notification_enabled'
  ) THEN
    ALTER TABLE public.units ADD COLUMN notification_enabled BOOLEAN NOT NULL DEFAULT false;
    COMMENT ON COLUMN public.units.notification_enabled IS 'Whether notifications are enabled for this unit';
  END IF;
END $$;
-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '═══════════════════════════════════════════════════════════════';
    RAISE NOTICE 'MIGRATION COMPLETE: notification_enabled columns added';
    RAISE NOTICE '═══════════════════════════════════════════════════════════════';
END $$;
