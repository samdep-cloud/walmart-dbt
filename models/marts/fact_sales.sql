{{ config(materialized='table') }}

select
    store_id,
    dept_id,
    date_id,
    sales_date,
    store_size,
    weekly_sales,
    fuel_price,
    temperature,
    unemployment,
    cpi,
    markdown1,
    markdown2,
    markdown3,
    markdown4,
    markdown5,
    dbt_valid_from as vrsn_start_date,
    dbt_valid_to as vrsn_end_date,
    dbt_valid_from as insert_date,
    coalesce(dbt_valid_to, dbt_valid_from) as update_date
from {{ ref('walmart_sales_history') }}