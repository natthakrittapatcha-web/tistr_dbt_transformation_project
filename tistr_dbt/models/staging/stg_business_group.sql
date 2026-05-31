-- stg_business_group.sql
with hris as (
    select * from {{ source('hris_systems', 'stg_business_group') }}
)
select
    business_group_code as business_group_code,
    src_org_code as src_org_code,
    business_group_name_th as business_group_name_th,
    business_group_full_name_th as business_group_full_name_th,
    business_group_name_en as business_group_name_en,
    business_group_full_name_en as business_group_full_name_en,
    director_employee_id as director_employee_id,
    business_group_status as business_group_status,
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS' as source_system
from hris