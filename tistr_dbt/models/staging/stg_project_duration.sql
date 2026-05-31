-- models/staging/stg_project_duration.sql
select
    project_id,
    project_nature as project_type,
    project_time,
    project_start as start_date,
    project_finish as finish_date
from {{ source('rdms_systems', 'stg_project_duration') }}