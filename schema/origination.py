# schema/origination.py
# Freddie Mac SFLLD — Origination Data File (sample_orig_2018.txt)
# Source of truth: file_layout.xlsx (Pre-July 2026 layout), sheet "Origination Data File"
# 32 columns, in exact file order. Bronze layer loads ALL as strings;
# typing happens later in dbt staging. Column ORDER is what matters for parsing.

ORIGINATION_COLUMNS = [
    "credit_score",                        # 1  Numeric        (9999 = unknown)
    "first_payment_date",                  # 2  Date  YYYYMM
    "first_time_homebuyer_flag",           # 3  Alpha  Y/N/9
    "maturity_date",                       # 4  Date  YYYYMM
    "msa",                                 # 5  Numeric  (Metropolitan Statistical Area)
    "mi_pct",                              # 6  Numeric  (Mortgage Insurance %)
    "number_of_units",                     # 7  Numeric
    "occupancy_status",                    # 8  Alpha  O/I/S
    "original_cltv",                       # 9  Numeric  (Combined LTV)
    "original_dti",                        # 10 Numeric  (Debt-to-Income)
    "original_upb",                        # 11 Numeric  (loan amount)
    "original_ltv",                        # 12 Numeric  <-- you will band this
    "original_interest_rate",              # 13 Numeric 6,3
    "channel",                             # 14 Alpha  retail/broker/correspondent
    "ppm_flag",                            # 15 Alpha  (Prepayment Penalty Mortgage)
    "amortization_type",                   # 16 Alpha  (formerly Product Type: FRM/ARM)
    "property_state",                      # 17 Alpha  <-- concentration analysis
    "property_type",                       # 18 Alpha
    "postal_code",                         # 19 Numeric
    "loan_sequence_number",                # 20 AlphaNumeric  <-- PRIMARY KEY / use to join to performance table
    "loan_purpose",                        # 21 Alpha  Purchase/Refi
    "original_loan_term",                  # 22 Numeric  (months)
    "number_of_borrowers",                 # 23 Numeric
    "seller_name",                         # 24 AlphaNumeric
    "servicer_name",                       # 25 AlphaNumeric
    "super_conforming_flag",               # 26 Alpha
    "pre_harp_loan_sequence_number",       # 27 AlphaNumeric
    "program_indicator",                   # 28 AlphaNumeric
    "harp_indicator",                      # 29 Alpha
    "property_valuation_method",           # 30 Numeric
    "interest_only_indicator",             # 31 Alpha
    "mi_cancellation_indicator",           # 32 Alpha
]

assert len(ORIGINATION_COLUMNS) == 32, f"Expected 32 columns, got {len(ORIGINATION_COLUMNS)}"
