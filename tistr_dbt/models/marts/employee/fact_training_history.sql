-- models/gold/fact_training_history.sql
{{
  config(
    materialized        = 'incremental',
    incremental_strategy= 'insert_overwrite',
    partitioned_by      = ['load_date'],
    s3_data_location    = 's3://tistr-data-lake/03-curated/fact_training_history/',
    file_format         = 'parquet'
  )
}}

with src as (
    select * from {{ ref('stg_training_history') }}
),

emp as (
    select employee_sk, employee_id
    from {{ ref('dim_employee') }}
    where is_current = true
),

course as (
    select course_sk, course_name, training_institute
    from {{ ref('dim_course') }}
),

dt as (
    select date_sk, full_date
    from {{ ref('dim_date') }}
)

select
    {{ dbt_utils.generate_surrogate_key([
        'src.training_record_id'
    ]) }}                                       as training_record_sk,
    coalesce(d.date_sk, -1)                     as date_sk,
    coalesce(e.employee_sk, '-1')          as employee_sk,
    coalesce(c.course_sk, '-1')            as course_sk,
    cast(src.training_record_id as varchar)     as training_record_id,
    src.employee_id,
    src.start_date,
    src.end_date,
    src.sign_date,
    src.training_status,
    src.certificate_path,
    src.remarks,
    src.learning_outcomes,
    src.admin_emp_id,
    src.created_date,
    src.updated_date,
    -- partition
    src.year,
    cast(
        date_format(current_timestamp, '%Y%m%d%H%i%s')
    as varchar)                                 as batch_id,
    cast(current_timestamp as timestamp)        as load_ts,
    'HRIS'                                      as source_system,
    cast(current_timestamp as date) as load_date
from src

left join emp e
    on src.employee_id = e.employee_id
left join course c
    on src.course_name         = c.course_name
    and src.training_institute = c.training_institute
left join dt d
    on src.start_date = d.full_date

{% if is_incremental() %}
where src.updated_date >= (
    select max(updated_date) from {{ this }}
)
{% endif %}