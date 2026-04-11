-- Custom Email Verification Table
-- Raouf: 2026-02-13 (Australia/Sydney)
--
-- Stores SHA-256 hashed verification tokens. Raw tokens are NEVER stored.
-- Only 1 active (unused + non-expired) token per user at a time.

-- ============================================================================
-- email_verifications table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.email_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  token_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);
-- Index for fast token lookup during verification
CREATE INDEX idx_email_verifications_token_hash
  ON public.email_verifications (token_hash)
  WHERE used = FALSE;
-- Index for cleanup job (expired tokens)
CREATE INDEX idx_email_verifications_expires_at
  ON public.email_verifications (expires_at)
  WHERE used = FALSE;
-- Index for invalidating previous tokens per user
CREATE INDEX idx_email_verifications_user_id
  ON public.email_verifications (user_id)
  WHERE used = FALSE;
-- ============================================================================
-- RLS Policies
-- ============================================================================

ALTER TABLE public.email_verifications ENABLE ROW LEVEL SECURITY;
-- Only service_role can access this table (all operations are server-side)
-- No policies for anon or authenticated — they go through API routes.

-- ============================================================================
-- Cleanup function: delete expired tokens
-- ============================================================================

CREATE OR REPLACE FUNCTION public.cleanup_expired_email_verifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM public.email_verifications
  WHERE expires_at < now() OR used = TRUE;

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;
-- SECURITY: Only service_role may call this function
REVOKE ALL ON FUNCTION public.cleanup_expired_email_verifications() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.cleanup_expired_email_verifications() FROM anon;
REVOKE ALL ON FUNCTION public.cleanup_expired_email_verifications() FROM authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_email_verifications() TO service_role;
-- ============================================================================
-- Scheduled cleanup via pg_cron (if available)
-- ============================================================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'cleanup-expired-email-verifications',
      '0 3 * * *',  -- Daily at 3:00 AM UTC
      'SELECT public.cleanup_expired_email_verifications()'
    );
  END IF;
END
$$;
