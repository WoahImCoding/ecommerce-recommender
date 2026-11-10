-- Monthly acquisition cohorts: what % of each cohort buys again N months after joining?

WITH first_month AS (
    -- each customer's cohort = the month of their first purchase
    SELECT customer_id, date_trunc('month', min(t_dat)) AS cohort_month
    FROM transactions
    GROUP BY 1
),
activity AS (
    -- every month each customer was active (bought at least once)
    SELECT DISTINCT customer_id, date_trunc('month', t_dat) AS active_month
    FROM transactions
),
cohort_size AS (
    -- how many customers started in each month
    SELECT cohort_month, count(*) AS cohort_customers
    FROM first_month
    GROUP BY 1
)
SELECT f.cohort_month,
       date_diff('month', f.cohort_month, a.active_month) AS months_since_first,
       count(*)                                           AS active_customers,
       s.cohort_customers,
       round(100.0 * count(*) / s.cohort_customers, 2)    AS retention_pct
FROM first_month f
JOIN activity a    USING (customer_id)
JOIN cohort_size s USING (cohort_month)
GROUP BY 1, 2, 4
ORDER BY 1, 2;