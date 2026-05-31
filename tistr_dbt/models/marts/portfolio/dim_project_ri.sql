-- models/marts/portfolio/dim_project_ri.sql
{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_project_ri/',
    file_format      = 'parquet'
) }}
with src as (
    select * from {{ ref('stg_project_ri') }}
),

emp as (
    select employee_sk, employee_id
    from {{ ref('dim_employee') }}
    where is_current = true
),

pos as (
    select employee_id, org_unit_sk,
    -- แนะนำให้เพิ่มการกรองหาตำแหน่งหลัก (ถ้ามี) เพื่อกัน Fan-out
    row_number() over (partition by employee_id order by start_date desc) as rn
    from {{ ref('fact_employee_position') }}
    where is_current = true
)
select
    {{ dbt_utils.generate_surrogate_key(['project_id']) }}  as project_sk,
    src.project_id,
    src.project_max_id,
    src.project_year, 
    src.project_code,
    src.project_sap_code,
    src.project_category,
    src.project_plan_name,
    src.project_name_th,
    src.project_name_eng,
    coalesce(ep.org_unit_sk, 'unknown') as org_unit_sk,
    src.keyword_thai as keyword_th,
    src.keyword_eng as keyword_en,
    src.type_id,
    src.plan_id,
    src.category_fund as fund_category,
    src.type_fund as fund_type,
    src.fund as fund_source,
    coalesce(h.employee_sk, 'unknown') as project_head_sk,
    src.project_head_id,
    coalesce(c.employee_sk, 'unknown') as project_coor_sk,
    src.project_coor_id,
    src.project_status,
    src.ref_project_id, 
    src.budget_operating,
    src.budget_investment,
    src.budget_total,
    'THB' as currency,
    src.remark,
    cast(null as varchar) as note,
    src.attribute_1_id,
    src.attribute_2_id,
    src.contract_id,
    src.contract_type,
    src.contract_code_id,
    src.employee_id_upated as updated_by_id, -- แก้ชื่อ column ผิด
    src.employee_id_created,
    src.employee_id_send as delivered_by_id,
    cast(src.send_date as timestamp) as delivered_date,  
    src.admin_emp_id,
    cast(src.admin_updated_date as timestamp) as admin_updated_date,  
    src.rdms_project_id,
    cast(null as varchar) as  sap_project_id,
    cast(null as varchar) as  cms_project_id,
    cast(src.load_ts as date)       as valid_from,
    date('9999-12-31')          as valid_to,
    true                        as is_current,
    cast(src.created_date as timestamp)           as created_date,
    cast(src.last_update_project as timestamp) as updated_date,
    -- metadata
    cast(
        date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    source_system,
    
    cast(load_ts as date)       as load_date
from src
    left join emp h on src.project_head_id = h.employee_id
    left join emp c on src.project_coor_id = c.employee_id
    left join pos ep on src.project_head_id = ep.employee_id and ep.rn = 1