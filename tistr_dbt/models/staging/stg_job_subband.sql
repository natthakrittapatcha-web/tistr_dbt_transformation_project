-- stg_job_subband.sql

with hris as (
    select * from {{ source('hris_systems', 'stg_job_subband') }}
)
select  
    bandcode as band_code,
    sub_band_code as subband_code,
    subband_name as subband_name,
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS' as source_system
from hris