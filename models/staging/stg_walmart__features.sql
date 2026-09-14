select
    store        as store_id,
    date         as record_date,
    temperature,
    fuel_price,
    markdown1,
    markdown2,
    markdown3,
    markdown4,
    markdown5,
    cpi,
    unemployment,
    isholiday    as is_holiday
from {{ source('raw', 'features') }}