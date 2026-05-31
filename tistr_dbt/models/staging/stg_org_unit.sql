
-- models/staging/stg_org_unit.sql
-- รวม business_group, office, division, cluster จาก HRIS

with business_group as (
    select
        cast('business_group' as varchar)        as org_unit_type,
        -- ใช้ชื่อคอลัมน์จริงจาก Glue (ไม่ต้องใส่ Double Quotes แล้วเพราะเป็นตัวพิมพ์เล็ก)
        cast(src_org_code as varchar)            as src_org_code, 
        cast(null as varchar)                    as cluster_code,
        cast(null as varchar)                    as division_code,
        cast(null as varchar)                    as office_code,
        cast(business_group_code as varchar)     as business_group_code,
        cast(business_group_status as varchar)   as status,
        
        -- เนื่องจากในตารางไม่มี ValidFrom, ValidTo จึงต้องใส่เป็น null ชั่วคราว 
        -- (เพื่อให้ UNION ALL กับตารางอื่นที่อาจจะมีฟิลด์นี้ได้โดยไม่ Error)
        cast(null as date)                       as valid_from,
        cast(null as date)                       as valid_to,
        
        cast('HRIS' as varchar)                  as source_system
    from {{ source('hris_systems', 'stg_business_group') }}
),

office as (
    select
        cast('office' as varchar)               as org_unit_type,
        -- ใช้ชื่อคอลัมน์จริงจาก Glue
        cast(null as varchar)                   as src_org_code,
        cast(null as varchar)                   as cluster_code,
        cast(null as varchar)                   as division_code,
        cast(office_code as varchar)            as office_code,
        cast(business_group_code as varchar)    as business_group_code,
        cast(office_status as varchar)          as status,
        
        -- ใส่ null ชั่วคราวเพื่อให้ Type ตรงกับตารางอื่น
        cast(null as date)                      as valid_from,
        cast(null as date)                      as valid_to,
        
        cast('HRIS' as varchar)                 as source_system
    from {{ source('hris_systems', 'stg_expert_center_office') }}
),

division as (
    select
        cast('division' as varchar)             as org_unit_type,
        cast(null as varchar)                   as src_org_code,
        cast(null as varchar)                   as cluster_code,
        cast(division_code as varchar)          as division_code,
        cast(office_code as varchar)            as office_code,
        cast(business_group_code as varchar)    as business_group_code,
        cast(division_status as varchar)        as status,
        cast(null as date)                      as valid_from,
        cast(null as date)                      as valid_to,
        cast('HRIS' as varchar)                 as source_system
    from {{ source('hris_systems', 'stg_division') }}
)

select * from business_group
union 
select * from office
union 
select * from division