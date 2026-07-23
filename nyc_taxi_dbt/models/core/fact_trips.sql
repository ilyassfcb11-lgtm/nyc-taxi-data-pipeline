-- =============================================================
-- fact_trips.sql — Core: Fact Table
-- =============================================================
-- Grain: one row per cleaned taxi trip (~44M rows)
-- Depends on: {{ ref('stg_trips') }}
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

SELECT
    pickup_location_id,
    dropoff_location_id,
    pickup_date,
    pickup_datetime,
    dropoff_datetime,
    pickup_hour,
    pickup_day_of_week,
    pickup_month,
    pickup_year,
    trip_duration_minutes,
    trip_distance_miles,
    passenger_count,
    rate_code_id,
    payment_type,
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

    -- Computed revenue metrics (calculated once, reused in all mart tables)
    ROUND(fare_amount + COALESCE(tip_amount, 0), 2)     AS fare_plus_tip,

    ROUND(
        CASE
            WHEN trip_distance_miles > 0
            THEN total_amount / trip_distance_miles
            ELSE NULL
        END, 2
    )                                                    AS revenue_per_mile,

    ROUND(
        CASE
            WHEN trip_duration_minutes > 0
            THEN total_amount / trip_duration_minutes * 60
            ELSE NULL
        END, 2
    )                                                    AS revenue_per_hour,

    is_airport_pickup,
    is_credit_card,
    is_weekend,
    vendor_id

FROM {{ ref('stg_trips') }}
