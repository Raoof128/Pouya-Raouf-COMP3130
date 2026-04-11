-- Fix: Supabase security lint — user_details was SECURITY DEFINER (runs
-- with the view-owner's privileges, bypassing RLS).  Recreate it with
-- SECURITY INVOKER so RLS policies of the querying user are enforced.
CREATE OR REPLACE VIEW public.user_details
WITH (security_invoker = true)
AS
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
        ELSE LEAST(100::double precision,
             floor(sqrt(gp.xp::double precision / 25::double precision)) + 1::double precision)::integer
    END AS level
FROM public.profiles p
LEFT JOIN public.gamification_profiles gp ON p.id = gp.user_id;

-- Preserve existing grants
GRANT ALL ON TABLE public.user_details TO anon;
GRANT ALL ON TABLE public.user_details TO authenticated;
GRANT ALL ON TABLE public.user_details TO service_role;
