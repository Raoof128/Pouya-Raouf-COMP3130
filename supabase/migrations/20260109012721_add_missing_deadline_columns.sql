-- ============================================================================
-- ADD MISSING COLUMNS TO DEADLINES TABLE
-- This migration ensures all columns exist in the deadlines table
-- ============================================================================

-- Add due_date column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'deadlines' AND column_name = 'due_date'
  ) THEN
    ALTER TABLE public.deadlines ADD COLUMN due_date timestamp with time zone NOT NULL DEFAULT now();
  END IF;
END $$;
-- Add priority column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'deadlines' AND column_name = 'priority'
  ) THEN
    ALTER TABLE public.deadlines ADD COLUMN priority text NOT NULL DEFAULT 'Medium';
  END IF;
END $$;
-- Add type column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'deadlines' AND column_name = 'type'
  ) THEN
    ALTER TABLE public.deadlines ADD COLUMN type text NOT NULL DEFAULT 'Assignment';
  END IF;
END $$;
-- Add completed column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'deadlines' AND column_name = 'completed'
  ) THEN
    ALTER TABLE public.deadlines ADD COLUMN completed boolean NOT NULL DEFAULT false;
  END IF;
END $$;
-- Add unit_code column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'deadlines' AND column_name = 'unit_code'
  ) THEN
    ALTER TABLE public.deadlines ADD COLUMN unit_code text NOT NULL DEFAULT 'MISC';
  END IF;
END $$;
-- Add updated_at column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'deadlines' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE public.deadlines ADD COLUMN updated_at timestamp with time zone DEFAULT now();
  END IF;
END $$;
-- Now create index on due_date if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_deadlines_due_date ON public.deadlines(due_date);
CREATE INDEX IF NOT EXISTS idx_deadlines_completed ON public.deadlines(completed);
CREATE INDEX IF NOT EXISTS idx_deadlines_unit_code ON public.deadlines(unit_code);
-- ============================================================================
-- ADD MISSING COLUMNS TO UNITS TABLE
-- ============================================================================

-- Add building column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'units' AND column_name = 'building'
  ) THEN
    ALTER TABLE public.units ADD COLUMN building text;
  END IF;
END $$;
-- Add room column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'units' AND column_name = 'room'
  ) THEN
    ALTER TABLE public.units ADD COLUMN room text;
  END IF;
END $$;
-- Add description column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'units' AND column_name = 'description'
  ) THEN
    ALTER TABLE public.units ADD COLUMN description text;
  END IF;
END $$;
-- Add color column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'units' AND column_name = 'color'
  ) THEN
    ALTER TABLE public.units ADD COLUMN color text NOT NULL DEFAULT '#3B82F6';
  END IF;
END $$;
-- ============================================================================
-- ADD MISSING COLUMNS TO PROFILES TABLE
-- ============================================================================

-- Add avatar_url column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'avatar_url'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN avatar_url text;
  END IF;
END $$;
-- Add updated_at column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN updated_at timestamp with time zone DEFAULT now();
  END IF;
END $$;
-- ============================================================================
-- ADD MISSING COLUMNS TO CLASS_TIMES TABLE
-- ============================================================================

-- Add day column check constraint (won't error if column exists)
DO $$
BEGIN
  -- Only add constraint if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'class_times_day_check'
  ) THEN
    ALTER TABLE public.class_times ADD CONSTRAINT class_times_day_check
      CHECK (day = ANY (ARRAY['Monday'::text, 'Tuesday'::text, 'Wednesday'::text, 'Thursday'::text, 'Friday'::text, 'Saturday'::text, 'Sunday'::text]));
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================;
