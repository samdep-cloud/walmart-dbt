-- Raw source row counts

SELECT 'department' AS table_name, COUNT(*) AS row_count
FROM walmart.raw.department
UNION ALL
SELECT 'stores', COUNT(*)
FROM walmart.raw.stores
UNION ALL
SELECT 'fact', COUNT(*)
FROM walmart.raw.fact;


-- Duplicate source keys: each query should return no rows

SELECT store, dept, date, COUNT(*) AS row_count
FROM walmart.raw.department
GROUP BY store, dept, date
HAVING COUNT(*) > 1;

SELECT store, COUNT(*) AS row_count
FROM walmart.raw.stores
GROUP BY store
HAVING COUNT(*) > 1;

SELECT store, date, COUNT(*) AS row_count
FROM walmart.raw.fact
GROUP BY store, date
HAVING COUNT(*) > 1;


-- Duplicate dimension keys: each query should return no rows

SELECT date_id, COUNT(*) AS row_count
FROM walmart.dbt_sdepalma.dim_date
GROUP BY date_id
HAVING COUNT(*) > 1;

SELECT store_id, dept_id, COUNT(*) AS row_count
FROM walmart.dbt_sdepalma.dim_store
GROUP BY store_id, dept_id
HAVING COUNT(*) > 1;


-- Exactly one current fact version per business key
-- Expected behavior: no results returned

SELECT
    store_id,
    dept_id,
    date_id,
    COUNT_IF(vrsn_end_date IS NULL) AS current_versions
FROM walmart.dbt_sdepalma.fact_sales
GROUP BY store_id, dept_id, date_id
HAVING COUNT_IF(vrsn_end_date IS NULL) <> 1;


-- Invalid version periods: should return no rows

SELECT *
FROM walmart.dbt_sdepalma.fact_sales
WHERE vrsn_start_date IS NULL
   OR (
       vrsn_end_date IS NOT NULL
       AND vrsn_end_date <= vrsn_start_date
   );


-- Fact references without matching dimensions: should return no rows

SELECT
    fact.store_id,
    fact.dept_id,
    fact.date_id
FROM walmart.dbt_sdepalma.fact_sales fact
LEFT JOIN walmart.dbt_sdepalma.dim_store stores
    ON fact.store_id = stores.store_id
   AND fact.dept_id = stores.dept_id
LEFT JOIN walmart.dbt_sdepalma.dim_date dates
    ON fact.date_id = dates.date_id
WHERE stores.store_id IS NULL
   OR dates.date_id IS NULL;


-- Current fact count should equal the OBT count

SELECT
    (
        SELECT COUNT(*)
        FROM walmart.dbt_sdepalma.fact_sales
        WHERE vrsn_end_date IS NULL
    ) AS current_fact_rows,
    (
        SELECT COUNT(*)
        FROM walmart.dbt_sdepalma.obt_walmart_sales
    ) AS obt_rows;


-- Duplicate OBT keys: should return no rows

SELECT store_id, dept_id, sales_date, COUNT(*) AS row_count
FROM walmart.dbt_sdepalma.obt_walmart_sales
GROUP BY store_id, dept_id, sales_date
HAVING COUNT(*) > 1;


-- Controlled SCD Type 2 demonstration
-- Original -> changed -> restored original

SELECT
    store_id,
    dept_id,
    sales_date,
    weekly_sales,
    vrsn_start_date,
    vrsn_end_date,
    insert_date,
    update_date
FROM walmart.dbt_sdepalma.fact_sales
WHERE store_id = 1
  AND dept_id = 1
  AND sales_date = '2010-02-05'
ORDER BY vrsn_start_date;


-- After restoration and an unchanged rerun:
-- expected total_versions = 3, current_versions = 1

SELECT
    COUNT(*) AS total_versions,
    COUNT_IF(vrsn_end_date IS NULL) AS current_versions
FROM walmart.dbt_sdepalma.fact_sales
WHERE store_id = 1
  AND dept_id = 1
  AND sales_date = '2010-02-05';