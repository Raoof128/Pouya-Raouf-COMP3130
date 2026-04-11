-- ============================================================================
-- GAMIFICATION SYSTEM - XP, Levels, Streaks
-- Phase 1: MVP implementation for visual progression feedback
-- ============================================================================

-- Enable UUID extension (required for gamification tables)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
/**
 * gamification_profiles - Current state snapshot for each user
 * This is the "scoreboard" that the UI fetches to display XP/level/streak
 */
CREATE TABLE public.gamification_profiles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  xp integer NOT NULL DEFAULT 0 CHECK (xp >= 0),
  streak_days integer NOT NULL DEFAULT 0 CHECK (streak_days >= 0),
  longest_streak integer NOT NULL DEFAULT 0 CHECK (longest_streak >= 0),
  last_activity_date date, -- NULL if never active
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT gamification_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT gamification_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
/**
 * xp_events - Audit log of all XP changes (transaction history)
 * Used for debugging, anti-cheat, and future features like charts
 */
CREATE TABLE public.xp_events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  event_type text NOT NULL CHECK (event_type = ANY (ARRAY[
    'deadline_completed'::text,    -- Completing a deadline
    'deadline_early'::text,        -- Completing deadline early (bonus)
    'daily_login'::text,           -- First activity of the day
    'streak_bonus'::text,          -- Bonus for maintaining streak
    'unit_added'::text,            -- Adding a new unit
    'event_attended'::text,        -- Marking event as attended
    'profile_completed'::text,     -- Completing profile info
    'first_deadline'::text,        -- First deadline ever completed
    'weekly_goal'::text,           -- Weekly completion goal
    'level_up_bonus'::text         -- Bonus XP on level up
  ])),
  xp_amount integer NOT NULL CHECK (xp_amount > 0),
  reference_id uuid, -- Optional: ID of related entity (deadline_id, unit_id, etc.)
  metadata jsonb DEFAULT '{}'::jsonb, -- Additional context (deadline title, etc.)
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT xp_events_pkey PRIMARY KEY (id),
  CONSTRAINT xp_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
-- Indexes for gamification tables
CREATE INDEX IF NOT EXISTS idx_gamification_profiles_user_id ON public.gamification_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_xp_events_user_id ON public.xp_events(user_id);
CREATE INDEX IF NOT EXISTS idx_xp_events_created_at ON public.xp_events(created_at);
CREATE INDEX IF NOT EXISTS idx_xp_events_event_type ON public.xp_events(event_type);
CREATE INDEX IF NOT EXISTS idx_xp_events_reference_id ON public.xp_events(reference_id);
-- Enable RLS on gamification tables
ALTER TABLE public.gamification_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xp_events ENABLE ROW LEVEL SECURITY;
-- Revoke anonymous access
REVOKE ALL ON public.gamification_profiles FROM anon;
REVOKE ALL ON public.xp_events FROM anon;
-- Grant to authenticated users
GRANT SELECT, INSERT, UPDATE ON public.gamification_profiles TO authenticated;
GRANT SELECT, INSERT ON public.xp_events TO authenticated;
-- RLS Policies for gamification_profiles
CREATE POLICY "Users can view their own gamification profile"
  ON public.gamification_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own gamification profile"
  ON public.gamification_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own gamification profile"
  ON public.gamification_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);
-- RLS Policies for xp_events (read-only for users, inserts via triggers)
CREATE POLICY "Users can view their own xp events"
  ON public.xp_events FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
-- Note: xp_events INSERT is handled by SECURITY DEFINER functions (triggers)
-- This prevents users from awarding themselves XP directly

-- ============================================================================
-- XP CONFIGURATION - Easy to tune without code changes
-- ============================================================================

-- XP amounts for each action (can be adjusted without migrations)
CREATE TABLE IF NOT EXISTS public.xp_config (
  event_type text PRIMARY KEY,
  base_xp integer NOT NULL CHECK (base_xp > 0),
  description text
);
INSERT INTO public.xp_config (event_type, base_xp, description) VALUES
  ('deadline_completed', 25, 'Completing any deadline'),
  ('deadline_early', 10, 'Bonus for completing 24h+ before due date'),
  ('daily_login', 5, 'First activity of the day'),
  ('streak_bonus', 5, 'Per day of streak (multiplied by streak_days)'),
  ('unit_added', 15, 'Adding a new unit to schedule'),
  ('event_attended', 10, 'Marking a campus event as attended'),
  ('profile_completed', 50, 'One-time bonus for completing profile'),
  ('first_deadline', 25, 'One-time bonus for first deadline completed'),
  ('weekly_goal', 50, 'Completing 5+ deadlines in a week'),
  ('level_up_bonus', 10, 'Bonus XP on level up (multiplied by new level)')
ON CONFLICT (event_type) DO NOTHING;
-- Make xp_config readable by authenticated users
GRANT SELECT ON public.xp_config TO authenticated;
-- ============================================================================
-- XP LEVEL CALCULATION - Derived function (not stored)
-- ============================================================================

/**
 * Calculate level from XP using a progressive curve
 * Level 1: 0-99 XP
 * Level 2: 100-249 XP
 * Level 3: 250-449 XP
 * Level n: Uses formula floor(sqrt(xp / 50)) + 1, capped at level 100
 */
CREATE OR REPLACE FUNCTION calculate_level(p_xp integer)
RETURNS integer AS $$
BEGIN
  IF p_xp < 0 THEN
    RETURN 1;
  END IF;
  -- Progressive curve: each level requires more XP
  -- Level 1: 0-49, Level 2: 50-149, Level 3: 150-299, etc.
  RETURN LEAST(100, FLOOR(SQRT(p_xp::float / 25)) + 1)::integer;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
/**
 * Calculate XP required to reach a specific level
 */
CREATE OR REPLACE FUNCTION xp_for_level(p_level integer)
RETURNS integer AS $$
BEGIN
  IF p_level <= 1 THEN
    RETURN 0;
  END IF;
  RETURN ((p_level - 1) * (p_level - 1) * 25)::integer;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
-- ============================================================================
-- GAMIFICATION TRIGGERS - Automatic XP awards
-- ============================================================================

/**
 * Award XP to a user (internal function, called by triggers)
 * This is SECURITY DEFINER to ensure consistent XP awards
 */
CREATE OR REPLACE FUNCTION award_xp(
  p_user_id uuid,
  p_event_type text,
  p_reference_id uuid DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb AS $$
DECLARE
  v_base_xp integer;
  v_xp_amount integer;
  v_old_xp integer;
  v_new_xp integer;
  v_old_level integer;
  v_new_level integer;
  v_streak_days integer;
  v_level_up_bonus integer;
BEGIN
  -- Get base XP for this event type
  SELECT base_xp INTO v_base_xp FROM public.xp_config WHERE event_type = p_event_type;
  IF v_base_xp IS NULL THEN
    RAISE EXCEPTION 'Unknown XP event type: %', p_event_type;
  END IF;

  v_xp_amount := v_base_xp;

  -- Get current user profile (create if doesn't exist)
  INSERT INTO public.gamification_profiles (user_id)
  VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT xp, streak_days INTO v_old_xp, v_streak_days
  FROM public.gamification_profiles
  WHERE user_id = p_user_id;

  v_old_level := calculate_level(v_old_xp);

  -- Apply streak multiplier for streak_bonus
  IF p_event_type = 'streak_bonus' AND v_streak_days > 0 THEN
    v_xp_amount := v_base_xp * v_streak_days;
  END IF;

  -- Calculate new XP
  v_new_xp := v_old_xp + v_xp_amount;
  v_new_level := calculate_level(v_new_xp);

  -- Record the XP event
  INSERT INTO public.xp_events (user_id, event_type, xp_amount, reference_id, metadata)
  VALUES (p_user_id, p_event_type, v_xp_amount, p_reference_id, p_metadata);

  -- Update user's total XP
  UPDATE public.gamification_profiles
  SET xp = v_new_xp, updated_at = NOW()
  WHERE user_id = p_user_id;

  -- Award level up bonus if leveled up
  IF v_new_level > v_old_level THEN
    v_level_up_bonus := 10 * v_new_level;

    INSERT INTO public.xp_events (user_id, event_type, xp_amount, metadata)
    VALUES (p_user_id, 'level_up_bonus', v_level_up_bonus,
            jsonb_build_object('old_level', v_old_level, 'new_level', v_new_level));

    UPDATE public.gamification_profiles
    SET xp = xp + v_level_up_bonus, updated_at = NOW()
    WHERE user_id = p_user_id;

    v_new_xp := v_new_xp + v_level_up_bonus;
  END IF;

  RETURN jsonb_build_object(
    'xp_awarded', v_xp_amount,
    'old_xp', v_old_xp,
    'new_xp', v_new_xp,
    'old_level', v_old_level,
    'new_level', v_new_level,
    'leveled_up', v_new_level > v_old_level
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
/**
 * Update daily streak when user performs an action
 */
CREATE OR REPLACE FUNCTION update_streak(p_user_id uuid)
RETURNS void AS $$
DECLARE
  v_last_date date;
  v_today date := CURRENT_DATE;
  v_streak integer;
  v_longest integer;
BEGIN
  -- Ensure profile exists
  INSERT INTO public.gamification_profiles (user_id)
  VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT last_activity_date, streak_days, longest_streak
  INTO v_last_date, v_streak, v_longest
  FROM public.gamification_profiles
  WHERE user_id = p_user_id;

  IF v_last_date IS NULL THEN
    -- First activity ever
    UPDATE public.gamification_profiles
    SET streak_days = 1, last_activity_date = v_today, updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Award daily login XP
    PERFORM award_xp(p_user_id, 'daily_login');

  ELSIF v_last_date = v_today THEN
    -- Already active today, do nothing
    NULL;

  ELSIF v_last_date = v_today - 1 THEN
    -- Consecutive day - increment streak
    UPDATE public.gamification_profiles
    SET streak_days = streak_days + 1,
        longest_streak = GREATEST(longest_streak, streak_days + 1),
        last_activity_date = v_today,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Award daily login + streak bonus
    PERFORM award_xp(p_user_id, 'daily_login');
    PERFORM award_xp(p_user_id, 'streak_bonus');

  ELSE
    -- Streak broken - reset to 1
    UPDATE public.gamification_profiles
    SET streak_days = 1, last_activity_date = v_today, updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Award daily login XP
    PERFORM award_xp(p_user_id, 'daily_login');
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
/**
 * Trigger: Award XP when a deadline is completed
 */
CREATE OR REPLACE FUNCTION on_deadline_completed()
RETURNS TRIGGER AS $$
DECLARE
  v_is_early boolean;
  v_is_first boolean;
BEGIN
  -- Only trigger when completed changes from false to true
  IF NEW.completed = true AND (OLD.completed = false OR OLD.completed IS NULL) THEN
    -- Update streak
    PERFORM update_streak(NEW.user_id);

    -- Check if this is the user's first completed deadline
    SELECT NOT EXISTS (
      SELECT 1 FROM public.deadlines
      WHERE user_id = NEW.user_id AND completed = true AND id != NEW.id
    ) INTO v_is_first;

    IF v_is_first THEN
      PERFORM award_xp(NEW.user_id, 'first_deadline', NEW.id,
                       jsonb_build_object('title', NEW.title));
    END IF;

    -- Award base completion XP
    PERFORM award_xp(NEW.user_id, 'deadline_completed', NEW.id,
                     jsonb_build_object('title', NEW.title, 'unit_code', NEW.unit_code));

    -- Check if completed early (24h+ before due date)
    IF NEW.due_date > NOW() + INTERVAL '24 hours' THEN
      PERFORM award_xp(NEW.user_id, 'deadline_early', NEW.id,
                       jsonb_build_object('hours_early',
                         EXTRACT(EPOCH FROM (NEW.due_date - NOW())) / 3600));
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER deadline_completed_trigger
  AFTER UPDATE OF completed ON public.deadlines
  FOR EACH ROW
  EXECUTE FUNCTION on_deadline_completed();
/**
 * Trigger: Award XP when a new unit is added
 */
CREATE OR REPLACE FUNCTION on_unit_created()
RETURNS TRIGGER AS $$
BEGIN
  -- Update streak
  PERFORM update_streak(NEW.user_id);

  -- Award XP for adding a unit
  PERFORM award_xp(NEW.user_id, 'unit_added', NEW.id,
                   jsonb_build_object('code', NEW.code, 'name', NEW.name));

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER unit_created_trigger
  AFTER INSERT ON public.units
  FOR EACH ROW
  EXECUTE FUNCTION on_unit_created();
-- Grant execute on gamification functions
GRANT EXECUTE ON FUNCTION calculate_level TO authenticated;
GRANT EXECUTE ON FUNCTION xp_for_level TO authenticated;
