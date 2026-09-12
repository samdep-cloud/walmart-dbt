{{
  config(
    materialized = 'incremental',
    unique_key   = 'date_id'
  )
}}

with all_dates as (
    -- dates live in TWO source models; pull from both
    select sales_date   as calendar_date, is_holiday from {{ ref('stg_walmart__department') }}
    union all
    select weather_date as calendar_date, is_holiday from {{ ref('stg_walmart__fact') }}
),

deduped as (
    -- one row per date; if any row flags the week as a holiday, it's a holiday
    select
        calendar_date,
        max(case when is_holiday then 1 else 0 end) as holiday_flag
    from all_dates
    group by calendar_date
),

prepared as (
    select
        to_number(to_char(calendar_date, 'YYYYMMDD')) as date_id,
        calendar_date as store_date,
        case when holiday_flag = 1 then 'true' else 'false' end as isholiday
    from deduped
)

select
    src.date_id,
    src.store_date,
    src.isholiday,

    {% if is_incremental() %}
    coalesce(existing.insert_date, current_timestamp()) as insert_date,
    {% else %}
    current_timestamp() as insert_date,
    {% endif %}

    current_timestamp() as update_date

from prepared src

{% if is_incremental() %}
left join {{ this }} existing on src.date_id = existing.date_id
{% endif %}