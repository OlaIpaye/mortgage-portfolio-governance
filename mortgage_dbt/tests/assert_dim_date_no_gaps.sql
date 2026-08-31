with bounds as (

    select
        min(full_date) as min_date,
        max(full_date) as max_date,
        count(*) as row_count
    from {{ ref('dim_date') }}

)

select
    min_date,
    max_date,
    row_count,
    datediff(day, min_date, max_date) + 1 as expected_row_count
from bounds
where row_count <> datediff(day, min_date, max_date) + 1