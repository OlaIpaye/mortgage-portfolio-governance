# Mortgage Portfolio Product Governance & Performance Review

An end-to-end analytics-engineering project on Microsoft Fabric. Freddie Mac
loan-level data flows through a Lakehouse, into a dbt-built star schema, and out
to a Direct Lake Power BI governance pack. Built as the quarterly governance pack
a Product Analyst at a UK lender would produce.

## Data schema

The Freddie Mac Single-Family Loan-Level Dataset was downloaded as pipe-delimited
".txt" files with no header rows, so column names must come from Freddie
Mac's published File Layout rather than the data itself.

Freddie Mac changed the layout in July 2026, so two versions exist. I confirmed which one my 2018 sample matches by counting the columns in the raw origination file and comparing against each layout:

- Pre-July 2026 layout: 32 columns
- July 2026 layout: 31 columns
- The sample_orig_2018.txt and sample_svcg_2018.txt: **32 columns matches Pre-July 2026 layout**

The schema folder holds the column definitions derived from that confirmed
layout, one file per dataset:

- schema/origination.py - 32 fields for the Origination Data File
- schema/performance.py - 32 fields for the Monthly Performance Data File

Each file lists the columns in exact file order (order is what I relied on, since the raw files have no headers). **Columns are loaded as text at the bronze stage** to preserve the source faithfully; typing happens later in dbt.

##
