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