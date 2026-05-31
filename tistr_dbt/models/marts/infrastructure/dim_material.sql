-- models/infrastructure/dim_material.sql

{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_material/',
    file_format      = 'parquet'
) }}

with src as (
    select * from {{ source('sap_systems', 'stg_material') }}
)

select
    material_code
    bigint,
    material_description,
    material_type,
    material_group,
    base_uom,
    total_stock,
    total_value,
    price_control,
    moving_average_price,
    valuation_class,
    alternate_uom,
    uom_numerator,
    uom_denominator,
    cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'SAP' as source_system,
    
    cast(current_timestamp as date) as load_date
from src