ALTER TABLE public.user_preferences
ADD COLUMN IF NOT EXISTS push_notifications boolean DEFAULT true;
UPDATE public.user_preferences
SET push_notifications = true
WHERE push_notifications IS NULL;
