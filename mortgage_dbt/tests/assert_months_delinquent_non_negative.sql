select
    *
from {{ ref('int_performance_delinquency_split') }}
where months_delinquent is not null
  and months_delinquent < 0