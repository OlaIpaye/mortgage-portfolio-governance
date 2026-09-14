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

    -- descriptive / filterable / groupable attributes, fixed at origination.
    -- Raw code retained alongside each decode for traceability back to the layout spec.
    first_time_homebuyer_flag,
    case first_time_homebuyer_flag
        when 'Y' then 'First time buyer'
        when 'N' then 'Not first time buyer'
        when '9' then 'Not available or not applicable'
        else 'Unknown'
    end as first_time_homebuyer_desc,

    occupancy_status,
    case occupancy_status
        when 'P' then 'Primary residence'
        when 'I' then 'Investment property'
        when 'S' then 'Second home'
        when '9' then 'Not available'
        else 'Unknown'
    end as occupancy_type,

    original_interest_rate,

    channel,
    case channel
        when 'R' then 'Retail'
        when 'B' then 'Broker'
        when 'C' then 'Correspondent'
        when 'T' then 'TPO not specified'
        when '9' then 'Not available'
        else 'Unknown'
    end as channel_desc,

    property_state,

    property_type,
    case property_type
        when 'SF' then 'Single-family'
        when 'CO' then 'Condo'
        when 'PU' then 'PUD'
        when 'MH' then 'Manufactured housing'
        when 'CP' then 'Co-op'
        when '99' then 'Not available'
        else 'Unknown'
    end as property_type_desc,

    postal_code,

    loan_purpose,
    case loan_purpose
        when 'P' then 'Purchase'
        when 'C' then 'Refinance, cash out'
        when 'N' then 'Refinance, no cash out'
        when 'R' then 'Refinance, not specified'
        when '9' then 'Not available'
        else 'Unknown'
    end as loan_purpose_desc,

    original_loan_term,
    number_of_borrowers,
    seller_name,
    servicer_name,

    program_indicator,
    case program_indicator
        when 'H' then 'Home Possible'
        when 'F' then 'HFA Advantage'
        when 'R' then 'Refi Possible'
        when '9' then 'Not available or not applicable'
        else 'Unknown'
    end as program_indicator_desc,

    property_valuation_method,
    case property_valuation_method
        when '1' then 'Appraisal waiver (ACE)'
        when '2' then 'Appraisal'
        when '3' then 'Other'
        when '4' then 'ACE plus PDR'
        when '7' then 'Not available'
        else 'Unknown'
    end as property_valuation_method_desc,

    mi_cancellation_indicator,
    case mi_cancellation_indicator
        when 'Y' then 'MI cancelled'
        when 'N' then 'MI not cancelled'
        when '7' then 'Not applicable, no MI'
        when '9' then 'Not disclosed'
        else 'Unknown'
    end as mi_cancellation_desc,

    credit_score,
    -- 9999 is the layout's Not Available sentinel, isolated so it never
    -- lands inside a scored band and distorts the comparison
    case
        when credit_score is null then 'Not available'
        when credit_score = 9999 then 'Not available'
        when credit_score < 620 then '1. Below 620'
        when credit_score < 660 then '2. 620-659'
        when credit_score < 700 then '3. 660-699'
        when credit_score < 740 then '4. 700-739'
        when credit_score < 780 then '5. 740-779'
        else '6. 780 and above'
    end as credit_score_band,

    original_ltv,
    -- 999 is the layout's Not Available sentinel. The 80 boundary is the
    -- one that carries meaning: above it, mortgage insurance is required.
    case
        when original_ltv is null then 'Not available'
        when original_ltv = 999 then 'Not available'
        when original_ltv <= 60 then '1. 60 and below'
        when original_ltv <= 70 then '2. 61-70'
        when original_ltv <= 80 then '3. 71-80'
        when original_ltv <= 90 then '4. 81-90'
        when original_ltv <= 95 then '5. 91-95'
        else '6. Above 95'
    end as original_ltv_band,

    original_cltv,
    original_dti,
    msa,
    mi_pct,
    number_of_units,

    amortization_type,
    case amortization_type
        when 'FRM' then 'Fixed rate'
        when 'ARM' then 'Adjustable rate'
        else 'Unknown'
    end as amortization_type_desc,

    ppm_flag,
    case ppm_flag
        when 'Y' then 'Prepayment penalty mortgage'
        when 'N' then 'Not a prepayment penalty mortgage'
        else 'Unknown'
    end as ppm_desc,

    super_conforming_flag,
    -- NULL in this extract, a single space per the layout spec. Both mean
    -- not super conforming, so both are handled.
    case
        when super_conforming_flag = 'Y' then 'Super conforming'
        when super_conforming_flag is null then 'Not super conforming'
        when ltrim(rtrim(super_conforming_flag)) = '' then 'Not super conforming'
        else 'Unknown'
    end as super_conforming_desc,

    harp_indicator,
    -- Source field is the Relief Refinance Indicator. HARP is the subset of
    -- these where original LTV is above 80, so this is NOT a HARP flag and
    -- must not be labelled as one in the pack.
    case
        when harp_indicator = 'Y' then 'Relief refinance'
        when harp_indicator is null then 'Not relief refinance'
        when ltrim(rtrim(harp_indicator)) = '' then 'Not relief refinance'
        else 'Unknown'
    end as relief_refinance_desc,

    interest_only_indicator,
    case interest_only_indicator
        when 'Y' then 'Interest only'
        when 'N' then 'Not interest only'
        else 'Unknown'
    end as interest_only_desc,

    -- dates fixed at origination; can be used to later join a dim_date (role-playing dimension)
    first_payment_date,
    maturity_date

from source