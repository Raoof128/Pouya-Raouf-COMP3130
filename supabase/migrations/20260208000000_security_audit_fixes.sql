-- Security Audit Fixes Migration
-- Raouf: 2026-02-08 (Australia/Sydney)
--
-- 1. RPC function for user email lookup (replaces admin.listUsers() which
--    loads ALL users into memory — DoS vector + functional bug for >50 users)
-- 2. Scheduled cleanup of expired WebAuthn challenges

-- ============================================================================
-- Secure user-email lookup (service_role only)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.lookup_user_by_email(lookup_email TEXT)
RETURNS TABLE(user_id UUID, user_email TEXT, user_meta JSONB)
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT u.id, u.email::TEXT, u.raw_user_meta_data
  FROM auth.users u
  WHERE lower(u.email) = lower(lookup_email)
  LIMIT 1;
$$;
-- SECURITY: Only service_role may call this function
REVOKE ALL ON FUNCTION public.lookup_user_by_email(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.lookup_user_by_email(TEXT) FROM anon;
REVOKE ALL ON FUNCTION public.lookup_user_by_email(TEXT) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.lookup_user_by_email(TEXT) TO service_role;
-- ============================================================================
-- Scheduled cleanup of expired WebAuthn challenges (if pg_cron available)
-- ============================================================================

DO $outer$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'cleanup-webauthn-challenges',
      '*/15 * * * *',
      $cron$DELETE FROM public.webauthn_challenges WHERE expires_at < now()$cron$
    );
  END IF;
END $outer$;
