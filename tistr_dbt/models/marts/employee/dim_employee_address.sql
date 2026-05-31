-- models/marts/employee/dim_employee_address.sql
{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_employee_address/',
    file_format      = 'parquet'
) }}

with src as (
    select * from {{ source('hris_systems', 'stg_employee_address') }}
),
emp as (
    select employee_sk, employee_id
    from {{ ref('dim_employee') }}
    where is_current = true
)
select
    {{ dbt_utils.generate_surrogate_key(['src.emp_address_id']) }} as emp_address_sk,     
    src.emp_address_id,
    coalesce(e.employee_sk, '-1')                     as employee_sk,
    src.employee_id,
    src.address_type,
    src.house_no,
    src.village,
    src.street,
    src.subdistrict,
    src.district,
    src.province,
    src.zipcode,
    src.mobile_contact,
    src.home_phone,
    src.admin_emp_id,
    src.address_status,
    -- SCD2 tracking
    cast(src.created_date as timestamp) as created_date,
    cast(src.updated_date as timestamp) as updated_date,
    cast(date_format(current_timestamp, '%Y%m%d%H%i%s')as varchar)       as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS' as source_system,
    
    cast(current_timestamp as date) as load_date
from src
left join emp e on src.employee_id = e.employee_id