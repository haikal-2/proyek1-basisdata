-- =====================================================================
-- Uji role data_engineer: CREATE / MODIFY / DROP semua object + CRUD semua tabel
-- =====================================================================
\echo '=== Login sebagai:'
SELECT current_user, session_user;

\echo '=== [OK] CREATE TABLE'
CREATE TABLE "SALAM".krs_test (
    id     INT PRIMARY KEY,
    nim    VARCHAR(10) REFERENCES "SALAM".mahasiswas(nim),
    matkul VARCHAR(50)
);

\echo '=== [OK] MODIFY: ALTER TABLE ADD COLUMN'
ALTER TABLE "SALAM".krs_test ADD COLUMN sks SMALLINT DEFAULT 3;
\d "SALAM".krs_test

\echo '=== [OK] CRUD pada tabel baru'
INSERT INTO "SALAM".krs_test (id, nim, matkul) VALUES (1, '1247050086', 'Manajemen Basis Data');
SELECT * FROM "SALAM".krs_test;
UPDATE "SALAM".krs_test SET sks = 4 WHERE id = 1;
DELETE FROM "SALAM".krs_test WHERE id = 1;

\echo '=== [OK] CRUD pada tabel mahasiswas'
INSERT INTO "SALAM".mahasiswas (nim, nama, email, angkatan, semester, ipk)
VALUES ('1247050666', 'Engineer Test', 'engineer.test@example.com', 2024, 5, 3.30);
UPDATE "SALAM".mahasiswas SET ipk = 3.40 WHERE nim = '1247050666';
SELECT nim, nama, ipk FROM "SALAM".mahasiswas WHERE nim = '1247050666';
DELETE FROM "SALAM".mahasiswas WHERE nim = '1247050666';

\echo '=== [OK] CREATE VIEW, lalu MODIFY (ALTER) tabel yang sudah ada'
CREATE VIEW "SALAM".v_engineer_test AS SELECT nim, nama FROM "SALAM".mahasiswas;
ALTER TABLE "SALAM".mahasiswas ADD COLUMN catatan TEXT;
ALTER TABLE "SALAM".mahasiswas DROP COLUMN catatan;

\echo '=== [OK] DROP object'
DROP VIEW  "SALAM".v_engineer_test;
DROP TABLE "SALAM".krs_test;

\echo '=== Verifikasi: object uji sudah hilang, tabel utama tetap ada'
\dt "SALAM".*
