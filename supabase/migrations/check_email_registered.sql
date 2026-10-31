-- ====================================================================
-- FUNGSI VALIDASI EMAIL PENDAFTARAN (ANTI-DUPLIKASI AKUN)
-- ====================================================================

CREATE OR REPLACE FUNCTION public.check_email_registered(p_email text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- Cek apakah email sudah terdaftar di auth.users ATAU di public.profiles yang aktif
  RETURN EXISTS (
    SELECT 1 FROM auth.users 
    WHERE LOWER(email) = LOWER(TRIM(p_email))
  ) OR EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE LOWER(email) = LOWER(TRIM(p_email)) 
      AND deleted_at IS NULL
  );
END;
$$;

-- Berikan izin akses ke 'anon' (calon pendaftar yang belum login) dan 'authenticated'
GRANT EXECUTE ON FUNCTION public.check_email_registered(text) TO anon, authenticated;

