-- Migration: Add missing columns for room and color support
-- Date: 2026-01-26
--
-- This migration adds:
-- 1. room and color columns to events table
-- 2. building and room columns to deadlines table (for exam locations)

-- ============================================================================
-- EVENTS TABLE UPDATES
-- ============================================================================

-- Add room column to events table (for specific room within a building)
ALTER TABLE public.events
ADD COLUMN IF NOT EXISTS room text;
-- Add color column to events table (for custom event colors)
ALTER TABLE public.events
ADD COLUMN IF NOT EXISTS color text;
-- Add comments for documentation
COMMENT ON COLUMN public.events.room IS 'Room number within the building (e.g., "204")';
COMMENT ON COLUMN public.events.color IS 'Custom color for the event (hex value like "#A6192E")';
-- ============================================================================
-- DEADLINES TABLE UPDATES
-- ============================================================================

-- Add building column to deadlines table (for exam locations)
ALTER TABLE public.deadlines
ADD COLUMN IF NOT EXISTS building text;
-- Add room column to deadlines table (for exam locations)
ALTER TABLE public.deadlines
ADD COLUMN IF NOT EXISTS room text;
-- Add color column to deadlines table (for custom colors)
ALTER TABLE public.deadlines
ADD COLUMN IF NOT EXISTS color text;
-- Add comments for documentation
COMMENT ON COLUMN public.deadlines.building IS 'Building code for exams (e.g., "C5C")';
COMMENT ON COLUMN public.deadlines.room IS 'Room number for exams (e.g., "204")';
COMMENT ON COLUMN public.deadlines.color IS 'Custom color override (defaults to unit color)';
-- ============================================================================
-- REFRESH SCHEMA CACHE
-- ============================================================================
-- Note: Supabase automatically refreshes the schema cache after migrations
-- If you're using a local instance, you may need to restart the server;
