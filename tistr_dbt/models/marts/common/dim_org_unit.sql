{{
  config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/dim_org_unit/',
    file_format      = 'parquet'
  )
}}

-- 1. ดึงข้อมูลจาก Staging มาพักไว้
with src as (
    select * from {{ ref('stg_org_unit') }}
),


-- 5. ประกอบร่างข้อมูลเข้าด้วยกัน
final_data as (
    select
        {{ dbt_utils.generate_surrogate_key(['s.org_unit_type', 's.src_org_code', 's.division_code', 's.office_code']) }} as org_unit_sk,
        s.org_unit_type,
        s.src_org_code,
        s.business_group_code,
        s.office_code,
        s.division_code,
        cast(null as varchar) as cluster_sk,
        s.status,
        s.valid_from,
        s.valid_to,
        case
            when s.valid_to is null or s.valid_to = date('9999-12-31') then true
            else false
        end as is_current,
        cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar) as batch_id,
        
        -- แก้ไขแล้ว: แปลงให้เป็น timestamp ธรรมดา (ไม่มี time zone)
        cast(current_timestamp as timestamp) as load_ts, 
        
        s.source_system,
        
        -- แก้ไขแล้ว: load_date อยู่บรรทัดสุดท้ายถูกต้องตามกฎของ Athena
        cast(current_timestamp as date) as load_date 
    from src s
)

-- 6. Select ผลลัพธ์สุดท้าย
select * from final_data

{% if is_incremental() %}
where src_org_code not in (
    select src_org_code from {{ this }}
    where is_current = true
)
{% endif %}