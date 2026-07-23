-- =============================================================
-- fact_trips.sql — Core: Fact Table
-- =============================================================
-- What is a fact table?
--   In a star schema, the fact table is the center. It contains
--   one row per business event (here: one row per taxi trip).
--   It stores measurable numbers (fares, distances, durations)
--   and foreign keys that point to dimension tables.
--
-- What are foreign keys?
--   Instead of storing "Upper East Side South" in every row,
--   we store the zone ID (237). The dim_zone table has one row
--   for zone 237 with its name and borough. This avoids
--   repeating text in 2 million rows.
--
-- Why rebuild from staging (not raw)?
--   All cleaning is already done in stg_trips. fact_trips
--   simply reorganizes and selects the columns needed for
--   analytics. Raw data is never touched again.
-- =============================================================

CREATE OR REPLACE TABLE `nyc-taxi-intelligence.core.fact_trips`
PARTITION BY pickup_date
AS

SELECT
    -- -------------------------
    -- Keys (link to dimension tables)
    -- -------------------------
    pickup_location_id,
    dropoff_location_id,
    pickup_date,

    -- -------------------------
    -- Time attributes
    -- -------------------------
    pickup_datetime,
    dropoff_datetime,
    pickup_hour,
    pickup_day_of_week,
    pickup_month,
    pickup_year,
    trip_duration_minutes,

    -- -------------------------
    -- Trip measures
    -- -------------------------
    trip_distance_miles,
    passenger_count,
    rate_code_id,
    payment_type,

    -- -------------------------
    -- Revenue measures
    -- -------------------------
    fare_amount,
    tip_amount,
    tolls_amount,
    total_amount,
    extra,
    mta_tax,
    improvement_surcharge,
    congestion_surcharge,
    airport_fee,
    cbd_congestion_fee,

    -- -------------------------
    -- Computed revenue metrics
    -- (calculated once here, used in every mart table)
    -- -------------------------
    ROUND(fare_amount + COALESCE(tip_amount, 0), 2)     AS fare_plus_tip,
    -- COALESCE(tip_amount, 0) treats NULL as 0 — cash trips have null tip

    ROUND(
        CASE
            WHEN trip_distance_miles > 0
            THEN total_amount / trip_distance_miles
            ELSE NULL
        END, 2
    )                                                    AS revenue_per_mile,
    -- Revenue per mile: how efficiently distance converts to money
    -- NULL when distance = 0 to avoid division by zero

    ROUND(
        CASE
            WHEN trip_duration_minutes > 0
            THEN total_amount / trip_duration_minutes * 60
            ELSE NULL
        END, 2
    )                                                    AS revenue_per_hour,
    -- Revenue per hour: annualizes the trip rate
    -- (total_amount / minutes) * 60 = hourly equivalent rate

    -- -------------------------
    -- Flags
    -- -------------------------
    is_airport_pickup,
    is_credit_card,
    is_weekend,
    vendor_id

FROM `nyc-taxi-intelligence.staging.stg_trips`
;
