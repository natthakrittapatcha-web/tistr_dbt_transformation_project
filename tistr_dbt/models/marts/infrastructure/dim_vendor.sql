-- models/infrastructure/dim_vendor.sql

{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_vendor/',
    file_format      = 'parquet'
) }}

with src as (
    select * from {{ source('sap_systems', 'stg_vendor') }}
)

select
    vendor_code,
    vendor_name_1,
    vendor_name_2,
    is_cancelled,
    search_term_1,
    search_term_2,
    street,
    house_number,
    address_supplement,
    district,
    postal_code,
    country,
    province,
    tax_id_1,
    tax_id_3,
    tax_id_4,
    vat_registration_number,
    account_group,
    account_group_name,
    is_deleted_central,
    is_blocked_fi,
    is_blocked_mm,
    reconciliation_account,
    payment_term,
    "recent_year_posted#0" as recent_year_posted,
    has_open_items,
    open_amount,
    mobile_phone,
    email,
    cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'SAP' as source_system,
    
    cast(current_timestamp as date) as load_date
from src
