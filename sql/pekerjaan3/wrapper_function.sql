-- dapatkan semua laporan penjualan (display original)

CREATE OR REPLACE FUNCTION laporan_penjualan_2(
    periode_type TEXT,
    tanggal1 TEXT,
    tanggal2 TEXT DEFAULT NULL
)

RETURNS TABLE (
    type TEXT,
    start_date DATE,
    end_date DATE,
    total_money FLOAT,
    total_transaction BIGINT,
    total_product_sold BIGINT,
    total_customer BIGINT,
    mean_money_per_transaction FLOAT,
    mean_product_per_transaction BIGINT,
    mean_transaction_per_customer BIGINT,
    mean_money_per_customer FLOAT,
    best_sold_product TEXT,
    best_customer TEXT
)

LANGUAGE plpgsql AS $$

DECLARE
    t_start DATE;
    t_end DATE;
    money FLOAT;
    trx BIGINT;
    customer BIGINT;
    product BIGINT;
    mean_money_trx FLOAT;
    mean_product_trx BIGINT;
    mean_trx_cust BIGINT;
    mean_money_cust FLOAT;
    best_product_name TEXT;
    best_customer_name TEXT;

BEGIN
    SELECT * INTO t_start, t_end FROM get_start_end_date(periode_type, tanggal1, tanggal2);

    money := get_total_money(t_start, t_end);
    trx := get_total_transaction(t_start, t_end);
    customer := get_total_customer(t_start, t_end);
    product := get_total_product_sold(t_start, t_end);

    mean_money_trx := get_mean_money_per_transaction(t_start, t_end);
    mean_product_trx := get_mean_product_per_transaction(t_start, t_end);
    mean_trx_cust := get_mean_transaction_per_customer(t_start, t_end);
    mean_money_cust := get_mean_money_per_customer(t_start, t_end);

    SELECT product_name INTO best_product_name FROM get_best_sold_product(t_start, t_end) LIMIT 1;
    SELECT company_name INTO best_customer_name FROM get_best_customer(t_start, t_end) LIMIT 1;

    RETURN QUERY
    SELECT
        periode_type,
        t_start,
        t_end,
        money,
        trx,
        product,
        customer,
        mean_money_trx,
        mean_product_trx,
        mean_trx_cust,
        mean_money_cust,
        best_product_name,
        best_customer_name;
END;
$$;

-- debug
SELECT * FROM laporan_penjualan_2('harian', '1997-01-01'); -- harian
SELECT * FROM laporan_penjualan_2('bulanan', '1997-01');   -- bulanan
SELECT * FROM laporan_penjualan_2('tahunan', '1997');      -- tahunan


-- dapatkan semua laporan penjualan (display key value)

CREATE OR REPLACE FUNCTION laporan_penjualan(
    periode_type TEXT,
    tanggal1 TEXT,
    tanggal2 TEXT DEFAULT NULL
)

RETURNS TABLE (
    key TEXT,
    value TEXT
)

LANGUAGE plpgsql AS $$

DECLARE
    t_start DATE;
    t_end DATE;
    money FLOAT;
    trx BIGINT;
    customer BIGINT;
    product BIGINT;
    mean_money_trx FLOAT;
    mean_product_trx BIGINT;
    mean_trx_cust BIGINT;
    mean_money_cust FLOAT;
    best_product_name TEXT;
    best_customer_name TEXT;

BEGIN
    SELECT * INTO t_start, t_end FROM get_start_end_date(periode_type, tanggal1, tanggal2);

    money := get_total_money(t_start, t_end);
    trx := get_total_transaction(t_start, t_end);
    customer := get_total_customer(t_start, t_end);
    product := get_total_product_sold(t_start, t_end);

    mean_money_trx := get_mean_money_per_transaction(t_start, t_end);
    mean_product_trx := get_mean_product_per_transaction(t_start, t_end);
    mean_trx_cust := get_mean_transaction_per_customer(t_start, t_end);
    mean_money_cust := get_mean_money_per_customer(t_start, t_end);

    SELECT product_name INTO best_product_name FROM get_best_sold_product(t_start, t_end) LIMIT 1;
    SELECT company_name INTO best_customer_name FROM get_best_customer(t_start, t_end) LIMIT 1;

    RETURN QUERY VALUES
        ('Tipe periode', periode_type),
        ('start_date', t_start::TEXT),
        ('end_date', t_end::TEXT),
        ('Total pemasukan', money::TEXT),
        ('Total transaksi', trx::TEXT),
        ('Total produk terjual', product::TEXT),
        ('Total pelanggan', customer::TEXT),
        ('Rata-rata jumlah uang per transaksi', mean_money_trx::TEXT),
        ('Rata-rata jumlah item per transaksi', mean_product_trx::TEXT),
        ('Rata-rata transaksi tiap pelanggan', mean_trx_cust::TEXT),
        ('Rata-rata pembelanjaan tiap pelanggan', mean_money_cust::TEXT),
        ('Produk paling banyak terjual', COALESCE(best_product_name, 'N/A')),
        ('Pelanggan paling banyak bertransaksi', COALESCE(best_customer_name, 'N/A'));

END;
$$;

-- debug
SELECT * FROM laporan_penjualan('harian', '1997-01-01'); -- harian
SELECT * FROM laporan_penjualan('bulanan', '1997-01');   -- bulanan
SELECT * FROM laporan_penjualan('tahunan', '1997');      -- tahunan