-- models/marts/portfolio/fact_project_expected_outcome.sql
{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/fact_project_expected_outcome/',
    file_format      = 'parquet'
) }}

with src as (
    select * from {{ source('rdms_systems', 'stg_project_expected_outcome') }}
),

pro as (
    select project_sk, project_id
    from {{ ref('dim_project_ri') }}
    where is_current = true
)
select
    {{ dbt_utils.generate_surrogate_key(['src.outcome_id']) }}  as outcome_sk,
    cast(src.outcome_id as int) as outcome_id,
    Coalesce(pro.project_sk, '-1') as project_sk,
    src.project_id,
    src.status,

    -- SCD2 tracking
    cast(current_timestamp as date)       as valid_from,
    date('9999-12-31')          as valid_to,
    true                        as is_current,
    cast(src.created_date as timestamp) as created_date,
    cast(src.updated_date as timestamp) as updated_date,

    cast(date_format(current_timestamp, '%Y%m%d%H%i%s')as varchar)       as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'RDMS' as source_system,
    
    cast(current_timestamp as date) as load_date
from src
left join pro on src.project_id = pro.project_id
