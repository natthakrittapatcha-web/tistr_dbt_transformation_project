-- dim course
{{
  config(
    materialized        = 'table',
    s3_data_location    = 's3://tistr-data-lake/03-curated/dim_course/',
    file_format         = 'parquet'
  )
}}

with src as (
    select * from {{ ref('stg_training_history') }}
),


skill_cat as (
    select skill_category_id, skill_category_name_en
    from {{ ref('dim_skill_category') }}
),

-- dedup เอาแค่ unique course
courses as (
    select distinct
        course_name,
        type_iso,
        type_country,
        training_institute,
        training_manager,
        training_description,
        training_facility,
        training_hours,
        training_type,
        training_time,
        target,
        training_cost,
        lecturer
    from src
    where course_name is not null
)


select
    {{ dbt_utils.generate_surrogate_key([
        'course_name',
        'training_institute'
    ]) }}                                   as course_sk,
    course_name,
    coalesce(sc.skill_category_id, 6)       as skill_category_id,  -- default = General
    lecturer,
    training_hours,
    type_iso,
    type_country,
    training_manager,
    training_institute,
    training_facility,
    training_description,
    training_time,
    target,
    training_cost,
    training_type,
    cast(
        date_format(current_timestamp, '%Y%m%d%H%i%s')
    as varchar)                                 as batch_id,
    cast(current_timestamp as timestamp)                           as load_ts,
    'HRIS'                                      as source_system
    
from courses c
left join skill_cat sc
    on case
        when lower(c.training_type) like '%วิทยาศาสตร%'  then 'Science & Technology'
        when lower(c.training_type) like '%บริหาร%'       then 'Management'
        when lower(c.training_type) like '%ดิจิทัล%'      then 'Digital & IT'
        when lower(c.training_type) like '%ภาษา%'         then 'Language'
        when lower(c.training_type) like '%ความปลอดภัย%'  then 'Safety & Compliance'
        else 'General Skills'
    end = sc.skill_category_name_en