-- models/marts/portfolio/dim_trl.sql
{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_trl/',
    file_format      = 'parquet'
) }}
with src as (
    select * from {{ source('rdms_systems', 'stg_trl') }}
)
select
    trl_id,
    trl_detail,
    trlcomment as trl_comment,
    trl_level,
    cast(current_timestamp as timestamp) as load_ts,
    'RDMS' as source_system,
    
    cast(current_timestamp as date) as load_date
from src