-- stg_division.sql
with hris as (
    select * from {{ source('hris_systems', 'stg_division') }}
)
select
    division_code as division_code,
    business_group_code as business_group_code,
    office_code as office_code,
    division_name_th as division_name_th,
    division_full_name_th as division_full_name_th,
    division_name_en as division_name_en,
    division_full_name_en as division_full_name_en,
    director_employee_id as director_employee_id,
    division_status as division_status,
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS' as source_system
from hris