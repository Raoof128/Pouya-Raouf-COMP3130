-- Migration: Shift all 16 sample public events from March → April 2026
-- Reason: March dates are in the past (today is 2026-03-08).
-- New range: April 10–27 (one event per day, AEST UTC+10 — DST ends Apr 5)
-- Both the SQL database and the TypeScript fallback store must stay in sync.

-- ══════════ ACADEMIC (4) ══════════

-- Research Skills Workshop: Fri Apr 17
UPDATE public.public_events SET
  start_at = '2026-04-17 10:00:00+10',
  end_at   = '2026-04-17 12:00:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0001-4000-8000-000000000001';
-- AI & Ethics Public Lecture: Wed Apr 15 (featured)
UPDATE public.public_events SET
  start_at = '2026-04-15 14:00:00+10',
  end_at   = '2026-04-15 16:00:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0001-4000-8000-000000000002';
-- Study Jam: Midterm Prep: Sat Apr 18
UPDATE public.public_events SET
  start_at = '2026-04-18 10:00:00+10',
  end_at   = '2026-04-18 14:00:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0001-4000-8000-000000000003';
-- Data Science Bootcamp: Fri Apr 24
UPDATE public.public_events SET
  start_at = '2026-04-24 09:00:00+10',
  end_at   = '2026-04-24 17:00:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0001-4000-8000-000000000004';
-- ══════════ FREE FOOD (4) ══════════

-- Free Pizza Friday: Fri Apr 10
UPDATE public.public_events SET
  start_at = '2026-04-10 12:30:00+10',
  end_at   = '2026-04-10 14:00:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0002-4000-8000-000000000001';
-- Pancake Breakfast: Mon Apr 13
UPDATE public.public_events SET
  start_at = '2026-04-13 07:30:00+10',
  end_at   = '2026-04-13 09:30:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0002-4000-8000-000000000002';
-- Sushi & Smoothie Giveaway: Thu Apr 23
UPDATE public.public_events SET
  start_at = '2026-04-23 12:00:00+10',
  end_at   = '2026-04-23 13:30:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0002-4000-8000-000000000003';
-- BBQ on the Lawn: Sun Apr 26 (featured)
UPDATE public.public_events SET
  start_at = '2026-04-26 11:30:00+10',
  end_at   = '2026-04-26 14:00:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0002-4000-8000-000000000004';
-- ══════════ CAREER (4) ══════════

-- Tech Industry Career Fair: Tue Apr 14 (featured)
UPDATE public.public_events SET
  start_at = '2026-04-14 09:00:00+10',
  end_at   = '2026-04-14 16:00:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0003-4000-8000-000000000001';
-- Graduate Employer Mixer: Thu Apr 16
UPDATE public.public_events SET
  start_at = '2026-04-16 17:00:00+10',
  end_at   = '2026-04-16 19:30:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0003-4000-8000-000000000002';
-- Resume & LinkedIn Workshop: Wed Apr 22
UPDATE public.public_events SET
  start_at = '2026-04-22 13:00:00+10',
  end_at   = '2026-04-22 15:00:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0003-4000-8000-000000000003';
-- Startup Pitch Night: Sat Apr 25
UPDATE public.public_events SET
  start_at = '2026-04-25 18:00:00+10',
  end_at   = '2026-04-25 21:00:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0003-4000-8000-000000000004';
-- ══════════ SOCIAL (4) ══════════

-- International Student Mixer: Sat Apr 11
UPDATE public.public_events SET
  start_at = '2026-04-11 17:00:00+10',
  end_at   = '2026-04-11 20:00:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0004-4000-8000-000000000001';
-- Trivia Night: Mon Apr 20
UPDATE public.public_events SET
  start_at = '2026-04-20 18:30:00+10',
  end_at   = '2026-04-20 21:00:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0004-4000-8000-000000000002';
-- Outdoor Movie Night: Tue Apr 21
UPDATE public.public_events SET
  start_at = '2026-04-21 19:00:00+10',
  end_at   = '2026-04-21 22:00:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0004-4000-8000-000000000003';
-- Cultural Festival: Mon Apr 27 (all-day, featured)
UPDATE public.public_events SET
  start_at = '2026-04-27 10:00:00+10',
  end_at   = '2026-04-27 18:00:00+10',
  updated_at = now()
WHERE id = 'aaaaaaaa-0004-4000-8000-000000000004';
