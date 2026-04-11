-- Migration: Add faculty to user_details view and get_my_profile function
-- The faculty column was added to profiles table in 20260220000000 but the
-- user_details view and get_my_profile() function were never updated to include it.

-- Recreate the user_details view with faculty included
DROP VIEW IF EXISTS public.user_details;
CREATE VIEW public.user_details AS
SELECT
    p.id,
    p.email,
    p.full_name,
    p.student_id,
    p.faculty,
    p.course,
    p.year,
    p.avatar_url,
    p.created_at,
    p.updated_at,
    gp.xp,
    gp.streak_days,
    gp.longest_streak,
    gp.last_activity_date,
    CASE
        WHEN gp.xp IS NULL OR gp.xp < 0 THEN 1
        ELSE LEAST(100, FLOOR(SQRT(gp.xp::float / 25)) + 1)::integer
    END AS level
FROM public.profiles p
LEFT JOIN public.gamification_profiles gp ON p.id = gp.user_id;
GRANT SELECT ON public.user_details TO authenticated;
-- Recreate get_my_profile() function to include faculty
DROP FUNCTION IF EXISTS public.get_my_profile();
CREATE FUNCTION public.get_my_profile()
RETURNS TABLE (
    id uuid,
    email text,
    full_name text,
    student_id text,
    faculty text,
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
    RETURN QUERY SELECT * FROM public.user_details ud WHERE ud.id = auth.uid();
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_my_profile() TO authenticated;
