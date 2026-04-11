-- Migration: Add course and year columns to profiles table
-- These fields store the student's course/program and academic year

-- Add course and year columns to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS course text,
ADD COLUMN IF NOT EXISTS year text;
-- Drop the existing view first (required when changing column order)
DROP VIEW IF EXISTS public.user_details;
-- Recreate the user_details VIEW to include course and year
-- NOTE: gamification_profiles doesn't exist yet - it's created in a later migration
-- That migration will recreate this view with gamification data
CREATE VIEW public.user_details AS
SELECT
    p.id,
    p.email,
    p.full_name,
    p.student_id,
    p.course,
    p.year,
    p.avatar_url,
    p.created_at,
    p.updated_at,
    0 AS xp,
    0 AS streak_days,
    0 AS longest_streak,
    NULL::date AS last_activity_date,
    1 AS level
FROM public.profiles p;
-- Ensure authenticated users can still select from the view
GRANT SELECT ON public.user_details TO authenticated;
-- Drop the existing function first (required when changing return type)
DROP FUNCTION IF EXISTS public.get_my_profile();
-- Recreate get_my_profile() function to return course and year
CREATE FUNCTION public.get_my_profile()
RETURNS TABLE (
    id uuid,
    email text,
    full_name text,
    student_id text,
    course text,
    year text,
    avatar_url text,
    created_at timestamptz,
    updated_at timestamptz,
    xp integer,
    streak_days integer,
    longest_streak integer,
    last_activity_date date,
    level integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ud.id,
        ud.email,
        ud.full_name,
        ud.student_id,
        ud.course,
        ud.year,
        ud.avatar_url,
        ud.created_at,
        ud.updated_at,
        ud.xp,
        ud.streak_days,
        ud.longest_streak,
        ud.last_activity_date,
        ud.level
    FROM public.user_details ud
    WHERE ud.id = auth.uid();
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_my_profile() TO authenticated;
