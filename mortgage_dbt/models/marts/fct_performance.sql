with performance as (

    select
        *,
        -- monthly_reporting_period is a date landing on the 1st.
        -- Normalise to first of month, add a month, step back a day
        -- -> last day of the reporting month.
        dateadd(
            day, -1,
            dateadd(
                month, 1,
                datefromparts(
                    year(monthly_reporting_period),
                    month(monthly_reporting_period),
                    1
                )
            )
        ) as snapshot_month_end
    from {{ ref('int_performance_delinquency_split') }}

),

loan as (

    select
        loan_key,
        loan_sequence_number
    from {{ ref('dim_loan') }}

)

select
    -- foreign key, inherited from dim_loan via the join
    loan.loan_key,

    -- degenerate dimension: identifier with no attributes of its own, lives directly on the fact
    performance.loan_sequence_number,

    -- grain column
    performance.monthly_reporting_period,

    -- month-end date and its integer key, for the dim_date relationship
    performance.snapshot_month_end,

    cast(
        (year(performance.snapshot_month_end) * 10000)
        + (month(performance.snapshot_month_end) * 100)
        + day(performance.snapshot_month_end)
    as int) as date_key,

    -- measures carried from the intermediate model
    performance.months_delinquent,
    performance.loan_status,

    -- 90+ arrears flag: bit type (Fabric/T-SQL's native yes/no type)
    -- REO (months_delinquent is null) falls through to 0, not null:
    -- NULL >= 3 evaluates to unknown in SQL, so the ELSE catches it.
    -- Deliberate: REO is a terminal/resolved status, not active 90+ arrears.
    case
        when performance.months_delinquent >= 3 then cast(1 as bit)
        else cast(0 as bit)
    end as is_90_plus_delinquent,

    -- remaining performance columns to bring forward from the intermediate model
    performance.current_actual_upb,
    performance.current_interest_rate,
    performance.loan_age,
    performance.remaining_months_to_legal_maturity,
    performance.defect_settlement_date,
    performance.modification_flag,
    performance.zero_balance_code,
    performance.zero_balance_effective_date,
    performance.current_deferred_upb,
    performance.ddlpi,
    performance.mi_recoveries,
    performance.net_sales_proceeds,
    performance.non_mi_recoveries,
    performance.expenses,
    performance.legal_costs,
    performance.maintenance_and_preservation_costs,
    performance.taxes_and_insurance,
    performance.miscellaneous_expenses,
    performance.actual_loss_calculation,
    performance.modification_cost,
    performance.step_modification_flag,
    performance.deferred_payment_plan,
    performance.eltv,
    performance.zero_balance_removal_upb,
    performance.delinquent_accrued_interest,
    performance.delinquency_due_to_disaster,
    performance.borrower_assistance_status_code,
    performance.current_month_modification_cost,
    performance.interest_bearing_upb

from performance
left join loan
    on performance.loan_sequence_number = loan.loan_sequence_number