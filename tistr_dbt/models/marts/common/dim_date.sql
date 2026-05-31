-- models/marts/core/dim_date.sql
{{
  config(
    materialized     = 'table',
    s3_data_location = 's3://tistr-data-lake/03-curated/common/dim_date/',
    file_format      = 'parquet'
  )
}}

with date_spine as (

    {{ dbt_utils.date_spine(
        datepart   = "day",
        start_date = "cast('2000-01-01' as date)",
        end_date   = "cast('2030-12-31' as date)"
    ) }}

),

final as (

    select
        -- surrogate key
        cast(date_format(date_day, '%Y%m%d') as integer)                 as date_sk,

        -- date
        cast(date_day as date)                                           as full_date,

        -- day
        cast(day_of_week(date_day) as integer)                           as day_of_week,
        cast(date_format(date_day, '%W') as varchar)                     as day_name,

        cast(
            case day_of_week(date_day)
                when 1 then 'อาทิตย์'
                when 2 then 'จันทร์'
                when 3 then 'อังคาร'
                when 4 then 'พุธ'
                when 5 then 'พฤหัสบดี'
                when 6 then 'ศุกร์'
                when 7 then 'เสาร์'
            end as varchar
        )                                                                as day_name_th,

        cast(day_of_month(date_day) as integer)                          as day_of_month,
        cast(week_of_year(date_day) as integer)                          as week_of_year,

        -- month
        cast(month(date_day) as integer)                                 as month_num,
        cast(date_format(date_day, '%M') as varchar)                     as month_name,

        cast(
            case month(date_day)
                when 1  then 'มกราคม'
                when 2  then 'กุมภาพันธ์'
                when 3  then 'มีนาคม'
                when 4  then 'เมษายน'
                when 5  then 'พฤษภาคม'
                when 6  then 'มิถุนายน'
                when 7  then 'กรกฎาคม'
                when 8  then 'สิงหาคม'
                when 9  then 'กันยายน'
                when 10 then 'ตุลาคม'
                when 11 then 'พฤศจิกายน'
                when 12 then 'ธันวาคม'
            end as varchar
        )                                                                as month_name_th,

        -- quarter
        cast(quarter(date_day) as integer)                               as quarter_num,
        cast(concat('Q', cast(quarter(date_day) as varchar)) as varchar) as quarter_name,

        -- year
        cast(year(date_day) as integer)                                  as year_num,

        -- fiscal
        cast(
            case
                when month(date_day) >= 10 then year(date_day) + 1
                else year(date_day)
            end as integer
        )                                                                as fiscal_year,

        cast(
            case
                when month(date_day) in (10,11,12) then 1
                when month(date_day) in (1,2,3)    then 2
                when month(date_day) in (4,5,6)    then 3
                when month(date_day) in (7,8,9)    then 4
            end as integer
        )                                                                as fiscal_quarter,

        -- flags
        cast(
            case
                when day_of_week(date_day) in (1,7) then true
                else false
            end as boolean
        )                                                                as is_weekend,

        cast(false as boolean)                                           as is_holiday,

        cast(null as varchar)                                            as holiday_name,

        -- metadata
        cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
        cast(current_timestamp as timestamp)                             as load_ts

    from date_spine

)

select * from final