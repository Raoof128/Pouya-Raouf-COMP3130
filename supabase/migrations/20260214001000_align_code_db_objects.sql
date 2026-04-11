-- ============================================================================
-- ALIGN CODE-REFERENCED DB OBJECTS
-- ----------------------------------------------------------------------------
-- Ensures DB objects referenced by application code exist in canonical
-- supabase/migrations history.
--
-- Added objects:
-- 1) public.user_sessions table (used by session termination logic)
-- 2) public.get_my_audit_logs RPC (used by /api/audit)
-- ============================================================================

BEGIN;
-- ---------------------------------------------------------------------------
-- user_sessions table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_info text,
  ip_address text,
  user_agent text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  last_activity_at timestamp with time zone NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_last_activity_at ON public.user_sessions(last_activity_at DESC);
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'user_sessions'
      AND policyname = 'Users can view their own sessions'
  ) THEN
    CREATE POLICY "Users can view their own sessions"
      ON public.user_sessions
      FOR SELECT
      TO authenticated
      USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'user_sessions'
      AND policyname = 'Users can insert their own sessions'
  ) THEN
    CREATE POLICY "Users can insert their own sessions"
      ON public.user_sessions
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'user_sessions'
      AND policyname = 'Users can update their own sessions'
  ) THEN
    CREATE POLICY "Users can update their own sessions"
      ON public.user_sessions
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'user_sessions'
      AND policyname = 'Users can delete their own sessions'
  ) THEN
    CREATE POLICY "Users can delete their own sessions"
      ON public.user_sessions
      FOR DELETE
      TO authenticated
      USING (auth.uid() = user_id);
  END IF;
END $$;
REVOKE ALL ON public.user_sessions FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_sessions TO authenticated;
-- ---------------------------------------------------------------------------
-- get_my_audit_logs RPC
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_my_audit_logs(
  p_limit integer DEFAULT 100,
  p_offset integer DEFAULT 0,
  p_action text DEFAULT NULL,
  p_severity text DEFAULT NULL,
  p_start_date timestamp with time zone DEFAULT NULL,
  p_end_date timestamp with time zone DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  action text,
  table_name text,
  record_id uuid,
  old_data jsonb,
  new_data jsonb,
  severity text,
  ip_address text,
  user_agent text,
  metadata jsonb,
  created_at timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    al.id,
    al.user_id,
    al.action,
    al.table_name,
    al.record_id,
    al.old_data,
    al.new_data,
    al.severity,
    al.ip_address::text,
    al.user_agent,
    al.metadata,
    al.created_at
  FROM public.audit_logs al
  WHERE al.user_id = auth.uid()
    AND (p_action IS NULL OR al.action = p_action)
    AND (p_severity IS NULL OR al.severity = p_severity)
    AND (p_start_date IS NULL OR al.created_at >= p_start_date)
    AND (p_end_date IS NULL OR al.created_at <= p_end_date)
  ORDER BY al.created_at DESC
  LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 100), 1000))
  OFFSET GREATEST(0, COALESCE(p_offset, 0));
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_my_audit_logs(
  integer,
  integer,
  text,
  text,
  timestamp with time zone,
  timestamp with time zone
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_audit_logs(
  integer,
  integer,
  text,
  text,
  timestamp with time zone,
  timestamp with time zone
) TO service_role;
COMMIT;
