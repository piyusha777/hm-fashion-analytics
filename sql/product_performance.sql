SELECT
    a.product_group_name,
    COUNT(*) AS units_sold,
    SUM(t.price) AS total_relative_revenue,
    AVG(t.price) AS avg_price
FROM transactions t
JOIN articles a ON t.article_id = a.article_id
GROUP BY a.product_group_name
ORDER BY total_relative_revenue DESC;


SELECT
    a.product_group_name,
    t.article_id,
    a.prod_name,
    a.product_type_name,
    COUNT(*) AS units_sold,
    SUM(t.price) AS total_relative_revenue,
    AVG(t.price) AS avg_price
FROM transactions t
JOIN articles a ON t.article_id = a.article_id
WHERE a.product_group_name IN ('Garment Upper body', 'Garment Lower body', 'Garment Full body')
GROUP BY a.product_group_name, t.article_id, a.prod_name, a.product_type_name;


SELECT
    a.product_group_name,
    t.article_id,
    COUNT(*) AS units_sold,
    AVG(t.price) AS avg_price
FROM transactions t
JOIN articles a ON t.article_id = a.article_id
GROUP BY a.product_group_name, t.article_id
HAVING COUNT(*) >= 10;