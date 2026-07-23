-- =============================================================
-- assert_no_negative_duration.sql
-- Business rule: trip duration must always be >= 0 minutes
-- Reason: dropoff_datetime cannot be before pickup_datetime.
-- A negative duration means the timestamps are swapped or corrupt.
-- Our staging filter removes zero-duration trips, but negative
-- values are a different bug — this catches any that slip through.
-- Fails if: any trip has trip_duration_minutes < 0
-- =============================================================

SELECT
    pickup_datetime,
    dropoff_datetime,
    pickup_location_id,
    trip_duration_minutes
FROM {{ ref('fact_trips') }}
WHERE trip_duration_minutes < 0
