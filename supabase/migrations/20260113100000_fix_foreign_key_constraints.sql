-- ============================================================================
-- FIX FOREIGN KEY CONSTRAINTS ON UNITS AND OTHER TABLES
-- ============================================================================
-- The units_user_id_fkey constraint is failing even for valid users.
-- This migration drops and recreates the FK constraints properly.
-- ============================================================================

-- ============================================================================
-- STEP 1: Check and fix units table FK
-- ============================================================================

-- Drop the broken FK constraint
ALTER TABLE public.units DROP CONSTRAINT IF EXISTS units_user_id_fkey;
-- Recreate it properly referencing auth.users
ALTER TABLE public.units 
ADD CONSTRAINT units_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- ============================================================================
-- STEP 2: Check and fix deadlines table FK
-- ============================================================================

-- Drop if exists
ALTER TABLE public.deadlines DROP CONSTRAINT IF EXISTS deadlines_user_id_fkey;
-- Recreate properly
ALTER TABLE public.deadlines 
ADD CONSTRAINT deadlines_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- ============================================================================
-- STEP 3: Fix events table FK
-- ============================================================================

ALTER TABLE public.events DROP CONSTRAINT IF EXISTS events_user_id_fkey;
ALTER TABLE public.events 
ADD CONSTRAINT events_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- ============================================================================
-- STEP 4: Fix notifications table FK
-- ============================================================================

ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;
ALTER TABLE public.notifications 
ADD CONSTRAINT notifications_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- ============================================================================
-- STEP 5: Fix user_preferences table FK
-- ============================================================================

ALTER TABLE public.user_preferences DROP CONSTRAINT IF EXISTS user_preferences_user_id_fkey;
ALTER TABLE public.user_preferences 
ADD CONSTRAINT user_preferences_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- ============================================================================
-- STEP 6: Fix profiles table FK (uses id, not user_id)
-- ============================================================================

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE public.profiles 
ADD CONSTRAINT profiles_id_fkey 
FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- ============================================================================
-- STEP 7: Fix gamification_profiles table FK
-- ============================================================================

ALTER TABLE public.gamification_profiles DROP CONSTRAINT IF EXISTS gamification_profiles_user_id_fkey;
ALTER TABLE public.gamification_profiles 
ADD CONSTRAINT gamification_profiles_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- ============================================================================
-- STEP 8: Fix xp_events table FK
-- ============================================================================

ALTER TABLE public.xp_events DROP CONSTRAINT IF EXISTS xp_events_user_id_fkey;
ALTER TABLE public.xp_events 
ADD CONSTRAINT xp_events_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
-- ============================================================================
-- VERIFICATION: Run this query to verify all FKs are correct
-- ============================================================================
/*
SELECT
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_schema AS foreign_table_schema,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name;
*/;
