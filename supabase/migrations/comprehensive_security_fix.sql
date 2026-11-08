-- ====================================================================
-- BRAWIGO COMPREHENSIVE SECURITY, INTEGRITY, & PERFORMANCE MIGRATION
-- Jalankan skrip ini di Supabase Dashboard > SQL Editor
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. PENCEGAHAN RACE CONDITION / STOK MINUS (Overselling Prevention)
-- --------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'products_stock_non_negative'
  ) THEN
    ALTER TABLE public.products ADD CONSTRAINT products_stock_non_negative CHECK (stock >= 0);
  END IF;
END $$;

-- --------------------------------------------------------------------
-- 2. DATABASE PERFORMANCE INDEXES (Optimasi Kecepatan 100+ User)
-- --------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_orders_buyer_id ON public.orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_orders_seller_id ON public.orders(seller_id);
CREATE INDEX IF NOT EXISTS idx_orders_product_id ON public.orders(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_order_status ON public.orders(order_status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_products_seller_id ON public.products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_status ON public.products(status);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_conversations_buyer_id ON public.conversations(buyer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_seller_id ON public.conversations(seller_id);

CREATE INDEX IF NOT EXISTS idx_wishlists_user_id ON public.wishlists(user_id);
CREATE INDEX IF NOT EXISTS idx_product_reports_product_id ON public.product_reports(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON public.reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer_id ON public.reviews(reviewer_id);

-- --------------------------------------------------------------------
-- 3. PERLINDUNGAN PRIVASI PII (Personal Identifiable Information)
--    Menghapus akses publik anonim ke tabel profiles & hanya izinkan
--    pengguna terotentikasi (@ub.ac.id) untuk melihat profil aktif.
-- --------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Hapus seluruh policy lama yang bertumpuk / mengizinkan akses anonim tanpa login
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;
DROP POLICY IF EXISTS "User can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile." ON public.profiles;
DROP POLICY IF EXISTS "User can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Authenticated users can view profiles" ON public.profiles;
DROP POLICY IF EXISTS "Authenticated users can view active profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

-- Policy SELECT: Hanya user yang login terautentikasi dan akun tidak soft-deleted
CREATE POLICY "Authenticated users can view active profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (deleted_at IS NULL OR auth.uid() = id);

-- Policy UPDATE: Hanya user pemilik akun yang dapat mengedit profilnya
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Policy INSERT: Hanya user pemilik akun saat pendaftaran
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- --------------------------------------------------------------------
-- 4. INTEGRITAS TRANSAKSI ORDERS (Mencegah Manipulasi Harga / Pihak)
-- --------------------------------------------------------------------
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Bersihkan policy lama orders yang bertumpuk
DROP POLICY IF EXISTS "Buyers can insert orders" ON public.orders;
DROP POLICY IF EXISTS "Buyers can view their own orders" ON public.orders;
DROP POLICY IF EXISTS "Sellers and buyers can update their orders" ON public.orders;
DROP POLICY IF EXISTS "Sellers and buyers can view their orders" ON public.orders;
DROP POLICY IF EXISTS "Users can update their orders" ON public.orders;
DROP POLICY IF EXISTS "Users can view their orders" ON public.orders;
DROP POLICY IF EXISTS "Participants can view their orders" ON public.orders;
DROP POLICY IF EXISTS "Participants can update their orders" ON public.orders;

-- Policy INSERT: Pembeli hanya bisa membuat order atas namanya sendiri
CREATE POLICY "Buyers can insert orders"
  ON public.orders FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = buyer_id);

-- Policy SELECT: Hanya pembeli dan penjual terkait yang bisa melihat detail pesanan
CREATE POLICY "Participants can view their orders"
  ON public.orders FOR SELECT
  TO authenticated
  USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- Policy UPDATE: Hanya pembeli dan penjual terkait yang bisa mengubah data
CREATE POLICY "Participants can update their orders"
  ON public.orders FOR UPDATE
  TO authenticated
  USING (auth.uid() = buyer_id OR auth.uid() = seller_id)
  WITH CHECK (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- TRIGGER IMMUTABILITY: Mencegah manipulasi harga atau pemindahan order setelah dibuat
CREATE OR REPLACE FUNCTION public.protect_order_immutability()
RETURNS TRIGGER AS $$
BEGIN
  -- Total harga tidak boleh diubah dari client setelah checkout
  IF NEW.total_amount <> OLD.total_amount THEN
    RAISE EXCEPTION 'Keamanan: total_amount pesanan tidak dapat diubah setelah dibuat.';
  END IF;

  -- Pihak pembeli & penjual tidak boleh ditukar
  IF NEW.buyer_id <> OLD.buyer_id THEN
    RAISE EXCEPTION 'Keamanan: buyer_id tidak dapat diubah.';
  END IF;
  IF NEW.seller_id <> OLD.seller_id THEN
    RAISE EXCEPTION 'Keamanan: seller_id tidak dapat diubah.';
  END IF;
  IF NEW.product_id <> OLD.product_id THEN
    RAISE EXCEPTION 'Keamanan: product_id tidak dapat diubah.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_protect_order_immutability ON public.orders;
CREATE TRIGGER trg_protect_order_immutability
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_order_immutability();

-- --------------------------------------------------------------------
-- 5. PERAPIHAN POLICY PRODUCTS (Deduplikasi Policy)
-- --------------------------------------------------------------------
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view active products" ON public.products;
DROP POLICY IF EXISTS "Authenticated users can view products" ON public.products;
DROP POLICY IF EXISTS "Public can view products" ON public.products;
DROP POLICY IF EXISTS "Seller can create own product" ON public.products;
DROP POLICY IF EXISTS "Seller can delete own product" ON public.products;
DROP POLICY IF EXISTS "Seller can delete own products" ON public.products;
DROP POLICY IF EXISTS "Seller can update own product" ON public.products;
DROP POLICY IF EXISTS "Users can delete their own products" ON public.products;
DROP POLICY IF EXISTS "Users can insert their own products" ON public.products;
DROP POLICY IF EXISTS "Users can update their own products" ON public.products;

-- SELECT: Produk aktif bisa dilihat siapa saja; produk non-aktif hanya oleh pemiliknya
CREATE POLICY "Anyone can view products"
  ON public.products FOR SELECT
  USING (status = 'active'::product_status OR auth.uid() = seller_id);

-- INSERT: Penjual hanya bisa menambah produk miliknya sendiri
CREATE POLICY "Seller can insert own product"
  ON public.products FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = seller_id);

-- UPDATE: Penjual hanya bisa mengedit produk miliknya sendiri
CREATE POLICY "Seller can update own product"
  ON public.products FOR UPDATE
  TO authenticated
  USING (auth.uid() = seller_id)
  WITH CHECK (auth.uid() = seller_id);

-- DELETE: Penjual hanya bisa menghapus produk miliknya sendiri
CREATE POLICY "Seller can delete own product"
  ON public.products FOR DELETE
  TO authenticated
  USING (auth.uid() = seller_id);

-- --------------------------------------------------------------------
-- 6. PERAPIHAN POLICY PRODUCT_REPORTS & WISHLISTS
-- --------------------------------------------------------------------
ALTER TABLE public.product_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view product reports" ON public.product_reports;
DROP POLICY IF EXISTS "Users can insert reports" ON public.product_reports;
DROP POLICY IF EXISTS "Users can insert their own reports" ON public.product_reports;
DROP POLICY IF EXISTS "Users can view their own reports" ON public.product_reports;

CREATE POLICY "Anyone can view product reports"
  ON public.product_reports FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own reports"
  ON public.product_reports FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = reporter_id);

-- Wishlists
ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can delete own wishlists" ON public.wishlists;
DROP POLICY IF EXISTS "Users can insert own wishlists" ON public.wishlists;
DROP POLICY IF EXISTS "Users can view own wishlists" ON public.wishlists;

CREATE POLICY "Users can view own wishlists"
  ON public.wishlists FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own wishlists"
  ON public.wishlists FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own wishlists"
  ON public.wishlists FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- --------------------------------------------------------------------
-- 7. FUNGSI PENGHAPUSAN AKUN PERMANEN (SECURITY DEFINER)
--    Menghapus akun secara tuntas dari auth.users, profiles, seluruh produk,
--    wishlist, cart, dan pesan, serta membersihkan akun soft-deleted lama.
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid;
  v_active_orders int;
BEGIN
  -- Dapatkan ID user yang sedang login
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: User belum login.';
  END IF;

  -- 1. Cek apakah ada transaksi yang sedang berjalan (baik sebagai buyer maupun seller)
  SELECT COUNT(*) INTO v_active_orders
  FROM public.orders
  WHERE (buyer_id = v_user_id OR seller_id = v_user_id)
    AND LOWER(COALESCE(order_status, status, '')) IN (
      'created', 'waiting_confirmation', 'pending', 'waiting_verification', 
      'paid', 'processing', 'courier_on_the_way', 'ready_for_pickup'
    );

  IF v_active_orders > 0 THEN
    RAISE EXCEPTION 'Tidak dapat menghapus akun karena Anda masih memiliki % transaksi yang sedang berjalan.', v_active_orders;
  END IF;

  -- 2. Hapus seluruh produk yang dijual oleh user ini (termasuk foto & keterkaitan)
  DELETE FROM public.product_images WHERE product_id IN (SELECT id FROM public.products WHERE seller_id = v_user_id);
  DELETE FROM public.product_favorites WHERE product_id IN (SELECT id FROM public.products WHERE seller_id = v_user_id) OR user_id = v_user_id;
  DELETE FROM public.product_reports WHERE product_id IN (SELECT id FROM public.products WHERE seller_id = v_user_id) OR reporter_id = v_user_id;
  DELETE FROM public.wishlists WHERE product_id IN (SELECT id FROM public.products WHERE seller_id = v_user_id) OR user_id = v_user_id;
  DELETE FROM public.cart_items WHERE product_id IN (SELECT id FROM public.products WHERE seller_id = v_user_id);
  DELETE FROM public.products WHERE seller_id = v_user_id;

  -- 3. Hapus wishlist & cart milik user
  DELETE FROM public.wishlists WHERE user_id = v_user_id;
  DELETE FROM public.cart_items WHERE cart_id IN (SELECT id FROM public.carts WHERE user_id = v_user_id);
  DELETE FROM public.carts WHERE user_id = v_user_id;

  -- 4. Hapus riwayat chat & pesan milik user
  DELETE FROM public.messages WHERE conversation_id IN (
    SELECT id FROM public.conversations WHERE buyer_id = v_user_id OR seller_id = v_user_id
  );
  DELETE FROM public.conversations WHERE buyer_id = v_user_id OR seller_id = v_user_id;

  -- 5. Bersihkan riwayat transaksi yang sudah selesai / dibatalkan
  DELETE FROM public.order_items WHERE order_id IN (
    SELECT id FROM public.orders WHERE buyer_id = v_user_id OR seller_id = v_user_id
  );
  DELETE FROM public.payments WHERE order_id IN (
    SELECT id FROM public.orders WHERE buyer_id = v_user_id OR seller_id = v_user_id
  );
  DELETE FROM public.reviews WHERE reviewer_id = v_user_id OR order_id IN (
    SELECT id FROM public.orders WHERE buyer_id = v_user_id OR seller_id = v_user_id
  );
  DELETE FROM public.orders WHERE buyer_id = v_user_id OR seller_id = v_user_id;

  -- 6. Hapus dari tabel profiles
  DELETE FROM public.profiles WHERE id = v_user_id;

  -- 7. HAPUS PERMANEN DARI AUTH.USERS
  -- Ini memastikan user tidak bisa login lagi dan email bisa didaftarkan ulang (sign-up baru)
  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

-- Bersihkan akun lama yang sebelumnya sudah di-soft-delete (seperti 'deleted_7e8b4a02')
DELETE FROM public.products WHERE seller_id IN (
  SELECT id FROM public.profiles WHERE full_name = '[AKUN DIHAPUS]' OR username LIKE 'deleted_%' OR deleted_at IS NOT NULL
);
DELETE FROM auth.users WHERE id IN (
  SELECT id FROM public.profiles WHERE full_name = '[AKUN DIHAPUS]' OR username LIKE 'deleted_%' OR deleted_at IS NOT NULL
);
DELETE FROM public.profiles WHERE full_name = '[AKUN DIHAPUS]' OR username LIKE 'deleted_%' OR deleted_at IS NOT NULL;

