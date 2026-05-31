-- stg_employee_family.sql

with hris as (
    select * from {{ source('hris_systems', 'stg_employee_family') }}
)
select
    family_id,
    employee_id ,
    family_full_name,
    birthdate,
    address,
    relation,
    remark,
    created_date ,
    updated_date,
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS' as source_system
from hris

