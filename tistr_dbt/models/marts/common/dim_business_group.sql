-- dim_business_group.sql
{{
  config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_business_group/',
    file_format      = 'parquet'
  )
}}

with src as (
    select * from {{ ref('stg_business_group') }}
),

final as (
    select
        business_group_code,
        src_org_code,
        business_group_name_th,
        business_group_full_name_th,
        business_group_name_en,
        business_group_full_name_en,
        director_employee_id,
        business_group_status ,
        cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
        cast(current_timestamp as timestamp) as load_ts,
        'HRIS' as source_system,
        
        cast(current_timestamp as date) as load_date
    from src
)
select * from final