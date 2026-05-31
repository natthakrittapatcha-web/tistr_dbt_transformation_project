-- dim_degree.sql
{{
  config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_degree/',
    file_format      = 'parquet'
  )
}}
with src as (
    select * from {{ ref('stg_degree') }}
),
final as (
    select
        degree_id,
        education_level_id,
        degree_short_name,
        degree_full_name,
        cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
        cast(current_timestamp as timestamp) as load_ts,
        'HRIS' as source_system,
        
        cast(current_timestamp as date) as load_date
    from src
)
select * from final