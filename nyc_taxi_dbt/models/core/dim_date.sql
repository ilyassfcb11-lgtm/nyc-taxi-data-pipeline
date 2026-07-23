-- =============================================================
-- dim_date.sql — Core: Date Dimension Table
-- =============================================================
-- Grain: one row per calendar date in 2025 (365 rows)
-- No upstream dependencies — generated from date array
-- =============================================================

SELECT
    pickup_date                                         AS date_id,
    EXTRACT(YEAR        FROM pickup_date)               AS year,
    EXTRACT(MONTH       FROM pickup_date)               AS month_num,
    FORMAT_DATE('%B',       pickup_date)                AS month_name,
    FORMAT_DATE('%b',       pickup_date)                AS month_short,
    EXTRACT(QUARTER     FROM pickup_date)               AS quarter,
    EXTRACT(WEEK        FROM pickup_date)               AS week_of_year,
    EXTRACT(DAYOFYEAR   FROM pickup_date)               AS day_of_year,
    EXTRACT(DAY         FROM pickup_date)               AS day_of_month,
    EXTRACT(DAYOFWEEK   FROM pickup_date)               AS day_of_week_num,
    FORMAT_DATE('%A',       pickup_date)                AS day_name,
    FORMAT_DATE('%a',       pickup_date)                AS day_short,
    CASE
        WHEN EXTRACT(DAYOFWEEK FROM pickup_date) IN (1, 7) THEN TRUE
        ELSE FALSE
    END                                                 AS is_weekend,
    CASE
        WHEN EXTRACT(DAYOFWEEK FROM pickup_date) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END                                                 AS day_type

FROM (
    SELECT date_val AS pickup_date
    FROM UNNEST(
        GENERATE_DATE_ARRAY('2025-01-01', '2025-12-31', INTERVAL 1 DAY)
    ) AS date_val
)
ORDER BY pickup_date
