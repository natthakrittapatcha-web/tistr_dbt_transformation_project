-- models/marts/portfolio/dim_budget_category_sub.sql
{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_budget_category_sub/',
    file_format      = 'parquet'
) }}
with src as (
    select * from {{ source('rdms_systems', 'stg_budget_category_sub') }}
)
select
    sub_category_id,
    budget_category_id,
    code,
    name_th,
    reference_code_odoo,
    created_date,
    updated_date,
    cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'RDMS' as source_system,
    
    cast(current_timestamp as date) as load_date
from src