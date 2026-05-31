-- models/gold/dim_customer.sql
{{
  config(
    materialized        = 'incremental',
    incremental_strategy= 'insert_overwrite',
    partitioned_by      = ['load_date'],
    s3_data_location    = 's3://tistr-data-lake/03-curated/dim_customer/',
    file_format         = 'parquet'
  )
}}

with src as (
    select * from {{ ref('stg_customer') }}
),

-- dedup by tax_id — SAP wins over CMS wins over MIS
-- JUMP has no tax_id so it gets its own rows unless matched by name
ranked as (
    select
        *,
        row_number() over (
            partition by
                -- group duplicates by tax_id (trim + upper to normalize)
                upper(trim(coalesce(tax_id, src_customer_id))),
                customer_type
            order by
                case source_system
                    when 'SAP'  then 1
                    when 'CMS'  then 2
                    when 'MIS'  then 3
                    when 'JUMP' then 4
                end
        )                                           as rn
    from src
),

-- keep only master row per customer
-- but preserve src_ids from all systems for lineage
master as (
    select * from ranked where rn = 1
),

-- collect all source IDs per customer for lineage tracking
lineage as (
    select
        upper(trim(coalesce(tax_id, src_customer_id))) as dedup_key,
        customer_type,
        max(case when source_system = 'SAP'  then src_customer_id end) as sap_customer_id,
        max(case when source_system = 'CMS'  then src_customer_id end) as cms_customer_id,
        max(case when source_system = 'MIS'  then src_customer_id end) as mis_customer_id,
        max(case when source_system = 'JUMP' then src_customer_id end) as jump_customer_id
    from src
    group by 1, 2
)

select
    {{ dbt_utils.generate_surrogate_key([
        'upper(trim(coalesce(m.tax_id, m.src_customer_id)))',
        'm.customer_type'
    ]) }}                                           as customer_sk,

    m.src_customer_id as customer_id,  -- from source system (SAP/CMS/MIS/JUMP)
    m.customer_type,

    -- company fields
    m.company_name,

    -- person fields
    m.title,
    m.person_name,
    m.person_lastname,

    -- shared identity
    m.tax_id,
    m.id_card,

    -- contact (coalesce already done in staging — master source wins)
    m.address,
    m.district,
    m.province,
    m.zipcode,
    m.phone,
    m.email,
    m.fax,

    'unknown' as segment_tier,  
    false as is_sandbox,      
    false as is_esg_relevant, 
    m.status,

    -- source lineage (which systems have this customer)
    l.sap_customer_id,
    l.cms_customer_id,
    l.mis_customer_id,
    l.jump_customer_id,
    m.source_system                                 as master_source,

    -- SCD2
    date('1900-01-01')                              as valid_from,
    date('9999-12-31')                              as valid_to,
    true                                            as is_current,

    -- metadata
    cast(
        date_format(current_timestamp, '%Y%m%d%H%i%s')
    as varchar)                                     as batch_id,
    cast(current_timestamp as timestamp)            as load_ts,
    cast(current_timestamp as date)                 as load_date
from master m
left join lineage l
    on upper(trim(coalesce(m.tax_id, m.src_customer_id))) = l.dedup_key
    and m.customer_type = l.customer_type

{% if is_incremental() %}
where m.source_system = 'SAP'   -- re-process all when SAP updates
   or m.tax_id not in (
       select tax_id from {{ this }}
       where tax_id is not null
   )
{% endif %}