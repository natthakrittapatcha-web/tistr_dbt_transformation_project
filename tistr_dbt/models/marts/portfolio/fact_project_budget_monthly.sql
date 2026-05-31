-- models/marts/portfolio/fact_project_budget_monthly.sql
{{ config(
    materialized        = 'incremental',
    incremental_strategy= 'insert_overwrite',
    partitioned_by      = ['budget_year'],
    s3_data_location    = 's3://tistr-data-lake/03-curated/fact_project_budget_monthly/',
    file_format         = 'parquet'
) }}

with src as (
    select * from {{ source('rdms_systems', 'stg_project_budget_monthly') }}
),

-- lookup project_sk from dim_project_ri
proj as (
    select project_sk, project_id
    from {{ ref('dim_project_ri') }}
    where is_current = true
),

-- unpivot month_1..12 into rows
-- Thai fiscal: month_1=Oct, month_2=Nov, month_3=Dec,
--              month_4=Jan, month_5=Feb ... month_12=Sep
unpivoted as (
    select monthly_id, project_id, subcategoryid, year as fiscal_year, 1  as fiscal_month, month_1  as monthly_amount from src where month_1  is not null
    union all
    select monthly_id, project_id, subcategoryid, year as fiscal_year, 2  as fiscal_month, month_2  as monthly_amount from src where month_2  is not null
    union all
    select monthly_id, project_id, subcategoryid, year as fiscal_year, 3  as fiscal_month, month_3  as monthly_amount from src where month_3  is not null
    union all
    select monthly_id, project_id, subcategoryid, year as fiscal_year, 4  as fiscal_month, month_4  as monthly_amount from src where month_4  is not null
    union all
    select monthly_id, project_id, subcategoryid, year as fiscal_year, 5  as fiscal_month, month_5  as monthly_amount from src where month_5  is not null
    union all
    select monthly_id, project_id, subcategoryid, year as fiscal_year, 6  as fiscal_month, month_6  as monthly_amount from src where month_6  is not null
    union all
    select monthly_id, project_id, subcategoryid, year as fiscal_year, 7  as fiscal_month, month_7  as monthly_amount from src where month_7  is not null
    union all
    select monthly_id, project_id, subcategoryid, year as fiscal_year, 8  as fiscal_month, month_8  as monthly_amount from src where month_8  is not null
    union all
    select monthly_id, project_id, subcategoryid, year as fiscal_year, 9  as fiscal_month, month_9  as monthly_amount from src where month_9  is not null
    union all
    select monthly_id, project_id, subcategoryid, year as fiscal_year, 10 as fiscal_month, month_10 as monthly_amount from src where month_10 is not null
    union all
    select monthly_id, project_id, subcategoryid, year as fiscal_year, 11 as fiscal_month, month_11 as monthly_amount from src where month_11 is not null
    union all
    select monthly_id, project_id, subcategoryid, year as fiscal_year, 12 as fiscal_month, month_12 as monthly_amount from src where month_12 is not null
),

-- convert fiscal_month to calendar month and build month_date
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
        end                                             as calendar_month,
        case
            when fiscal_month <= 3
            then cast(fiscal_year as int) - 1           -- Oct-Dec = previous calendar year
            else cast(fiscal_year as int)               -- Jan-Sep = current calendar year
        end                                             as calendar_year
    from unpivoted
),

-- build month_date as first day of each month
with_date as (
    select
        c.*,
        date_parse(
            concat(
                cast(calendar_year as varchar), '-',
                lpad(cast(calendar_month as varchar), 2, '0'), '-01'
            ),
            '%Y-%m-%d'
        )                                               as month_date
    from with_calendar c
)

select
    {{ dbt_utils.generate_surrogate_key([
        'wd.monthly_id',
        'wd.fiscal_month'
    ]) }}                                               as monthly_sk,

    coalesce(p.project_sk, '-1')                         as project_sk,

    -- date_sk from dim_date
    coalesce(d.date_sk, -1)                            as month_date_sk,

    -- sub_category_id: cast to INT, -1 if null or unparseable
    coalesce(
        try_cast(wd.subcategoryid as int), -1
    )                                                   as sub_category_id,

    wd.month_date,
    cast(wd.monthly_amount as decimal(18,2))            as monthly_amount,
    'THB'                                               as currency,

    -- metadata
    cast(
        date_format(current_timestamp, '%Y%m%d%H%i%s')
    as varchar)                                         as batch_id,
    cast(current_timestamp as timestamp)                as load_ts,
    'RDMS'                                              as source_system,
    wd.fiscal_year                                      as budget_year   -- partition key

from with_date wd
left join proj p
    on wd.project_id = p.project_id
left join {{ ref('dim_date') }} d
    on wd.month_date = d.full_date

{% if is_incremental() %}
where wd.fiscal_year = (
    select max(budget_year) from {{ this }}
)
{% endif %}