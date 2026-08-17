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
    end as loan_status

from cte_delinquency