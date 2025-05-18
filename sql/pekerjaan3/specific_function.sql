-- fungsi : mendapat date awal dan date akhir yang akan dicek
CREATE OR REPLACE FUNCTION get_start_end_date(
    periode_type TEXT,
    tanggal1 TEXT,
    tanggal2 TEXT DEFAULT NULL
)

RETURNS TABLE(start_date DATE, end_date DATE)
LANGUAGE plpgsql AS $$
BEGIN

    IF periode_type = 'bulanan' THEN
        start_date := TO_DATE(tanggal1 || '-01', 'YYYY-MM-DD');
        end_date := (start_date + INTERVAL '1 month - 1 day')::DATE;

    ELSIF periode_type = 'tahunan' THEN
        start_date := TO_DATE(tanggal1 || '-01-01', 'YYYY-MM-DD');
        end_date := TO_DATE(tanggal1 || '-12-31', 'YYYY-MM-DD');

    ELSIF periode_type = 'mingguan' THEN
        start_date := TO_DATE(tanggal1, 'YYYY-MM-DD');
        IF EXTRACT(DOW FROM start_date) = 0 THEN
            start_date := start_date - INTERVAL '6 days';
        ELSE
            start_date := start_date - (EXTRACT(DOW FROM start_date)::INTEGER - 1);
        END IF;
        end_date := start_date + INTERVAL '6 days';

    ELSIF periode_type = 'range' AND tanggal2 IS NOT NULL THEN
        start_date := TO_DATE(tanggal1, 'YYYY-MM-DD');
        end_date := TO_DATE(tanggal2, 'YYYY-MM-DD');

    ELSE
        start_date := TO_DATE(tanggal1, 'YYYY-MM-DD');
        end_date := start_date;

    END IF;
    RETURN NEXT;

END;
$$;
-- debug
SELECT * FROM get_start_end_date('type', 'YYYY-MM-DD', 'YYYY-MM-DD(optional_if_type_range)');
SELECT * FROM get_start_end_date('harian', '1997-05-25');
SELECT * FROM get_start_end_date('mingguan', '1997-05-25');
SELECT * FROM get_start_end_date('bulanan', '1997-05');
SELECT * FROM get_start_end_date('tahunan', '1997');
SELECT * FROM get_start_end_date('range', '1997-05-01', '1997-05-25');


-- fungsi : mendapat jumlah uang pada periode tertentu
CREATE OR REPLACE FUNCTION get_total_money(
    start_date DATE,
    end_date DATE
)

RETURNS FLOAT AS $$
DECLARE
    total FLOAT;
BEGIN
    SELECT SUM(
        od.unit_price * od.quantity * (1 - od.discount)
    ) INTO total
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    WHERE o.order_date BETWEEN start_date AND end_date;
    RETURN COALESCE(total, 0);
END;
$$ LANGUAGE plpgsql;
-- debug
SELECT * FROM get_total_money('YYYY-MM-DD', 'YYYY-MM-DD');
SELECT * FROM get_total_money('1997-01-01', '1997-01-01'); -- harian
SELECT * FROM get_total_money('1997-01-01', '1997-01-31'); -- bulanan
SELECT * FROM get_total_money('1997-01-01', '1997-12-31'); -- tahunan


-- fungsi : mendapat jumlah transaksi/order pada periode tertentu
CREATE OR REPLACE FUNCTION get_total_transaction(
    start_date DATE,
    end_date DATE
)

RETURNS BIGINT AS $$
DECLARE
    total BIGINT;
BEGIN
    SELECT COUNT(*) INTO total FROM orders
    WHERE order_date BETWEEN start_date AND end_date;
    RETURN total;
END;
$$ LANGUAGE plpgsql;
-- debug
SELECT * FROM get_total_transaction('YYYY-MM-DD', 'YYYY-MM-DD');
SELECT * FROM get_total_transaction('1997-01-01', '1997-01-01'); -- harian
SELECT * FROM get_total_transaction('1997-01-01', '1997-01-31'); -- bulanan
SELECT * FROM get_total_transaction('1997-01-01', '1997-12-31'); -- tahunan


-- fungsi : mendapat jumlah customer (unik dengan DISTINCT) pada periode tertentu
CREATE OR REPLACE FUNCTION get_total_customer(
    start_date DATE,
    end_date DATE
)

RETURNS BIGINT AS $$
DECLARE
    total BIGINT;
BEGIN
    SELECT COUNT(DISTINCT customer_id) INTO total FROM orders
    WHERE order_date BETWEEN start_date AND end_date;
    RETURN total;
END;
$$ LANGUAGE plpgsql;
-- debug
SELECT * FROM get_total_customer('YYYY-MM-DD', 'YYYY-MM-DD');
SELECT * FROM get_total_customer('1997-01-01', '1997-01-01'); -- harian
SELECT * FROM get_total_customer('1997-01-01', '1997-01-31'); -- bulanan
SELECT * FROM get_total_customer('1997-01-01', '1997-12-31'); -- tahunan


-- fungsi : mendapat jumlah produk terjual (unik dengan DISTINCT) pada periode tertentu
CREATE OR REPLACE FUNCTION get_total_product_sold_unique(
    start_date DATE,
    end_date DATE
)

RETURNS BIGINT AS $$
DECLARE
    total BIGINT;
BEGIN
    SELECT COUNT(*) INTO total
    FROM (
        SELECT DISTINCT o.order_id, od.product_id FROM orders o
        JOIN order_details od ON o.order_id = od.order_id
        WHERE o.order_date BETWEEN start_date AND end_date
    ) sub;
    RETURN total;
END;
$$ LANGUAGE plpgsql;
-- debug
SELECT * FROM get_total_product_sold_unique('YYYY-MM-DD', 'YYYY-MM-DD');
SELECT * FROM get_total_product_sold_unique('1997-01-01', '1997-01-01'); -- harian
SELECT * FROM get_total_product_sold_unique('1997-01-01', '1997-01-31'); -- bulanan
SELECT * FROM get_total_product_sold_unique('1997-01-01', '1997-12-31'); -- tahunan


-- fungsi : mendapat jumlah produk terjual pada periode tertentu
CREATE OR REPLACE FUNCTION get_total_product_sold(
    start_date DATE,
    end_date DATE
)

RETURNS BIGINT AS $$
DECLARE
    total BIGINT;
BEGIN
    SELECT SUM(od.quantity)::BIGINT INTO total FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    WHERE o.order_date BETWEEN start_date AND end_date;
    RETURN COALESCE(total, 0);
END;
$$ LANGUAGE plpgsql;
-- debug
SELECT * FROM get_total_product_sold('YYYY-MM-DD', 'YYYY-MM-DD');
SELECT * FROM get_total_product_sold('1997-01-01', '1997-01-01'); -- harian
SELECT * FROM get_total_product_sold('1997-01-01', '1997-01-31'); -- bulanan
SELECT * FROM get_total_product_sold('1997-01-01', '1997-12-31'); -- tahunan


-- fungsi : mendapat produk terlaris pada periode tertentu
CREATE OR REPLACE FUNCTION get_best_sold_product(
    start_date DATE,
    end_date DATE
)

RETURNS TABLE (
    product_id BIGINT,
    product_name TEXT,
    unit_price REAL
) AS $$

BEGIN
    RETURN QUERY
    SELECT 
        p.product_id,
        p.product_name::TEXT,
        p.unit_price
    FROM order_details od
    JOIN orders o ON o.order_id = od.order_id
    JOIN products p ON p.product_id = od.product_id
    WHERE o.order_date BETWEEN start_date AND end_date
    GROUP BY p.product_id, p.product_name, p.unit_price
    ORDER BY SUM(od.quantity) DESC
    LIMIT 1;

END;
$$ LANGUAGE plpgsql;
-- debug
SELECT * FROM get_best_sold_product('YYYY-MM-DD', 'YYYY-MM-DD');
SELECT * FROM get_best_sold_product('1997-01-01', '1997-01-01'); -- harian
SELECT * FROM get_best_sold_product('1997-01-01', '1997-01-31'); -- bulanan
SELECT * FROM get_best_sold_product('1997-01-01', '1997-12-31'); -- tahunan


-- fungsi : mendapat customer paling banyak spend money pada periode tertentu
CREATE OR REPLACE FUNCTION get_best_customer(
    start_date DATE,
    end_date DATE
)

RETURNS TABLE (
    customer_id TEXT,
    company_name TEXT,
    total_spending FLOAT
) AS $$

BEGIN
    RETURN QUERY
    SELECT 
        c.customer_id::TEXT,
        c.company_name::TEXT,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_spending
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_date BETWEEN start_date AND end_date
    GROUP BY c.customer_id, c.company_name
    ORDER BY total_spending DESC
    LIMIT 1;

END;
$$ LANGUAGE plpgsql;
-- debug
SELECT * FROM get_best_customer('YYYY-MM-DD', 'YYYY-MM-DD');
SELECT * FROM get_best_customer('1997-01-01', '1997-01-01'); -- harian
SELECT * FROM get_best_customer('1997-01-01', '1997-01-31'); -- bulanan
SELECT * FROM get_best_customer('1997-01-01', '1997-12-31'); -- tahunan


-- fungsi : mendapat rata-rata jumlah uang per transaksi pada periode tertentu
CREATE OR REPLACE FUNCTION get_mean_money_per_transaction(
    start_date DATE,
    end_date DATE
)

RETURNS FLOAT AS $$
DECLARE
    result FLOAT;
BEGIN
    SELECT AVG(sub.total)::FLOAT INTO result
    FROM (
        SELECT SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total
        FROM orders o
        JOIN order_details od ON o.order_id = od.order_id
        WHERE o.order_date BETWEEN start_date AND end_date
        GROUP BY o.order_id
    ) sub;
    RETURN COALESCE(result, 0);
END;
$$ LANGUAGE plpgsql;
-- debug
SELECT * FROM get_mean_money_per_transaction('YYYY-MM-DD', 'YYYY-MM-DD');
SELECT * FROM get_mean_money_per_transaction('1997-01-01', '1997-01-01'); -- harian
SELECT * FROM get_mean_money_per_transaction('1997-01-01', '1997-01-31'); -- bulanan
SELECT * FROM get_mean_money_per_transaction('1997-01-01', '1997-12-31'); -- tahunan


-- fungsi : mendapat rata-rata jumlah produk per transaksi pada periode tertentu
CREATE OR REPLACE FUNCTION get_mean_product_per_transaction(
    start_date DATE,
    end_date DATE
)

RETURNS BIGINT AS $$
DECLARE
    result FLOAT;
BEGIN
    SELECT AVG(sub.total)::FLOAT INTO result
    FROM (
        SELECT COUNT(*) AS total
        FROM orders o
        JOIN order_details od ON o.order_id = od.order_id
        WHERE o.order_date BETWEEN start_date AND end_date
        GROUP BY o.order_id
    ) sub;
    RETURN COALESCE(result, 0)::BIGINT;
END;
$$ LANGUAGE plpgsql;
-- debug
SELECT * FROM get_mean_product_per_transaction('YYYY-MM-DD', 'YYYY-MM-DD');
SELECT * FROM get_mean_product_per_transaction('1997-01-01', '1997-01-01'); -- harian
SELECT * FROM get_mean_product_per_transaction('1997-01-01', '1997-01-31'); -- bulanan
SELECT * FROM get_mean_product_per_transaction('1997-01-01', '1997-12-31'); -- tahunan


-- fungsi : mendapat rata-rata jumlah transaksi per customer (unik dengan DISTINCT) pada periode tertentu
CREATE OR REPLACE FUNCTION get_mean_transaction_per_customer(
    start_date DATE,
    end_date DATE
)

RETURNS BIGINT AS $$
DECLARE
    result FLOAT;
BEGIN
    SELECT COUNT(*)::FLOAT / NULLIF(COUNT(DISTINCT customer_id), 0)::FLOAT INTO result
    FROM orders
    WHERE order_date BETWEEN start_date AND end_date;
    RETURN COALESCE(result, 0)::BIGINT;
END;
$$ LANGUAGE plpgsql;
-- debug
SELECT * FROM get_mean_transaction_per_customer('YYYY-MM-DD', 'YYYY-MM-DD');
SELECT * FROM get_mean_transaction_per_customer('1997-01-01', '1997-01-01'); -- harian
SELECT * FROM get_mean_transaction_per_customer('1997-01-01', '1997-01-31'); -- bulanan
SELECT * FROM get_mean_transaction_per_customer('1997-01-01', '1997-12-31'); -- tahunan


-- fungsi : mendapat rata-rata jumlah uang per customer (unik dengan DISTINCT) pada periode tertentu
CREATE OR REPLACE FUNCTION get_mean_money_per_customer(
    start_date DATE,
    end_date DATE
)

RETURNS FLOAT AS $$
DECLARE
    result FLOAT;
BEGIN
    SELECT SUM(od.unit_price * od.quantity * (1 - od.discount))::FLOAT
           / NULLIF(COUNT(DISTINCT o.customer_id), 0)::FLOAT
    INTO result
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    WHERE o.order_date BETWEEN start_date AND end_date;
    RETURN COALESCE(result, 0);
END;
$$ LANGUAGE plpgsql;
-- debug
SELECT * FROM get_mean_money_per_customer('YYYY-MM-DD', 'YYYY-MM-DD');
SELECT * FROM get_mean_money_per_customer('1997-01-01', '1997-01-01'); -- harian
SELECT * FROM get_mean_money_per_customer('1997-01-01', '1997-01-31'); -- bulanan
SELECT * FROM get_mean_money_per_customer('1997-01-01', '1997-12-31'); -- tahunan