-- models/infrastructure/dim_asset_category.sql

{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_asset_category/',
    file_format      = 'parquet'
) }}
with src as (
    select * from {{ source('sap_systems', 'stg_category_asset') }}
)

select
    category_code,
    category_name,
    cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'SAP' as source_system,
    
    cast(current_timestamp as date) as load_date
from src
