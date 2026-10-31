-- ====================================================================
-- BRAWIGO PERMANENT ACCOUNT DELETION FUNCTION & CLEANUP SCRIPT
-- ====================================================================

-- 1. Buat / perbarui fungsi RPC delete_user_account()
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, storage
AS $$
DECLARE
  v_user_id uuid;
  v_active_orders int;
  v_target_order_ids uuid[];
  v_target_product_ids uuid[];
BEGIN
  -- Dapatkan user ID yang sedang terotentikasi
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: User belum login.';
  END IF;

  -- 1. Pastikan tidak ada transaksi aktif yang sedang berjalan
  -- CATATAN: status di-cast ke ::text agar COALESCE kompatibel dengan order_status enum!
  SELECT COUNT(*) INTO v_active_orders
  FROM public.orders
  WHERE (buyer_id = v_user_id OR seller_id = v_user_id)
    AND LOWER(COALESCE(order_status, status::text, '')) IN (
      'created', 'waiting_confirmation', 'pending', 'waiting_verification', 
      'paid', 'processing', 'courier_on_the_way', 'ready_for_pickup'
    );

  IF v_active_orders > 0 THEN
    RAISE EXCEPTION 'Tidak dapat menghapus akun karena masih ada % transaksi yang sedang berjalan.', v_active_orders;
  END IF;

  -- 2. Kumpulkan seluruh ID produk milik user
  SELECT COALESCE(ARRAY_AGG(id), '{}') INTO v_target_product_ids
  FROM public.products
  WHERE seller_id = v_user_id;

  -- 3. Kumpulkan ID order terkait user:
  -- - User sebagai buyer
  -- - User sebagai seller
  -- - Order yang membeli produk user
  -- - Order yang itemnya berasal dari toko/produk user
  SELECT COALESCE(ARRAY_AGG(id), '{}') INTO v_target_order_ids
  FROM public.orders
  WHERE buyer_id = v_user_id 
     OR seller_id = v_user_id 
     OR product_id = ANY(v_target_product_ids)
     OR id IN (
       SELECT order_id FROM public.order_items 
       WHERE seller_id = v_user_id OR product_id = ANY(v_target_product_ids)
     );

  -- 4. Hapus riwayat transaksi secara berurutan (child ke parent)
  IF array_length(v_target_order_ids, 1) > 0 THEN
    DELETE FROM public.order_items WHERE order_id = ANY(v_target_order_ids);
    DELETE FROM public.payments WHERE order_id = ANY(v_target_order_ids);
    DELETE FROM public.reviews WHERE order_id = ANY(v_target_order_ids);
  END IF;

  -- Hapus sisa order_items terkait user sebagai seller atau produk user
  DELETE FROM public.order_items 
  WHERE seller_id = v_user_id 
     OR product_id = ANY(v_target_product_ids);

  -- Hapus reviews lain terkait user / produk user
  DELETE FROM public.reviews 
  WHERE reviewer_id = v_user_id 
     OR product_id = ANY(v_target_product_ids);

  -- Hapus tabel orders
  IF array_length(v_target_order_ids, 1) > 0 THEN
    DELETE FROM public.orders WHERE id = ANY(v_target_order_ids);
  END IF;
  DELETE FROM public.orders WHERE buyer_id = v_user_id OR seller_id = v_user_id;

  -- 5. Hapus pesan & percakapan chat
  DELETE FROM public.messages 
  WHERE sender_id = v_user_id 
     OR conversation_id IN (
       SELECT id FROM public.conversations 
       WHERE buyer_id = v_user_id 
          OR seller_id = v_user_id 
          OR product_id = ANY(v_target_product_ids)
     );

  DELETE FROM public.conversations 
  WHERE buyer_id = v_user_id 
     OR seller_id = v_user_id 
     OR product_id = ANY(v_target_product_ids);

  -- 6. Hapus relasi produk user (foto produk, favorit, laporan, wishlist, keranjang)
  IF array_length(v_target_product_ids, 1) > 0 THEN
    DELETE FROM public.product_images WHERE product_id = ANY(v_target_product_ids);
    DELETE FROM public.product_favorites WHERE product_id = ANY(v_target_product_ids);
    DELETE FROM public.product_reports WHERE product_id = ANY(v_target_product_ids);
    DELETE FROM public.wishlists WHERE product_id = ANY(v_target_product_ids);
    DELETE FROM public.cart_items WHERE product_id = ANY(v_target_product_ids);
    DELETE FROM public.products WHERE id = ANY(v_target_product_ids);
  END IF;

  -- 7. Hapus keterlibatan user pada tabel lain
  DELETE FROM public.product_favorites WHERE user_id = v_user_id;
  DELETE FROM public.product_reports WHERE reporter_id = v_user_id;
  DELETE FROM public.wishlists WHERE user_id = v_user_id;
  DELETE FROM public.cart_items WHERE cart_id IN (SELECT id FROM public.carts WHERE user_id = v_user_id);
  DELETE FROM public.carts WHERE user_id = v_user_id;

  -- 8. Bersihkan storage objects milik user agar foreign key objects_owner_fkey tidak error
  BEGIN
    DELETE FROM storage.objects WHERE owner = v_user_id;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  -- 9. Hapus dari tabel profiles
  DELETE FROM public.profiles WHERE id = v_user_id;

  -- 10. Hapus akun auth secara permanen (email bebas didaftarkan ulang)
  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;

-- Berikan izin eksekusi kepada seluruh user yang sudah login (authenticated)
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;
