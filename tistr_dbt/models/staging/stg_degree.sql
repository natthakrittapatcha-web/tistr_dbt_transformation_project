-- stg_degree.sql
with hris as (
    select * from {{ source('hris_systems', 'stg_degree') }}
)
select
    degree_id as degree_id,
    education_level_id as education_level_id,
    degree_short_name as degree_short_name,
    degree_full_name as degree_full_name,
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS' as source_system
from hris