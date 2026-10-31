# UTS / Proyek 1 — Manajemen Basis Data (PostgreSQL + pgAdmin4 via Docker)

NIM 1247050086 → XXX = **086** → port PostgreSQL **22086**, pgAdmin **44086**.

## Struktur
```
.env                  # nilai rahasia (TIDAK di-commit)
.env.example          # template untuk repo
docker-compose.yml    # 2 service: postgres_NAMA, pgadmin_NAMA
sql/01_setup.sql      # skema SALAM, tabel mahasiswas, 3 role, grant
tests/01..04_*.sql    # bukti constraint & hak akses tiap role
dokumentasi/          # screenshot + laporan PDF
```

## Langkah 1 — Siapkan .env
Salin `.env.example` → `.env`, lalu isi (POSTGRES_PASSWORD wajib `ifunggul`).
`docker-compose.yml` hanya memakai `${VARIABEL}`, tanpa hardcode user/password.

## Langkah 2 — Jalankan container
```
docker compose config      # cek: nilai .env terbaca
docker compose up -d
docker compose ps          # postgres: healthy, pgadmin: running
```
Nama container: `postgres_<NAMA>` dan `pgadmin_<NAMA>`.

## Langkah 3 — Buat skema, tabel, role (SQL script)
```
docker exec postgres_<NAMA> sh -c 'psql -U postgres -d kampus_db -v backend_pw=$BACKEND_DEV_PASSWORD -v bi_pw=$BI_DEV_PASSWORD -v de_pw=$DATA_ENGINEER_PASSWORD -f /sql/01_setup.sql'
```
Ganti `<NAMA>` sesuai `.env`. Aman dijalankan ulang.

## Langkah 4 — Bukti koneksi (soal no. 2d)
**Internal docker (pgAdmin4)** — buka http://localhost:44086, login dengan `PGADMIN_DEFAULT_EMAIL` / `PGADMIN_DEFAULT_PASSWORD`.
Register Server → Connection: Host `postgres` (nama service, bukan localhost), Port `5432`, DB `kampus_db`, User `postgres`, Password `ifunggul`.

**Eksternal docker (DBeaver)** — New Connection → PostgreSQL: Host `localhost`, Port `22086`, DB `kampus_db`, User `postgres`, Password `ifunggul`. Test Connection → Connected.

## Langkah 5 — Bukti constraint (soal no. 3)
```
docker exec postgres_<NAMA> psql -U postgres -d kampus_db -f /tests/01_constraints.sql
```
Baris `[ERROR]` harus ditolak (PK, UNIQUE, CHECK, NOT NULL); baris `[OK]` harus masuk.

## Langkah 6 — Bukti hak akses role (soal no. 4)
Login memakai `-h postgres` agar lewat jaringan docker dan password benar-benar diperiksa.
```
docker exec postgres_<NAMA> sh -c 'PGPASSWORD=$BACKEND_DEV_PASSWORD  psql -h postgres -U backend_dev  -d kampus_db -f /tests/02_backend.sql'
docker exec postgres_<NAMA> sh -c 'PGPASSWORD=$BI_DEV_PASSWORD       psql -h postgres -U bi_dev        -d kampus_db -f /tests/03_bi.sql'
docker exec postgres_<NAMA> sh -c 'PGPASSWORD=$DATA_ENGINEER_PASSWORD psql -h postgres -U data_engineer -d kampus_db -f /tests/04_engineer.sql'
```
Hasil yang diharapkan:

| Role | Boleh | Harus ditolak |
|---|---|---|
| backend_dev | INSERT/SELECT/UPDATE/DELETE | CREATE / ALTER / DROP |
| bi_dev | SELECT tabel & view | INSERT / UPDATE / DELETE / CREATE / DROP |
| data_engineer | CREATE / ALTER / DROP + CRUD | — |

## Langkah 7 — Push ke GitHub (soal no. 5)
```
git init
git add .
git status                 # pastikan .env TIDAK ikut
git commit -m "UTS MBD Proyek 1: docker compose postgres + pgadmin"
git branch -M main
git remote add origin https://github.com/<username>/proyek1-basisdata.git
git push -u origin main
```

## Fitur pembeda (highlight di laporan)
1. Tabel `audit_mahasiswas` + trigger: setiap INSERT/UPDATE/DELETE tercatat beserta role DB pelakunya.
2. Fungsi `fn_predikat_ipk()` + view `v_mahasiswa_ringkas` untuk tim BI.
3. Trigger `updated_at` otomatis.
4. Constraint tambahan: format NIM (10 digit), format email, rentang angkatan/semester, status terbatas.
5. Uji transaksi `BEGIN … ROLLBACK` pada role backend_dev.
6. `data_engineer` dijadikan owner skema SALAM; `ALTER DEFAULT PRIVILEGES` agar tabel baru otomatis dapat hak yang benar.

## Checklist screenshot untuk laporan PDF
- [ ] Isi `.env` dan `docker-compose.yml`
- [ ] Docker Desktop: 2 container running + port 22086 / 44086
- [ ] `docker compose ps`
- [ ] pgAdmin: server terkoneksi (host `postgres`) + schema SALAM
- [ ] DBeaver: koneksi sukses (port 22086)
- [ ] Output `01_setup.sql`
- [ ] Output `01_constraints.sql` (semua ERROR + 1 OK)
- [ ] Output 02, 03, 04 (bagian OK dan ERROR)
- [ ] Tabel `audit_mahasiswas` berisi jejak per role
- [ ] Halaman repo GitHub
