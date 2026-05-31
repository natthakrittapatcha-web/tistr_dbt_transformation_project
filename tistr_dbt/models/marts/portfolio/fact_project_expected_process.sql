-- models/marts/portfolio/fact_project_expected_process.sql
{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/fact_project_expected_process/',
    file_format      = 'parquet'
) }}

with src as (
    select * from {{ source('rdms_systems', 'stg_project_expected_process') }}
),
out as (
    select outcome_sk, outcome_id
    from {{ ref('fact_project_expected_outcome') }}
    where is_current = true
)
select
    {{ dbt_utils.generate_surrogate_key(['src.process_id']) }}  as process_sk,
    cast(src.process_id as int) as process_id,
    Coalesce(out.outcome_sk, '-1') as outcome_sk,
    src.outcome_id,
    src.seq_no,
    src.process_name,
    src.quantity_number,
    src.quantity_unit,
    src.description,
    src.beneficiaries,
    -- SCD2 tracking
    cast(src.created_date as timestamp) as created_date,
    cast(src.updated_date as timestamp) as updated_date,

    cast(date_format(current_timestamp, '%Y%m%d%H%i%s')as varchar)       as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'RDMS' as source_system,
    
    cast(current_timestamp as date) as load_date
from src
left join out on src.outcome_id = out.outcome_id