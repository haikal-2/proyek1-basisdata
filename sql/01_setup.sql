-- =====================================================================
-- 01_setup.sql  |  UTS/Proyek 1 Manajemen Basis Data
-- Skema SALAM + tabel mahasiswas + 3 role (backend_dev, bi_dev, data_engineer)
-- Dijalankan sebagai superuser postgres. Variabel password dikirim lewat
-- psql -v (nilainya dari .env), jadi TIDAK ada password hardcode di sini.
-- Aman dijalankan ulang (idempotent).
-- =====================================================================
\set ON_ERROR_STOP on

\echo '>>> [1/7] Membuat role (SQL script)'
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', 'backend_dev', :'backend_pw')
 WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'backend_dev') \gexec
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', 'bi_dev', :'bi_pw')
 WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bi_dev') \gexec
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', 'data_engineer', :'de_pw')
 WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'data_engineer') \gexec

\echo '>>> [2/7] Membuat skema SALAM (huruf besar -> wajib kutip ganda)'
CREATE SCHEMA IF NOT EXISTS "SALAM";

\echo '>>> [3/7] Membuat tabel mahasiswas (PK, UNIQUE, CHECK, NOT NULL)'
CREATE TABLE IF NOT EXISTS "SALAM".mahasiswas (
    id             BIGINT GENERATED ALWAYS AS IDENTITY,
    nim            VARCHAR(10)   NOT NULL,
    nama           VARCHAR(100)  NOT NULL,
    email          VARCHAR(100)  NOT NULL,
    program_studi  VARCHAR(50)   NOT NULL DEFAULT 'Teknik Informatika',
    angkatan       SMALLINT      NOT NULL,
    semester       SMALLINT      NOT NULL,
    ipk            NUMERIC(3,2)  NOT NULL DEFAULT 0.00,
    status         VARCHAR(10)   NOT NULL DEFAULT 'aktif',
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_mahasiswas          PRIMARY KEY (id),
    CONSTRAINT uq_mahasiswas_nim      UNIQUE (nim),
    CONSTRAINT uq_mahasiswas_email    UNIQUE (email),
    CONSTRAINT ck_mahasiswas_nim      CHECK (nim ~ '^[0-9]{10}$'),
    CONSTRAINT ck_mahasiswas_email    CHECK (email LIKE '%_@_%.__%'),
    CONSTRAINT ck_mahasiswas_angkatan CHECK (angkatan BETWEEN 2000 AND 2100),
    CONSTRAINT ck_mahasiswas_semester CHECK (semester BETWEEN 1 AND 14),
    CONSTRAINT ck_mahasiswas_ipk      CHECK (ipk BETWEEN 0.00 AND 4.00),
    CONSTRAINT ck_mahasiswas_status   CHECK (status IN ('aktif','cuti','lulus','nonaktif'))
);

-- ---------------- FITUR PEMBEDA (di-highlight di laporan) ----------------
-- (A) Tabel audit: mencatat siapa (role DB) melakukan INSERT/UPDATE/DELETE
CREATE TABLE IF NOT EXISTS "SALAM".audit_mahasiswas (
    audit_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    waktu      TIMESTAMPTZ NOT NULL DEFAULT now(),
    db_user    TEXT        NOT NULL DEFAULT session_user,
    aksi       TEXT        NOT NULL,
    nim        VARCHAR(10),
    data_lama  JSONB,
    data_baru  JSONB
);

-- (B) Fungsi predikat IPK + (C) view ringkasan untuk tim BI
CREATE OR REPLACE FUNCTION "SALAM".fn_predikat_ipk(p_ipk NUMERIC)
RETURNS TEXT LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN p_ipk >= 3.51 THEN 'Dengan Pujian'
        WHEN p_ipk >= 3.00 THEN 'Sangat Memuaskan'
        WHEN p_ipk >= 2.75 THEN 'Memuaskan'
        WHEN p_ipk >= 2.00 THEN 'Cukup'
        ELSE 'Kurang'
    END
$$;

CREATE OR REPLACE VIEW "SALAM".v_mahasiswa_ringkas AS
SELECT nim, nama, program_studi, angkatan, semester, ipk,
       "SALAM".fn_predikat_ipk(ipk) AS predikat, status
  FROM "SALAM".mahasiswas;

-- (D) Trigger: updated_at otomatis + audit otomatis
CREATE OR REPLACE FUNCTION "SALAM".fn_set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION "SALAM".fn_audit_mahasiswas()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, "SALAM" AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO "SALAM".audit_mahasiswas(aksi, nim, data_baru)
        VALUES (TG_OP, NEW.nim, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO "SALAM".audit_mahasiswas(aksi, nim, data_lama, data_baru)
        VALUES (TG_OP, NEW.nim, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSE
        INSERT INTO "SALAM".audit_mahasiswas(aksi, nim, data_lama)
        VALUES (TG_OP, OLD.nim, to_jsonb(OLD));
        RETURN OLD;
    END IF;
END $$;

\echo '>>> [4/7] Data awal (sebelum trigger audit dipasang)'
INSERT INTO "SALAM".mahasiswas (nim, nama, email, angkatan, semester, ipk, status) VALUES
 ('1247050086', 'Muhammad Haikal Fadhil Imani', 'haikal@example.com', 2024, 5, 3.80, 'aktif'),
 ('1247050001', 'Sari Wulandari',               'sari@example.com',   2024, 5, 3.45, 'aktif'),
 ('1247050002', 'Budi Santoso',                 'budi@example.com',   2024, 5, 2.90, 'aktif'),
 ('1247050003', 'Dewi Lestari',                 'dewi@example.com',   2023, 7, 3.10, 'cuti'),
 ('1247050004', 'Andi Pratama',                 'andi@example.com',   2021, 14, 3.62, 'lulus')
ON CONFLICT DO NOTHING;

DROP TRIGGER IF EXISTS trg_mahasiswas_updated_at ON "SALAM".mahasiswas;
CREATE TRIGGER trg_mahasiswas_updated_at BEFORE UPDATE ON "SALAM".mahasiswas
    FOR EACH ROW EXECUTE FUNCTION "SALAM".fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_mahasiswas_audit ON "SALAM".mahasiswas;
CREATE TRIGGER trg_mahasiswas_audit AFTER INSERT OR UPDATE OR DELETE ON "SALAM".mahasiswas
    FOR EACH ROW EXECUTE FUNCTION "SALAM".fn_audit_mahasiswas();

\echo '>>> [5/7] data_engineer dijadikan OWNER semua object di skema SALAM'
-- Owner otomatis boleh CREATE / ALTER (MODIFY) / DROP + CRUD semua tabel.
ALTER SCHEMA "SALAM" OWNER TO data_engineer;
ALTER TABLE    "SALAM".mahasiswas          OWNER TO data_engineer;
ALTER TABLE    "SALAM".audit_mahasiswas    OWNER TO data_engineer;
ALTER VIEW     "SALAM".v_mahasiswa_ringkas OWNER TO data_engineer;
ALTER FUNCTION "SALAM".fn_predikat_ipk(NUMERIC) OWNER TO data_engineer;
ALTER FUNCTION "SALAM".fn_set_updated_at()      OWNER TO data_engineer;
ALTER FUNCTION "SALAM".fn_audit_mahasiswas()    OWNER TO data_engineer;

\echo '>>> [6/7] GRANT hak akses per role'
GRANT CONNECT ON DATABASE kampus_db TO backend_dev, bi_dev, data_engineer;
GRANT USAGE   ON SCHEMA "SALAM"     TO backend_dev, bi_dev;

-- backend_dev: CRUD semua tabel (tanpa hak DDL)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES    IN SCHEMA "SALAM" TO backend_dev;
GRANT USAGE, SELECT                  ON ALL SEQUENCES IN SCHEMA "SALAM" TO backend_dev;

-- bi_dev: hanya SELECT (tabel + view)
GRANT SELECT ON ALL TABLES IN SCHEMA "SALAM" TO bi_dev;

-- Objek BARU yang dibuat data_engineer/postgres otomatis ikut hak di atas
ALTER DEFAULT PRIVILEGES FOR ROLE postgres, data_engineer IN SCHEMA "SALAM"
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO backend_dev;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres, data_engineer IN SCHEMA "SALAM"
    GRANT USAGE, SELECT ON SEQUENCES TO backend_dev;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres, data_engineer IN SCHEMA "SALAM"
    GRANT SELECT ON TABLES TO bi_dev;

\echo '>>> [7/7] Verifikasi'
\dn+ "SALAM"
\dt "SALAM".*
\du backend_dev
\du bi_dev
\du data_engineer
\echo '>>> SELESAI'
