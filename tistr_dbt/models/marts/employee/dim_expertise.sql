-- dim_expertise.sql
{{
  config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_expertise/',
    file_format      = 'parquet'
  )
}}

with src as (
    select * from {{ ref('stg_expertise') }}
),

final as (
    select
        expertise_id,
        expertise_description,
        cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
        cast(current_timestamp as timestamp) as load_ts,
        'HRIS' as source_system,
        
        cast(current_timestamp as date) as load_date
    from src
)
select * from final