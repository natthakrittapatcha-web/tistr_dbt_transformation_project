-- models/marts/portfolio/fact_project_budget_item.sql
{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/fact_project_budget_item/',
    file_format      = 'parquet'
) }}

with src as (
    select * from {{ source('rdms_systems', 'stg_project_budget_item') }}
),

pro as (
    select project_sk, project_id
    from {{ ref('dim_project_ri') }}
    where is_current = true
)

select
    {{ dbt_utils.generate_surrogate_key(['src.item_id', 'src.source_system']) }} as budget_item_sk,
    src.item_id,
    Coalesce(pro.project_sk, '-1') as project_sk,
    src.project_id,
    src.sub_category_id,
    src.budget_category_id,
    src.item_name,
    src.quantity,
    src.unit_name,
    src.person_count,
    src.purchase_frequency,
    src.unit_price,
    src.total_amount,
    -- ใช้ date_parse พร้อมระบุ Format String
    date_parse(src.created_date, '%d/%m/%Y %H:%i') as created_date,
    date_parse(src.updated_date, '%d/%m/%Y %H:%i') as updated_date,
    cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'RDMS' as source_system,
    
    cast(current_timestamp as date) as load_date
from src
left join pro on cast(src.project_id as varchar) = cast(pro.project_id as varchar)
