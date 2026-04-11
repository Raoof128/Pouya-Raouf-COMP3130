-- WebAuthn / Passkey Tables Migration
-- Creates tables for storing WebAuthn credentials and challenges
-- Supports multiple passkeys per user with proper security constraints

-- ============================================================================
-- webauthn_credentials: Stores registered passkey credentials
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.webauthn_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  credential_id TEXT NOT NULL,
  public_key TEXT NOT NULL,
  counter BIGINT NOT NULL DEFAULT 0,
  transports TEXT[] DEFAULT '{}',
  device_name TEXT NOT NULL DEFAULT 'Passkey',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_used_at TIMESTAMPTZ,
  CONSTRAINT webauthn_credentials_credential_id_unique UNIQUE (credential_id)
);
-- Index for quick lookup by user
CREATE INDEX IF NOT EXISTS idx_webauthn_credentials_user_id
  ON public.webauthn_credentials(user_id);
-- Index for credential lookup during authentication
CREATE INDEX IF NOT EXISTS idx_webauthn_credentials_credential_id
  ON public.webauthn_credentials(credential_id);
-- ============================================================================
-- webauthn_challenges: Short-lived challenges for registration/authentication
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.webauthn_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('registration', 'authentication')),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '5 minutes'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Index for challenge lookup
CREATE INDEX IF NOT EXISTS idx_webauthn_challenges_challenge
  ON public.webauthn_challenges(challenge);
-- Auto-cleanup expired challenges (5-minute TTL)
CREATE INDEX IF NOT EXISTS idx_webauthn_challenges_expires_at
  ON public.webauthn_challenges(expires_at);
-- ============================================================================
-- backup_codes: For MFA backup codes (if table doesn't exist)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.backup_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  used BOOLEAN NOT NULL DEFAULT false,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_backup_codes_user_id
  ON public.backup_codes(user_id);
-- ============================================================================
-- RLS Policies
-- ============================================================================

-- Enable RLS
ALTER TABLE public.webauthn_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.webauthn_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_codes ENABLE ROW LEVEL SECURITY;
-- webauthn_credentials: Users can only see/manage their own credentials
CREATE POLICY "Users can view own credentials"
  ON public.webauthn_credentials
  FOR SELECT
  USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own credentials"
  ON public.webauthn_credentials
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own credentials"
  ON public.webauthn_credentials
  FOR DELETE
  USING (auth.uid() = user_id);
CREATE POLICY "Users can update own credentials"
  ON public.webauthn_credentials
  FOR UPDATE
  USING (auth.uid() = user_id);
-- webauthn_challenges: Allow authenticated users to create and read challenges
CREATE POLICY "Users can view own challenges"
  ON public.webauthn_challenges
  FOR SELECT
  USING (auth.uid() = user_id OR user_id IS NULL);
CREATE POLICY "Users can insert challenges"
  ON public.webauthn_challenges
  FOR INSERT
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);
CREATE POLICY "Users can delete own challenges"
  ON public.webauthn_challenges
  FOR DELETE
  USING (auth.uid() = user_id OR user_id IS NULL);
-- backup_codes: Users can only manage their own backup codes
CREATE POLICY "Users can view own backup codes"
  ON public.backup_codes
  FOR SELECT
  USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own backup codes"
  ON public.backup_codes
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own backup codes"
  ON public.backup_codes
  FOR UPDATE
  USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own backup codes"
  ON public.backup_codes
  FOR DELETE
  USING (auth.uid() = user_id);
-- ============================================================================
-- Service role bypass for server-side operations (admin client)
-- ============================================================================

-- Allow service_role to manage all webauthn data (needed for login flow
-- where user is not yet authenticated)
CREATE POLICY "Service role full access to credentials"
  ON public.webauthn_credentials
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
CREATE POLICY "Service role full access to challenges"
  ON public.webauthn_challenges
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
CREATE POLICY "Service role full access to backup codes"
  ON public.backup_codes
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
-- ============================================================================
-- Cleanup function: Remove expired challenges
-- ============================================================================
CREATE OR REPLACE FUNCTION public.cleanup_expired_webauthn_challenges()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.webauthn_challenges
  WHERE expires_at < now();
END;
$$;
