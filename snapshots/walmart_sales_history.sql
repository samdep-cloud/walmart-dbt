{% snapshot walmart_sales_history %}

{{
    config(
        target_database=target.database,
        target_schema=target.schema,
        unique_key='sales_record_key',
        strategy='check',
        check_cols=[
            'store_size',
            'weekly_sales',
            'fuel_price',
            'temperature',
            'unemployment',
            'cpi',
            'markdown1',
            'markdown2',
            'markdown3',
            'markdown4',
            'markdown5'
        ]
    )
}}

select
    concat(
        to_varchar(sales.store_id), '|',
        to_varchar(sales.dept_id), '|',
        to_char(sales.sales_date, 'YYYYMMDD')
    ) as sales_record_key,

    sales.store_id,
    sales.dept_id,
    sales.sales_date,
    to_number(to_char(sales.sales_date, 'YYYYMMDD')) as date_id,
    stores.store_size,
    sales.weekly_sales,
    feat.fuel_price,
    feat.temperature,
    feat.unemployment,
    feat.cpi,
    feat.markdown1,
    feat.markdown2,
    feat.markdown3,
    feat.markdown4,
    feat.markdown5

from {{ ref('stg_walmart__sales') }} sales

left join {{ ref('stg_walmart__features') }} feat
    on sales.store_id = feat.store_id
   and sales.sales_date = feat.record_date

left join {{ ref('dim_store') }} stores
    on sales.store_id = stores.store_id
   and sales.dept_id = stores.dept_id

{% endsnapshot %}