-- models/staging/stg_job_band.sql

with hris as (

    select *
    from {{ source('hris_systems', 'stg_job_band') }}

)

select
    band_code as band_code,
    bandname as band_name,
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS' as source_system

from hris
