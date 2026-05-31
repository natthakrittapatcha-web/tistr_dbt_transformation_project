-- stg_employee_group.sql
with hris as (
    select * from {{ source('hris_systems', 'stg_employee_group') }}
)  
select
    employee_group_id as employee_group_id,
    employee_group_name as employee_group_name,
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS' as source_system
from hris