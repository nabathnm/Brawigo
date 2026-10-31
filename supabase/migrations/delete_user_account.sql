-- ====================================================================
-- BRAWIGO PERMANENT ACCOUNT DELETION FUNCTION & CLEANUP SCRIPT
-- ====================================================================

-- 1. Buat atau perbarui fungsi RPC delete_user_account()
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid;
  v_active_orders int;
  v_target_order_ids uuid[];
  v_target_product_ids uuid[];
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: User belum login.';
  END IF;

  -- 1. Cek apakah ada transaksi aktif yang sedang berjalan
  SELECT COUNT(*) INTO v_active_orders
  FROM public.orders
  WHERE (buyer_id = v_user_id OR seller_id = v_user_id)
    AND LOWER(COALESCE(order_status, status, '')) IN (
      'created', 'waiting_confirmation', 'pending', 'waiting_verification', 
      'paid', 'processing', 'courier_on_the_way', 'ready_for_pickup'
    );

  IF v_active_orders > 0 THEN
    RAISE EXCEPTION 'Tidak dapat menghapus akun karena masih ada % transaksi yang sedang berjalan.', v_active_orders;
  END IF;

  -- 2. Kumpulkan ID produk milik user
  SELECT COALESCE(ARRAY_AGG(id), '{}') INTO v_target_product_ids
  FROM public.products
  WHERE seller_id = v_user_id;

  -- 3. Kumpulkan ID order terkait user (sebagai buyer, seller, atau yang membeli produk user)
  SELECT COALESCE(ARRAY_AGG(id), '{}') INTO v_target_order_ids
  FROM public.orders
  WHERE buyer_id = v_user_id 
     OR seller_id = v_user_id 
     OR product_id = ANY(v_target_product_ids);

  -- 4. Hapus riwayat transaksi secara berurutan dari child ke parent
  IF array_length(v_target_order_ids, 1) > 0 THEN
    DELETE FROM public.order_items WHERE order_id = ANY(v_target_order_ids);
    DELETE FROM public.payments WHERE order_id = ANY(v_target_order_ids);
    DELETE FROM public.reviews WHERE order_id = ANY(v_target_order_ids);
  END IF;

  -- Hapus reviews lain dari user atau ke produk user
  DELETE FROM public.reviews 
  WHERE reviewer_id = v_user_id 
     OR product_id = ANY(v_target_product_ids);

  -- Hapus order_items dari produk user yang mungkin belum terhapus
  IF array_length(v_target_product_ids, 1) > 0 THEN
    DELETE FROM public.order_items WHERE product_id = ANY(v_target_product_ids);
  END IF;

  -- Hapus orders yang terkait
  IF array_length(v_target_order_ids, 1) > 0 THEN
    DELETE FROM public.orders WHERE id = ANY(v_target_order_ids);
  END IF;

  -- Hapus fallback sisa order buyer/seller jika ada
  DELETE FROM public.orders WHERE buyer_id = v_user_id OR seller_id = v_user_id;

  -- 5. Hapus pesan & percakapan chat
  DELETE FROM public.messages 
  WHERE sender_id = v_user_id 
     OR conversation_id IN (
       SELECT id FROM public.conversations WHERE buyer_id = v_user_id OR seller_id = v_user_id
     );
  DELETE FROM public.conversations WHERE buyer_id = v_user_id OR seller_id = v_user_id;

  -- 6. Hapus relasi produk user
  IF array_length(v_target_product_ids, 1) > 0 THEN
    DELETE FROM public.product_images WHERE product_id = ANY(v_target_product_ids);
    DELETE FROM public.product_favorites WHERE product_id = ANY(v_target_product_ids);
    DELETE FROM public.product_reports WHERE product_id = ANY(v_target_product_ids);
    DELETE FROM public.wishlists WHERE product_id = ANY(v_target_product_ids);
    DELETE FROM public.cart_items WHERE product_id = ANY(v_target_product_ids);
    DELETE FROM public.products WHERE id = ANY(v_target_product_ids);
  END IF;

  -- 7. Hapus keterlibatan user pada tabel relasi lain
  DELETE FROM public.product_favorites WHERE user_id = v_user_id;
  DELETE FROM public.product_reports WHERE reporter_id = v_user_id;
  DELETE FROM public.wishlists WHERE user_id = v_user_id;
  DELETE FROM public.cart_items WHERE cart_id IN (SELECT id FROM public.carts WHERE user_id = v_user_id);
  DELETE FROM public.carts WHERE user_id = v_user_id;

  -- 8. Hapus profil publik user
  DELETE FROM public.profiles WHERE id = v_user_id;

  -- 9. Hapus akun auth secara permanen (email bebas didaftarkan ulang)
  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

-- ====================================================================
-- PEMBERSIHAN DATA AKUN RAYA (deleted_7e8b4a02) SECARA BERSIH TOTAL
-- ====================================================================
DO $$
DECLARE
  v_del_ids uuid[];
  v_prod_ids uuid[];
  v_ord_ids uuid[];
BEGIN
  -- Kumpulkan user ID yang sebelumnya di-soft delete atau berawalan deleted_
  SELECT COALESCE(ARRAY_AGG(id), '{}') INTO v_del_ids
  FROM public.profiles
  WHERE full_name = '[AKUN DIHAPUS]' 
     OR username LIKE 'deleted_%' 
     OR deleted_at IS NOT NULL
     OR id = '7e8b4a02-1089-4e14-a174-603b072f8e2e';

  IF array_length(v_del_ids, 1) > 0 THEN
    -- Kumpulkan produk milik akun-akun tersebut
    SELECT COALESCE(ARRAY_AGG(id), '{}') INTO v_prod_ids
    FROM public.products
    WHERE seller_id = ANY(v_del_ids);

    -- Kumpulkan order terkait
    SELECT COALESCE(ARRAY_AGG(id), '{}') INTO v_ord_ids
    FROM public.orders
    WHERE buyer_id = ANY(v_del_ids)
       OR seller_id = ANY(v_del_ids)
       OR product_id = ANY(v_prod_ids);

    -- Hapus child records order (order_items, payments, reviews)
    IF array_length(v_ord_ids, 1) > 0 THEN
      DELETE FROM public.order_items WHERE order_id = ANY(v_ord_ids);
      DELETE FROM public.payments WHERE order_id = ANY(v_ord_ids);
      DELETE FROM public.reviews WHERE order_id = ANY(v_ord_ids);
      DELETE FROM public.orders WHERE id = ANY(v_ord_ids);
    END IF;

    -- Hapus reviews lain
    DELETE FROM public.reviews WHERE reviewer_id = ANY(v_del_ids) OR product_id = ANY(v_prod_ids);

    -- Hapus chat
    DELETE FROM public.messages 
    WHERE sender_id = ANY(v_del_ids) 
       OR conversation_id IN (
         SELECT id FROM public.conversations WHERE buyer_id = ANY(v_del_ids) OR seller_id = ANY(v_del_ids)
       );
    DELETE FROM public.conversations WHERE buyer_id = ANY(v_del_ids) OR seller_id = ANY(v_del_ids);

    -- Hapus relasi produk
    IF array_length(v_prod_ids, 1) > 0 THEN
      DELETE FROM public.product_images WHERE product_id = ANY(v_prod_ids);
      DELETE FROM public.product_favorites WHERE product_id = ANY(v_prod_ids);
      DELETE FROM public.product_reports WHERE product_id = ANY(v_prod_ids);
      DELETE FROM public.wishlists WHERE product_id = ANY(v_prod_ids);
      DELETE FROM public.cart_items WHERE product_id = ANY(v_prod_ids);
      DELETE FROM public.products WHERE id = ANY(v_prod_ids);
    END IF;

    -- Hapus cart & wishlist milik user
    DELETE FROM public.product_favorites WHERE user_id = ANY(v_del_ids);
    DELETE FROM public.product_reports WHERE reporter_id = ANY(v_del_ids);
    DELETE FROM public.wishlists WHERE user_id = ANY(v_del_ids);
    DELETE FROM public.cart_items WHERE cart_id IN (SELECT id FROM public.carts WHERE user_id = ANY(v_del_ids));
    DELETE FROM public.carts WHERE user_id = ANY(v_del_ids);

    -- Hapus profil dari tabel profiles
    DELETE FROM public.profiles WHERE id = ANY(v_del_ids);

    -- Hapus dari auth.users secara tuntas
    DELETE FROM auth.users WHERE id = ANY(v_del_ids);
  END IF;
END $$;
