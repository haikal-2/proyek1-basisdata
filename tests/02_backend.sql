-- =====================================================================
-- Uji role backend_dev: CRUD semua tabel, TANPA hak DDL
-- =====================================================================
\echo '=== Login sebagai:'
SELECT current_user, session_user;

\echo '=== [OK] CREATE (INSERT)'
INSERT INTO "SALAM".mahasiswas (nim, nama, email, angkatan, semester, ipk)
VALUES ('1247050777', 'Backend Test', 'backend.test@example.com', 2024, 5, 3.00)
RETURNING id, nim, nama, ipk;

\echo '=== [OK] READ (SELECT)'
SELECT id, nim, nama, ipk FROM "SALAM".mahasiswas WHERE nim = '1247050777';

\echo '=== [OK] UPDATE'
UPDATE "SALAM".mahasiswas SET ipk = 3.75 WHERE nim = '1247050777'
RETURNING nim, ipk, updated_at;

\echo '=== [OK] Transaksi: UPDATE lalu ROLLBACK (semester kembali semula)'
BEGIN;
UPDATE "SALAM".mahasiswas SET semester = semester + 1 WHERE nim = '1247050777';
SELECT nim, semester AS semester_dalam_transaksi FROM "SALAM".mahasiswas WHERE nim = '1247050777';
ROLLBACK;
SELECT nim, semester AS semester_setelah_rollback FROM "SALAM".mahasiswas WHERE nim = '1247050777';

\echo '=== [OK] DELETE'
DELETE FROM "SALAM".mahasiswas WHERE nim = '1247050777';

\echo '=== [OK] Jejak audit otomatis (db_user = backend_dev)'
SELECT audit_id, waktu, db_user, aksi, nim
  FROM "SALAM".audit_mahasiswas ORDER BY audit_id DESC LIMIT 4;

\echo '=== [ERROR] CREATE TABLE -> permission denied for schema SALAM'
CREATE TABLE "SALAM".coba_backend (id INT);

\echo '=== [ERROR] ALTER TABLE -> must be owner'
ALTER TABLE "SALAM".mahasiswas ADD COLUMN coba TEXT;

\echo '=== [ERROR] DROP TABLE -> must be owner'
DROP TABLE "SALAM".mahasiswas;
