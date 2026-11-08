-- ============================================================
-- MIGRATION: Fix RLS on product_reports
-- Jalankan file ini di Supabase Dashboard > SQL Editor
-- ============================================================

-- 1. Pastikan RLS aktif
ALTER TABLE public.product_reports ENABLE ROW LEVEL SECURITY;

-- 2. Hapus policy SELECT lama yang membatasi pembacaan hanya kepada pelapor
DROP POLICY IF EXISTS "Users can view own reports" ON public.product_reports;
DROP POLICY IF EXISTS "Anyone can view product reports" ON public.product_reports;
DROP POLICY IF EXISTS "Allow read product_reports" ON public.product_reports;
DROP POLICY IF EXISTS "Sellers and reporters can view reports" ON public.product_reports;

-- 3. Izinkan pembacaan product_reports agar:
-- - Penjual dapat melihat seluruh laporan pelanggaran produk tokonya di Beranda & Detail
-- - Pembeli lain dapat melihat transparansi riwayat laporan toko saat mengunjungi profil penjual
CREATE POLICY "Anyone can view product reports"
  ON public.product_reports FOR SELECT
  USING (true);

-- 4. Pastikan policy INSERT mengizinkan pelapor menambahkan laporan
DROP POLICY IF EXISTS "Users can insert reports" ON public.product_reports;
CREATE POLICY "Users can insert reports"
  ON public.product_reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

