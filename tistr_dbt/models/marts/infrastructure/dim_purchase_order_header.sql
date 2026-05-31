-- models/infrastructure/dim_purchase_order_header.sql
{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_purchase_order_header/',
    file_format      = 'parquet'
) }}

with src as (
    select * from {{ source('sap_systems', 'stg_purchase_order_header') }}
)

select
    po_number,
    company_code,
    document_category,
    document_type,
    creation_date,
    created_by,
    vendor,
    payment_term,
    purchasing_org,
    purchasing_group,
    currency,
    exchange_rate,
    document_date,
    validity_start,
    validity_end,
    incoterms_1,
    ccontract_number,
    "contract_name________#0" as contract_name,
    cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'SAP' as source_system,
    
    cast(current_timestamp as date) as load_date
from src
