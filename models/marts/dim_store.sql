{{
  config(
    materialized = 'incremental',
    unique_key   = 'store_id'
  )
}}

with source as (
    select
        store_id,
        store_type,
        store_size
    from {{ ref('stg_walmart__stores') }}
)

select
    src.store_id,
    src.store_type,
    src.store_size,

    {% if is_incremental() %}
    coalesce(existing.insert_date, current_timestamp()) as insert_date,
    {% else %}
    current_timestamp() as insert_date,
    {% endif %}

    current_timestamp() as update_date

from source src

{% if is_incremental() %}
left join {{ this }} existing
    on src.store_id = existing.store_id
{% endif %}