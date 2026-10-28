-- ============================================================
-- MIGRATION: Create wishlists table for Brawigo
-- Run this in Supabase Dashboard > SQL Editor
-- ============================================================

-- 1. Create wishlists table
CREATE TABLE IF NOT EXISTS public.wishlists (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id  UUID        NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Prevent duplicate wishlist entries
  CONSTRAINT wishlists_user_product_unique UNIQUE (user_id, product_id)
);

-- 2. Enable Row Level Security
ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies: users can only see and manage their own wishlists
CREATE POLICY "Users can view own wishlists"
  ON public.wishlists FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own wishlists"
  ON public.wishlists FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own wishlists"
  ON public.wishlists FOR DELETE
  USING (auth.uid() = user_id);

-- 4. Index for fast lookup
CREATE INDEX IF NOT EXISTS wishlists_user_id_idx ON public.wishlists(user_id);
CREATE INDEX IF NOT EXISTS wishlists_product_id_idx ON public.wishlists(product_id);

-- ============================================================
-- OPTIONAL: Add deleted_at column to profiles (for soft-delete)
-- This allows account deletion without removing the auth user
-- ============================================================
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

