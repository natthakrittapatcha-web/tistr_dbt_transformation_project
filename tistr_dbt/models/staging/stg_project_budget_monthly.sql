--  models/staging/stg_project_budget_monthly.sql

with rdms as (
    select * from {{ source('rdms_systems', 'stg_project_budget_monthly') }}
)
select
    budget_id,
    project_id,
    budget_year,
    budget_month,
    budget_amount,
1
project_id,
sub_category_id,
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
month_12,
Count_Month,
monthly_amount,
created_date,
updated_date,
    cast(current_timestamp as timestamp) as load_ts,
    'RDMS' as source_system

from rdms