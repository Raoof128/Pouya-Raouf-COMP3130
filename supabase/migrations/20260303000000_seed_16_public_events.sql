-- Migration: Seed 16 sample public events for the Events Feed
-- 4 Academic, 4 Free Food, 4 Career, 4 Social — originally March 4–21 2026
-- NOTE: Dates below are superseded by 20260308000000_shift_events_to_april.sql
--       which moves all events to April 10–27 2026 (AEST +10).
-- These appear in the Events Feed tab; users can add them to their personal calendar.

INSERT INTO public.public_events (
  id, title, description, start_at, end_at, all_day,
  location, building, room, category, is_featured, priority, image_url
) VALUES
-- ══════════ ACADEMIC (4) ══════════
(
  'aaaaaaaa-0001-4000-8000-000000000001',
  'Research Skills Workshop',
  'Learn essential research methodology and academic writing skills. Perfect for thesis students and researchers.',
  '2026-03-05 10:00:00+11', '2026-03-05 12:00:00+11', false,
  'Library Level 3, Room 301', 'LIB', '301', 'Academic', false, 50, NULL
),
(
  'aaaaaaaa-0001-4000-8000-000000000002',
  'AI & Ethics Public Lecture',
  'Guest speaker Prof. Sarah Chen discusses ethical implications of generative AI in education.',
  '2026-03-04 14:00:00+11', '2026-03-04 16:00:00+11', false,
  '4 Eastern Road Auditorium', '4ER', NULL, 'Academic', true, 70, NULL
),
(
  'aaaaaaaa-0001-4000-8000-000000000003',
  'Study Jam: Midterm Prep',
  'Collaborative study session with peer tutors. Bring your notes and questions!',
  '2026-03-12 10:00:00+11', '2026-03-12 14:00:00+11', false,
  'Library Level 2 Study Hub', 'LIB', '201', 'Academic', false, 45, NULL
),
(
  'aaaaaaaa-0001-4000-8000-000000000004',
  'Data Science Bootcamp',
  'Hands-on intro to Python data analysis. Laptops provided. No prior experience needed.',
  '2026-03-18 09:00:00+11', '2026-03-18 17:00:00+11', false,
  '9 Wally''s Walk Lab', '9WW', '120', 'Academic', false, 55, NULL
),
-- ══════════ FREE FOOD (4) ══════════
(
  'aaaaaaaa-0002-4000-8000-000000000001',
  'Free Pizza Friday',
  'Join us for free pizza! Hosted by the Student Association. All students welcome.',
  '2026-03-06 12:30:00+11', '2026-03-06 14:00:00+11', false,
  'Wally''s Walk Courtyard', 'WALLYS', NULL, 'Free Food', false, 60, NULL
),
(
  'aaaaaaaa-0002-4000-8000-000000000002',
  'Pancake Breakfast',
  'Free pancakes, fruit, and coffee to kickstart your week! Vegan and GF options available.',
  '2026-03-09 07:30:00+11', '2026-03-09 09:30:00+11', false,
  'Central Courtyard', 'LIB', NULL, 'Free Food', false, 50, NULL
),
(
  'aaaaaaaa-0002-4000-8000-000000000003',
  'Sushi & Smoothie Giveaway',
  'Free sushi rolls and smoothies while stocks last. Grab lunch on us!',
  '2026-03-13 12:00:00+11', '2026-03-13 13:30:00+11', false,
  'UniBar Courtyard', 'UBAR', NULL, 'Free Food', false, 55, NULL
),
(
  'aaaaaaaa-0002-4000-8000-000000000004',
  'BBQ on the Lawn',
  'Classic Aussie BBQ with snags, burgers, and veggie options. Sponsored by MQ Sport.',
  '2026-03-20 11:30:00+11', '2026-03-20 14:00:00+11', false,
  'Sports Fields', 'FIELDS', NULL, 'Free Food', true, 65, NULL
),
-- ══════════ CAREER (4) ══════════
(
  'aaaaaaaa-0003-4000-8000-000000000001',
  'Tech Industry Career Fair',
  'Meet recruiters from Google, Microsoft, Atlassian, and more. Bring your resume!',
  '2026-03-07 09:00:00+11', '2026-03-07 16:00:00+11', false,
  'Macquarie Theatre', 'MQTH', NULL, 'Career', true, 80, NULL
),
(
  'aaaaaaaa-0003-4000-8000-000000000002',
  'Graduate Employer Mixer',
  'Casual networking with hiring managers from top graduate programs. Refreshments provided.',
  '2026-03-11 17:00:00+11', '2026-03-11 19:30:00+11', false,
  'Campus Hub Foyer', '18WW', NULL, 'Career', false, 55, NULL
),
(
  'aaaaaaaa-0003-4000-8000-000000000003',
  'Resume & LinkedIn Workshop',
  'Professional career advisors help you polish your resume and LinkedIn profile.',
  '2026-03-14 13:00:00+11', '2026-03-14 15:00:00+11', false,
  'Digital Learning Centre', 'DLC', NULL, 'Career', false, 50, NULL
),
(
  'aaaaaaaa-0003-4000-8000-000000000004',
  'Startup Pitch Night',
  'Watch student startups pitch to a panel of investors. Networking drinks afterwards.',
  '2026-03-19 18:00:00+11', '2026-03-19 21:00:00+11', false,
  'Incubator Hub', 'INCUB', NULL, 'Career', false, 60, NULL
),
-- ══════════ SOCIAL (4) ══════════
(
  'aaaaaaaa-0004-4000-8000-000000000001',
  'International Student Mixer',
  'Meet fellow international students! Games, music, and free refreshments.',
  '2026-03-08 17:00:00+11', '2026-03-08 20:00:00+11', false,
  'UniBar', 'UBAR', NULL, 'Social', false, 55, NULL
),
(
  'aaaaaaaa-0004-4000-8000-000000000002',
  'Trivia Night',
  'Test your knowledge in teams of 4–6. Prizes for top 3! Drinks at bar prices.',
  '2026-03-12 18:30:00+11', '2026-03-12 21:00:00+11', false,
  'UniBar', 'UBAR', NULL, 'Social', false, 50, NULL
),
(
  'aaaaaaaa-0004-4000-8000-000000000003',
  'Outdoor Movie Night',
  'Screening of Interstellar on the big screen. BYO blankets and snacks!',
  '2026-03-15 19:00:00+11', '2026-03-15 22:00:00+11', false,
  'Sports Fields', 'FIELDS', NULL, 'Social', false, 70, NULL
),
(
  'aaaaaaaa-0004-4000-8000-000000000004',
  'Cultural Festival',
  'Celebrating diversity with food stalls, performances, and art from 30+ cultures.',
  '2026-03-21 10:00:00+11', '2026-03-21 18:00:00+11', true,
  'Central Courtyard', 'LIB', NULL, 'Social', true, 75, NULL
)
ON CONFLICT (id) DO UPDATE SET
  title       = EXCLUDED.title,
  description = EXCLUDED.description,
  start_at    = EXCLUDED.start_at,
  end_at      = EXCLUDED.end_at,
  all_day     = EXCLUDED.all_day,
  location    = EXCLUDED.location,
  building    = EXCLUDED.building,
  room        = EXCLUDED.room,
  category    = EXCLUDED.category,
  is_featured = EXCLUDED.is_featured,
  priority    = EXCLUDED.priority,
  image_url   = EXCLUDED.image_url,
  updated_at  = now();
