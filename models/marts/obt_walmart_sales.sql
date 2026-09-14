{{
    config(
        materialized = 'table'
    )

}}

-- OBT: flat serving layer for visualization via Python
-- GRAIN: one row per store x department x week (same grain as fact)
-- Joins the fact to store + date attributes ONCE here, so Python can read all data required for viz into a single, ready-to-use dataframe
-- Plain table, not incremental. Derived from models that already handle the incrementality/version, so it just rebuilds each run 
-- Small dataset, so cheap at this scale - but reconsider workflow at scale

with fact as (
    select *
    from {{ ref('fact_sales') }}
    where vrsn_end_date = to_timestamp('9999-12-31')   -- current version only; guards against SCD dupes
),

store as (
    select store_id, store_type, store_size
    from {{ ref('dim_store') }}
),

dates as (
    select date_id, isholiday
    from {{ ref('dim_date') }}
)

select
    -- dimensions for downstreaming aggregation 
    fact.sales_date, 
    fact.store_id,
    fact.dept_id,

    -- measure
    fact.weekly_sales,

    -- store attributes
    store.store_type,
    store.store_size,

    -- date attribute 
    case when dates.isholiday = 'true' then true else false end as is_holiday,

    -- store-week context (macro-economic features)
    fact.temperature,
    fact.fuel_price,
    fact.cpi,
    fact.unemployment,
    fact.markdown1, fact.markdown2, fact.markdown3, fact.markdown4, fact.markdown5

from fact
left join store on fact.store_id = store.store_id
left join dates on fact.date_id  = dates.date_id