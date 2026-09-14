with source as (

    select * from {{ ref('stg_performance') }}

),

cte_delinquency as (

    select
        *,
        try_cast(current_loan_delinquency_status as int) as months_delinquent
    from source

)

select
    *,
    case
        when months_delinquent = 0 then 'Current'
        when months_delinquent = 1 then '30 Days Delinquent'
        when months_delinquent = 2 then '60 Days Delinquent'
        when months_delinquent >= 3 then '90+ Days Delinquent'
        when current_loan_delinquency_status = 'RA' then 'REO Acquisition'
        else 'Unknown'
    end as loan_status,

    case
        when zero_balance_code is null then 'Active, no termination event'
        when zero_balance_code = '01' then 'Prepaid or matured'
        when zero_balance_code = '02' then 'Third party sale'
        when zero_balance_code = '03' then 'Short sale or charge off'
        when zero_balance_code = '09' then 'REO disposition'
        when zero_balance_code = '15' then 'Whole loan sale'
        when zero_balance_code = '16' then 'Reperforming loan securitisation'
        when zero_balance_code = '96' then 'Defect prior to other termination'
        else 'Unknown'
    end as zero_balance_desc,

    case
        when modification_flag = 'Y' then 'Modified in current period'
        when modification_flag = 'P' then 'Modified in prior period'
        when modification_flag is null then 'Not modified'
        else 'Unknown'
    end as modification_status,

    case
        when delinquency_due_to_disaster = 'Y' then 'Disaster related'
        when delinquency_due_to_disaster is null then 'Not disaster related'
        else 'Unknown'
    end as disaster_delinquency_status,

    case
        when borrower_assistance_status_code = 'F' then 'Forbearance'
        when borrower_assistance_status_code = 'R' then 'Repayment plan'
        when borrower_assistance_status_code = 'T' then 'Trial period'
        when borrower_assistance_status_code is null then 'No assistance plan'
        else 'Unknown'
    end as assistance_plan_type

from cte_delinquency