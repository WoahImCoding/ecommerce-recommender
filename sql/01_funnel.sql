--- purchase funnel: how many customers reach a 2nd, 3rd and 5th shopping trip?
--- trip is a distinct shopping day, so one basket counts once
--- only customers with 180+ days of history, so recent joiners don't look like churners

with per_customer as (
    select customer_id,
           min(t_dat)  as first_day,
           count(distinct t_dat) as n_trips,
    from transactions
    group by 1
),

eligible as (
    select *
    from per_customer
    where first_day <= (select max(t_dat) from transactions) - INTERVAL 180 DAY 
)

select '1. First trip' as stage, count(*) as customers from eligible
union all 
select '2. Second trip', count(*) filter (where n_trips >=2) from eligible
union all
select '3. Third trip', count(*) filter (where n_trips >=3) from eligible
union all
select '4. Fifth trip', count(*) filter (where n_trips >= 5) from eligible
order by stage;