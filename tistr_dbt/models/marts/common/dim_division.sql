-- dim_division.sql
{{
  config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_division/',
    file_format      = 'parquet'
  )
}}
with src as (
    select * from {{ ref('stg_division') }}
),
final as (
    select
        division_code,
        business_group_code,
        office_code,
        division_name_th,
        division_full_name_th,
        division_name_en,
        division_full_name_en,
        director_employee_id,
        division_status, 	
        cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
        cast(current_timestamp as timestamp) as load_ts,
        'HRIS' as source_system,
        
        cast(current_timestamp as date) as load_date
    from src
)
select * from final