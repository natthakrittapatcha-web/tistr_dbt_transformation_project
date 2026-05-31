{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'insert_overwrite',
    partitioned_by = ['order_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/fact_service_txn/',
    file_format = 'parquet'
  )
}}

with src_mis as (
    select * from {{ source('mis_systems', 'stg_service_request') }}
),

transformed as (
    select
        -- 1. Transaction Keys
        concat(cast(doc_id as varchar), '-', cast(work_id as varchar))  as txn_id,

        -- 2. Dimension Natural Keys
        cast(cust_id as varchar)                                        as customer_id,
        cast(emp_id as varchar)                                         as employee_id,
        cast(branch_id as varchar)                                      as branch_id,
        
        -- [WORKAROUND] ใช้ mea_code หรือ product เป็น service_id ชั่วคราวจนกว่า Business จะเคาะ
        coalesce(cast(mea_code as varchar), cast(product as varchar), 'UNKNOWN') as service_id,

        -- 3. Dates
        cast(doc_date as date)                                          as order_date,
        cast(mea_start_date as date)                                    as start_date,
        cast(mea_end_date as date)                                      as end_date,

        -- 4. Measures
        cast(null as decimal(5,4))                                      as discount, -- ไม่มีใน source
        cast(mea_amt as decimal(18,2))                                  as amount_net,

        -- 5. Status & Channels
        case 
            when wp_closed = 'Y' and wr_closed = 'Y' then 'CLOSED'
            when wp_closed = 'N' or wr_closed = 'N'  then 'OPEN'
            else 'UNKNOWN'
        end                                                             as service_txn_status,
        'MIS_SYSTEM'                                                    as channel,
        'MIS'                                                           as source_system
    from src_mis
)

select
    -- Primary Key ของ Fact
    {{ dbt_utils.generate_surrogate_key(['txn_id', 'source_system']) }} as txn_sk,
    txn_id,

    -- Foreign Keys (Surrogate Keys) ไปยัง Dimensions
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }}             as customer_sk,
    customer_id,

    -- FK Service: เจน SK จาก service_id ชั่วคราวไปก่อน
    {{ dbt_utils.generate_surrogate_key(['service_id']) }}              as service_sk,
    service_id,

    {{ dbt_utils.generate_surrogate_key(['employee_id']) }}             as employee_sk,
    try_cast(employee_id as integer)                                    as employee_id,

    -- ✅ แก้ไข 1: ดึง Raw dates ออกมาด้วยเพื่อให้ Athena ใช้ทำ Partition ได้
    order_date,
    start_date,
    end_date,

    -- Date Surrogate Keys (Format: YYYYMMDD)
    cast(date_format(order_date, '%Y%m%d') as integer)                  as order_date_sk,
    cast(date_format(start_date, '%Y%m%d') as integer)                  as start_date_sk,
    cast(date_format(end_date, '%Y%m%d') as integer)                    as end_date_sk,

    -- Measures
    discount,
    amount_net,

    -- Other Dimensions
    {{ dbt_utils.generate_surrogate_key(['branch_id']) }}               as org_unit_sk,
    channel,
    service_txn_status,

    -- ETL Metadata
    cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)     as batch_id,
    current_timestamp                                                   as load_ts,
    source_system

from transformed

{% if is_incremental() %}
  -- ✅ แก้ไข 2: เปลี่ยนจาก doc_date เป็น order_date ให้ตรงกับคอลัมน์ใน transformed
  where order_date >= (select max(order_date) from {{ this }})
{% endif %}