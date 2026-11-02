-- =====================================================================
-- FIX ORDER STOCK TRIGGER
-- Memastikan stok berkurang secara tepat sesuai jumlah item yang dibeli,
-- dan tidak terjadi pengurangan ganda (double deduction).
-- =====================================================================

-- 1. Buat / Perbarui Trigger Function dengan SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.handle_order_stock_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Saat ada pesanan baru (INSERT), otomatis kurangi stok produk
  IF (TG_OP = 'INSERT') THEN
    IF (NEW.product_id IS NOT NULL) THEN
      UPDATE public.products
      SET stock = GREATEST(0, stock - COALESCE(NEW.quantity, 1))
      WHERE id = NEW.product_id;
    END IF;
    RETURN NEW;

  -- Saat pesanan dibatalkan (UPDATE ke status 'cancelled'), kembalikan stok produk
  ELSIF (TG_OP = 'UPDATE') THEN
    IF (OLD.order_status IS DISTINCT FROM 'cancelled' AND NEW.order_status = 'cancelled') THEN
      IF (NEW.product_id IS NOT NULL) THEN
        UPDATE public.products
        SET stock = stock + COALESCE(OLD.quantity, 1)
        WHERE id = NEW.product_id;
      END IF;
    END IF;
    RETURN NEW;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Daftarkan Trigger pada tabel orders
DROP TRIGGER IF EXISTS trg_order_stock ON public.orders;
CREATE TRIGGER trg_order_stock
AFTER INSERT OR UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.handle_order_stock_change();

