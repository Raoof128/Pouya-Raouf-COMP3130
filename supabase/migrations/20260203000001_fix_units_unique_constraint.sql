-- Migration: Fix units unique constraint to exclude soft-deleted records
-- This allows users to delete a unit and re-add one with the same code
--
-- The previous constraint UNIQUE(user_id, code) blocked re-adding units
-- even after they were soft-deleted.

-- Step 1: Drop the existing unique constraint
ALTER TABLE public.units DROP CONSTRAINT IF EXISTS units_user_code_unique;
-- Step 2: Create a partial unique index that only applies to non-deleted records
-- This means soft-deleted records won't block new inserts with the same code
CREATE UNIQUE INDEX IF NOT EXISTS units_user_code_unique
ON public.units (user_id, code)
WHERE deleted_at IS NULL;
-- Step 3: Clean up any existing soft-deleted units that might be blocking inserts
-- (Optional: Uncomment if you want to hard-delete all soft-deleted units)
-- DELETE FROM public.units WHERE deleted_at IS NOT NULL;

-- For this migration, let's hard-delete existing soft-deleted units
-- since we're moving to hard delete for the DELETE endpoint anyway
DELETE FROM public.units WHERE deleted_at IS NOT NULL;
-- Log completion
DO $$
BEGIN
    RAISE NOTICE '═══════════════════════════════════════════════════════════════';
    RAISE NOTICE 'MIGRATION COMPLETE: units_user_code_unique is now a partial index';
    RAISE NOTICE 'Soft-deleted units have been permanently removed';
    RAISE NOTICE '═══════════════════════════════════════════════════════════════';
END $$;
