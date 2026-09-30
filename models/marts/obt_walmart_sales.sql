{{
    config(
        materialized = 'table'
    )

}}

-- OBT: flat serving layer for efficient downstream analysis of sales and other, related features
-- GRAIN: one row per store x department x week  

with current_sales as (
    select *
    from {{ ref('fact_sales') }}
    where vrsn_end_date is null
)

select
    fact.sales_date,
    fact.store_id,
    fact.dept_id,
    fact.weekly_sales,

    stores.store_type,
    fact.store_size,

    case
        when dates.isholiday = 'true' then true
        else false
    end as is_holiday,

    fact.temperature,
    fact.fuel_price,
    fact.cpi,
    fact.unemployment,
    fact.markdown1,
    fact.markdown2,
    fact.markdown3,
    fact.markdown4,
    fact.markdown5

from current_sales fact

left join {{ ref('dim_store') }} stores
    on fact.store_id = stores.store_id
   and fact.dept_id = stores.dept_id

left join {{ ref('dim_date') }} dates
    on fact.date_id = dates.date_id