-- models/marts/portfolio/fact_project_manpower.sql
{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/fact_project_manpower/',
    file_format      = 'parquet'
) }}

with src as (
    select * from {{ source('rdms_systems', 'stg_project_manpower') }}
),

proj as (
    select project_sk, project_id
    from {{ ref('dim_project_ri') }}
    where is_current = true
),

emp as (
    select employee_sk, employee_id
    from {{ ref('dim_employee') }}
    where is_current = true
)

select
    {{ dbt_utils.generate_surrogate_key(['src.project_id', 'src.employee_id']) }}  as manpower_sk,
    src.manpower_id,
    Coalesce(proj.project_sk, '-1') as project_sk,
    Coalesce(emp.employee_sk, '-1') as employee_sk,
    src.project_id,
    src.employee_id,
    src.participant_seq,
    src.employee_type,
    'unknown' as fte_equivalent,
    'unknown' as activity_type,
    src.project_role_id,
    src.workload_pct,
    src.allocated_hours,
    src.employee_update_id,
    src.delivered_by_id,
    src.admin_emp_id,
    cast(src.updated_date as timestamp) as updated_date,
    cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'RDMS' as source_system,
    
    cast(current_timestamp as date) as load_date
from src
left join proj on src.project_id = proj.project_id
left join emp on src.employee_id = emp.employee_id