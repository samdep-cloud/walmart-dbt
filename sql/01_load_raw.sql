-- Original Snowflake setup and raw data loading

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

CREATE OR REPLACE DATABASE walmart;
USE DATABASE walmart;

CREATE OR REPLACE SCHEMA walmart.raw;
CREATE OR REPLACE SCHEMA walmart.transformed;
CREATE OR REPLACE SCHEMA walmart.snapshot;


-- S3 storage integration
-- The AWS role trust policy authorizes the Snowflake identity
-- and external ID returned by DESC INTEGRATION.

CREATE OR REPLACE STORAGE INTEGRATION s3_walmart_int
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN =
        'arn:aws:iam::<AWS_ACCOUNT_ID>:role/<S3_READ_ROLE>'
    STORAGE_ALLOWED_LOCATIONS = ('s3://<SOURCE_BUCKET>/');

DESC INTEGRATION s3_walmart_int;


-- CSV source format, includes missing-value handling

CREATE OR REPLACE FILE FORMAT walmart.raw.walmart_csv_ff
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NA', '')
    EMPTY_FIELD_AS_NULL = TRUE;


-- External stage

CREATE OR REPLACE STAGE walmart.raw.raw_stage
    STORAGE_INTEGRATION = s3_walmart_int
    URL = 's3://<SOURCE_BUCKET>/';

LIST @walmart.raw.raw_stage;

-- Define Schemas:
-- department.csv: weekly sales by store, department, and date

CREATE OR REPLACE TABLE walmart.raw.department (
    store        INT,
    dept         INT,
    date         DATE,
    weekly_sales NUMBER(12,2),
    isholiday    BOOLEAN
) COMMENT = 'Source department.csv: weekly sales by store, department, and date';

-- stores.csv: store attributes

CREATE OR REPLACE TABLE walmart.raw.stores (
    store INT,
    type  VARCHAR,
    size  INT
) COMMENT = 'Source stores.csv: store type and size';

-- fact.csv: weekly conditions by store and date, e.g. temperature, fuel price, etc.

CREATE OR REPLACE TABLE walmart.raw.fact (
    store        INT,
    date         DATE,
    temperature  FLOAT,
    fuel_price   FLOAT,
    markdown1    FLOAT,
    markdown2    FLOAT,
    markdown3    FLOAT,
    markdown4    FLOAT,
    markdown5    FLOAT,
    cpi          FLOAT,
    unemployment FLOAT,
    isholiday    BOOLEAN
) COMMENT = 'Source fact.csv: weekly conditions by store and date';


-- Load the source files

COPY INTO walmart.raw.department
    FROM @walmart.raw.raw_stage/department.csv
    FILE_FORMAT = (FORMAT_NAME = 'walmart.raw.walmart_csv_ff');

COPY INTO walmart.raw.stores
    FROM @walmart.raw.raw_stage/stores.csv
    FILE_FORMAT = (FORMAT_NAME = 'walmart.raw.walmart_csv_ff');

COPY INTO walmart.raw.fact
    FROM @walmart.raw.raw_stage/fact.csv
    FILE_FORMAT = (FORMAT_NAME = 'walmart.raw.walmart_csv_ff');