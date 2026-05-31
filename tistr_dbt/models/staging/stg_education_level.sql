-- stg_education_level.sql
with hris as (
    select * from {{ source('hris_systems', 'stg_education_level') }}
)
select
    education_level_id as education_level_id,
    education_level_name as education_level_name,
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS' as source_system
from hris