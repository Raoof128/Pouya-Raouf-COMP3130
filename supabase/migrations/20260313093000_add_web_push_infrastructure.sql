-- Web push infrastructure for background reminder delivery.
-- Adds subscription storage plus durable reminder preference fields required by
-- cron-driven push notifications when the browser tab is closed.

ALTER TABLE public.user_preferences
ADD COLUMN IF NOT EXISTS deadline_notifications_enabled boolean NOT NULL DEFAULT true,
ADD COLUMN IF NOT EXISTS class_notifications_enabled boolean NOT NULL DEFAULT true,
ADD COLUMN IF NOT EXISTS event_notifications_enabled boolean NOT NULL DEFAULT true,
ADD COLUMN IF NOT EXISTS deadline_reminder_timing_minutes integer NOT NULL DEFAULT 1440,
ADD COLUMN IF NOT EXISTS class_reminder_timing_minutes integer NOT NULL DEFAULT 15,
ADD COLUMN IF NOT EXISTS event_reminder_timing_minutes integer NOT NULL DEFAULT 60;
UPDATE public.user_preferences
SET deadline_notifications_enabled = COALESCE(deadline_notifications_enabled, true),
    class_notifications_enabled = COALESCE(class_notifications_enabled, true),
    event_notifications_enabled = COALESCE(event_notifications_enabled, true),
    deadline_reminder_timing_minutes = COALESCE(deadline_reminder_timing_minutes, 1440),
    class_reminder_timing_minutes = COALESCE(class_reminder_timing_minutes, 15),
    event_reminder_timing_minutes = COALESCE(event_reminder_timing_minutes, 60);
ALTER TABLE public.user_preferences
ADD CONSTRAINT user_preferences_deadline_timing_positive
  CHECK (deadline_reminder_timing_minutes >= 0),
ADD CONSTRAINT user_preferences_class_timing_positive
  CHECK (class_reminder_timing_minutes >= 0),
ADD CONSTRAINT user_preferences_event_timing_positive
  CHECK (event_reminder_timing_minutes >= 0);
CREATE TABLE IF NOT EXISTS public.push_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  endpoint text NOT NULL UNIQUE,
  p256dh_key text NOT NULL,
  auth_key text NOT NULL,
  expiration_time timestamp with time zone,
  user_agent text,
  failure_count integer NOT NULL DEFAULT 0 CHECK (failure_count >= 0),
  last_success_at timestamp with time zone,
  last_failure_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_push_subscriptions_user_id
  ON public.push_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_push_subscriptions_updated_at
  ON public.push_subscriptions(updated_at DESC);
CREATE TABLE IF NOT EXISTS public.push_reminder_deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reminder_key text NOT NULL UNIQUE,
  reminder_type text NOT NULL CHECK (
    reminder_type = ANY (ARRAY['deadline'::text, 'event'::text, 'class'::text])
  ),
  related_id uuid,
  scheduled_for timestamp with time zone NOT NULL,
  sent_at timestamp with time zone NOT NULL DEFAULT now(),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX IF NOT EXISTS idx_push_reminder_deliveries_user_id
  ON public.push_reminder_deliveries(user_id);
CREATE INDEX IF NOT EXISTS idx_push_reminder_deliveries_sent_at
  ON public.push_reminder_deliveries(sent_at DESC);
ALTER TABLE public.push_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_reminder_deliveries ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.push_subscriptions FROM anon;
REVOKE ALL ON public.push_subscriptions FROM authenticated;
REVOKE ALL ON public.push_reminder_deliveries FROM anon;
REVOKE ALL ON public.push_reminder_deliveries FROM authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.push_subscriptions TO authenticated;
GRANT SELECT ON public.push_reminder_deliveries TO authenticated;
DROP POLICY IF EXISTS "Users can view their own push subscriptions" ON public.push_subscriptions;
DROP POLICY IF EXISTS "Users can insert their own push subscriptions" ON public.push_subscriptions;
DROP POLICY IF EXISTS "Users can update their own push subscriptions" ON public.push_subscriptions;
DROP POLICY IF EXISTS "Users can delete their own push subscriptions" ON public.push_subscriptions;
DROP POLICY IF EXISTS "Users can view their own push reminder deliveries" ON public.push_reminder_deliveries;
CREATE POLICY "Users can view their own push subscriptions"
  ON public.push_subscriptions FOR SELECT
  USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own push subscriptions"
  ON public.push_subscriptions FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own push subscriptions"
  ON public.push_subscriptions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own push subscriptions"
  ON public.push_subscriptions FOR DELETE
  USING (auth.uid() = user_id);
CREATE POLICY "Users can view their own push reminder deliveries"
  ON public.push_reminder_deliveries FOR SELECT
  USING (auth.uid() = user_id);
