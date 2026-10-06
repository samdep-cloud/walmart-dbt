# Walmart: BI Analysis

This project models Walmart weekly sales data in Snowflake using dbt and analyzes the results with Python and matplotlib. CSV source files are staged in Amazon S3 and loaded into Snowflake, where dbt builds Type 1 date and store/department dimensions, captures Type 2 sales history through a snapshot, and produces fact and current-version analytical tables. Python retrieves the modeled data through the Snowflake Connector for Python, and matplotlib visualizations examine sales trends across stores, departments, and time. 

## Data Flow

CSV source files → Amazon S3 → Snowflake RAW tables → dbt staging → dimensions and sales history snapshot → fact and analytical tables → Python analysis

| Source File | Snowflake Raw Table | dbt Source | Grain |
|---|---|---|---|
| `department.csv` | `WALMART.RAW.DEPARTMENT` | `raw.sales` | Store, department, week |
| `stores.csv` | `WALMART.RAW.STORES` | `raw.stores` | Store |
| `fact.csv` | `WALMART.RAW.FACT` | `raw.features` | Store, week |

The ingestion SQL defines the storage integration, external stage, file format, raw tables, and loading statements. The source configuration in `models/staging/_walmart__sources.yml` maps the raw tables to the dbt sources.

## Models

| Layer | Models | Purpose |
|---|---|---|
| Staging | `stg_walmart__sales`, `stg_walmart__stores`, `stg_walmart__features` | Standardizes source field names |
| Dimensions | `dim_store`, `dim_date` | Maintains store/department and date attributes through Type 1 upserts |
| History | `walmart_sales_history` | Captures changes to sales, store size, and weekly features using a dbt check-strategy snapshot |
| Fact | `fact_sales` | Exposes current and historical versions with version start/end dates and insertion/update timestamps. |
| Serving | `obt_walmart_sales` | Combines current fact versions with dimension attributes for downstream analysis |

`dim_store` uses a composite store/department key, while `dim_date` uses `date_id`. Both preserve their insertion timestamps during normal incremental runs, while the updated time stamp reflects the latest processing run.

The sales snapshot implements Type 2 history at the store, department, and week grain. When a tracked value changes, the existing version receives an end timestamp and remains in the history table, and a new version is inserted. `fact_sales` exposes these periods through `vrsn_start_date` and `vrsn_end_date`. A `NULL` end date identifies the current version.

`obt_walmart_sales` selects only current fact versions and joins the store dimension on both store and department, preserving one row per store, department, and week.

## Analysis

Python connects to Snowflake using the Snowflake Connector for Python and retrieves the modeled sales data. Matplotlib visualizations examine weekly trends and compare sales across stores and departments.

## Project Documentation

- [Modeling and validation](docs/solution.md)
- [Snowflake setup and raw loading](sql/01_load_raw.sql)
- [Verification queries](sql/02_verify_results.sql)
- [Analysis Notebook](notebooks/walmart_sales_data_analysis.ipynb)
