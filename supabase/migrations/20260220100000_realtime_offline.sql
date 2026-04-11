-- Migration: Real-Time Collaboration & Offline Sync Support
-- Adds shared schedules, member access control, versioning for conflict resolution,
-- and enables Supabase Realtime on key tables.

-- ============================================================================
-- 1. CREATE TABLES FIRST (before any cross-referencing RLS policies)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.schedules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT 'My Schedule',
  description TEXT,
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_schedules_owner ON public.schedules(owner_id);
CREATE TABLE IF NOT EXISTS public.schedule_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  schedule_id UUID NOT NULL REFERENCES public.schedules(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('viewer', 'editor', 'owner')) DEFAULT 'viewer',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(schedule_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_schedule_members_schedule ON public.schedule_members(schedule_id);
CREATE INDEX IF NOT EXISTS idx_schedule_members_user ON public.schedule_members(user_id);
-- ============================================================================
-- 2. RLS POLICIES (both tables exist now, safe to cross-reference)
-- ============================================================================

ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own schedules"
  ON public.schedules FOR SELECT
  USING (owner_id = auth.uid());
CREATE POLICY "Users can view shared schedules"
  ON public.schedules FOR SELECT
  USING (
    id IN (SELECT schedule_id FROM public.schedule_members WHERE user_id = auth.uid())
  );
CREATE POLICY "Users can create own schedules"
  ON public.schedules FOR INSERT
  WITH CHECK (owner_id = auth.uid());
CREATE POLICY "Owners can update own schedules"
  ON public.schedules FOR UPDATE
  USING (owner_id = auth.uid());
CREATE POLICY "Owners can delete own schedules"
  ON public.schedules FOR DELETE
  USING (owner_id = auth.uid());
ALTER TABLE public.schedule_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members can view their memberships"
  ON public.schedule_members FOR SELECT
  USING (user_id = auth.uid());
CREATE POLICY "Schedule owners can view all members"
  ON public.schedule_members FOR SELECT
  USING (
    schedule_id IN (SELECT id FROM public.schedules WHERE owner_id = auth.uid())
  );
CREATE POLICY "Schedule owners can manage members"
  ON public.schedule_members FOR INSERT
  WITH CHECK (
    schedule_id IN (SELECT id FROM public.schedules WHERE owner_id = auth.uid())
  );
CREATE POLICY "Schedule owners can update members"
  ON public.schedule_members FOR UPDATE
  USING (
    schedule_id IN (SELECT id FROM public.schedules WHERE owner_id = auth.uid())
  );
CREATE POLICY "Schedule owners can remove members"
  ON public.schedule_members FOR DELETE
  USING (
    schedule_id IN (SELECT id FROM public.schedules WHERE owner_id = auth.uid())
  );
-- ============================================================================
-- 3. VERSIONING FOR OFFLINE CONFLICT RESOLUTION
-- ============================================================================

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS version INT DEFAULT 1,
  ADD COLUMN IF NOT EXISTS last_modified_by UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS schedule_id UUID REFERENCES public.schedules(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_events_schedule ON public.events(schedule_id);
CREATE INDEX IF NOT EXISTS idx_events_version ON public.events(id, version);
-- ============================================================================
-- 4. ENABLE SUPABASE REALTIME
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'events'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.events;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'schedule_members'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.schedule_members;
  END IF;
END
$$;
