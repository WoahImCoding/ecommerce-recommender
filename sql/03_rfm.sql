-- RFM segmentation and each segment's share of customers and revenue.
-- Frequency uses fixed bands: many customers have only 1 trip, so quintiles would split ties arbitrarily.

WITH ref AS (
    -- the "today" we measure recency from: the day after the data ends
    SELECT max(t_dat) + INTERVAL 1 DAY AS ref_date FROM transactions
),
base AS (
    -- one row per customer with their R, F and M values
    SELECT customer_id,
           date_diff('day', max(t_dat), (SELECT ref_date FROM ref)) AS recency_days,
           count(DISTINCT t_dat)                                    AS frequency,
           sum(price)                                               AS monetary
    FROM transactions
    GROUP BY 1
),
scored AS (
    -- turn the raw values into 1-5 scores (5 = best)
    SELECT *,
           ntile(5) OVER (ORDER BY recency_days DESC) AS r_score,
           CASE WHEN frequency = 1  THEN 1
                WHEN frequency = 2  THEN 2
                WHEN frequency <= 4 THEN 3
                WHEN frequency <= 9 THEN 4
                ELSE 5 END                            AS f_score
    FROM base
),
segmented AS (
    -- name the segments from the score combinations
    SELECT *,
           CASE WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
                WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
                WHEN r_score >= 4 AND f_score <= 2 THEN 'New / promising'
                WHEN r_score <= 2 AND f_score >= 3 THEN 'At risk'
                WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating / lost'
                ELSE 'Needs attention' END AS segment
    FROM scored
)
SELECT segment,
       count(*)                                                     AS customers,
       round(100.0 * count(*) / sum(count(*)) OVER (), 1)           AS pct_customers,
       round(100.0 * sum(monetary) / sum(sum(monetary)) OVER (), 1) AS pct_revenue,
       round(avg(recency_days))                                     AS avg_recency_days,
       round(avg(frequency), 1)                                     AS avg_trips
FROM segmented
GROUP BY segment
ORDER BY pct_revenue DESC;