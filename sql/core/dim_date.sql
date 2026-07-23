-- =============================================================
-- dim_date.sql — Core: Date Dimension Table
-- =============================================================
-- What is a date dimension?
--   Instead of computing EXTRACT(MONTH FROM pickup_datetime)
--   in every single query, we pre-compute all date attributes
--   once and store them. Every query that needs "what month
--   is this date" just joins dim_date instead of recalculating.
--
--   This is the standard pattern in every data warehouse.
-- =============================================================

CREATE OR REPLACE TABLE `nyc-taxi-intelligence.core.dim_date`
AS

SELECT
    pickup_date                                         AS date_id,
    -- date_id is the join key — fact_trips.pickup_date = dim_date.date_id

    EXTRACT(YEAR        FROM pickup_date)               AS year,
    EXTRACT(MONTH       FROM pickup_date)               AS month_num,
    FORMAT_DATE('%B',       pickup_date)                AS month_name,
    -- FORMAT_DATE('%B') = "January", "February", etc.

    FORMAT_DATE('%b',       pickup_date)                AS month_short,
    -- FORMAT_DATE('%b') = "Jan", "Feb", etc.

    EXTRACT(QUARTER     FROM pickup_date)               AS quarter,
    -- Q1=1, Q2=2, Q3=3, Q4=4

    EXTRACT(WEEK        FROM pickup_date)               AS week_of_year,
    EXTRACT(DAYOFYEAR   FROM pickup_date)               AS day_of_year,
    EXTRACT(DAY         FROM pickup_date)               AS day_of_month,
    EXTRACT(DAYOFWEEK   FROM pickup_date)               AS day_of_week_num,
    -- 1=Sunday, 2=Monday, ..., 7=Saturday

    FORMAT_DATE('%A',       pickup_date)                AS day_name,
    -- "Monday", "Tuesday", etc.

    FORMAT_DATE('%a',       pickup_date)                AS day_short,
    -- "Mon", "Tue", etc.

    CASE
        WHEN EXTRACT(DAYOFWEEK FROM pickup_date) IN (1, 7) THEN TRUE
        ELSE FALSE
    END                                                 AS is_weekend,

    CASE
        WHEN EXTRACT(DAYOFWEEK FROM pickup_date) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END                                                 AS day_type

FROM (
    -- Generate one row per date in 2025
    -- UNNEST(GENERATE_DATE_ARRAY) creates a table from an array of dates
    SELECT date_val AS pickup_date
    FROM UNNEST(
        GENERATE_DATE_ARRAY('2025-01-01', '2025-12-31', INTERVAL 1 DAY)
    ) AS date_val
)
ORDER BY pickup_date
;
