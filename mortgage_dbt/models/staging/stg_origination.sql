with source as (
    select * from {{ source('bronze', 'bronze_origination') }}
)

select
    -- identifier: kept as text. It's a key, not a quantity — never a number.
    cast(loan_sequence_number as varchar(20))             as loan_sequence_number,

    -- sentinel = null, then a real integer.
    -- 9999 means "credit score not available"; it must NOT survive as 9999.
    try_cast(nullif(credit_score, '9999') as int)         as credit_score,

    -- YYYYMM text = a real date (first day of that month).
    try_cast(first_payment_date + '01' as date)           as first_payment_date,
    try_cast(maturity_date + '01' as date)                as maturity_date,

    -- money and rates = real decimals.
    try_cast(original_upb as decimal(12,2))               as original_upb,
    try_cast(original_interest_rate as decimal(6,3))      as original_interest_rate,

    -- another sentinel: 999 LTV means "not available" = null, then integer.
    try_cast(nullif(original_ltv, '999') as int)          as original_ltv,

    cast(first_time_homebuyer_flag as varchar(1))         as first_time_homebuyer_flag,

    cast(msa as varchar(5))                               as msa,

    try_cast(mi_pct as int)                               as mi_pct,

    try_cast(nullif(number_of_units, '99') as int)        as number_of_units,

    cast(occupancy_status as varchar(1))                  as occupancy_status,

    -- another sentinel: 999 CLTV means "not available" = null, then integer.
    try_cast(nullif(original_cltv, '999') as int)         as original_cltv,

    -- another sentinel: 999 LTV means "not available" = null, then integer.
    try_cast(nullif(original_dti, '999') as int)          as original_dti,

    cast(channel as varchar(10))                          as channel,

    cast(ppm_flag as varchar(1))                          as ppm_flag,

    cast(amortization_type as varchar(10))                as amortization_type,

    cast(property_state as varchar(10))                   as property_state,

    cast(property_type as varchar(10))                    as property_type,

    cast(postal_code as varchar(10))                      as postal_code,

    cast(loan_purpose as varchar(5))                      as loan_purpose,

    try_cast(original_loan_term as int)                   as original_loan_term,

    try_cast(nullif(number_of_borrowers, '99') as int)    as number_of_borrowers,

    cast(seller_name as varchar(100))                     as seller_name,

    cast(servicer_name as varchar(100))                   as servicer_name,

    cast(super_conforming_flag as varchar(5))             as super_conforming_flag,

    cast(pre_harp_loan_sequence_number as varchar(20))    as pre_harp_loan_sequence_number,

    cast(program_indicator as varchar(5))                 as program_indicator,

    cast(harp_indicator as varchar(5))                    as harp_indicator,

    cast(property_valuation_method as varchar(1))         as property_valuation_method,

    cast(interest_only_indicator as varchar(1))           as interest_only_indicator,

    cast(mi_cancellation_indicator as varchar(1))         as mi_cancellation_indicator

from source