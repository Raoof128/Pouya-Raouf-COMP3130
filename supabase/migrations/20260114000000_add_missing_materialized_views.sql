-- Migration to add missing materialized views detected in production
-- These views are used for analytics and leaderboards

-- 1. Deadline Analytics
-- Aggregates deadline statistics per user for dashboard widgets
DROP MATERIALIZED VIEW IF EXISTS public.mv_deadline_analytics;
CREATE MATERIALIZED VIEW public.mv_deadline_analytics AS
SELECT
    d.user_id,
    COUNT(*) AS total_deadlines,
    COUNT(*) FILTER (WHERE d.completed = true) AS completed_count,
    COUNT(*) FILTER (WHERE d.completed = false) AS pending_count,
    COUNT(*) FILTER (WHERE d.completed = false AND d.due_date < NOW()) AS overdue_count,
    MIN(d.due_date) FILTER (WHERE d.completed = false AND d.due_date > NOW()) AS next_deadline_date
FROM public.deadlines d
GROUP BY d.user_id;
CREATE UNIQUE INDEX idx_mv_deadline_analytics_key ON public.mv_deadline_analytics(user_id);
-- 2. XP Leaderboard
-- Ranks users by XP for the gamification leaderboard
DROP MATERIALIZED VIEW IF EXISTS public.mv_xp_leaderboard;
CREATE MATERIALIZED VIEW public.mv_xp_leaderboard AS
SELECT
    gp.user_id,
    p.full_name,
    p.avatar_url,
    gp.xp,
    gp.streak_days,
    -- Calculate level based on the formula: floor(sqrt(xp/25)) + 1
    LEAST(100, FLOOR(SQRT(gp.xp::float / 25)) + 1)::integer AS level,
    RANK() OVER (ORDER BY gp.xp DESC) AS rank
FROM public.gamification_profiles gp
JOIN public.profiles p ON gp.user_id = p.id;
CREATE UNIQUE INDEX idx_mv_xp_leaderboard_user_id ON public.mv_xp_leaderboard(user_id);
-- 3. User Activity Summary
-- Summarizes user engagement for reporting
DROP MATERIALIZED VIEW IF EXISTS public.mv_user_activity_summary;
CREATE MATERIALIZED VIEW public.mv_user_activity_summary AS
SELECT
    gp.user_id,
    gp.last_activity_date,
    gp.streak_days,
    gp.longest_streak,
    (SELECT COUNT(*) FROM public.xp_events xe WHERE xe.user_id = gp.user_id) AS total_actions,
    (SELECT MAX(created_at) FROM public.xp_events xe WHERE xe.user_id = gp.user_id) AS last_action_at
FROM public.gamification_profiles gp;
CREATE UNIQUE INDEX idx_mv_user_activity_summary_user_id ON public.mv_user_activity_summary(user_id);
-- Permissions
GRANT SELECT ON public.mv_deadline_analytics TO authenticated;
GRANT SELECT ON public.mv_xp_leaderboard TO authenticated;
GRANT SELECT ON public.mv_user_activity_summary TO authenticated;
-- RLS (Materialized Views don't support RLS directly in the same way, 
-- usually you secure them by filtering in the query or revoking public access.
-- Since these are aggregated, we generally just allow authenticated read 
-- (for leaderboard) or restrict via wrapper view if privacy is needed.
-- For now, simple GRANT SELECT is standard for these use cases.);
