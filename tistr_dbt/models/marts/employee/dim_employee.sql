-- models/marts/employee/dim_employee.sql
{{
  config(
    materialized        = 'table',
    incremental_strategy= 'insert_overwrite',
    partitioned_by       = ['load_date'],
    s3_data_location    = 's3://tistr-data-lake/03-curated/dim_employee/',
    file_format         = 'parquet'
  )
}}

with src as (
    select * from {{ ref('stg_employee') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['employee_id']) }}  as employee_sk,
        employee_id,
        seq_no,
        card_no,
        title_id,
        employee_name_th,
        employee_lastname_th,
        employee_name_en,
        employee_lastname_en,
        gender,
        birthdate,
        marital_id,
        nationality_id,
        telephone_contact,
        mobile_contact,
        email_contact,
        fund_type,
        employee_status,
        hris_employee_id,
        cms_employee_id,
        -- SCD2 tracking
        cast(load_ts as date)       as valid_from,
        date('9999-12-31')          as valid_to,
        true                        as is_current,
        cast(current_timestamp as timestamp)           as created_date,
        cast(current_timestamp as timestamp)           as updated_date,
        -- metadata
        cast(
          date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
        cast(current_timestamp as timestamp) as load_ts,
        source_system,
        
        cast(load_ts as date)       as load_date

    from src
)

select * from final

{% if is_incremental() %}
where employee_id not in (
    select employee_id from {{ this }}
    where is_current = true
)
{% endif %}