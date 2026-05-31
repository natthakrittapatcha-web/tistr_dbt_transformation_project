-- dim_employee_education.sql
{{
  config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_employee_education/',
    file_format      = 'parquet'
  )
}}
with src as (
    select * from {{ ref('stg_employee_education') }}
),

emp as (
    select employee_sk, employee_id
    from {{ ref('dim_employee') }}
    where is_current = true
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['src.education_id']) }}  as education_sk,
        src.education_id,
        coalesce(e.employee_sk, '-1')          as employee_sk,
        src.employee_id,
        src.degree_id,
        src.institute_id,
        src.faculty_name,
        src.major_name,
        src.minor_name,
        src.gpa,
        src.campus_name,
        src.education_detail,
        src.recruitment_path,
        src.admin_emp_id,
        src.created_date,
        src.updated_date,
        src.education_status,
        cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
        cast(current_timestamp as timestamp) as load_ts,
        'HRIS' as source_system,
        cast(current_timestamp as date) as load_date
    from src
    left join emp e
        on src.employee_id = e.employee_id

    {% if is_incremental() %}
    where cast(src.updated_date as date) >= (
      select max(cast(updated_date as date)) from {{ this }}
)
{% endif %}
)


select * from final