-- Create user profile function for signup flow
-- This SECURITY DEFINER function bypasses RLS to allow profile creation during user registration

CREATE OR REPLACE FUNCTION create_user_profile(
  p_user_id uuid,
  p_email text,
  p_full_name text DEFAULT NULL,
  p_student_id text DEFAULT NULL
)
RETURNS jsonb AS $$
DECLARE
  v_result jsonb;
BEGIN
  -- Validate that the caller is creating their own profile
  IF p_user_id != auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized: Cannot create profile for another user';
  END IF;

  -- Insert the profile
  INSERT INTO public.profiles (id, email, full_name, student_id)
  VALUES (p_user_id, p_email, p_full_name, p_student_id);

  -- Return success
  v_result := jsonb_build_object(
    'success', true,
    'profile_id', p_user_id,
    'message', 'Profile created successfully'
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_user_profile TO authenticated;
