-- models/infrastructure/dim_purchase_order_item.sql

{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_purchase_order_item/',
    file_format      = 'parquet'
) }}
with src as (
    select * from {{ source('sap_systems', 'stg_purchase_order_item') }}
)
select
    po_number,
    po_item,
    "material_description________________#0" as material_description,
    material_code,
    company_code,
    plant,
    material_group,
    quantity,
    unit_of_measure,
    net_price,
    price_unit,
    net_value,
    "gross_value#1" as gross_value,
    tax_code,
    item_category,
    account_assignment_category,
    cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'SAP' as source_system,
    
    cast(current_timestamp as date) as load_date
from src