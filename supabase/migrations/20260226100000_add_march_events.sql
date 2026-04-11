-- Migration: Add sample public events for March 2026
-- Date: 2026-02-26
-- Adds 4 events across Academic, Career, Free Food categories for March 1+

INSERT INTO public.public_events (
  id, title, description, start_at, end_at, all_day,
  location, building, room, category, is_featured, priority, image_url
) VALUES
-- Academic: Study Jam Session (1 March)
(
  '11111111-aaaa-4000-8000-000000000001',
  'Study Jam Session',
  'Collaborative study session with peer tutors for midterm prep. Bring your notes and questions!',
  '2026-03-01 10:00:00+11',
  '2026-03-01 14:00:00+11',
  false,
  'Library Level 3 Study Hub',
  'LIB',
  '301',
  'Academic',
  false,
  45,
  NULL
),
-- Career: Graduate Employer Mixer (2 March)
(
  '11111111-aaaa-4000-8000-000000000002',
  'Graduate Employer Mixer',
  'Meet hiring managers from top graduate programs. Casual networking with refreshments provided.',
  '2026-03-02 17:00:00+11',
  '2026-03-02 19:30:00+11',
  false,
  'Campus Hub Foyer',
  '18WW',
  NULL,
  'Career',
  false,
  55,
  NULL
),
-- Free Food: Pancake Breakfast (3 March)
(
  '11111111-aaaa-4000-8000-000000000003',
  'Pancake Breakfast',
  'Free pancakes, fruit, and coffee to kickstart your week! Vegan and gluten-free options available.',
  '2026-03-03 07:30:00+11',
  '2026-03-03 09:30:00+11',
  false,
  'Central Courtyard',
  'LIB',
  NULL,
  'Free Food',
  false,
  50,
  NULL
),
-- Academic: AI & Ethics Public Lecture (4 March)
(
  '11111111-aaaa-4000-8000-000000000004',
  'AI & Ethics Public Lecture',
  'Guest speaker Prof. Sarah Chen discusses the ethical implications of generative AI in education and beyond.',
  '2026-03-04 14:00:00+11',
  '2026-03-04 16:00:00+11',
  false,
  '4 Eastern Road Auditorium',
  '4ER',
  NULL,
  'Academic',
  false,
  60,
  NULL
)
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  start_at = EXCLUDED.start_at,
  end_at = EXCLUDED.end_at,
  all_day = EXCLUDED.all_day,
  location = EXCLUDED.location,
  building = EXCLUDED.building,
  room = EXCLUDED.room,
  category = EXCLUDED.category,
  is_featured = EXCLUDED.is_featured,
  priority = EXCLUDED.priority,
  image_url = EXCLUDED.image_url,
  updated_at = now();
