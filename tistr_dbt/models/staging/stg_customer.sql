--  staging/stg_customer.sql
    
with sap as (
    select
        cast(customer_code as varchar)          as src_customer_id,
        -- detect type from account_group_name
        -- adjust these values to match your actual account_group values
        case
            when lower(account_group) in ('0001','kna1')
                then 'organization'
            when lower(account_group) in ('0002','priv')
                then 'person'
            when customer_name_1 like 'บริษัท%'
              or customer_name_1 like 'ห้างหุ้น%'
              or customer_name_1 like 'มหาวิทยาลัย%'
              or customer_name_1 like 'กรม%'
              or customer_name_1 like 'สำนัก%'
              or customer_name_1 like 'ธนาคาร%'
                then 'organization'
            else 'person'
        end                                     as customer_type,
        -- company name
        case
            when customer_name_1 like 'บริษัท%'
              or customer_name_1 like 'ห้างหุ้น%'
              or customer_name_1 like 'มหาวิทยาลัย%'
              or customer_name_1 like 'กรม%'
              or customer_name_1 like 'สำนัก%'
              or customer_name_1 like 'ธนาคาร%'
                then customer_name_1
            else null
        end                                     as company_name,
        -- person name
        case
            when customer_name_1 not like 'บริษัท%'
             and customer_name_1 not like 'ห้างหุ้น%'
             and customer_name_1 not like 'มหาวิทยาลัย%'
             and customer_name_1 not like 'กรม%'
             and customer_name_1 not like 'สำนัก%'
             and customer_name_1 not like 'ธนาคาร%'
                then customer_name_1
            else null
        end                                     as person_name,
        cast(null as varchar)                                    as person_lastname,
        cast(null as varchar)                                   as title,
        tax_id_1                                as tax_id,
        cast(null as varchar)                                   as id_card,
        street                                  as address,
        district,
        province,
        cast(postal_code as varchar)            as zipcode,
        cast(mobile_phone as varchar)           as phone,
        email,
        cast(null as varchar)                                    as fax,
        case
            when is_cancelled = 'X'
              or is_deleted_central = 'X'
                then 'inactive'
            else 'active'
        end                                     as status,
        'SAP'                                   as source_system
    from {{ source('sap_systems', 'stg_customer') }}
),

cms as (
    select
        cast(customer_id as varchar)            as src_customer_id,
        -- detect type from customer_prefix
        case
            when lower(customer_prefix) in ('บริษัท','ห้างหุ้น','มหาวิทยาลัย','กรม','สำนัก','ธนาคาร')
                then 'organization'
            when lower(customer_prefix) in ('นาย','นาง','นางสาว','mr.','mrs.','ms.')
                then 'person'
            -- fallback: if customer_name2 exists likely company (branch name)
            when customer_name2 is not null
                then 'organization'
            else 'person'
        end                                     as customer_type,
        case
            when lower(customer_prefix) in ('บริษัท','ห้างหุ้น','มหาวิทยาลัย','กรม','สำนัก', 'ธนาคาร')
                then concat(customer_prefix, ' ', customer_name)
            else null
        end                                     as company_name,
        case
            when lower(customer_prefix) in ('นาย','นาง','นางสาว','mr.','mrs.','ms.')
                then customer_name
            else null
        end                                     as person_name,
        customer_name2                          as person_lastname,
        customer_prefix                         as title,
        tax_id,
        cast(null as varchar)                                   as id_card,
        cast(null as varchar)                                   as address,
        cast(null as varchar)                                   as district,
        cast(null as varchar)                                   as province,
        cast(null as varchar)            as zipcode,
        cast(null as varchar)           as phone,
        cast(null as varchar)                                    as email,
        cast(null as varchar)                                    as fax,
        case
            when delete_status = 1 then 'inactive'
            else 'active'
        end                                     as status,
        'CMS'                                   as source_system
    from {{ source('cms_systems', 'stg_customer') }}
),

mis as (
    select
        cust_id                                 as src_customer_id,
        -- detect type from cust_title
        case
            when lower(cust_title) in ('บริษัท','ห้างหุ้น','มหาวิทยาลัย','กรม','สำนัก','ธนาคาร')
                then 'organization'
            when lower(cust_title) in ('นาย','นาง','นางสาว','mr.','mrs.','ms.')
                then 'person'
            -- fallback: business_name exists = company
            when business_name is not null and business_name != ''
                then 'organization'
            else 'person'
        end                                     as customer_type,
        case
            when business_name is not null
             and business_name != ''
                then business_name
            else null
        end                                     as company_name,
        case
            when business_name is null
              or business_name = ''
                then cust_name
            else null
        end                                     as person_name,
        cast(null as varchar)                                    as person_lastname,
        cust_title                              as title,
        tax_no                                  as tax_id,
        cast(null as varchar)                                   as id_card,
        concat_ws(' ',
            addr_no, addr_street
        )                                       as address,
        addr_distric                            as district,
        addr_province                           as province,
        addr_zipcode                            as zipcode,
        cust_phone                              as phone,
        cust_email                              as email,
        cust_fax                                as fax,
        case
            when cancel = 'Y' then 'inactive'
            else 'active'
        end                                     as status,
        'MIS'                                   as source_system
    from {{ source('mis_systems', 'stg_customer') }}
),

jump as (
    select
        cast(customer_id as varchar)            as src_customer_id,
        -- JUMP is the only system with explicit customer_type
        lower(customer_type)                    as customer_type,
        case
            when lower(customer_type) in ('company','นิติบุคคล','juristic')
                then customer_company
            else null
        end                                     as company_name,
        case
            when lower(customer_type) not in ('company','นิติบุคคล','juristic')
                then customer_full_name
            else null
        end                                     as person_name,
        customer_last_name                      as person_lastname,
        customer_title                          as title,
        cast(null as varchar)                                    as tax_id,      -- JUMP has no tax_id
        cast(null as varchar)                                   as id_card,
        cast(null as varchar)                                   as address,
        cast(null as varchar)                                   as district,
        province_name                           as province,
        zipcode,
        cast(null as varchar)           as phone,
        cast(null as varchar)                                    as email,
        cast(null as varchar)                                    as fax,
        'active'                                as status,      -- no cancel flag in JUMP
        'JUMP'                                  as source_system
    from {{ source('jump_systems', 'stg_customer') }}
)

select * from sap
union all
select * from cms
union all
select * from mis
union all
select * from jump