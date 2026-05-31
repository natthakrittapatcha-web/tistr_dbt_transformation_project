-- dim_position.sql
{{
  config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_position/',
    file_format      = 'parquet'
  )
}}
with src as (
    select * from {{ source('hris_systems', 'stg_position') }}
),

final as (
    select
        main_position_id,
        band_code,
        sub_band_code,
        position_abb_name,
        position_name_th,
        position_name_en,
        position_type,
        position_created_date,
        -- metadata
        cast(
          date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
        'hris' as source_system,
        cast(current_timestamp as timestamp)  as load_ts,
        cast(current_timestamp as date)       as load_date

    from src
)

select * from final
