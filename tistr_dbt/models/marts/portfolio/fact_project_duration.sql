-- models/marts/portfolio/fact_project_duration.sql
{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/fact_project_duration/',
    file_format      = 'parquet'
) }}
with src as (
    select * from {{ source('rdms_systems', 'stg_project_duration') }}
),

proj as (
    select project_sk, project_id
    from {{ ref('dim_project_ri') }}
    where is_current = true
)


select
    {{ dbt_utils.generate_surrogate_key(['src.duration_id']) }} as project_duration_sk,     
    duration_id,
    coalesce(p.project_sk, '-1')                     as project_sk,
    src.project_id,
    src.project_nature,
    src.project_time,
    cast(src.project_start as timestamp) as project_start,
    cast(src.project_finish as timestamp) as project_finish,
    -- SCD2 tracking
    cast(date_format(current_timestamp, '%Y%m%d%H%i%s')as varchar)       as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'RDMS' as source_system,
    
    cast(current_timestamp as date) as load_date
from src
left join proj p on src.project_id = p.project_id