{{
  config(
    materialized = 'incremental',
    unique_key   = ['store_id', 'dept_id', 'date_id']
  )
}}

with joined as (
    select
        dept.store_id,
        dept.dept_id,
        to_number(to_char(dept.sales_date, 'YYYYMMDD')) as date_id,
        dept.weekly_sales,
        fct.temperature,
        fct.fuel_price,
        fct.cpi,
        fct.unemployment,
        fct.markdown1, fct.markdown2, fct.markdown3, fct.markdown4, fct.markdown5
    from {{ ref('stg_walmart__department') }} dept
    left join {{ ref('stg_walmart__fact') }} fct
        on  dept.store_id   = fct.store_id
        and dept.sales_date = fct.weather_date
)

select
    src.store_id,
    src.dept_id,
    src.date_id,
    src.weekly_sales,
    src.temperature, src.fuel_price, src.cpi, src.unemployment,
    src.markdown1, src.markdown2, src.markdown3, src.markdown4, src.markdown5,

    -- audit + version columns
    {% if is_incremental() %}
    coalesce(existing.insert_date, current_timestamp()) as insert_date,
    {% else %}
    current_timestamp() as insert_date,
    {% endif %}
    current_timestamp()            as update_date,

    {% if is_incremental() %}
    coalesce(existing.vrsn_start_date, current_timestamp()) as vrsn_start_date,
    {% else %}
    current_timestamp() as vrsn_start_date,
    {% endif %}
    to_timestamp('9999-12-31') as vrsn_end_date

from joined src

{% if is_incremental() %}
left join {{ this }} existing
    on  src.store_id = existing.store_id
    and src.dept_id  = existing.dept_id
    and src.date_id  = existing.date_id
    and existing.vrsn_end_date = to_timestamp('9999-12-31')
{% endif %}