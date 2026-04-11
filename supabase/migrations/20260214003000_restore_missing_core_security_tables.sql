-- ============================================================================
-- RESTORE MISSING CORE SECURITY TABLES
-- ----------------------------------------------------------------------------
-- Some environments can have migration-history drift where versions exist in
-- schema_migrations but underlying objects were never created. This migration
-- restores DB objects that are actively used by application code.
-- ============================================================================

BEGIN;
-- ---------------------------------------------------------------------------
-- auth_audit_logs
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.auth_audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type text NOT NULL,
  ip_address text,
  user_agent text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_auth_audit_logs_event_type ON public.auth_audit_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_auth_audit_logs_created_at ON public.auth_audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_auth_audit_logs_ip ON public.auth_audit_logs(ip_address);
ALTER TABLE public.auth_audit_logs ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'auth_audit_logs'
      AND policyname = 'Service role can insert audit logs'
  ) THEN
    CREATE POLICY "Service role can insert audit logs"
      ON public.auth_audit_logs
      FOR INSERT
      TO service_role
      WITH CHECK (true);
  END IF;
END $$;
-- ---------------------------------------------------------------------------
-- app_config
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE,
  value jsonb NOT NULL DEFAULT '{}'::jsonb,
  description text,
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_app_config_key ON public.app_config(key);
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'app_config'
      AND policyname = 'Service role can manage app config'
  ) THEN
    CREATE POLICY "Service role can manage app config"
      ON public.app_config
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;
INSERT INTO public.app_config (key, value, description)
VALUES ('signup_enabled', 'true'::jsonb, 'Master switch for new user registrations')
ON CONFLICT (key) DO NOTHING;
-- ---------------------------------------------------------------------------
-- audit_logs
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  user_email text,
  action text NOT NULL,
  table_name text,
  record_id uuid,
  ip_address inet,
  user_agent text,
  request_id text,
  old_data jsonb,
  new_data jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  severity text NOT NULL DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical'))
);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_table_name ON public.audit_logs(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_severity ON public.audit_logs(severity);
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'audit_logs'
      AND policyname = 'Users can view own audit logs'
  ) THEN
    CREATE POLICY "Users can view own audit logs"
      ON public.audit_logs
      FOR SELECT
      TO authenticated
      USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'audit_logs'
      AND policyname = 'Service role full access to audit logs'
  ) THEN
    CREATE POLICY "Service role full access to audit logs"
      ON public.audit_logs
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;
-- ---------------------------------------------------------------------------
-- WebAuthn and backup codes tables
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.webauthn_credentials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  credential_id text NOT NULL UNIQUE,
  public_key text NOT NULL,
  counter bigint NOT NULL DEFAULT 0,
  transports text[] NOT NULL DEFAULT '{}',
  device_name text NOT NULL DEFAULT 'Passkey',
  created_at timestamptz NOT NULL DEFAULT now(),
  last_used_at timestamptz
);
CREATE INDEX IF NOT EXISTS idx_webauthn_credentials_user_id
  ON public.webauthn_credentials(user_id);
CREATE INDEX IF NOT EXISTS idx_webauthn_credentials_credential_id
  ON public.webauthn_credentials(credential_id);
CREATE TABLE IF NOT EXISTS public.webauthn_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge text NOT NULL,
  type text NOT NULL CHECK (type IN ('registration', 'authentication')),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  expires_at timestamptz NOT NULL DEFAULT (now() + INTERVAL '5 minutes'),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_webauthn_challenges_challenge
  ON public.webauthn_challenges(challenge);
CREATE INDEX IF NOT EXISTS idx_webauthn_challenges_expires_at
  ON public.webauthn_challenges(expires_at);
CREATE TABLE IF NOT EXISTS public.backup_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  code text NOT NULL,
  used boolean NOT NULL DEFAULT false,
  used_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_backup_codes_user_id ON public.backup_codes(user_id);
ALTER TABLE public.webauthn_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.webauthn_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_codes ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='webauthn_credentials'
      AND policyname='Users can view own credentials'
  ) THEN
    CREATE POLICY "Users can view own credentials"
      ON public.webauthn_credentials FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='webauthn_credentials'
      AND policyname='Users can insert own credentials'
  ) THEN
    CREATE POLICY "Users can insert own credentials"
      ON public.webauthn_credentials FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='webauthn_credentials'
      AND policyname='Users can update own credentials'
  ) THEN
    CREATE POLICY "Users can update own credentials"
      ON public.webauthn_credentials FOR UPDATE
      USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='webauthn_credentials'
      AND policyname='Users can delete own credentials'
  ) THEN
    CREATE POLICY "Users can delete own credentials"
      ON public.webauthn_credentials FOR DELETE
      USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='webauthn_credentials'
      AND policyname='Service role full access to credentials'
  ) THEN
    CREATE POLICY "Service role full access to credentials"
      ON public.webauthn_credentials FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='webauthn_challenges'
      AND policyname='Users can view own challenges'
  ) THEN
    CREATE POLICY "Users can view own challenges"
      ON public.webauthn_challenges FOR SELECT
      USING (auth.uid() = user_id OR user_id IS NULL);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='webauthn_challenges'
      AND policyname='Users can insert challenges'
  ) THEN
    CREATE POLICY "Users can insert challenges"
      ON public.webauthn_challenges FOR INSERT
      WITH CHECK (auth.uid() = user_id OR user_id IS NULL);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='webauthn_challenges'
      AND policyname='Users can delete own challenges'
  ) THEN
    CREATE POLICY "Users can delete own challenges"
      ON public.webauthn_challenges FOR DELETE
      USING (auth.uid() = user_id OR user_id IS NULL);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='webauthn_challenges'
      AND policyname='Service role full access to challenges'
  ) THEN
    CREATE POLICY "Service role full access to challenges"
      ON public.webauthn_challenges FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='backup_codes'
      AND policyname='Users can view own backup codes'
  ) THEN
    CREATE POLICY "Users can view own backup codes"
      ON public.backup_codes FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='backup_codes'
      AND policyname='Users can insert own backup codes'
  ) THEN
    CREATE POLICY "Users can insert own backup codes"
      ON public.backup_codes FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='backup_codes'
      AND policyname='Users can update own backup codes'
  ) THEN
    CREATE POLICY "Users can update own backup codes"
      ON public.backup_codes FOR UPDATE
      USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='backup_codes'
      AND policyname='Users can delete own backup codes'
  ) THEN
    CREATE POLICY "Users can delete own backup codes"
      ON public.backup_codes FOR DELETE
      USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='backup_codes'
      AND policyname='Service role full access to backup codes'
  ) THEN
    CREATE POLICY "Service role full access to backup codes"
      ON public.backup_codes FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;
COMMIT;
