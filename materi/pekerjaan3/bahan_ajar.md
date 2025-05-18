# Function untuk Pembuatan Laporan Penjualan Otomatis

## 1. Pendahuluan
Pada sistem basis data aktif, *function* merupakan bagian penting dari logika bisnis untuk membantu proses komputasi yang menghasilkan nilai secara langsung. Dalam konteks Perusahaan XYZ (kasus Pemicu 3), function sangat berguna untuk **menghasilkan laporan penjualan** secara **otomatis** tanpa harus menunggu pengolahan manual oleh tim keuangan.

## 2. Pengertian Database Function
Function di dalam DBMS adalah blok kode SQL yang:
- Mengembalikan *nilai* (harus memiliki pernyataan `RETURN`),
- Bisa menerima parameter (input),
- Dapat dipanggil di dalam `SELECT`, `WHERE`, `SET`, atau bagian dari ekspresi SQL lainnya.

### Sintaks Umum Function
```sql
CREATE [OR REPLACE] FUNCTION function_name(
    parameter_name datatype,
    ...
)
RETURN return_datatype
IS
    -- deklarasi variabel lokal
BEGIN
    -- logika function
    RETURN hasil;
END;
```

### Contoh Sederhana
Contoh 1 :
```sql
CREATE OR REPLACE FUNCTION hitung_diskon(harga NUMBER)
RETURN NUMBER
IS
BEGIN
    RETURN harga * 0.10;
END;
```
Contoh 2 :
```sql
CREATE OR REPLACE FUNCTION contoh(n NUMBER)
RETURN NUMBER -- Mengembalikan angka
IS            -- Awal blok function
    hasil NUMBER;
BEGIN          -- Mulai logika eksekusi
    hasil := n * 2;
    RETURN hasil; -- Nilai yang dikembalikan
END;
```

### Penjelasan Struktur Function
Setiap function memiliki bagian-bagian penting sebagai berikut :
- `CREATE OR REPLACE FUNCTION` : Membuat function baru
- `RETURN <datatype>` : Menentukan tipe data yang akan dikembalikan oleh function (misalnya *NUMBER*, *VARCHAR*, dll).
- `IS` atau `AS` : Digunakan untuk membuka blok deklarasi function. IS lebih umum digunakan di PL/SQL.
- `BEGIN ... END;` : Menandakan blok utama tempat kode eksekusi dijalankan. Di sini diletakkan perintah SQL, logika komputasi, dan perintah RETURN.
- `RETURN <value>` : Nilai yang dikembalikan sebagai hasil dari function. Ini wajib ada dalam function.

### Perbedaan `CREATE FUNCTION` vs `CREATE OR REPLACE FUNCTION`
- `CREATE FUNCTION` : Digunakan untuk membuat function baru. Akan gagal jika function dengan nama yang sama sudah ada.
- `CREATE OR REPLACE FUNCTION`: Digunakan untuk membuat baru atau mengganti function yang sudah ada tanpa harus menghapusnya terlebih dahulu.

### Cara Menghapus Function
Query Umum
```sql
DROP FUNCTION IF EXISTS nama_function(parameter_type, ...);
```
Contoh
```sql
DROP FUNCTION IF EXISTS laporan_penjualan(TEXT, TEXT, TEXT);
```

## 3. Studi Kasus Pembuatan Laporan Penjualan Otomatis
**Masalah:** Tim manajemen membutuhkan laporan penjualan **harian**, **mingguan**, dan **bulanan** yang saat ini dilakukan secara manual, lambat, dan rawan kesalahan.

### Solusi:
Membuat beberapa function SQL untuk menghasilkan laporan penjualan berdasarkan waktu.

## 4. Struktur Tabel Referensi (Northwind)

Untuk menyusun laporan penjualan otomatis, berikut adalah beberapa tabel penting dalam skema Northwind yang terlibat:

- **customers**: menyimpan data pelanggan
- **suppliers**: menyimpan data pemasok
- **products**: menyimpan data produk, termasuk harga dan ID pemasok
- **orders**: menyimpan data transaksi pemesanan dari pelanggan
- **order_details**: menyimpan rincian pesanan, termasuk kuantitas dan harga satuan produk

Struktur ringkasnya adalah sebagai berikut:
```sql
-- Tabel utama pelanggan
CREATE TABLE customers (
    customer_id bpchar PRIMARY KEY,
    company_name VARCHAR(40),
    ...
);

-- Tabel utama pemasok
CREATE TABLE suppliers (
    supplier_id BIGINT PRIMARY KEY,
    company_name VARCHAR(40),
    ...
);

-- Tabel produk
CREATE TABLE products (
    product_id BIGINT PRIMARY KEY,
    product_name VARCHAR(40),
    supplier_id BIGINT REFERENCES suppliers(supplier_id),
    unit_price REAL,
    ...
);

-- Tabel pesanan
CREATE TABLE orders (
    order_id BIGINT PRIMARY KEY,
    customer_id bpchar REFERENCES customers(customer_id),
    order_date DATE,
    ...
);

-- Tabel detail pesanan
CREATE TABLE order_details (
    order_id BIGINT REFERENCES orders(order_id),
    product_id BIGINT REFERENCES products(product_id),
    unit_price REAL,
    quantity BIGINT,
    discount REAL,
    PRIMARY KEY (order_id, product_id)
);
```

## 5. Implementasi Function untuk Laporan Penjualan Dinamis

Function ini akan menerima parameter `periode_type` untuk menentukan jenis laporan: `harian`, `mingguan`, `bulanan`, atau `tahunan`, serta `tanggal_acuan` sebagai referensi waktu.

```sql
CREATE OR REPLACE FUNCTION laporan_penjualan(
    periode_type TEXT,
    tanggal_acuan DATE
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    total NUMERIC := 0;
BEGIN
    IF periode_type = 'harian' THEN
        SELECT SUM(od.unit_price * od.quantity * (1 - od.discount)) INTO total
        FROM orders o
        JOIN order_details od ON o.order_id = od.order_id
        WHERE DATE(o.order_date) = tanggal_acuan;

    ELSIF periode_type = 'mingguan' THEN
        SELECT SUM(od.unit_price * od.quantity * (1 - od.discount)) INTO total
        FROM orders o
        JOIN order_details od ON o.order_id = od.order_id
        WHERE DATE_PART('week', o.order_date) = DATE_PART('week', tanggal_acuan)
          AND DATE_PART('year', o.order_date) = DATE_PART('year', tanggal_acuan);

    ELSIF periode_type = 'bulanan' THEN
        SELECT SUM(od.unit_price * od.quantity * (1 - od.discount)) INTO total
        FROM orders o
        JOIN order_details od ON o.order_id = od.order_id
        WHERE DATE_PART('month', o.order_date) = DATE_PART('month', tanggal_acuan)
          AND DATE_PART('year', o.order_date) = DATE_PART('year', tanggal_acuan);

    ELSIF periode_type = 'tahunan' THEN
        SELECT SUM(od.unit_price * od.quantity * (1 - od.discount)) INTO total
        FROM orders o
        JOIN order_details od ON o.order_id = od.order_id
        WHERE DATE_PART('year', o.order_date) = DATE_PART('year', tanggal_acuan);
    END IF;

    RETURN COALESCE(total, 0);
END;
$$;
```

## 6. Cara Pemanggilan Function

Untuk menjalankan function dan mendapatkan laporan penjualan, gunakan:

### 6.1. Laporan Harian
```sql
SELECT laporan_penjualan('harian', '2025-05-11') AS total_harian;
```

### 6.2. Laporan Mingguan
```sql
SELECT laporan_penjualan('mingguan', '2025-05-11') AS total_mingguan;
```

### 6.3. Laporan Bulanan
```sql
SELECT laporan_penjualan('bulanan', '2025-05-01') AS total_bulanan;
```

### 6.4. Laporan Tahunan
```sql
SELECT laporan_penjualan('tahunan', '2025-01-01') AS total_tahunan;
```

## 7. Kesimpulan
Function adalah alat bantu yang **efisien**, **fleksibel**, dan **terstruktur** dalam membantu otomasi komputasi seperti pembuatan laporan. Dengan mengimplementasikan function seperti pada contoh di atas, Perusahaan XYZ dapat:
- Mempercepat proses pengambilan keputusan,
- Mengurangi kesalahan manual,
- Meningkatkan akurasi laporan,
- Menghemat waktu operasional.

Untuk menjalankan secara *otomatis* (seperti setiap malam atau awal bulan), function ini bisa dipanggil oleh **event scheduler** atau aplikasi backend perusahaan.

---
