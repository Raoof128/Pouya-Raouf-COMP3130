-- Migration: Create todos table for To-Do List feature
-- Purpose: Store user tasks separate from academic deadlines
-- Date: 2026-01-24

-- ============================================================================
-- TODOS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.todos (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT NOT NULL DEFAULT 'Medium',
  completed BOOLEAN NOT NULL DEFAULT FALSE,
  due_date TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT todos_pkey PRIMARY KEY (id),
  CONSTRAINT todos_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT todos_priority_check CHECK (priority IN ('Low', 'Medium', 'High'))
);
-- ============================================================================
-- INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_todos_user_id ON public.todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_completed ON public.todos(completed);
CREATE INDEX IF NOT EXISTS idx_todos_created_at ON public.todos(created_at);
CREATE INDEX IF NOT EXISTS idx_todos_deleted_at ON public.todos(deleted_at) WHERE deleted_at IS NULL;
-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;
-- Revoke default public access
REVOKE ALL ON public.todos FROM anon;
REVOKE ALL ON public.todos FROM public;
-- Grant access to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.todos TO authenticated;
-- ============================================================================
-- RLS POLICIES
-- ============================================================================
-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Users can view their own todos" ON public.todos;
DROP POLICY IF EXISTS "Users can insert their own todos" ON public.todos;
DROP POLICY IF EXISTS "Users can update their own todos" ON public.todos;
DROP POLICY IF EXISTS "Users can delete their own todos" ON public.todos;
CREATE POLICY "Users can view their own todos"
  ON public.todos FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own todos"
  ON public.todos FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own todos"
  ON public.todos FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own todos"
  ON public.todos FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
-- ============================================================================
-- UPDATED_AT TRIGGER
-- ============================================================================
DROP TRIGGER IF EXISTS update_todos_updated_at ON public.todos;
CREATE TRIGGER update_todos_updated_at
  BEFORE UPDATE ON public.todos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================
COMMENT ON TABLE public.todos IS 'User to-do items for the To-Do List widget';
COMMENT ON COLUMN public.todos.id IS 'Unique identifier for the todo item';
COMMENT ON COLUMN public.todos.user_id IS 'Reference to the owning user';
COMMENT ON COLUMN public.todos.title IS 'Title of the todo item';
COMMENT ON COLUMN public.todos.description IS 'Optional description or notes';
COMMENT ON COLUMN public.todos.priority IS 'Priority level: Low, Medium, or High';
COMMENT ON COLUMN public.todos.completed IS 'Whether the todo has been completed';
COMMENT ON COLUMN public.todos.due_date IS 'Optional due date for the todo';
COMMENT ON COLUMN public.todos.completed_at IS 'Timestamp when the task was marked complete';
COMMENT ON COLUMN public.todos.deleted_at IS 'Soft delete timestamp (null means not deleted)';
COMMENT ON COLUMN public.todos.created_at IS 'Timestamp when the todo was created';
COMMENT ON COLUMN public.todos.updated_at IS 'Timestamp when the todo was last updated';
