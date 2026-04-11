-- Migration: Fix invalid building codes in public_events
-- Date: 2026-02-07
--
-- This fixes building codes that don't exist in the buildings.ts list.
-- Invalid codes: C7A, C3C, E7A, W6A, W3A, C5C, E6A, USQ
-- Valid codes: 18WW, LIB, 9WW, WALU, 4ER, LOTUS, SPORT, etc.

-- ============================================================================
-- UPDATE BUILDING CODES IN PUBLIC_EVENTS
-- ============================================================================

-- C7A (Campus Hub) -> 18WW (18 Wally's Walk - Central Hub)
UPDATE public.public_events
SET building = '18WW', updated_at = now()
WHERE building = 'C7A';
-- C3C (Library area) -> LIB (Waranara Library)
UPDATE public.public_events
SET building = 'LIB', updated_at = now()
WHERE building = 'C3C';
-- C5C (Lecture Theatre) -> LOTUS (Lotus Theatre)
UPDATE public.public_events
SET building = 'LOTUS', updated_at = now()
WHERE building = 'C5C';
-- E6A (Seminar Room) -> 9WW (Engineering Building)
UPDATE public.public_events
SET building = '9WW', updated_at = now()
WHERE building = 'E6A';
-- E7A (Engineering) -> 9WW (9 Wally's Walk - Engineering)
UPDATE public.public_events
SET building = '9WW', updated_at = now()
WHERE building = 'E7A';
-- W6A (Wallumattagal) -> WALU (Walanga Muru)
UPDATE public.public_events
SET building = 'WALU', updated_at = now()
WHERE building = 'W6A';
-- W3A (Careers Centre) -> 18WW (18 Wally's Walk - has career services)
UPDATE public.public_events
SET building = '18WW', updated_at = now()
WHERE building = 'W3A';
-- USQ (University Oval/Sports) -> SPORT (Sports & Aquatic Centre) or FIELDS
UPDATE public.public_events
SET building = 'FIELDS', updated_at = now()
WHERE building = 'USQ';
-- ============================================================================
-- UPDATE BUILDING CODES IN USER EVENTS (events table)
-- ============================================================================

-- Apply same fixes to user events that may have been copied from public events
-- C7A -> 18WW
UPDATE public.events
SET building = '18WW', updated_at = now()
WHERE building = 'C7A';
-- C3C -> LIB
UPDATE public.events
SET building = 'LIB', updated_at = now()
WHERE building = 'C3C';
-- C5C -> LOTUS
UPDATE public.events
SET building = 'LOTUS', updated_at = now()
WHERE building = 'C5C';
-- E6A -> 9WW
UPDATE public.events
SET building = '9WW', updated_at = now()
WHERE building = 'E6A';
-- E7A -> 9WW
UPDATE public.events
SET building = '9WW', updated_at = now()
WHERE building = 'E7A';
-- W6A -> WALU
UPDATE public.events
SET building = 'WALU', updated_at = now()
WHERE building = 'W6A';
-- W3A -> 18WW
UPDATE public.events
SET building = '18WW', updated_at = now()
WHERE building = 'W3A';
-- USQ -> FIELDS
UPDATE public.events
SET building = 'FIELDS', updated_at = now()
WHERE building = 'USQ';
