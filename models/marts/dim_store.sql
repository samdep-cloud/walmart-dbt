{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['store_id', 'dept_id']
    )
}}

with store_departments as (
    select distinct
        store_id,
        dept_id
    from {{ ref('stg_walmart__sales') }}
),

prepared as (
    select
        sd.store_id,
        sd.dept_id,
        stores.store_type,
        stores.store_size
    from store_departments sd
    left join {{ ref('stg_walmart__stores') }} stores
        on sd.store_id = stores.store_id
)

select
    src.store_id,
    src.dept_id,
    src.store_type,
    src.store_size,

    {% if is_incremental() %}
    coalesce(existing.insert_date, current_timestamp()) as insert_date,
    {% else %}
    current_timestamp() as insert_date,
    {% endif %}

    current_timestamp() as update_date

from prepared src

{% if is_incremental() %}
left join {{ this }} existing
    on src.store_id = existing.store_id
   and src.dept_id = existing.dept_id
{% endif %}