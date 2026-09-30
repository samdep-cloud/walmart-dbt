# Modeling and Validation

## Data Model

The date dimension contains a numeric date key, the corresponding date, a holiday flag, and insertion and update timestamps. Type 1 upserts maintain the latest attribute values while preserving the original insertion timestamp.

The store dimension contains one row per store and department. Distinct combinations are derived from the sales source and joined to store type and size from the stores source. Type 1 upserts replace attribute values while preserving the original insertion timestamp.

The sales history snapshot combines weekly department sales, store size, and store-level weekly conditions. Its check strategy implements Type 2 history by comparing tracked values between runs. When a value changes, the existing version receives an end timestamp and is retained, and a new version is inserted.

`fact_sales` exposes all captured versions, including effective-period and audit timestamps. The analytical table, `obt_walmart_sales`, selects current versions and joins the dimensions for downstream analysis.

## Type 2 History Validation

A controlled test used store 1, department 1, week 2010-02-05.

| Stage | Weekly Sales | Observed Behavior |
|---|---:|---|
| Initial capture | 24,924.50 | Original version recorded |
| Controlled change | 24,925.50 | Original version ended; new current version inserted |
| Restoration | 24,924.50 | Test version ended; restored value inserted as a third version |
| Unchanged rerun | 24,924.50 | Version count remained at three, with one current version |

The historical version's end timestamp matches the succeeding version's start timestamp. Current versions have a NULL end date.

![SCD Type 2 sales history](images/07_scd2_logic_test_sales_v2.png)

## Serving Table Validation

Duplicate-key checks returned no rows for the store dimension and analytical table. After restoration, the analytical table returned one row for the tested store, department, and week with the original sales amount of 24,924.50.

The verification queries are retained in [02_verify_results.sql](../sql/02_verify_results.sql).