-- Migration: Cleanup duplicate public events and ensure consistent category counts
-- Date: 2026-03-04
-- Issue: Earlier migration (20260226100000_add_march_events.sql) created 4 events
-- that overlap with the main seed (20260303000000_seed_16_public_events.sql),
-- causing incorrect category counts (e.g., Academic showing 5 instead of 4)

-- Delete the 4 duplicate events from the earlier migration
DELETE FROM public.public_events
WHERE id IN (
  '11111111-aaaa-4000-8000-000000000001', -- Study Jam Session (duplicate of Study Jam: Midterm Prep)
  '11111111-aaaa-4000-8000-000000000002', -- Graduate Employer Mixer (duplicate)
  '11111111-aaaa-4000-8000-000000000003', -- Pancake Breakfast (duplicate)
  '11111111-aaaa-4000-8000-000000000004'  -- AI & Ethics Public Lecture (duplicate with different date)
);
-- Update the AI & Ethics Public Lecture to March 4th (the original intended date)
UPDATE public.public_events
SET start_at = '2026-03-04 14:00:00+11',
    end_at = '2026-03-04 16:00:00+11',
    updated_at = now()
WHERE id = 'aaaaaaaa-0001-4000-8000-000000000002';
