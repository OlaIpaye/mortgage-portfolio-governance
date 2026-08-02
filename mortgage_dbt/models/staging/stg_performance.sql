with source as (
    select * from {{ source('bronze', 'bronze_performance') }}
)

select
    -- composite key, part 1: which loan (assert format — it's a key)
    cast(loan_sequence_number as varchar(20))              as loan_sequence_number,

    -- composite key, part 2: which month. YYYYMM -> date.
    cast(monthly_reporting_period + '01' as date)          as monthly_reporting_period,

    -- the arrears backbone: a CODE, not a number.
    -- holds '0'..'3'+ but ALSO 'RA'. Keep faithful as text.
    cast(current_loan_delinquency_status as varchar(3))    as current_loan_delinquency_status,

    try_cast(current_actual_upb as decimal(12,2))          as current_actual_upb,

    try_cast(loan_age as int)                              as loan_age,

    -- the number of months until the loan is legally due to be paid off. somve values start with '0' and are therefore not numeric. Keep faithful as text.
    try_cast(remaining_months_to_legal_maturity as int)    as remaining_months_to_legal_maturity,

    try_cast(defect_settlement_date + '01' as date)        as defect_settlement_date,

    cast(modification_flag as varchar(1))                  as modification_flag,

    -- contains numbers tha tstarted with zero, so keep as text.
    cast(zero_balance_code as varchar(2))                  as zero_balance_code,

    try_cast(zero_balance_effective_date + '01' as date)   as zero_balance_effective_date,

    try_cast(current_interest_rate as decimal(6,3))        as current_interest_rate,

    try_cast(current_deferred_upb as decimal(12,2))        as current_deferred_upb,

    try_cast(ddlpi + '01' as date)                         as ddlpi,

    try_cast(mi_recoveries as decimal(12,2))               as mi_recoveries,

    try_cast(net_sales_proceeds as decimal(12,2))          as net_sales_proceeds,

    try_cast(non_mi_recoveries as decimal(12,2))           as non_mi_recoveries,

    try_cast(expenses as decimal(12,2))                     as expenses,

    try_cast(legal_costs as decimal(12,2))                 as legal_costs,

    try_cast(maintenance_and_preservation_costs as decimal(12,2))         as maintenance_and_preservation_costs,

    try_cast(taxes_and_insurance as decimal(12,2))         as taxes_and_insurance,

    try_cast(miscellaneous_expenses as decimal(12,2))      as miscellaneous_expenses,

    try_cast(actual_loss_calculation as decimal(12,2))     as actual_loss_calculation,

    try_cast(modification_cost as decimal(12,2))           as modification_cost,

    cast(step_modification_flag as varchar(1))             as step_modification_flag,

    cast(deferred_payment_plan as varchar(1))         as deferred_payment_plan,

    -- another sentinel: 999 ELTV means "not available" = null, then integer.
    try_cast(nullif(eltv, '999') as int)                   as eltv,

    try_cast(zero_balance_removal_upb as decimal(12,2))    as zero_balance_removal_upb,

    try_cast(delinquent_accrued_interest as decimal(12,2)) as delinquent_accrued_interest,

    cast(delinquency_due_to_disaster as varchar(1))        as delinquency_due_to_disaster,

    cast(borrower_assistance_status_code as varchar(1))    as borrower_assistance_status_code,

    try_cast(current_month_modification_cost as decimal(12,2))         as current_month_modification_cost,

    try_cast(interest_bearing_upb as decimal(12,2))         as interest_bearing_upb

from source