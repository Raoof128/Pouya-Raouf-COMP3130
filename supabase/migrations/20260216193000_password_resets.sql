-- Custom Password Reset Tokens
-- Raouf: 2026-02-16 (Australia/Sydney)
--
-- Stores SHA-256 hashed password reset tokens. Raw tokens are NEVER stored.
-- All operations are server-side via API routes using service_role.

-- ============================================================================
-- password_resets table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.password_resets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  token_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);
-- Index for fast token lookup during reset
CREATE INDEX IF NOT EXISTS idx_password_resets_token_hash
  ON public.password_resets (token_hash)
  WHERE used = FALSE;
-- Index for invalidating previous tokens per user
CREATE INDEX IF NOT EXISTS idx_password_resets_user_id
  ON public.password_resets (user_id)
  WHERE used = FALSE;
-- Index for cleanup job
CREATE INDEX IF NOT EXISTS idx_password_resets_expires_at
  ON public.password_resets (expires_at)
  WHERE used = FALSE;
-- ============================================================================
-- RLS
-- ============================================================================

ALTER TABLE public.password_resets ENABLE ROW LEVEL SECURITY;
-- Only service_role can access this table.
-- No policies for anon/authenticated — they go through API routes.

-- ============================================================================
-- Cleanup function: delete expired/used tokens
-- ============================================================================

CREATE OR REPLACE FUNCTION public.cleanup_expired_password_resets()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM public.password_resets
  WHERE expires_at < now() OR used = TRUE;

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;
-- SECURITY: Only service_role may call this function
REVOKE ALL ON FUNCTION public.cleanup_expired_password_resets() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.cleanup_expired_password_resets() FROM anon;
REVOKE ALL ON FUNCTION public.cleanup_expired_password_resets() FROM authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_password_resets() TO service_role;
-- ============================================================================
-- Scheduled cleanup via pg_cron (if available)
-- ============================================================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'cleanup-expired-password-resets',
      '10 3 * * *',  -- Daily at 03:10 AM UTC
      'SELECT public.cleanup_expired_password_resets()'
    );
  END IF;
END
$$;
