-- models/marts/portfolio/fact_project_plan_monthly.sql
{{ config(
    materialized        = 'incremental',
    incremental_strategy= 'insert_overwrite',
    partitioned_by      = ['plan_year'],
    s3_data_location    = 's3://tistr-data-lake/03-curated/fact_project_plan_monthly/',
    file_format         = 'parquet'
) }}

with src as (
    select * from {{ source('rdms_systems', 'stg_project_plan_monthly') }}
),

-- lookup project_sk จาก dim_project
proj as (
    select project_sk, project_id
    from {{ ref('dim_project_ri') }}
    where is_current = true
),

-- unpivot month_1..12 → rows
-- Thai fiscal: month_1=ตค, month_2=พย, month_3=ธค, month_4=มค...month_12=กย
unpivoted as (
    select id, plan_id, year as fiscal_year, 1  as fiscal_month, month_1  as plan_month from src where month_1  is not null
    union all
    select id, plan_id, year as fiscal_year, 2  as fiscal_month, month_2  as plan_month from src where month_2  is not null
    union all
    select id, plan_id, year as fiscal_year, 3  as fiscal_month, month_3  as plan_month from src where month_3  is not null
    union all
    select id, plan_id, year as fiscal_year, 4  as fiscal_month, month_4  as plan_month from src where month_4  is not null
    union all
    select id, plan_id, year as fiscal_year, 5  as fiscal_month, month_5  as plan_month from src where month_5  is not null
    union all
    select id, plan_id, year as fiscal_year, 6  as fiscal_month, month_6  as plan_month from src where month_6  is not null
    union all
    select id, plan_id, year as fiscal_year, 7  as fiscal_month, month_7  as plan_month from src where month_7  is not null
    union all
    select id, plan_id, year as fiscal_year, 8  as fiscal_month, month_8  as plan_month from src where month_8  is not null
    union all
    select id, plan_id, year as fiscal_year, 9  as fiscal_month, month_9  as plan_month from src where month_9  is not null
    union all
    select id, plan_id, year as fiscal_year, 10 as fiscal_month, month_10 as plan_month from src where month_10 is not null
    union all
    select id, plan_id, year as fiscal_year, 11 as fiscal_month, month_11 as plan_month from src where month_11 is not null
    union all
    select id, plan_id, year as fiscal_year, 12 as fiscal_month, month_12 as plan_month from src where month_12 is not null
),

-- แปลง fiscal_month → calendar month + สร้าง month_date
with_calendar as (
    select
        *,
        case
            when fiscal_month = 1  then 10
            when fiscal_month = 2  then 11
            when fiscal_month = 3  then 12
            when fiscal_month = 4  then 1
            when fiscal_month = 5  then 2
            when fiscal_month = 6  then 3
            when fiscal_month = 7  then 4
            when fiscal_month = 8  then 5
            when fiscal_month = 9  then 6
            when fiscal_month = 10 then 7
            when fiscal_month = 11 then 8
            when fiscal_month = 12 then 9
        end                                         as calendar_month,
        case
            when fiscal_month <= 3
            then cast(fiscal_year as int) - 1
            else cast(fiscal_year as int)
        end                                         as calendar_year
    from unpivoted
),

-- สร้าง month_date และ lookup date_sk จาก dim_date
with_date as (
    select
        c.*,
        date_parse(
            concat(
                cast(calendar_year as varchar), '-',
                lpad(cast(calendar_month as varchar), 2, '0'), '-01'
            ),
            '%Y-%m-%d'
        )                                           as month_date
    from with_calendar c
)

select
    {{ dbt_utils.generate_surrogate_key([
        'wd.id',
        'wd.fiscal_month'
    ]) }}                                           as monthly_sk,

    -- project_sk จาก dim_project_ri
    coalesce(p.project_sk, '-1')                      as project_sk,
    wd.plan_id                                      as project_id,

    -- date_sk จาก dim_date
    coalesce(d.date_sk, -1)                         as month_date_sk,
    wd.month_date,

    -- fiscal info
    wd.fiscal_year,
    wd.fiscal_month,
    wd.plan_month,                                 -- ค่าที่เก็บใน source (string)

    -- metadata
    cast(
        date_format(current_timestamp, '%Y%m%d%H%i%s')
    as varchar)                                     as batch_id,
    cast(current_timestamp as timestamp)                               as load_ts,
    'RDMS'                                          as source_system,
    wd.fiscal_year                                  as plan_year    -- partition

from with_date wd
left join proj p
    on wd.plan_id = p.project_id
left join {{ ref('dim_date') }} d
    on wd.month_date = d.full_date

{% if is_incremental() %}
where wd.fiscal_year = (
    select max(fiscal_year) from {{ this }}
)
{% endif %}