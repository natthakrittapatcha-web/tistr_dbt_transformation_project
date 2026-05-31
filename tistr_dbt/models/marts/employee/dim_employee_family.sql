-- dim_employee_family.sql
{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_employee_family/',
    file_format      = 'parquet'
) }}
with src as (
    select * from {{ source('hris_systems', 'stg_employee_family') }}
),

emp as (
    select employee_sk, employee_id
    from {{ ref('dim_employee') }}
    where is_current = true
),


final as (
    select
        {{ dbt_utils.generate_surrogate_key(['src.family_id', 'src.employee_id']) }}  as family_sk,
        src.family_id,
        coalesce(e.employee_sk, '-1')          as employee_sk,
        src.employee_id,
        src.family_full_name,
        src.birthdate,
        src.address,
        src.relation,
        src.remark,
        src.created_date,
        src.updated_date,
        cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
        cast(current_timestamp as timestamp) as load_ts,
        'HRIS' as source_system,
        
        cast(current_timestamp as date) as load_date
    from src
    left join emp e
        on src.employee_id = e.employee_id
)
select * from final