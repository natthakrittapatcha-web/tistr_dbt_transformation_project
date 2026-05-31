-- models/infrastructure/dim_asset_register.sql

{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_asset_register/',
    file_format      = 'parquet'
) }}

with src as (
    select * from {{ source('sap_systems', 'stg_asset_register') }}
)

select	
    asset_main,
    asset_sub,
    asset_name,
    asset_class,
    asset_class_description,
    company_code,
    is_deleted,
    account_determination,
    deactivated_date,
    serial_number,
    inventory_no,
    acquisition_date,
    as_of_date,
    fiscal_year,
    fiscal_period,
    original_value,
    accumulated_depreciation,
    net_book_value,
    business_area,
    cost_center,
    plant,
    location,
    personal_no,
    fund,
    funds_center,
    order_41,
    order_42,
    evaluation_group_code,
    super_asset_number,
    cast(null as varchar) as is_critical,       
    cast(null as varchar) as esg_category,    
    cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'SAP' as source_system,
    
    cast(current_timestamp as date) as load_date
from src