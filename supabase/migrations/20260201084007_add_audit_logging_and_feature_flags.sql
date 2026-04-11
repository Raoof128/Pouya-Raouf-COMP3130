-- Migration: Add Audit Logging and Feature Flags
-- Created: 2026-02-01

-- ============================================================================
-- UPGRADE 1: The "Black Box" (Audit Logging)
-- ============================================================================
-- Purpose: Create forensic trail for auth events (signups, rate limits, etc.)
-- Security: RLS enabled so only Service Role can write; no one can read directly

CREATE TABLE IF NOT EXISTS auth_audit_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_type TEXT NOT NULL, -- 'signup_attempt', 'signup_success', 'signup_validation_fail', 'rate_limit_hit', 'honeypot_triggered', 'rollback_executed'
  ip_address TEXT,
  user_agent TEXT,
  metadata JSONB DEFAULT '{}'::jsonb, -- Store email domain, failure reason, target field, etc.
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
-- Enable RLS for security
ALTER TABLE auth_audit_logs ENABLE ROW LEVEL SECURITY;
-- Create policy: Only service role can insert (no one can read)
CREATE POLICY "Service role can insert audit logs" ON auth_audit_logs
  FOR INSERT TO service_role WITH CHECK (true);
-- Create index for faster queries on event type and date
CREATE INDEX IF NOT EXISTS idx_audit_logs_event_type ON auth_audit_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON auth_audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_ip ON auth_audit_logs(ip_address);
-- ============================================================================
-- UPGRADE 2: The "Kill Switch" (Feature Flags)
-- ============================================================================
-- Purpose: Remote configuration to disable features instantly without redeploy
-- Security: RLS enabled so only Service Role can modify

CREATE TABLE IF NOT EXISTS app_config (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  value JSONB NOT NULL DEFAULT '{}'::jsonb,
  description TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);
-- Enable RLS for security
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;
-- Create policy: Only service role can manage config
CREATE POLICY "Service role can manage app config" ON app_config
  FOR ALL TO service_role USING (true) WITH CHECK (true);
-- Insert default config values
-- signup_enabled: Boolean flag to enable/disable new registrations
INSERT INTO app_config (key, value, description) VALUES
  ('signup_enabled', 'true'::jsonb, 'Master switch for new user registrations. Set to false to disable signups instantly.')
ON CONFLICT (key) DO NOTHING;
-- Create index for quick lookups
CREATE INDEX IF NOT EXISTS idx_app_config_key ON app_config(key);
-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON TABLE auth_audit_logs IS 'Security audit trail for authentication events. Used for forensic analysis and attack detection.';
COMMENT ON TABLE app_config IS 'Remote configuration store for feature flags and app settings. Allows instant changes without deployment.';
