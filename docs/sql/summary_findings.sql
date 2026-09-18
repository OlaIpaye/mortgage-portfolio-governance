-- Sanity checks and analytical findings run against the gold layer in
-- Fabric Warehouse wh_mortgage.


-- SECTION A -- Star schema validation and portfolio-level findings

-- 1. Grain check: total rows vs distinct loans.
-- Expected 1,998,728 loan-months across 50,000 loans
select count(*) as total_rows,
       count(distinct loan_sequence_number) as distinct_loans
from dbo.fct_performance;

-- 2. Arrears distribution by status.
select loan_status,
       count(*) as loan_months,
       count(distinct loan_sequence_number) as distinct_loans
from dbo.fct_performance
group by loan_status
order by loan_months desc;

-- 3. 90+ arrears rate on a loan-month basis.
-- Result: 1.35%.
select
    sum(cast(is_90_plus_delinquent as int)) as loan_months_90_plus,
    count(*) as total_loan_months,
    cast(sum(cast(is_90_plus_delinquent as int)) as decimal(10,4))
        / count(*) * 100 as pct_90_plus
from dbo.fct_performance;

-- 4. Arrears rate by occupancy status.
select
    d.occupancy_status,
    sum(cast(f.is_90_plus_delinquent as int)) as loan_months_90_plus,
    count(*) as total_loan_months,
    cast(sum(cast(f.is_90_plus_delinquent as int)) as decimal(10,4))
        / count(*) * 100 as pct_90_plus
from dbo.fct_performance f
join dbo.dim_loan d on f.loan_key = d.loan_key
group by d.occupancy_status
order by pct_90_plus desc;

-- 5. Orphan check against dim_loan. Expected 0.
-- Independent confirmation of the dbt relationships test.
select count(*) as orphaned_fact_rows
from dbo.fct_performance f
left join dbo.dim_loan d on f.loan_key = d.loan_key
where d.loan_key is null;

-- 6. Loan-level severity: ever 90+ vs ever REO.
select
    count(distinct loan_sequence_number) as total_loans,
    count(distinct case when is_90_plus_delinquent = 1
                        then loan_sequence_number end) as loans_ever_90_plus,
    count(distinct case when loan_status = 'REO Acquisition'
                        then loan_sequence_number end) as loans_ever_reo,
    cast(count(distinct case when is_90_plus_delinquent = 1
                             then loan_sequence_number end) as decimal(10,4))
        / count(distinct loan_sequence_number) * 100 as pct_loans_ever_90_plus,
    cast(count(distinct case when loan_status = 'REO Acquisition'
                             then loan_sequence_number end) as decimal(10,4))
        / count(distinct loan_sequence_number) * 100 as pct_loans_ever_reo
from dbo.fct_performance;



-- SECTION B -- dim_date build verification

-- 1. Date spine bounds -- establishes the range dim_date must cover,
-- before padding out to whole calendar years.
select
    min(monthly_reporting_period) as min_reporting_period,
    max(monthly_reporting_period) as max_reporting_period,
    count(distinct monthly_reporting_period) as distinct_periods
from dbo.fct_performance;

-- 2. dim_date shape check.
-- Expected 2,922 rows (8 years incl. 2020 and 2024 leap days),
-- 2018-01-01 to 2025-12-31, 96 month-ends (8 x 12).
select count(*) as row_count,
       min(full_date) as min_date,
       max(full_date) as max_date,
       sum(cast(is_month_end as int)) as month_end_count
from dbo.dim_date;

-- 3. Confirm fact rows align to month end, not the 1st.
select top 5 date_key, snapshot_month_end, monthly_reporting_period
from dbo.fct_performance
order by date_key;

-- 4. Orphan check against dim_date. Expected 0.
select count(*) as orphaned_fact_rows
from dbo.fct_performance f
left join dbo.dim_date d on f.date_key = d.date_key
where d.date_key is null;



-- SECTION C -- Seasoning, vintage, and forbearance analysis
-- Backbone of the arrears deep-dive page in the governance pack.

-- 1. loan_age data quality check before using it as a seasoning axis.
select min(loan_age) as min_age,
       max(loan_age) as max_age,
       sum(case when loan_age < 0 then 1 else 0 end) as negative_ages
from dbo.fct_performance;

-- 2. Seasoning curve: arrears rate and population at risk by age band.
select
    case
        when loan_age <  12 then '00-11'
        when loan_age <  24 then '12-23'
        when loan_age <  36 then '24-35'
        when loan_age <  48 then '36-47'
        when loan_age <  60 then '48-59'
        when loan_age <  72 then '60-71'
        else '72+'
    end as age_band,
    count(distinct loan_sequence_number) as loans,
    count(*) as loan_months,
    avg(cast(is_90_plus_delinquent as float)) as arrears_rate
from dbo.fct_performance
group by
    case
        when loan_age <  12 then '00-11'
        when loan_age <  24 then '12-23'
        when loan_age <  36 then '24-35'
        when loan_age <  48 then '36-47'
        when loan_age <  60 then '48-59'
        when loan_age <  72 then '60-71'
        else '72+'
    end
order by age_band;

-- 3. Vintage distribution -- can seasoning be separated from COVID?
select year(first_payment_date) as origination_year,
       count(*) as loans
from dbo.dim_loan
group by year(first_payment_date)
order by origination_year;

-- 4. Borrower assistance and disaster coding by reporting year.
select year(monthly_reporting_period) as reporting_year,
       count(*) as loan_months,
       sum(case when borrower_assistance_status_code is not null
                then 1 else 0 end) as assisted,
       sum(case when delinquency_due_to_disaster = 'Y'
                then 1 else 0 end) as disaster_flagged
from dbo.fct_performance
group by year(monthly_reporting_period)
order by reporting_year;


-- SECTION D: OUTCOME FAIRNESS AND PRICE FOR RISK
-- Reconciles the Page 3 visuals against SQL. Whole book, loan-month basis.
-- Arrears rate = 90+ loan-months / total loan-months, not loan-level.

-- 1: 90+ arrears rate by origination channel
select
    l.channel_desc,
    count(*) as loan_months,
    sum(cast(f.is_90_plus_delinquent as int)) as arrears_months,
    cast(sum(cast(f.is_90_plus_delinquent as int)) * 100.0 / count(*) as decimal(5,2)) as arrears_rate_pct
from dbo.fct_performance f
join dbo.dim_loan l on f.loan_key = l.loan_key
group by l.channel_desc
order by arrears_rate_pct desc;

-- Result:
--   Broker          181,792 loan-months     3,265 arrears    1.80%
--   Correspondent   639,279 loan-months    10,249 arrears    1.60%
--   Retail        1,177,657 loan-months    13,435 arrears    1.14%
--
-- Broker runs 58% above retail, correspondent 40% above. Denominators are
-- large enough that this is not a small-sample artifact. Not controlled for
-- credit score, LTV or age mix, so it is a selection effect until proven
-- otherwise. Note the ordering follows the distance from the lender:
-- retail is direct, correspondent is a third party that funds its own
-- loans, broker is a third party that does not. Worth a controlled analysis
-- before treating it as conduct.


-- 2: 90+ arrears rate by occupancy type
select
    l.occupancy_type,
    count(*) as loan_months,
    sum(cast(f.is_90_plus_delinquent as int)) as arrears_months,
    cast(sum(cast(f.is_90_plus_delinquent as int)) * 100.0 / count(*) as decimal(5,2)) as arrears_rate_pct
from dbo.fct_performance f
join dbo.dim_loan l on f.loan_key = l.loan_key
group by l.occupancy_type
order by arrears_rate_pct desc;

-- Result:
--   Primary residence   1,716,571 loan-months   24,223 arrears    1.41%
--   Investment property   193,473 loan-months    2,122 arrears    1.10%
--   Second home            88,684 loan-months      604 arrears    0.68%
--
-- Runs counter to expectation. The usual assumption is that a borrower
-- defends the home they live in first, so primary residence should be the
-- lowest. It is the highest. With 193,473 investment loan-months the
-- denominator rules out a small-sample artifact, so the ordering is real
-- in the data even if the cause is not established. Live hypothesis is
-- underwriting selection: US investment property lending requires larger
-- deposits, higher scores and cash reserves, so occupancy may be proxying
-- for borrower affluence rather than measuring behaviour. Unresolved.
-- Not controlled for credit score, LTV or age band.


-- 3: 90+ arrears rate and average origination rate by credit score band
select
    l.credit_score_band,
    count(*) as loan_months,
    cast(sum(cast(f.is_90_plus_delinquent as int)) * 100.0 / count(*) as decimal(5,2)) as arrears_rate_pct,
    cast(avg(l.original_interest_rate) as decimal(6,3)) as avg_origination_rate
from dbo.fct_performance f
join dbo.dim_loan l on f.loan_key = l.loan_key
where l.credit_score_band <> 'Not available'
group by l.credit_score_band
order by l.credit_score_band;

-- Result:
--   1. Below 620         5,648 loan-months    3.84%    4.843
--   2. 620-659         104,790 loan-months    3.96%    5.023
--   3. 660-699         280,902 loan-months    2.54%    4.877
--   4. 700-739         476,160 loan-months    1.68%    4.748
--   5. 740-779         584,954 loan-months    0.87%    4.646
--   6. 780 and above   545,597 loan-months    0.43%    4.586
--
-- This is the core Fair Value finding. Arrears fall roughly ninefold from
-- the 620-659 band to 780 and above, so underwriting is measuring risk.
-- The origination rate falls 43.7 basis points across the same range, and
-- it is not even monotonic: 620-659 prices higher than below 620, and
-- below 620 prices lower than 660-699. Price is close to flat against a
-- risk profile that varies by an order of magnitude.
--
-- Basis note: this averages original_interest_rate over loan-months, so it
-- is loan-month weighted. The Power BI measure Average Origination Rate
-- averages over dim_loan, so it is loan weighted, and gives 4.885 at the
-- bottom against 4.629 at the top, a 25.6 bp spread. Both show the same
-- flat profile. The loan weighted figure is the one quoted in the pack
-- because the claim is about how loans were priced, not about how long
-- each priced loan stayed on the book.
--
-- Below 620 holds only 87 loans (5,648 loan-months), too thin to interpret
-- on its own, which is why the pack describes the bottom of the range as
-- "near 3.9% in the two lowest credit bands" rather than quoting it.