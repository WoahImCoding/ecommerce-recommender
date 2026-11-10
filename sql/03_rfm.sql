--- rfm segmentation and each segment's share of customers and revenue.
--- frequency uses fixed bands: many customers have only 1 trip, so quintiles split ties arbitrarily.

with ref as(
    select max(t_dat) + interval 1 DAY as ref_date from transactions
)