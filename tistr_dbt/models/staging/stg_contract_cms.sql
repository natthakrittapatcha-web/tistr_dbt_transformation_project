-- models/staging/stg_contract_cms.sql

with raw as (
    select * from {{ source('cms_systems', 'stg_contract') }}
),

parsed as (
    select
        seq_no,

        -- extract project_code: pattern is "name:XXXXXXXXXX" (10 digits after colon)
        -- e.g. "การพัฒนาระบบ...:6452201001"
        regexp_extract(project, ':([0-9]{10})', 1)
                                                as cms_project_code,

        -- extract project_name: text between first \n and the colon+code
        trim(regexp_extract(project,
            '\n(.+?):[0-9]{10}', 1
        ))                                      as cms_project_name,

        -- extract contract category from "ประเภท: XXX"
        trim(regexp_extract(project,
            'ประเภท:\s*(.+?)\n', 1
        ))                                      as contract_category,

        -- customer_contract: line 1 = customer name
        trim(split_part(customer_contract, chr(10), 1))
                                                as customer_name,

        -- customer_contract: line 2 = branch/office
        trim(split_part(customer_contract, chr(10), 2))
                                                as customer_branch,

        -- customer_contract: line 3+ = address
        trim(split_part(customer_contract, chr(10), 3))
                                                as customer_address,

        -- contract_type in CMS is actually customer_type
        contract_type                           as customer_type,

        phase_no,

        -- fiscal_year: "2564 / Q2" → split to year and quarter
        cast(
            trim(split_part(fiscal_year, '/', 1))
        as int)                                 as fiscal_year,
        trim(split_part(fiscal_year, '/', 2))   as fiscal_quarter,

        description                             as contract_description,

        -- budget: remove commas → cast to decimal
        cast(
            replace(budget_amount, ',', '')
        as decimal(18,2))                       as budget_amount,

        cast(
            replace(actual_amount, ',', '')
        as decimal(18,2))                       as actual_amount,

        -- duration: "12 เดือน" → extract number
        try_cast(
            regexp_extract(duration_month, '([0-9]+)', 1)
        as int)                                 as duration_months,

        -- sign_date: "5-ม.ค.-64" → needs manual mapping (Thai month abbrev)
        sign_date                               as sign_date_raw,

        -- plan_period: "05 ม.ค. 2564-\n05 ม.ค. 2565"
        trim(split_part(
            replace(plan_period, chr(10), ''), '-', 1
        ))                                      as plan_start_raw,
        trim(split_part(
            replace(plan_period, chr(10), ''), '-', 2
        ))                                      as plan_end_raw,

        business_group_name,
        office_name,
        division_name,
        contract_status,
        project_head,
        state_mechanism,
        installment_desc,

        year, month, day
    from raw
)

select * from parsed