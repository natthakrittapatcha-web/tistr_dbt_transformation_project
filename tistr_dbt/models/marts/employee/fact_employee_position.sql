-- models/marts/employee/fact_employee_position.sql
{{
  config(
    materialized        = 'incremental',
    incremental_strategy= 'insert_overwrite',
    partitioned_by      = ['load_date'],
    s3_data_location    = 's3://tistr-data-lake/03-curated/fact_employee_position/',
    file_format         = 'parquet'
  )
}}

with pos as (
    select * from {{ source('hris_systems', 'stg_employee_position') }}
),

emp as (
    select employee_sk, employee_id
    from {{ ref('dim_employee') }}
    where is_current = true
),

org as (
    select org_unit_sk, src_org_code
    from {{ ref('dim_org_unit') }}
    where is_current = true
)

select
    {{ dbt_utils.generate_surrogate_key(['"employee_position_id"']) }}
                                            as employee_position_sk,
    cast(p."employee_position_id" as int)          as employee_position_id,
    coalesce(e.employee_sk, '-1')              as employee_sk,
    p."employee_id"                         as employee_id,
    p."main_position_id"                     as main_position_id,
    coalesce(o.org_unit_sk, '-1')                as org_unit_sk,
    'unknown'                                 as room_code,
    p."position_level"                       as position_level,
    p."minor_position"                       as minor_position,
    p."employment_type_id"                           as employment_type_id,
    p."position_type_id"                   as position_type_id,
    p."employee_group_id"                          as employee_group_id,
    p."expertise_id"                         as expertise_id,
    'unknown'                                 as base_fte,
    'unknown'                                 as is_active,
    cast(p."start_date" as date)         as start_date,
    cast(p."end_date" as date)             as end_date,
    cast(p."appointment_date" as date)      as appointment_date,
    cast(p."status_effective_date" as date)         as status_effective_date,
    cast(p."total_effective_date" as date)    as total_effective_date,
    cast(p."manager_effective_date" as date)      as manager_effective_date,
    cast(p."tenure_start_date" as date)         as tenure_start_date,
    p."work_schedule_id"                        as work_schedule_id,
    cast(p."schedule_change_date" as date)         as schedule_change_date,
    p."benefits_of_tistr"                     as benefits_of_tistr,
    p."fund_type"                          as fund_type,
    cast(p."fund_contribution_pct" as decimal(6,2)) as fund_contribution_pct,
    p."fund_ref_no"                        as fund_ref_no,
    p."is_cremation_member"                   as is_cremation_member,   
    p."employee_office_phone"                        as employee_office_phone,
    p."status_code"                           as status_code,
    p."position_status"                   as position_status,
    p."admin_emp_id"                       as admin_emp_id,
    cast(p."created_date" as timestamp)        as created_date,
    cast(p."updated_date" as timestamp)     as updated_date,
    -- SCD2
    cast(p."start_date" as date)         as valid_from,
    coalesce(
        cast(p."end_date" as date),
        date('9999-12-31')
    )                                       as valid_to,
    case
        when p."end_date" is null then true
        else false
    end                                     as is_current,
    cast(date_format(current_timestamp, '%Y%m%d%H%i%s')as varchar)       as batch_id,
    cast(current_timestamp as timestamp)    as load_ts,
    'HRIS'                                  as source_system,
    cast(current_timestamp as date)      as load_date
from pos p
left join emp e on p."employee_id" = e.employee_id
left join org o on p."src_org_code" = o.src_org_code
{% if is_incremental() %}
where cast(p."updated_date" as date) >= (
    select max(cast(updated_date as date)) from {{ this }}
)
{% endif %}