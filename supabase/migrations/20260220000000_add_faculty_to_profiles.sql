-- Migration: Add faculty column to profiles table
-- Faculty was supported in the frontend but missing from the database

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS faculty text;
