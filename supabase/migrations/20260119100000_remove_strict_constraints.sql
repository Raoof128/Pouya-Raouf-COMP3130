-- ============================================================================
-- MIGRATION: Remove strict format constraints
-- CREATED: 2026-01-19
-- DESCRIPTION: Remove overly strict CHECK constraints that prevent flexible data entry
-- ============================================================================

-- Drop the strict unit code format constraint
-- Users should be able to enter unit codes in various formats (COMP, COMP1234, CS101, etc.)
ALTER TABLE public.units DROP CONSTRAINT IF EXISTS units_code_format;
-- Drop the strict color format constraint (already has a default, validation should be in app layer)
ALTER TABLE public.units DROP CONSTRAINT IF EXISTS units_color_format;
-- Add a more permissive constraint that just ensures code is not empty (idempotent)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'public' AND table_name = 'units' AND constraint_name = 'units_code_not_empty'
    ) THEN
        ALTER TABLE public.units ADD CONSTRAINT units_code_not_empty CHECK (code IS NOT NULL AND length(trim(code)) > 0);
    END IF;
END $$;
-- Ensure color is a valid hex format (6 or 3 digit) or empty (idempotent)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'public' AND table_name = 'units' AND constraint_name = 'units_color_format_permissive'
    ) THEN
        ALTER TABLE public.units ADD CONSTRAINT units_color_format_permissive
            CHECK (color IS NULL OR color ~ '^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})$');
    END IF;
END $$;
