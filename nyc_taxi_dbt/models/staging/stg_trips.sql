-- =============================================================
-- stg_trips.sql — Staging: Clean Trip Records
-- =============================================================
-- Grain: one row per cleaned taxi trip (~44M rows)
-- Source: {{ source('raw', 'raw_taxi_trips') }}
--
-- Cleaning rules applied:
--   1. Year = 2025 only
--   2. fare_amount > 0
--   3. trip_distance > 0
--   4. dropoff > pickup (no zero-duration trips)
--   5. fare_amount <= 500 (removes meter malfunctions)
--   6. trip_distance <= 100 (removes GPS errors)
--   7. total_amount >= fare_amount (removes negative adjustment records)
--   8. revenue/mile <= 200 for trips >= 0.5 miles (removes GPS distance errors)
-- =============================================================

{{
    config(
        materialized = 'table',
        partition_by = {
            'field': 'pickup_date',
            'data_type': 'date'
        }
    )
}}
-- Override default 'view' for stg_trips only:
-- 44M rows is too large to re-scan from raw on every downstream query.
-- Materializing as a partitioned table makes core and mart queries fast.

SELECT
    VendorID                                        AS vendor_id,
    CAST(tpep_pickup_datetime  AS TIMESTAMP)        AS pickup_datetime,
    CAST(tpep_dropoff_datetime AS TIMESTAMP)        AS dropoff_datetime,
    DATE(tpep_pickup_datetime)                      AS pickup_date,
    EXTRACT(HOUR        FROM tpep_pickup_datetime)  AS pickup_hour,
    EXTRACT(DAYOFWEEK   FROM tpep_pickup_datetime)  AS pickup_day_of_week,
    EXTRACT(MONTH       FROM tpep_pickup_datetime)  AS pickup_month,
    EXTRACT(YEAR        FROM tpep_pickup_datetime)  AS pickup_year,
    ROUND(
        TIMESTAMP_DIFF(
            CAST(tpep_dropoff_datetime AS TIMESTAMP),
            CAST(tpep_pickup_datetime  AS TIMESTAMP),
            SECOND
        ) / 60.0, 2
    )                                               AS trip_duration_minutes,
    CAST(passenger_count AS INT64)                  AS passenger_count,
    ROUND(CAST(trip_distance AS FLOAT64), 2)        AS trip_distance_miles,
    CAST(RatecodeID AS INT64)                       AS rate_code_id,
    store_and_fwd_flag,
    CAST(PULocationID AS INT64)                     AS pickup_location_id,
    CAST(DOLocationID AS INT64)                     AS dropoff_location_id,
    CAST(payment_type AS INT64)                     AS payment_type,
    ROUND(CAST(fare_amount           AS FLOAT64), 2) AS fare_amount,
    ROUND(CAST(extra                 AS FLOAT64), 2) AS extra,
    ROUND(CAST(mta_tax               AS FLOAT64), 2) AS mta_tax,
    ROUND(CAST(tip_amount            AS FLOAT64), 2) AS tip_amount,
    ROUND(CAST(tolls_amount          AS FLOAT64), 2) AS tolls_amount,
    ROUND(CAST(improvement_surcharge AS FLOAT64), 2) AS improvement_surcharge,
    ROUND(CAST(total_amount          AS FLOAT64), 2) AS total_amount,
    ROUND(CAST(congestion_surcharge  AS FLOAT64), 2) AS congestion_surcharge,
    ROUND(CAST(Airport_fee           AS FLOAT64), 2) AS airport_fee,
    ROUND(CAST(cbd_congestion_fee    AS FLOAT64), 2) AS cbd_congestion_fee,
    CASE
        WHEN CAST(PULocationID AS INT64) IN (132, 138) THEN TRUE
        ELSE FALSE
    END                                             AS is_airport_pickup,
    CASE
        WHEN CAST(payment_type AS INT64) = 1 THEN TRUE
        ELSE FALSE
    END                                             AS is_credit_card,
    CASE
        WHEN EXTRACT(DAYOFWEEK FROM tpep_pickup_datetime) IN (1, 7) THEN TRUE
        ELSE FALSE
    END                                             AS is_weekend

FROM {{ source('raw', 'raw_taxi_trips') }}

WHERE
    EXTRACT(YEAR FROM tpep_pickup_datetime) = 2025
    AND fare_amount > 0
    AND trip_distance > 0
    AND tpep_dropoff_datetime > tpep_pickup_datetime
    AND fare_amount <= 500
    AND trip_distance <= 100
    AND CAST(total_amount AS FLOAT64) >= CAST(fare_amount AS FLOAT64)
    AND NOT (
        trip_distance >= 0.5
        AND CAST(total_amount AS FLOAT64) / NULLIF(CAST(trip_distance AS FLOAT64), 0) > 200
    )
