-- ============================================================================
-- MULTI-USER DEMO SEED MIGRATION - DISABLED
-- ============================================================================
-- This migration is disabled because the units schema has changed
-- to use location::jsonb instead of separate building/room columns.
--
-- To re-enable, update all INSERT statements to use:
--   location::jsonb in format {"building": "X", "room": "Y"}
-- instead of separate building and room columns.
-- ============================================================================

-- Placeholder migration (no-op)
SELECT 1;
