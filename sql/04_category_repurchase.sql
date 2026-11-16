-- Repeat behaviour by product group.
--   category_repeat_rate:  buyers who bought from the group on 2+ different days
--   same_item_repeat_rate: (customer, article) pairs bought on 2+ different days

WITH tx AS (
    -- attach each transaction's product group once, keeping only the columns we need
    SELECT t.customer_id, t.article_id, t.t_dat, a.product_group_name
    FROM transactions t
    JOIN articles a USING (article_id)
),
cust_cat AS (
    -- one row per (customer, category): on how many days they bought from it
    SELECT customer_id, product_group_name, count(DISTINCT t_dat) AS n_days
    FROM tx
    GROUP BY 1, 2
),
cust_item AS (
    -- one row per (customer, item): on how many days they bought that exact item
    SELECT customer_id, article_id, product_group_name, count(DISTINCT t_dat) AS n_days
    FROM tx
    GROUP BY 1, 2, 3
),
cat AS (
    SELECT product_group_name,
           count(*) AS buyers,
           round(100.0 * avg(CASE WHEN n_days >= 2 THEN 1 ELSE 0 END), 1) AS category_repeat_rate
    FROM cust_cat
    GROUP BY 1
),
item AS (
    SELECT product_group_name,
           round(100.0 * avg(CASE WHEN n_days >= 2 THEN 1 ELSE 0 END), 2) AS same_item_repeat_rate
    FROM cust_item
    GROUP BY 1
)
SELECT cat.*, item.same_item_repeat_rate
FROM cat
JOIN item USING (product_group_name)
WHERE buyers >= 1000
ORDER BY buyers DESC;