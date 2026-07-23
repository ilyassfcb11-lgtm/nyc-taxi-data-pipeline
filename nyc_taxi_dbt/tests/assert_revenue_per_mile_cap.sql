-- =============================================================
-- assert_revenue_per_mile_cap.sql
-- Business rule: for trips >= 0.5 miles, revenue_per_mile must be < $200
-- Reason: the per-mile metric is meaningless for ultra-short NYC trips
-- (a 0.01 mile block hop with a $3 minimum fare = $300/mile legitimately).
-- We only validate trips where distance is meaningful (>= 0.5 miles).
-- Above 0.5 miles, earning >$200/mile would require ~$100 fare for half a mile
-- — almost certainly a GPS error recording a tiny distance for a long trip.
-- Negative values always indicate data corruption regardless of distance.
-- Fails if: any trip >= 0.5 miles has revenue_per_mile > 200 or < 0
-- =============================================================

SELECT
    pickup_datetime,
    pickup_location_id,
    total_amount,
    trip_distance_miles,
    revenue_per_mile
FROM {{ ref('fact_trips') }}
WHERE trip_distance_miles >= 0.5
  AND (revenue_per_mile > 200 OR revenue_per_mile < 0)
