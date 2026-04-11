-- ============================================================================
-- ADD TIMESTAMP FIELDS TO EVENTS TABLE
-- ============================================================================
-- This migration adds modern timestamp fields to the events table.
-- The legacy event_date and event_time fields may or may not exist depending
-- on when the database was created.
--
-- Changes:
-- 1. Add start_at, end_at, all_day columns to events table (if not exists)
-- 2. Set default values for any NULL start_at records
-- 3. Add indexes for performance
-- ============================================================================

-- Add new timestamp columns (if they don't exist)
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS start_at TIMESTAMPTZ;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS end_at TIMESTAMPTZ;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS all_day BOOLEAN DEFAULT FALSE;
-- Set default values for any events with NULL start_at
-- This handles both fresh databases and migrated databases
UPDATE public.events
SET
  start_at = COALESCE(start_at, created_at, NOW()),
  all_day = COALESCE(all_day, FALSE)
WHERE start_at IS NULL;
-- Make start_at NOT NULL after populating data
-- (skip if already NOT NULL)
DO $$
BEGIN
  -- Only alter if the column is currently nullable
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'events'
    AND column_name = 'start_at'
    AND is_nullable = 'YES'
  ) THEN
    ALTER TABLE public.events ALTER COLUMN start_at SET NOT NULL;
  END IF;
END $$;
-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_events_start_at ON public.events(start_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_events_end_at ON public.events(end_at) WHERE deleted_at IS NULL;
-- Add comments for documentation
COMMENT ON COLUMN public.events.start_at IS 'Event start timestamp (required)';
COMMENT ON COLUMN public.events.end_at IS 'Optional event end timestamp';
COMMENT ON COLUMN public.events.all_day IS 'Whether the event is an all-day event';
