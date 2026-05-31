-- stg_expert_center_office.sql
with hris as (
    select * from {{ source('hris_systems', 'stg_expert_center_office') }}
)
select
    office_code as office_code,
    business_group_code as business_group_code,
    office_name_th as office_name_th,
    office_full_name_th as office_full_name_th,
    office_name_en as office_name_en,
    office_full_name_en as office_full_name_en,
    director_employee_id as director_employee_id,
    office_status as office_status,
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS' as source_system
from hris