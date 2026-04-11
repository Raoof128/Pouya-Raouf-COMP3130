-- Migration: Fix SECURITY DEFINER view and enable RLS on xp_config
-- Purpose: Address security issues:
--   1. user_details view uses SECURITY DEFINER (should use SECURITY INVOKER)
--   2. xp_config table is missing RLS
-- Date: 2026-02-26

-- ============================================================================
-- FIX 1: Change user_details view from SECURITY DEFINER to SECURITY INVOKER
-- ============================================================================
-- By default, PostgreSQL views use SECURITY DEFINER which means the view
-- executes with the permissions of the view creator, bypassing RLS policies
-- on the underlying tables. We need SECURITY INVOKER so that the view
-- respects the RLS policies of the querying user.

-- Recreate the view with security_invoker = true
DROP VIEW IF EXISTS public.user_details;
CREATE VIEW public.user_details
WITH (security_invoker = true)
AS
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
    COALESCE(gp.xp, 0) AS xp,
    COALESCE(gp.streak_days, 0) AS streak_days,
    COALESCE(gp.longest_streak, 0) AS longest_streak,
    gp.last_activity_date,
    CASE
        WHEN gp.xp IS NULL OR gp.xp < 0 THEN 1
        ELSE LEAST(100, FLOOR(SQRT(gp.xp::float / 25)) + 1)::integer
    END AS level
FROM public.profiles p
LEFT JOIN public.gamification_profiles gp ON p.id = gp.user_id;
-- Re-grant SELECT permission to authenticated users
GRANT SELECT ON public.user_details TO authenticated;
-- ============================================================================
-- FIX 2: Enable RLS on xp_config table
-- ============================================================================
-- xp_config is a reference/configuration table exposed to PostgREST.
-- Even though it only contains static configuration data, RLS should be
-- enabled for security compliance.

ALTER TABLE public.xp_config ENABLE ROW LEVEL SECURITY;
-- Create a policy that allows authenticated users to read xp_config
-- This is a read-only reference table, so we only need SELECT policy
CREATE POLICY "Authenticated users can read xp_config"
  ON public.xp_config
  FOR SELECT
  TO authenticated
  USING (true);
-- ============================================================================
-- VERIFICATION COMMENTS
-- ============================================================================
-- After running this migration:
-- 1. user_details view will use security_invoker = true, respecting RLS
--    policies on profiles and gamification_profiles tables
-- 2. xp_config table will have RLS enabled with a permissive SELECT policy
--    for authenticated users;
