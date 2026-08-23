-- 1. count of distinct loans = 1,998,728 - 50,000
select count(*) as total_rows,
       count(distinct loan_sequence_number) as distinct_loans
from wh_mortgage.dbo.fct_performance

-- 2. Arrears distribution
select loan_status, count(*) as loan_months, count(distinct loan_sequence_number) as distinct_loans
from wh_mortgage.dbo.fct_performance
group by loan_status
order by loan_months desc

-- 3. 90+ arrears rate
select
    sum(cast(is_90_plus_delinquent as int)) as loan_months_90_plus,
    count(*) as total_loan_months,
    cast(sum(cast(is_90_plus_delinquent as int)) as decimal(10,4)) / count(*) * 100 as pct_90_plus
from wh_mortgage.dbo.fct_performance

-- 4. Arrears by loan attribute, with rates included
select 
    d.occupancy_status,
    sum(cast(f.is_90_plus_delinquent as int)) as loan_months_90_plus,
    count(*) as total_loan_months,
    cast(sum(cast(f.is_90_plus_delinquent as int)) as decimal(10,4)) / count(*) * 100 as pct_90_plus
from wh_mortgage.dbo.fct_performance f
join wh_mortgage.dbo.dim_loan d on f.loan_key = d.loan_key
group by d.occupancy_status
order by pct_90_plus desc

-- 5. Referential/orphan double-check = 0
select count(*) 
from wh_mortgage.dbo.fct_performance f
left join wh_mortgage.dbo.dim_loan d on f.loan_key = d.loan_key
where d.loan_key is null
