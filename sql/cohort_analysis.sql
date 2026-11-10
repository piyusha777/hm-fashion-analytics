WITH first_purchase AS (
    SELECT customer_id, MIN(t_dat) AS cohort_date
    FROM transactions
    GROUP BY customer_id
)
SELECT
    t.customer_id,
    DATE_TRUNC('week', fp.cohort_date)::date AS cohort_week,
    DATE_TRUNC('week', t.t_dat)::date AS transaction_week
FROM transactions t
JOIN first_purchase fp ON t.customer_id = fp.customer_id;