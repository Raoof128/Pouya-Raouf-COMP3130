-- Migration: Fix profile protection trigger to allow student_id changes
-- The previous trigger blocked ALL student_id changes after initial set,
-- which prevented users from correcting their student ID.
-- Now only email is immutable (must be changed via auth flow).

CREATE OR REPLACE FUNCTION protect_profile_fields()
RETURNS TRIGGER AS $$
BEGIN
  -- Prevent changing email directly (must use the authentication flow)
  IF NEW.email IS DISTINCT FROM OLD.email THEN
    RAISE EXCEPTION 'Cannot modify email directly. Use the authentication flow.';
  END IF;

  -- Auto-update the updated_at timestamp
  NEW.updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
