# View untuk Penyajian Data Virtual

## 1. Pendahuluan
Dalam sistem basis data, *view* merupakan salah satu fitur penting yang memungkinkan penyajian data kompleks dalam bentuk yang lebih sederhana dan terstruktur. View dapat digunakan untuk menyederhanakan query, meningkatkan keamanan data, serta membantu proses analisis tanpa menyimpan ulang data yang sama.

## 2. Pengertian View
View adalah sebuah **tabel virtual** yang isinya merupakan hasil dari sebuah pernyataan SELECT. View **tidak menyimpan data secara fisik**, tetapi menyimpan definisi query yang dieksekusi saat view dipanggil.

### Karakteristik View
- Tidak menyimpan data aktual, hanya menyimpan definisi query.
- Dapat digunakan layaknya tabel biasa dalam SELECT, JOIN, dan filter.
- Bisa menyederhanakan query yang kompleks atau panjang.
- Dapat membatasi akses kolom sensitif (contoh: menyembunyikan harga/modal).
- Bisa bersifat updatable (terbatas), tergantung jenis view dan RDBMS.

## 3. Sintaks Umum View
```sql
CREATE [OR REPLACE] VIEW nama_view AS
SELECT kolom1, kolom2, ...
FROM tabel_asli
WHERE kondisi;
```

### Contoh Sederhana
```sql
CREATE OR REPLACE VIEW view_customer_aktif AS
SELECT customer_id, company_name, country
FROM customers
WHERE country = 'USA';
```

### Penjelasan Struktur View
- `CREATE VIEW`: Membuat view baru.
- `OR REPLACE`: Jika view dengan nama tersebut sudah ada, maka akan diganti (replace).
- `SELECT ...`: Definisi isi view, biasanya query kompleks.
- `WHERE ...`: Batasan data yang ditampilkan dalam view.

## 4. Studi Kasus Penggunaan View
### Masalah:
Tim marketing ingin melihat data pelanggan di USA yang pernah melakukan transaksi, namun tidak ingin melihat kolom sensitif seperti nomor telepon dan alamat.

### Solusi:
Membuat view `view_pelanggan_aktif` yang hanya menampilkan `customer_id`, `company_name`, dan total transaksi yang dilakukan oleh pelanggan dari USA.

```sql
CREATE OR REPLACE VIEW view_pelanggan_aktif AS
SELECT 
    c.customer_id,
    c.company_name,
    COUNT(o.order_id) AS jumlah_transaksi
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE c.country = 'USA'
GROUP BY c.customer_id, c.company_name;
```

## 5. Cara Menggunakan View

Setelah view dibuat, view dapat dipanggil seperti tabel biasa:

### Contoh Pemanggilan
```sql
SELECT * FROM view_pelanggan_aktif;
```

### Contoh Filter
```sql
SELECT * FROM view_pelanggan_aktif
WHERE jumlah_transaksi > 5;
```

## 6. Menghapus View

Jika view tidak lagi dibutuhkan, dapat dihapus dengan perintah berikut:

```sql
DROP VIEW IF EXISTS nama_view;
```

Contoh:
```sql
DROP VIEW IF EXISTS view_pelanggan_aktif;
```

## 7. Kesimpulan
View adalah alat bantu yang sangat **efisien**, **fleksibel**, dan **aman** dalam menyajikan data kompleks dengan cara yang sederhana. Penggunaan view sangat direkomendasikan untuk:
- Membuat laporan data dinamis tanpa query panjang berulang,
- Membatasi kolom akses pengguna tertentu,
- Mempercepat proses pemanggilan data untuk analisis.

View tidak menyimpan data, tetapi memberikan cara pandang baru terhadap data yang sama dengan tujuan yang lebih spesifik dan terkontrol.