-- stg_university.sql
with hris as (
    select * from {{ source('hris_systems', 'stg_university') }}
)
select
    institute_id as institute_id,
    institute_name as institute_name,
    institute_type as institute_type,
    institute_region as institute_region,
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS' as source_system

from hris