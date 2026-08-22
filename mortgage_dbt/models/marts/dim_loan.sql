with source as (

    select * from {{ ref('stg_origination') }}

)

select
    -- surrogate key: generated from the natural key, used for all downstream joins
    row_number() over (order by loan_sequence_number) as loan_key,

    -- natural key, kept for traceability back to the source
    loan_sequence_number,

    -- reference key to a prior loan (HARP refinance lineage)
    pre_harp_loan_sequence_number,

    -- descriptive / filterable / groupable attributes, fixed at origination
    first_time_homebuyer_flag,
    occupancy_status,
    channel,
    property_state,
    property_type,
    postal_code,
    loan_purpose,
    original_loan_term,
    number_of_borrowers,
    seller_name,
    servicer_name,
    program_indicator,
    property_valuation_method,
    mi_cancellation_indicator,
    credit_score,
    original_ltv,
    original_cltv,
    original_dti,
    msa,
    number_of_units,
    amortization_type,
    ppm_flag,
    super_conforming_flag,
    harp_indicator,
    interest_only_indicator,

    -- dates fixed at origination; can be used to later join a dim_date (role-playing dimension)
    first_payment_date,
    maturity_date

from source