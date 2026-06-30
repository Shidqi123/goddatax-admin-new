-- ============================================================
-- GodDataX Admin Panel — Supabase SQL Update
-- Tambah dukungan GodData-X Combo (prefix: COMBO)
-- TIDAK MENGHAPUS data lisensi lama!
-- ============================================================

-- 1. LIHAT STRUKTUR TABEL (verifikasi)
-- SELECT * FROM licenses LIMIT 5;

-- 2. TAMBAH KOLOM project_type (opsional — untuk filter lebih mudah)
--    Jalankan ini hanya jika kolom belum ada
ALTER TABLE licenses 
ADD COLUMN IF NOT EXISTS project_type TEXT 
GENERATED ALWAYS AS (
    CASE 
        WHEN key ILIKE 'COMBO%'   THEN 'COMBO'
        WHEN key ILIKE 'JEANS%'   THEN 'JEANS'
        WHEN key ILIKE 'CLOUD%'   THEN 'CLOUD'
        WHEN key ILIKE 'SUPREME%' THEN 'SUPREME'
        WHEN key ILIKE 'ASCEND%'  THEN 'ASCEND'
        WHEN key ILIKE 'FREE%'    THEN 'FREE'
        ELSE 'UNKNOWN'
    END
) STORED;

-- 3. BUAT INDEX untuk performa filter berdasarkan prefix
CREATE INDEX IF NOT EXISTS idx_licenses_key_prefix 
ON licenses (key text_pattern_ops);

-- 4. CEK DATA LAMA MASIH ADA (tidak dihapus)
SELECT 
    project_type,
    COUNT(*) as total_licenses,
    COUNT(device_id) as terpakai,
    COUNT(*) - COUNT(device_id) as belum_terpakai
FROM licenses
GROUP BY project_type
ORDER BY project_type;

-- 5. CONTOH INSERT lisensi COMBO baru (via admin panel, bukan manual)
-- INSERT INTO licenses (key, device_id, max_devices)
-- VALUES ('COMBO' || upper(substring(gen_random_uuid()::text, 1, 6)), null, 1);

-- 6. BUAT VIEW untuk admin panel (opsional tapi berguna)
CREATE OR REPLACE VIEW v_license_summary AS
SELECT 
    project_type,
    COUNT(*) as total,
    COUNT(device_id) FILTER (WHERE device_id IS NOT NULL AND device_id != '') as active,
    COUNT(*) FILTER (WHERE device_id IS NULL OR device_id = '') as unused,
    MAX(id) as latest_id
FROM licenses
GROUP BY project_type;

-- Lihat summary:
-- SELECT * FROM v_license_summary;

-- ============================================================
-- CATATAN PENTING:
-- • Lisensi JEANS lama: TETAP VALID di app GodData-X Combo
-- • Lisensi COMBO baru: buat via admin panel (pilih "COMBO")
-- • Tidak perlu migrasi data apapun!
-- • App menerima KEDUA prefix: JEANS dan COMBO
-- ============================================================
