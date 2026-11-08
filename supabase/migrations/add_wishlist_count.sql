-- =====================================================
-- 1. Tambah kolom wishlist_count pada tabel products
-- =====================================================
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS wishlist_count INT NOT NULL DEFAULT 0;

-- =====================================================
-- 2. Sinkronisasi (backfill) nilai wishlist_count dari tabel wishlists
-- =====================================================
UPDATE public.products p
SET wishlist_count = COALESCE((
    SELECT COUNT(*) 
    FROM public.wishlists w 
    WHERE w.product_id = p.id
), 0);

-- =====================================================
-- 3. Buat Function dan Trigger untuk auto-sync wishlist_count
--    setiap kali ada INSERT atau DELETE di tabel wishlists
-- =====================================================
CREATE OR REPLACE FUNCTION public.sync_product_wishlist_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.products
        SET wishlist_count = COALESCE(wishlist_count, 0) + 1
        WHERE id = NEW.product_id;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.products
        SET wishlist_count = GREATEST(0, COALESCE(wishlist_count, 0) - 1)
        WHERE id = OLD.product_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_wishlist_count ON public.wishlists;
CREATE TRIGGER trg_sync_wishlist_count
AFTER INSERT OR DELETE ON public.wishlists
FOR EACH ROW
EXECUTE FUNCTION public.sync_product_wishlist_count();

-- =====================================================
-- 4. RPC Function: get_product_wishlist_count
--    (SECURITY DEFINER agar tidak dibatasi oleh RLS wishlists auth.uid() = user_id)
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_product_wishlist_count(p_product_id uuid)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_count int;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM public.wishlists
    WHERE product_id = p_product_id;

    -- Pastikan kolom wishlist_count di products sinkron
    UPDATE public.products
    SET wishlist_count = v_count
    WHERE id = p_product_id;

    RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_product_wishlist_count(uuid) TO authenticated, anon;
