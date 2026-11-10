-- 1. Basic scale and time span
SELECT
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT article_id) AS unique_articles,
    MIN(t_dat) AS first_date,
    MAX(t_dat) AS last_date
FROM transactions;

-- 2. Sales channel split (channel 1 vs 2 — likely in-store vs online, though the
--    dataset does not explicitly document which is which; verify before labelling)
SELECT
    sales_channel_id,
    COUNT(*) AS transactions,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_total,
    ROUND(AVG(price)::numeric, 5) AS avg_price
FROM transactions
GROUP BY sales_channel_id
ORDER BY transactions DESC;

-- Channel split within each category
SELECT
    a.product_group_name,
    SUM(CASE WHEN t.sales_channel_id = 2 THEN 1 ELSE 0 END) AS online_units,
    SUM(CASE WHEN t.sales_channel_id = 1 THEN 1 ELSE 0 END) AS instore_units,
    ROUND(100.0 * SUM(CASE WHEN t.sales_channel_id = 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_online,
    ROUND(AVG(CASE WHEN t.sales_channel_id = 2 THEN t.price END)::numeric, 5) AS avg_price_online,
    ROUND(AVG(CASE WHEN t.sales_channel_id = 1 THEN t.price END)::numeric, 5) AS avg_price_instore
FROM transactions t
JOIN articles a ON t.article_id = a.article_id
GROUP BY a.product_group_name
HAVING COUNT(*) >= 1000
ORDER BY online_units DESC;

-- 3. Daily transaction volume — checks for gaps, spikes, or weekly seasonality
SELECT
    t_dat,
    COUNT(*) AS transactions
FROM transactions
GROUP BY t_dat
ORDER BY t_dat;

-- 4. Transactions per customer — how concentrated is purchasing?
SELECT
    transactions_per_customer,
    COUNT(*) AS num_customers
FROM (
    SELECT customer_id, COUNT(*) AS transactions_per_customer
    FROM transactions
    GROUP BY customer_id
) sub
GROUP BY transactions_per_customer
ORDER BY transactions_per_customer
LIMIT 25;

-- 5. Customer age distribution — note ~1.2% missing, confirmed in Phase 1
SELECT
    CASE
        WHEN age IS NULL THEN 'Unknown'
        WHEN age < 25 THEN 'Under 25'
        WHEN age < 35 THEN '25-34'
        WHEN age < 45 THEN '35-44'
        WHEN age < 55 THEN '45-54'
        WHEN age < 65 THEN '55-64'
        ELSE '65+'
    END AS age_band,
    COUNT(*) AS customers
FROM customers
GROUP BY age_band
ORDER BY customers DESC;

-- 6. Club member status breakdown
SELECT
    COALESCE(club_member_status, 'Missing') AS status,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM customers
GROUP BY club_member_status
ORDER BY customers DESC;

-- 7. Index group breakdown (Ladieswear, Menswear, etc.) — top-level assortment split
SELECT
    a.index_group_name,
    COUNT(*) AS units_sold,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_units
FROM transactions t
JOIN articles a ON t.article_id = a.article_id
GROUP BY a.index_group_name
ORDER BY units_sold DESC;