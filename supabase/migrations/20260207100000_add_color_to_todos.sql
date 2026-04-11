-- Migration: Add color column to todos table
-- Date: 2026-02-07
-- Purpose: Allow users to customize todo colors in the calendar

-- Add color column to todos table
ALTER TABLE public.todos
ADD COLUMN IF NOT EXISTS color TEXT DEFAULT NULL;
-- Add comment for documentation
COMMENT ON COLUMN public.todos.color IS 'Custom color hex code for calendar display (e.g., #10b981)';
