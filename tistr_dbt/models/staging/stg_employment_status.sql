-- stg_employment_status.sql
with hris as (
    select * from {{ source('hris_systems', 'stg_employment_status') }}
)
select
    status_code as status_code,
    status_name as status_name,
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS' as source_system
from hris
