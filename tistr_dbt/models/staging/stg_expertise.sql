-- stg_expertise.sql
with hris as (
    select * from {{ source('hris_systems', 'stg_expertise') }}
)
select
    expertise_id as expertise_id,
    expertise_description as expertise_description,
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS' as source_system
from hris
