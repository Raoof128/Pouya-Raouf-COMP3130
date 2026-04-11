-- Migration: atomic_unit_sync
-- Purpose: Provide a robust, atomic way to sync units and their schedules
-- Date: 2026-01-22

-- Drop function if exists to allow updates
DROP FUNCTION IF EXISTS public.upsert_unit_with_schedule(jsonb, jsonb);
CREATE OR REPLACE FUNCTION public.upsert_unit_with_schedule(
    p_unit jsonb,           -- The parent unit object
    p_schedule jsonb        -- The array of class times (children)
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with owner permissions to manage the transaction safely
SET search_path = public -- Security best practice
AS $$
DECLARE
    v_unit_id uuid;
    v_result jsonb;
    v_user_id uuid;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 1. UPSERT THE UNIT (Parent)
    -- coalesce(id, gen_random_uuid()) handles new items (null ID) vs existing
    INSERT INTO units (
        id, 
        user_id, 
        code, 
        name, 
        color, 
        description, 
        location,
        created_at,
        updated_at
    )
    VALUES (
        COALESCE((p_unit->>'id')::uuid, gen_random_uuid()),
        v_user_id,
        p_unit->>'code',
        p_unit->>'name',
        COALESCE(p_unit->>'color', '#3B82F6'),
        p_unit->>'description',
        (p_unit->>'location')::jsonb,
        COALESCE((p_unit->>'created_at')::timestamptz, now()),
        now()
    )
    ON CONFLICT (id) DO UPDATE
    SET
        code = EXCLUDED.code,
        name = EXCLUDED.name,
        color = EXCLUDED.color,
        description = EXCLUDED.description,
        location = EXCLUDED.location,
        updated_at = now()
    WHERE units.user_id = v_user_id -- RLS CHECK: Only update if user owns record
    RETURNING id INTO v_unit_id;

    -- If v_unit_id is null, RLS check failed (id exists but belongs to another user)
    IF v_unit_id IS NULL THEN
        RAISE EXCEPTION 'Not authorized to update this unit';
    END IF;

    -- 2. REPLACE CHILDREN (Schedule)
    -- Atomic delete-then-insert
    DELETE FROM class_times 
    WHERE unit_id = v_unit_id;

    -- Insert new rows from JSON array
    IF jsonb_array_length(p_schedule) > 0 THEN
        INSERT INTO class_times (id, unit_id, day, start_time, end_time)
        SELECT 
            COALESCE((x->>'id')::uuid, gen_random_uuid()),
            v_unit_id,
            x->>'day',
            x->>'startTime', -- Note: matching frontend key names
            x->>'endTime'
        FROM jsonb_array_elements(p_schedule) t(x);
    END IF;

    -- 3. RETURN FULL DATA
    -- Return the reconstructed object
    SELECT jsonb_build_object(
        'id', u.id,
        'user_id', u.user_id,
        'code', u.code,
        'name', u.name,
        'color', u.color,
        'description', u.description,
        'location', u.location,
        'created_at', u.created_at,
        'updated_at', u.updated_at,
        'schedule', COALESCE((
            SELECT jsonb_agg(jsonb_build_object(
                'id', ct.id,
                'day', ct.day,
                'startTime', ct.start_time,
                'endTime', ct.end_time
            ))
            FROM class_times ct
            WHERE ct.unit_id = u.id
        ), '[]'::jsonb)
    ) INTO v_result
    FROM units u
    WHERE u.id = v_unit_id;

    RETURN v_result;
END;
$$;
-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.upsert_unit_with_schedule(jsonb, jsonb) TO authenticated;
