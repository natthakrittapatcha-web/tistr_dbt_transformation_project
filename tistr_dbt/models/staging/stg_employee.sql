-- models/staging/stg_employee.sql
-- อ่านจาก HRIS เป็น master, เติมจาก CMS ในส่วนที่ขาด

with hris as (
    select * from {{ source('hris_systems', 'stg_employee') }}
),

cms as (
    select * from {{ source('cms_systems', 'stg_employee') }}
)

select
    h."employee_id"            as employee_id,
    h."seq_no"               as seq_no,
    h."card_no"              as card_no,
    h."title_id"             as title_id,
    coalesce(h."employee_name_th",       c."employee_name")      as employee_name_th,
    coalesce(h."employee_lastname_th",      c."employee_name2")  as employee_lastname_th,
    h."employee_name_en"          as employee_name_en,
    h."employee_lastname_en"         as employee_lastname_en,
    h."gender"              as gender,
    cast(h."birthdate" as date)   as birthdate,
    h."citizen_id"              as citizen_id,
    h."tax_id"               as tax_id,
    h."marital_id"             as marital_id,
    h."religion_id"          as religion_id,
    h."nationality_id"        as nationality_id,
    h."race_id"              as race_id,
    h."blood_name"           as blood_name,
    coalesce(h."telephone_contact",   c."telephone_contact")  as telephone_contact,
    coalesce(h."mobile_contact",     c."mobile_contact")     as mobile_contact,
    coalesce(h."email_contact",      c."email_contact")      as email_contact,
    c."fax_contact"         as fax_number,
    h."line_id"              as line_id,
    h."fund_type"            as fund_type,
    h."emergency_contact_name"       as emergency_contact_name,
    h."emergency_contact_phone"        as emergency_contact_phone,
    h."employee_status"     as employee_status,
    h."employee_id"         as hris_employee_id,
    c."employee_id"         as cms_employee_id,
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS'                  as source_system
from hris h
left join cms c
    on h."employee_id" = c."employee_id"