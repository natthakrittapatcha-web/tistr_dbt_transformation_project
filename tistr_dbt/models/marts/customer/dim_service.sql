-- models/gold/dim_service.sql
with distinct_services as (
    -- ดึง service_id แบบไม่ซ้ำจาก Fact เพื่อสร้าง Dimension ชั่วคราว
    select distinct 
        coalesce(cast(mea_code as varchar), cast(product as varchar), 'UNKNOWN') as service_id,
        max(product) as service_name
    from {{ source('mis_systems', 'stg_service_request') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['service_id']) }} as service_sk,
    service_id,
    service_name,
    'UNASSIGNED'          as service_group,
    'UNASSIGNED'          as service_subgroup,
    'ACTIVE'              as service_status
    -- ... ใส่ค่า Null หรือ Default สำหรับคอลัมน์อื่นๆ ตาม DBML ...
from distinct_services