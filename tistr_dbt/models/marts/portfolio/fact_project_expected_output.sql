-- models/marts/portfolio/fact_project_expected_output.sql
{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/fact_project_expected_output/',
    file_format      = 'parquet'
) }}

with src as (
    select * from {{ source('rdms_systems', 'stg_project_expected_output') }}
)

/*out as (
    select outcome_sk, outcome_id
    from {{ ref('fact_project_expected_outcome') }}
    where is_current = true
)*/

select
    {{ dbt_utils.generate_surrogate_key(['src.output_id']) }}  as output_sk,
    cast(src.output_id as int) as output_id,
    {{ dbt_utils.generate_surrogate_key(['src.outcome_id']) }}  as outcome_sk,
    --เนื่องจาก mock data ผิด type ควร mock เป็น int แต่ดันเป็น varchar ทำให้ join ไม่ได้ จึงใช้การ generate surrogate key ใหม่จาก outcome_id แทน
    --Coalesce(out.outcome_sk, '-1') as outcome_sk, 
    src.outcome_id,
    src.product_id,
    src.product_sub_id,
    src.output_name,
    src.output_type,
    src.quantity_number,
    src.quantity_unit,
    src.description,
    src.operational_progress,
    src.actual_productivity,
    src.evidence,
    src.attachment_path,
    src.qualitative,
    -- SCD2 tracking
    try(date_parse(src.created_date, '%d/%m/%Y %H:%i')) as created_date, 
    try(date_parse(src.updated_date, '%d/%m/%Y %H:%i')) as updated_date,

    cast(date_format(current_timestamp, '%Y%m%d%H%i%s')as varchar)       as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'RDMS' as source_system,
    
    cast(current_timestamp as date) as load_date
from src
--left join out on src.outcome_id = out.outcome_id