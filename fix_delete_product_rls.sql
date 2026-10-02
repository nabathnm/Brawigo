-- ============================================================
-- FIX: Gagal menghapus produk dari aplikasi (Brawigo)
-- Jalankan di: Supabase Dashboard -> SQL Editor -> Run
-- ============================================================
--
-- Gejala:
--   Halaman seller menampilkan merah:
--   "Gagal menghapus produk: ... Produk tidak ditemukan atau
--    tidak memiliki izin untuk dihapus."
--
-- Akar masalah (sudah diverifikasi langsung ke backend Supabase):
--   - Delete produk memakai role ANON BISA: baris benar-benar
--     terhapus dari tabel products, dan baris product_images
--     terhapus otomatis (FK cascade).
--   - Delete produk dari aplikasi (role AUTHENTICATED, sesudah
--     login) menghasilkan 0 baris terhapus -> PostgREST mengembalikan
--     [] -> kode aplikasi (marketplace_bloc.dart) melempar error izin.
--   - Tabel products punya RLS aktif, tetapi role authenticated
--     TIDAK punya policy DELETE (policy yang ada hanya untuk role
--     anon / policy DELETE belum pernah dibuat).
--   - Tabel orders, order_items, cart_items, conversations, dan
--     product_reviews kosong -> bukan ini penyebabnya.
--
-- Solusi: tambahkan policy DELETE untuk role authenticated dengan
-- aturan otorisasi berbasis pemilik (server-side), sesuai arsitektur
-- Brawigo (validasi & otorisasi di server).

-- 1) products: hanya pemilik (seller_id = auth.uid()) yang boleh menghapus
drop policy if exists "Sellers can delete own products" on public.products;
create policy "Sellers can delete own products"
  on public.products
  for delete
  to authenticated
  using (auth.uid() = seller_id);

-- 2) product_images: baris gambar milik produk yang dimiliki seller
--    (dipakai saat update produk menghapus gambar lama dari DB)
drop policy if exists "Sellers can delete own product images" on public.product_images;
create policy "Sellers can delete own product images"
  on public.product_images
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.products p
      where p.id = product_images.product_id
        and p.seller_id = auth.uid()
    )
  );

-- Verifikasi:
--   1. Run SQL di atas di SQL Editor (harus sukses tanpa error).
--   2. Buka aplikasi -> seller -> Hapus Produk -> pilih "Hapus".
--   3. Produk harus hilang dari daftar dan muncul snackbar hijau
--      "Produk berhasil dihapus".
--   Jika masih gagal, salin teks error LENGKAP setelah
--   "Gagal menghapus produk:" untuk diagnosa lanjutan.
