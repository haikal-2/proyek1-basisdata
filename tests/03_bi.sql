-- =====================================================================
-- Uji role bi_dev: HANYA SELECT (tabel & view)
-- =====================================================================
\echo '=== Login sebagai:'
SELECT current_user, session_user;

\echo '=== [OK] SELECT tabel'
SELECT id, nim, nama, ipk, status FROM "SALAM".mahasiswas ORDER BY id;

\echo '=== [OK] SELECT view (dengan predikat IPK)'
SELECT nim, nama, ipk, predikat, status FROM "SALAM".v_mahasiswa_ringkas ORDER BY ipk DESC;

\echo '=== [OK] Agregasi untuk BI'
SELECT predikat, COUNT(*) AS jumlah, ROUND(AVG(ipk), 2) AS rata_ipk
  FROM "SALAM".v_mahasiswa_ringkas GROUP BY predikat ORDER BY jumlah DESC;

\echo '=== [ERROR] INSERT -> permission denied'
INSERT INTO "SALAM".mahasiswas (nim, nama, email, angkatan, semester, ipk)
VALUES ('1247050888', 'BI Test', 'bi.test@example.com', 2024, 5, 3.00);

\echo '=== [ERROR] UPDATE -> permission denied'
UPDATE "SALAM".mahasiswas SET ipk = 4.00 WHERE nim = '1247050086';

\echo '=== [ERROR] DELETE -> permission denied'
DELETE FROM "SALAM".mahasiswas WHERE nim = '1247050086';

\echo '=== [ERROR] CREATE TABLE -> permission denied for schema SALAM'
CREATE TABLE "SALAM".coba_bi (id INT);

\echo '=== [ERROR] DROP VIEW -> must be owner'
DROP VIEW "SALAM".v_mahasiswa_ringkas;
