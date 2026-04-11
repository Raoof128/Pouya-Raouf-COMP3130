-- ============================================================================
-- MIGRATION: 002_fix_schema_issues
-- CREATED: 2026-01-04
-- DESCRIPTION: Fix schema inconsistencies and constraints
-- ============================================================================

-- ============================================================================
-- FIX 1: Update units code format constraint to allow 3-4 letter codes
-- ============================================================================
-- Drop existing constraint if it exists and recreate with correct pattern
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'units_code_format' AND table_name = 'units'
  ) THEN
    ALTER TABLE public.units DROP CONSTRAINT units_code_format;
  END IF;

  ALTER TABLE public.units ADD CONSTRAINT units_code_format
    CHECK (code ~ '^[A-Z]{3,4}\d{3,4}$');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
-- ============================================================================
-- FIX 2: Fix events table time format constraint to allow both formats
-- ============================================================================
-- Drop existing constraint if it exists and recreate with correct pattern
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'events_time_format' AND table_name = 'events'
  ) THEN
    ALTER TABLE public.events DROP CONSTRAINT events_time_format;
  END IF;

  -- Accept both 24h format (HH:MM) and 12h format (H:MM AM/PM)
  ALTER TABLE public.events ADD CONSTRAINT events_time_format
    CHECK (event_time ~ '^([01]?[0-9]|2[0-3]):[0-5][0-9]$|^(1[0-2]|0?[1-9]):[0-5][0-9] [AP]M$');
EXCEPTION
  WHEN duplicate_object THEN NULL;
  WHEN undefined_column THEN
    -- event_time column might not exist yet, handle in next migration
    NULL;
END $$;
-- ============================================================================
-- FIX 3: Rename events columns if they have old names
-- ============================================================================
DO $$
BEGIN
  -- Rename 'date' to 'event_date' if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'events' AND column_name = 'date' AND table_schema = 'public'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'events' AND column_name = 'event_date' AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.events RENAME COLUMN date TO event_date;
  END IF;

  -- Rename 'time' to 'event_time' if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'events' AND column_name = 'time' AND table_schema = 'public'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'events' AND column_name = 'event_time' AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.events RENAME COLUMN time TO event_time;
  END IF;

  -- Rename 'imageUrl' to 'image_url' if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'events' AND column_name = 'imageUrl' AND table_schema = 'public'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'events' AND column_name = 'image_url' AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.events RENAME COLUMN "imageUrl" TO image_url;
  END IF;
END $$;
-- ============================================================================
-- FIX 4: Remove problematic future date constraint from deadlines (if exists)
-- ============================================================================
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'deadlines_future_date' AND table_name = 'deadlines'
  ) THEN
    ALTER TABLE public.deadlines DROP CONSTRAINT deadlines_future_date;
  END IF;
END $$;
-- ============================================================================
-- FIX 5: Update events index to use correct column name
-- ============================================================================
DROP INDEX IF EXISTS idx_events_date;
-- Only create index if event_date column exists (it may have been replaced by start_at)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'events' AND column_name = 'event_date' AND table_schema = 'public'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_events_date ON public.events(event_date);
  END IF;
END $$;
-- ============================================================================
-- FIX 6: Add missing ON DELETE CASCADE to class_times foreign key
-- ============================================================================
DO $$
BEGIN
  -- Drop existing constraint without CASCADE
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'class_times_unit_id_fkey' AND table_name = 'class_times'
  ) THEN
    ALTER TABLE public.class_times DROP CONSTRAINT class_times_unit_id_fkey;
    ALTER TABLE public.class_times ADD CONSTRAINT class_times_unit_id_fkey
      FOREIGN KEY (unit_id) REFERENCES public.units(id) ON DELETE CASCADE;
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
-- ============================================================================
-- FIX 7: Ensure all tables have proper updated_at triggers
-- ============================================================================

-- Create trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';
-- Add updated_at column to tables if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'deadlines' AND column_name = 'updated_at' AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.deadlines ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
END $$;
-- Create triggers if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_deadlines_updated_at') THEN
    CREATE TRIGGER update_deadlines_updated_at BEFORE UPDATE ON public.deadlines
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;
-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================;
