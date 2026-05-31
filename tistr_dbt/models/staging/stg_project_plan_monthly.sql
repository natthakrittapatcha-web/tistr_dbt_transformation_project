-- models/marts/portfolio/fact_project_plan_monthly.sql

with rdms as (
    select * from {{ source('rdms_systems', 'stg_project_plan_monthly') }}
)

select
    id,
    plan_id,
    month_1,
    month_2,
    month_3,
    month_4,
    month_5,
    month_6,
    month_7,
    month_8,
    month_9,
    month_10,
    month_11,
    month_12
from rdms