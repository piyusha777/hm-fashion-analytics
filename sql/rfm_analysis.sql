SELECT
    customer_id,
    (DATE '2020-09-23' - MAX(t_dat)) AS recency_days,
    COUNT(DISTINCT t_dat) AS frequency,
    SUM(price) AS monetary
FROM transactions
GROUP BY customer_id;