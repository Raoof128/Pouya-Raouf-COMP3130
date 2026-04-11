-- Backfill the legacy push_notifications flag when migration history was
-- repaired as applied on environments that already had newer reminder fields
-- but were still missing this earlier column.

ALTER TABLE public.user_preferences
ADD COLUMN IF NOT EXISTS push_notifications boolean NOT NULL DEFAULT true;
UPDATE public.user_preferences
SET push_notifications = COALESCE(push_notifications, true);
