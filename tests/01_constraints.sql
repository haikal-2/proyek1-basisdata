-- =====================================================================
-- Uji constraint tabel "SALAM".mahasiswas  (jalankan sebagai postgres)
-- Setiap blok bertanda [ERROR] HARUS gagal; blok [OK] HARUS berhasil.
-- =====================================================================
\echo '=== 0. Data awal'
SELECT id, nim, nama, ipk, status FROM "SALAM".mahasiswas ORDER BY id;

\echo '=== 1. PRIMARY KEY: id duplikat  [ERROR: pk_mahasiswas]'
INSERT INTO "SALAM".mahasiswas (id, nim, nama, email, angkatan, semester, ipk)
OVERRIDING SYSTEM VALUE
VALUES (1, '1247050901', 'Uji PK', 'uji.pk@example.com', 2024, 5, 3.00);

\echo '=== 2. UNIQUE: nim duplikat  [ERROR: uq_mahasiswas_nim]'
INSERT INTO "SALAM".mahasiswas (nim, nama, email, angkatan, semester, ipk)
VALUES ('1247050086', 'Uji NIM', 'uji.nim@example.com', 2024, 5, 3.00);

\echo '=== 3. UNIQUE: email duplikat  [ERROR: uq_mahasiswas_email]'
INSERT INTO "SALAM".mahasiswas (nim, nama, email, angkatan, semester, ipk)
VALUES ('1247050902', 'Uji Email', 'haikal@example.com', 2024, 5, 3.00);

\echo '=== 4. CHECK: ipk = 4.50 (> 4.00)  [ERROR: ck_mahasiswas_ipk]'
INSERT INTO "SALAM".mahasiswas (nim, nama, email, angkatan, semester, ipk)
VALUES ('1247050903', 'Uji IPK', 'uji.ipk@example.com', 2024, 5, 4.50);

\echo '=== 5. CHECK: semester = 0  [ERROR: ck_mahasiswas_semester]'
INSERT INTO "SALAM".mahasiswas (nim, nama, email, angkatan, semester, ipk)
VALUES ('1247050904', 'Uji Semester', 'uji.smt@example.com', 2024, 0, 3.00);

\echo '=== 6. CHECK: status tidak valid  [ERROR: ck_mahasiswas_status]'
INSERT INTO "SALAM".mahasiswas (nim, nama, email, angkatan, semester, ipk, status)
VALUES ('1247050905', 'Uji Status', 'uji.status@example.com', 2024, 5, 3.00, 'keluar');

\echo '=== 7. CHECK: format NIM salah (huruf)  [ERROR: ck_mahasiswas_nim]'
INSERT INTO "SALAM".mahasiswas (nim, nama, email, angkatan, semester, ipk)
VALUES ('ABC1234567', 'Uji Format NIM', 'uji.fmt@example.com', 2024, 5, 3.00);

\echo '=== 8. CHECK: format email salah  [ERROR: ck_mahasiswas_email]'
INSERT INTO "SALAM".mahasiswas (nim, nama, email, angkatan, semester, ipk)
VALUES ('1247050906', 'Uji Email Format', 'bukan-email', 2024, 5, 3.00);

\echo '=== 9. NOT NULL: nama NULL  [ERROR: not-null constraint]'
INSERT INTO "SALAM".mahasiswas (nim, nama, email, angkatan, semester, ipk)
VALUES ('1247050907', NULL, 'uji.null@example.com', 2024, 5, 3.00);

\echo '=== 10. Data VALID  [OK: 1 baris masuk]'
INSERT INTO "SALAM".mahasiswas (nim, nama, email, angkatan, semester, ipk)
VALUES ('1247050999', 'Mahasiswa Valid', 'valid@example.com', 2024, 5, 3.25)
RETURNING id, nim, nama, ipk;

\echo '=== 11. Ringkasan: hanya data valid yang tersimpan'
SELECT id, nim, nama, ipk, status FROM "SALAM".mahasiswas ORDER BY id;

\echo '=== 12. Bersihkan data uji'
DELETE FROM "SALAM".mahasiswas WHERE nim = '1247050999';
