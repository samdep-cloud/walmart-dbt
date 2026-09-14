{{
  config(
    materialized = 'incremental',
    unique_key   = ['store_id', 'dept_id', 'date_id']
  )
}}

with joined as (
    select
        sales.store_id,
        sales.dept_id,
        sales.sales_date,                                             -- real DATE, carried forward
        to_number(to_char(sales.sales_date, 'YYYYMMDD')) as date_id,  -- key for dim_date join
        sales.weekly_sales,
        feat.temperature,
        feat.fuel_price,
        feat.cpi,
        feat.unemployment,
        feat.markdown1, feat.markdown2, feat.markdown3, feat.markdown4, feat.markdown5
    from {{ ref('stg_walmart__sales') }} sales
    left join {{ ref('stg_walmart__features') }} feat
        on  sales.store_id  = feat.store_id
        and sales.sales_date = feat.record_date
)

select
    src.store_id,
    src.dept_id,
    src.date_id,
    src.sales_date,                                    
    src.weekly_sales,
    src.temperature, src.fuel_price, src.cpi, src.unemployment,
    src.markdown1, src.markdown2, src.markdown3, src.markdown4, src.markdown5,

    {% if is_incremental() %}
    coalesce(existing.insert_date, current_timestamp()) as insert_date,
    {% else %}
    current_timestamp() as insert_date,
    {% endif %}
    current_timestamp() as update_date,

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