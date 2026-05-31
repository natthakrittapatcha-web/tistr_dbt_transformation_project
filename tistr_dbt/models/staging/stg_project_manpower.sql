-- stg_project_manpower.sql

with rdms as (
    select * from {{ source('rdms_systems', 'stg_project_manpower') }}
)
select
    manpower_id,
    project_id,
    participant_seq,
    employee_id,
    employee_name,
    empposition,
    empdepartment,
    workload_pct,
    employee_update_id as updated_by_id,
    empsend as delivered_by_id,
    empadmin as admin_emp_id,
    updated_date,
    cast(current_timestamp as timestamp) as load_ts,
    'RDMS' as source_system