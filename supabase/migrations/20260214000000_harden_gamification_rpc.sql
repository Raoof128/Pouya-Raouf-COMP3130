-- ============================================================================
-- HARDEN GAMIFICATION RPC FUNCTIONS
-- ----------------------------------------------------------------------------
-- Goals:
-- 1) Prevent authenticated users from awarding XP/streak updates to other users
-- 2) Restrict direct function execution privileges
-- 3) Lock SECURITY DEFINER search_path to avoid function hijacking
-- ============================================================================

BEGIN;
CREATE OR REPLACE FUNCTION public.award_xp(
  p_user_id uuid,
  p_event_type text,
  p_reference_id uuid DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
  -- Authenticated callers may only mutate their own profile.
  IF auth.role() = 'authenticated' AND auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized XP award attempt for another user'
      USING ERRCODE = '42501';
  END IF;

  SELECT base_xp INTO v_base_xp FROM public.xp_config WHERE event_type = p_event_type;
  IF v_base_xp IS NULL THEN
    RAISE EXCEPTION 'Unknown XP event type: %', p_event_type;
  END IF;

  v_xp_amount := v_base_xp;

  INSERT INTO public.gamification_profiles (user_id)
  VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT xp, streak_days INTO v_old_xp, v_streak_days
  FROM public.gamification_profiles
  WHERE user_id = p_user_id;

  v_old_level := calculate_level(v_old_xp);

  IF p_event_type = 'streak_bonus' AND v_streak_days > 0 THEN
    v_xp_amount := v_base_xp * v_streak_days;
  END IF;

  v_new_xp := v_old_xp + v_xp_amount;
  v_new_level := calculate_level(v_new_xp);

  INSERT INTO public.xp_events (user_id, event_type, xp_amount, reference_id, metadata)
  VALUES (p_user_id, p_event_type, v_xp_amount, p_reference_id, p_metadata);

  UPDATE public.gamification_profiles
  SET xp = v_new_xp, updated_at = NOW()
  WHERE user_id = p_user_id;

  IF v_new_level > v_old_level THEN
    v_level_up_bonus := 10 * v_new_level;

    INSERT INTO public.xp_events (user_id, event_type, xp_amount, metadata)
    VALUES (
      p_user_id,
      'level_up_bonus',
      v_level_up_bonus,
      jsonb_build_object('old_level', v_old_level, 'new_level', v_new_level)
    );

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
$$;
CREATE OR REPLACE FUNCTION public.update_streak(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_last_date date;
  v_today date := CURRENT_DATE;
BEGIN
  -- Authenticated callers may only mutate their own profile.
  IF auth.role() = 'authenticated' AND auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized streak update attempt for another user'
      USING ERRCODE = '42501';
  END IF;

  INSERT INTO public.gamification_profiles (user_id)
  VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT last_activity_date INTO v_last_date
  FROM public.gamification_profiles
  WHERE user_id = p_user_id;

  IF v_last_date IS NULL THEN
    UPDATE public.gamification_profiles
    SET streak_days = 1, last_activity_date = v_today, updated_at = NOW()
    WHERE user_id = p_user_id;

    PERFORM award_xp(p_user_id, 'daily_login');
  ELSIF v_last_date = v_today THEN
    NULL;
  ELSIF v_last_date = v_today - 1 THEN
    UPDATE public.gamification_profiles
    SET streak_days = streak_days + 1,
        longest_streak = GREATEST(longest_streak, streak_days + 1),
        last_activity_date = v_today,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    PERFORM award_xp(p_user_id, 'daily_login');
    PERFORM award_xp(p_user_id, 'streak_bonus');
  ELSE
    UPDATE public.gamification_profiles
    SET streak_days = 1, last_activity_date = v_today, updated_at = NOW()
    WHERE user_id = p_user_id;

    PERFORM award_xp(p_user_id, 'daily_login');
  END IF;
END;
$$;
REVOKE ALL ON FUNCTION public.award_xp(uuid, text, uuid, jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_streak(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.award_xp(uuid, text, uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.award_xp(uuid, text, uuid, jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION public.update_streak(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_streak(uuid) TO service_role;
COMMIT;
