-- =============================================================
-- assert_airport_revenue_premium.sql
-- Business rule: airport trips must earn more on average than
-- non-airport trips.
-- Reason: JFK and LaGuardia trips are longer distance + flat-rate
-- surcharges apply. If airport avg <= non-airport avg, something
-- is wrong with the is_airport_pickup flag or fare data.
-- Fails if: airport avg revenue <= non-airport avg revenue
-- =============================================================

WITH revenue_by_type AS (
    SELECT
        is_airport_pickup,
        AVG(total_amount) AS avg_revenue
    FROM {{ ref('fact_trips') }}
    GROUP BY is_airport_pickup
),
airport     AS (SELECT avg_revenue FROM revenue_by_type WHERE is_airport_pickup = TRUE),
non_airport AS (SELECT avg_revenue FROM revenue_by_type WHERE is_airport_pickup = FALSE)

SELECT
    airport.avg_revenue     AS airport_avg,
    non_airport.avg_revenue AS non_airport_avg
FROM airport, non_airport
WHERE airport.avg_revenue <= non_airport.avg_revenue
