-- =============================================================
-- stg_trips.sql — Staging: Clean Trip Records
-- =============================================================
-- What this query does:
--   Takes the raw 48.7M row table and produces a clean version
--   with all bad rows removed and all columns properly typed.
--
-- Why staging exists:
--   Raw data is never touched after ingestion. All cleaning
--   happens here. If a cleaning rule turns out to be wrong,
--   we fix this file and re-run — the raw data is untouched.
--
-- Rows removed by this query:
--   - Fares <= $0 (2.87M rows) — not real revenue trips
--   - Distance <= 0 miles (1.4M rows) — not completed trips
--   - Trips outside 2025 (data quality / wrong year records)
--   - Trip duration <= 0 seconds (dropoff before or = pickup)
--   - Fare > $500 (extreme outlier — meter malfunction)
--   - Distance > 100 miles (extreme outlier — GPS error)
--
-- Columns added:
--   - trip_duration_minutes — computed from pickup/dropoff
--   - pickup_hour, pickup_day_of_week, pickup_month — for KPIs
--   - is_airport_trip — flag for JFK/LaGuardia pickups
-- =============================================================

CREATE OR REPLACE TABLE `nyc-taxi-intelligence.staging.stg_trips`
PARTITION BY pickup_date
AS

SELECT
    -- -------------------------
    -- Identifiers
    -- -------------------------
    VendorID                                        AS vendor_id,

    -- -------------------------
    -- Timestamps (cast to correct type)
    -- -------------------------
    CAST(tpep_pickup_datetime  AS TIMESTAMP)        AS pickup_datetime,
    CAST(tpep_dropoff_datetime AS TIMESTAMP)        AS dropoff_datetime,
    DATE(tpep_pickup_datetime)                      AS pickup_date,

    -- -------------------------
    -- Computed time columns
    -- (derived from pickup/dropoff — used in almost every KPI)
    -- -------------------------
    EXTRACT(HOUR        FROM tpep_pickup_datetime)  AS pickup_hour,
    EXTRACT(DAYOFWEEK   FROM tpep_pickup_datetime)  AS pickup_day_of_week,
    -- 1=Sunday, 2=Monday, ..., 7=Saturday in BigQuery
    EXTRACT(MONTH       FROM tpep_pickup_datetime)  AS pickup_month,
    EXTRACT(YEAR        FROM tpep_pickup_datetime)  AS pickup_year,

    ROUND(
        TIMESTAMP_DIFF(
            CAST(tpep_dropoff_datetime AS TIMESTAMP),
            CAST(tpep_pickup_datetime  AS TIMESTAMP),
            SECOND
        ) / 60.0,
        2
    )                                               AS trip_duration_minutes,
    -- TIMESTAMP_DIFF returns the difference in the given unit (SECOND here)
    -- We divide by 60 to convert to minutes and round to 2 decimal places

    -- -------------------------
    -- Trip details
    -- -------------------------
    CAST(passenger_count AS INT64)                  AS passenger_count,
    ROUND(CAST(trip_distance AS FLOAT64), 2)        AS trip_distance_miles,
    CAST(RatecodeID AS INT64)                       AS rate_code_id,
    -- RatecodeID meaning:
    -- 1 = Standard rate
    -- 2 = JFK (flat rate)
    -- 3 = Newark
    -- 4 = Nassau/Westchester
    -- 5 = Negotiated fare
    -- 6 = Group ride

    store_and_fwd_flag,
    -- Y = trip data was stored in vehicle memory before sending to vendor
    -- N = not stored (normal)

    -- -------------------------
    -- Location IDs
    -- -------------------------
    CAST(PULocationID AS INT64)                     AS pickup_location_id,
    CAST(DOLocationID AS INT64)                     AS dropoff_location_id,

    -- -------------------------
    -- Payment
    -- -------------------------
    CAST(payment_type AS INT64)                     AS payment_type,
    -- 1 = Credit card
    -- 2 = Cash
    -- 3 = No charge
    -- 4 = Dispute
    -- 5 = Unknown
    -- 6 = Voided trip

    -- -------------------------
    -- Fare components
    -- -------------------------
    ROUND(CAST(fare_amount          AS FLOAT64), 2) AS fare_amount,
    ROUND(CAST(extra                AS FLOAT64), 2) AS extra,
    ROUND(CAST(mta_tax              AS FLOAT64), 2) AS mta_tax,
    ROUND(CAST(tip_amount           AS FLOAT64), 2) AS tip_amount,
    ROUND(CAST(tolls_amount         AS FLOAT64), 2) AS tolls_amount,
    ROUND(CAST(improvement_surcharge AS FLOAT64), 2) AS improvement_surcharge,
    ROUND(CAST(total_amount         AS FLOAT64), 2) AS total_amount,
    ROUND(CAST(congestion_surcharge AS FLOAT64), 2) AS congestion_surcharge,
    ROUND(CAST(Airport_fee          AS FLOAT64), 2) AS airport_fee,
    ROUND(CAST(cbd_congestion_fee   AS FLOAT64), 2) AS cbd_congestion_fee,
    -- cbd_congestion_fee: NYC Central Business District toll
    -- launched January 5, 2025 — new column unique to 2025 data

    -- -------------------------
    -- Derived flags (true/false columns for easy filtering)
    -- -------------------------
    CASE
        WHEN CAST(PULocationID AS INT64) IN (132, 138) THEN TRUE
        ELSE FALSE
    END                                             AS is_airport_pickup,
    -- 132 = JFK Airport, 138 = LaGuardia Airport

    CASE
        WHEN CAST(payment_type AS INT64) = 1 THEN TRUE
        ELSE FALSE
    END                                             AS is_credit_card,

    CASE
        WHEN EXTRACT(DAYOFWEEK FROM tpep_pickup_datetime) IN (1, 7) THEN TRUE
        ELSE FALSE
    END                                             AS is_weekend
    -- 1 = Sunday, 7 = Saturday in BigQuery's DAYOFWEEK

FROM `nyc-taxi-intelligence.raw.raw_taxi_trips`

WHERE
    -- -------------------------
    -- CLEANING RULES (from EDA findings)
    -- -------------------------

    -- Rule 1: Only keep 2025 data
    -- Some records have wrong years (2024, 2009, etc.) — meter errors
    EXTRACT(YEAR FROM tpep_pickup_datetime) = 2025

    -- Rule 2: Remove zero and negative fares
    -- Found 2.87M such rows in EDA — refunds, cancellations, system errors
    AND fare_amount > 0

    -- Rule 3: Remove zero and negative distances
    -- Found 1.4M such rows in EDA — cancelled trips, GPS failures
    AND trip_distance > 0

    -- Rule 4: Remove trips where dropoff is not after pickup
    -- Zero or negative duration = data entry error or meter malfunction
    AND tpep_dropoff_datetime > tpep_pickup_datetime

    -- Rule 5: Cap extreme fare outliers
    -- EDA showed p99 = $79.75. Fares above $500 are meter malfunctions.
    AND fare_amount <= 500

    -- Rule 6: Cap extreme distance outliers
    -- EDA showed p95 = 12.68 miles. Over 100 miles is a GPS error.
    AND trip_distance <= 100
;
