# schema/performance.py
# Freddie Mac SFLLD — Monthly Performance Data File (sample_svcg_2018.txt)
# Source of truth: file_layout.xlsx (Pre-July 2026 layout), sheet "Monthly Performance Data File"
# 32 columns, in exact file order. Bronze layer loads ALL as strings;
# typing happens later in dbt staging. Column ORDER is what matters for parsing.

PERFORMANCE_COLUMNS = [
    "loan_sequence_number",                # 1  AlphaNumeric  <-- JOIN KEY to origination table
    "monthly_reporting_period",            # 2  Date  YYYYMM  <-- the monthly grain
    "current_actual_upb",                  # 3  Numeric 12,2  (current balance)
    "current_loan_delinquency_status",     # 4  AlphaNumeric  <-- ARREARS BACKBONE (0=current,1=30-59d,2=60-89d,3=90-119d,...,RA=REO,XX=unknown)
    "loan_age",                            # 5  Numeric  <-- months-on-book source
    "remaining_months_to_legal_maturity",  # 6  Numeric
    "defect_settlement_date",              # 7  Date
    "modification_flag",                    # 8  Alpha
    "zero_balance_code",                   # 9  Numeric  (why the loan left the book: prepaid/default/etc.)
    "zero_balance_effective_date",         # 10 Date
    "current_interest_rate",               # 11 Numeric 8,3
    "current_deferred_upb",                # 12 Numeric
    "ddlpi",                               # 13 Date  (Due Date of Last Paid Installment)
    "mi_recoveries",                       # 14 Numeric 12,2
    "net_sales_proceeds",                  # 15 AlphaNumeric
    "non_mi_recoveries",                   # 16 Numeric 12,2
    "expenses",                            # 17 Numeric 12,2
    "legal_costs",                         # 18 Numeric 12,2
    "maintenance_and_preservation_costs",  # 19 Numeric 12,2
    "taxes_and_insurance",                 # 20 Numeric 12,2
    "miscellaneous_expenses",              # 21 Numeric 12,2
    "actual_loss_calculation",             # 22 Numeric 12,2
    "modification_cost",                   # 23 Numeric 12,2
    "step_modification_flag",              # 24 Alpha
    "deferred_payment_plan",               # 25 Alpha
    "eltv",                                # 26 Numeric  (Estimated LTV)
    "zero_balance_removal_upb",            # 27 Numeric 12,2
    "delinquent_accrued_interest",         # 28 Numeric 12,2
    "delinquency_due_to_disaster",         # 29 Alpha
    "borrower_assistance_status_code",     # 30 Alpha
    "current_month_modification_cost",     # 31 Numeric 12,2
    "interest_bearing_upb",                # 32 Numeric 12,2
]

assert len(PERFORMANCE_COLUMNS) == 32, f"Expected 32 columns, got {len(PERFORMANCE_COLUMNS)}"
