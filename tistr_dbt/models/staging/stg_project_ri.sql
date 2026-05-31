-- models/staging/stg_project_ri.sql

with rdms as (
    select * from {{ source('rdms_systems', 'stg_project') }}
)

{# 
-- cms as (
--    select * from {{ source('cms_systems', 'stg_project') }}
-- ),
#}
{#
-- sap as (
--     select * from {{ source('sap_systems', 'stg_project') }}
-- ),
#}
select
    r.project_id,
    r.project_max_id,
    r.project_year,
    r.project_code,
    r.project_sap_code,
    r.project_category,
    r.project_plan_name,
    r.project_name_th,
    r.project_name_eng,
    r.keyword_thai,
    r.keyword_eng,
    r.type_id,
    r.plan_id,
    r.category_fund,
    r.type_fund,
    r.fund,
    r.project_head_id,
    r.head_tel,
    r.head_fax,
    r.head_mobile,
    r.head_email,
    r.project_coor_id,
    r.coor_address,
    r.coor_tel,
    r.coor_mobile,
    r.coor_email,
    r.employee_id_upated, -- แก้ชื่อ column ผิด
    r.employee_id_created,
    r.last_update_project,
    r.employee_id_send,
    r.send_date,
    r.ref_project_id,
    r.attribute_1_id,
    r.attribute_2_id,
    r.contract_id,
    r.contract_type,
    r.contract_code_id,
    r.project_status,
    r.created_date,
    r.admin_emp_id,
    r.admin_updated_date,
    r.budget_operating,
    r.budget_investment,
    r.budget_total,
    r.remark,
    r."project_id"         as rdms_project_id,
    --s.sap_project_id as sap_project_id,
    --c."project_id"         as cms_project_id,
    cast(current_timestamp as timestamp) as load_ts,
    'RDMS'                  as source_system
from {{ source('rdms_systems', 'stg_project') }} r

{# 
-- left join {{ source('cms_systems', 'stg_project') }} c
--    on r.project_id = c."project_id"

-- left join {{ source('sap_systems', 'stg_project') }} s
--    on r."project_id" = s."project_id"
#}