-- Migration: Add public_events table for university-wide announcements
-- Date: 2026-02-03
--
-- This creates a separate table for public/global events that are:
-- - Visible to ALL users (authenticated and anonymous)
-- - NOT editable by regular users
-- - Managed by admins/system only
-- - Can be copied to user's personal calendar (user_events)

-- ============================================================================
-- PUBLIC EVENTS TABLE
-- ============================================================================
-- Stores university-wide events visible to all users
-- These events are NOT user-owned and cannot be edited by regular users

CREATE TABLE IF NOT EXISTS public.public_events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  -- Time fields
  start_at timestamp with time zone NOT NULL,
  end_at timestamp with time zone,
  all_day boolean NOT NULL DEFAULT false,
  -- Location
  location text NOT NULL,
  building text, -- Building code from buildings.ts (e.g., "C5C")
  room text, -- Room number (e.g., "204")
  -- Metadata
  category text NOT NULL DEFAULT 'Academic' CHECK (category = ANY (ARRAY['Career'::text, 'Social'::text, 'Academic'::text, 'Free Food'::text])),
  image_url text,
  -- Featured/priority
  is_featured boolean NOT NULL DEFAULT false,
  priority integer NOT NULL DEFAULT 0, -- Higher = more prominent
  -- Timestamps
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  -- Soft delete
  deleted_at timestamp with time zone,
  CONSTRAINT public_events_pkey PRIMARY KEY (id),
  CONSTRAINT public_events_valid_time_range CHECK (end_at IS NULL OR end_at >= start_at)
);
-- ============================================================================
-- USER CALENDAR EVENTS (renamed from events for clarity)
-- ============================================================================
-- The existing events table already supports user-owned events
-- We just need to add a reference to the source public event if applicable

-- Add source_public_event_id to track which public event was copied
ALTER TABLE public.events
ADD COLUMN IF NOT EXISTS source_public_event_id uuid REFERENCES public.public_events(id) ON DELETE SET NULL;
-- Index for finding user's copies of public events
CREATE INDEX IF NOT EXISTS idx_events_source_public_event
ON public.events(source_public_event_id)
WHERE source_public_event_id IS NOT NULL;
-- ============================================================================
-- RLS POLICIES FOR PUBLIC EVENTS
-- ============================================================================

-- Enable RLS
ALTER TABLE public.public_events ENABLE ROW LEVEL SECURITY;
-- Everyone can READ public events (including anonymous users)
DROP POLICY IF EXISTS "Anyone can read public events" ON public.public_events;
CREATE POLICY "Anyone can read public events"
ON public.public_events
FOR SELECT
USING (deleted_at IS NULL);
-- Only service role can INSERT/UPDATE/DELETE (for admin operations)
-- Regular users cannot modify public events

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_public_events_start_at
ON public.public_events(start_at);
CREATE INDEX IF NOT EXISTS idx_public_events_category
ON public.public_events(category);
CREATE INDEX IF NOT EXISTS idx_public_events_featured
ON public.public_events(is_featured)
WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_public_events_not_deleted
ON public.public_events(id)
WHERE deleted_at IS NULL;
-- ============================================================================
-- SEED DATA: University Events
-- ============================================================================
-- Insert sample public events for all users to see

INSERT INTO public.public_events (
  id, title, description, start_at, end_at, all_day,
  location, building, room, category, is_featured, priority, image_url
) VALUES
-- Featured Events
(
  'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
  'Career Fair 2026',
  'Connect with 50+ leading employers from tech, finance, healthcare, and more. Bring your resume and dress professionally. Free professional headshots available!',
  NOW() + INTERVAL '7 days' + TIME '10:00:00',
  NOW() + INTERVAL '7 days' + TIME '16:00:00',
  false,
  'Campus Hub, Main Hall',
  '18WW',
  NULL,
  'Career',
  true,
  100,
  NULL
),
(
  'b2c3d4e5-f6a7-5b6c-9d0e-1f2a3b4c5d6e',
  'O-Week Welcome Festival',
  'Kick off the semester with live music, free food, club stalls, and campus tours. Meet new friends and discover everything MQ has to offer!',
  NOW() + INTERVAL '14 days' + TIME '11:00:00',
  NOW() + INTERVAL '14 days' + TIME '20:00:00',
  false,
  'Central Courtyard',
  'LIB',
  NULL,
  'Social',
  true,
  90,
  NULL
),

-- Free Food Events
(
  'c3d4e5f6-a7b8-6c7d-0e1f-2a3b4c5d6e7f',
  'Free Pizza Friday',
  'Join us for free pizza and networking with fellow students! Vegetarian and vegan options available.',
  NOW() + INTERVAL '3 days' + TIME '12:00:00',
  NOW() + INTERVAL '3 days' + TIME '14:00:00',
  false,
  'Library Courtyard',
  'LIB',
  NULL,
  'Free Food',
  false,
  50,
  NULL
),
(
  'd4e5f6a7-b8c9-7d8e-1f2a-3b4c5d6e7f8a',
  'Free Breakfast Week',
  'Start your day right! Free breakfast including coffee, pastries, and fruit available all week.',
  NOW() + INTERVAL '5 days' + TIME '07:30:00',
  NOW() + INTERVAL '5 days' + TIME '09:30:00',
  false,
  'Student Centre Cafe',
  '18WW',
  NULL,
  'Free Food',
  false,
  40,
  NULL
),
(
  'e5f6a7b8-c9d0-8e9f-2a3b-4c5d6e7f8a9b',
  'International Food Festival',
  'Taste cuisines from around the world! Free samples from 20+ countries. Celebrate our diverse campus community.',
  NOW() + INTERVAL '10 days' + TIME '11:00:00',
  NOW() + INTERVAL '10 days' + TIME '15:00:00',
  false,
  'Campus Common',
  'LIB',
  NULL,
  'Free Food',
  true,
  80,
  NULL
),

-- Academic Events
(
  'f6a7b8c9-d0e1-9f0a-3b4c-5d6e7f8a9b0c',
  'Study Skills Workshop',
  'Learn effective study techniques, time management strategies, and exam preparation tips from academic advisors.',
  NOW() + INTERVAL '2 days' + TIME '14:00:00',
  NOW() + INTERVAL '2 days' + TIME '16:00:00',
  false,
  'Library Room 204',
  'LIB',
  '204',
  'Academic',
  false,
  30,
  NULL
),
(
  'a7b8c9d0-e1f2-0a1b-4c5d-6e7f8a9b0c1d',
  'Research Methods Seminar',
  'Introduction to research methodologies for undergraduate and postgraduate students. Required for thesis students.',
  NOW() + INTERVAL '4 days' + TIME '10:00:00',
  NOW() + INTERVAL '4 days' + TIME '12:00:00',
  false,
  'C5C Lecture Theatre',
  'LOTUS',
  'LT1',
  'Academic',
  false,
  35,
  NULL
),
(
  'b8c9d0e1-f2a3-1b2c-5d6e-7f8a9b0c1d2e',
  'Library Research Tour',
  'Discover library resources, databases, and study spaces. Perfect for new students or anyone wanting to maximize their study efficiency.',
  NOW() + INTERVAL '1 day' + TIME '13:00:00',
  NOW() + INTERVAL '1 day' + TIME '14:00:00',
  false,
  'Library Main Entrance',
  'LIB',
  NULL,
  'Academic',
  false,
  25,
  NULL
),
(
  'c9d0e1f2-a3b4-2c3d-6e7f-8a9b0c1d2e3f',
  'Academic Integrity Workshop',
  'Understanding plagiarism, proper citation, and maintaining academic integrity. Mandatory for all new students.',
  NOW() + INTERVAL '6 days' + TIME '09:00:00',
  NOW() + INTERVAL '6 days' + TIME '11:00:00',
  false,
  'E6A Seminar Room',
  '9WW',
  '101',
  'Academic',
  false,
  45,
  NULL
),

-- Career Events
(
  'd0e1f2a3-b4c5-3d4e-7f8a-9b0c1d2e3f4a',
  'Resume Writing Workshop',
  'Get expert tips on crafting the perfect resume. One-on-one feedback sessions available.',
  NOW() + INTERVAL '8 days' + TIME '15:00:00',
  NOW() + INTERVAL '8 days' + TIME '17:00:00',
  false,
  'Careers Centre',
  '18WW',
  '203',
  'Career',
  false,
  55,
  NULL
),
(
  'e1f2a3b4-c5d6-4e5f-8a9b-0c1d2e3f4a5b',
  'Tech Industry Panel',
  'Hear from engineers at Google, Microsoft, and local startups about careers in tech.',
  NOW() + INTERVAL '9 days' + TIME '18:00:00',
  NOW() + INTERVAL '9 days' + TIME '20:00:00',
  false,
  '4 Eastern Road Auditorium',
  '4ER',
  NULL,
  'Career',
  false,
  60,
  NULL
),
(
  'f2a3b4c5-d6e7-5f6a-9b0c-1d2e3f4a5b6c',
  'Internship Info Session',
  'Learn about summer internship opportunities, application timelines, and how to stand out.',
  NOW() + INTERVAL '11 days' + TIME '12:00:00',
  NOW() + INTERVAL '11 days' + TIME '13:30:00',
  false,
  'C5C Room 120',
  'LOTUS',
  '120',
  'Career',
  false,
  50,
  NULL
),

-- Social Events
(
  'a3b4c5d6-e7f8-6a7b-0c1d-2e3f4a5b6c7d',
  'Campus Movie Night',
  'Outdoor screening of a blockbuster movie. Bring blankets! Free popcorn and drinks provided.',
  NOW() + INTERVAL '12 days' + TIME '19:00:00',
  NOW() + INTERVAL '12 days' + TIME '22:00:00',
  false,
  'University Oval',
  'FIELDS',
  NULL,
  'Social',
  false,
  40,
  NULL
),
(
  'b4c5d6e7-f8a9-7b8c-1d2e-3f4a5b6c7d8e',
  'Student Club Fair',
  'Explore 100+ student clubs and societies. Sign up for sports, arts, cultural groups, and more!',
  NOW() + INTERVAL '13 days' + TIME '10:00:00',
  NOW() + INTERVAL '13 days' + TIME '16:00:00',
  false,
  'Campus Hub',
  '18WW',
  NULL,
  'Social',
  true,
  75,
  NULL
),
(
  'c5d6e7f8-a9b0-8c9d-2e3f-4a5b6c7d8e9f',
  'Trivia Night',
  'Test your knowledge! Teams of 4-6. Prizes for top 3 teams. Free entry.',
  NOW() + INTERVAL '15 days' + TIME '18:30:00',
  NOW() + INTERVAL '15 days' + TIME '21:00:00',
  false,
  'Unibar',
  'UBAR',
  NULL,
  'Social',
  false,
  35,
  NULL
),
(
  'd6e7f8a9-b0c1-9d0e-3f4a-5b6c7d8e9f0a',
  'Yoga in the Park',
  'Destress with a free outdoor yoga session. All levels welcome. Mats provided.',
  NOW() + INTERVAL '4 days' + TIME '07:00:00',
  NOW() + INTERVAL '4 days' + TIME '08:00:00',
  false,
  'Central Park Lawn',
  'LIB',
  NULL,
  'Social',
  false,
  30,
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
-- ============================================================================
-- FUNCTION: Copy public event to user's calendar
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_public_event_to_calendar(
  p_public_event_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_existing_id uuid;
  v_new_event_id uuid;
  v_public_event public.public_events%ROWTYPE;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Check if already added
  SELECT id INTO v_existing_id
  FROM public.events
  WHERE user_id = v_user_id
    AND source_public_event_id = p_public_event_id
    AND deleted_at IS NULL;

  IF v_existing_id IS NOT NULL THEN
    -- Already exists, return existing ID
    RETURN v_existing_id;
  END IF;

  -- Get the public event
  SELECT * INTO v_public_event
  FROM public.public_events
  WHERE id = p_public_event_id AND deleted_at IS NULL;

  IF v_public_event.id IS NULL THEN
    RAISE EXCEPTION 'Public event not found';
  END IF;

  -- Insert into user's events
  INSERT INTO public.events (
    user_id,
    source_public_event_id,
    title,
    description,
    start_at,
    end_at,
    all_day,
    location,
    building,
    room,
    category,
    image_url
  ) VALUES (
    v_user_id,
    p_public_event_id,
    v_public_event.title,
    v_public_event.description,
    v_public_event.start_at,
    v_public_event.end_at,
    v_public_event.all_day,
    v_public_event.location,
    v_public_event.building,
    v_public_event.room,
    v_public_event.category,
    v_public_event.image_url
  )
  RETURNING id INTO v_new_event_id;

  RETURN v_new_event_id;
END;
$$;
-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.add_public_event_to_calendar(uuid) TO authenticated;
