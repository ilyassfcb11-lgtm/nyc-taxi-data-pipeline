-- =============================================================
-- mart_route_analysis.sql — Mart: Route-Level Analysis
-- =============================================================
-- Grain: one row per (pickup_zone, dropoff_zone) with >= 100 trips
-- Depends on: {{ ref('fact_trips') }}, {{ ref('dim_zone') }}
-- =============================================================

SELECT
    f.pickup_location_id,
    f.dropoff_location_id,
    pu.zone_name                                    AS pickup_zone,
    pu.borough                                      AS pickup_borough,
    do.zone_name                                    AS dropoff_zone,
    do.borough                                      AS dropoff_borough,
    CASE
        WHEN pu.borough = do.borough THEN TRUE
        ELSE FALSE
    END                                             AS is_same_borough,
    CASE
        WHEN pu.is_airport OR do.is_airport THEN TRUE
        ELSE FALSE
    END                                             AS is_airport_route,
    COUNT(*)                                        AS total_trips,
    ROUND(AVG(f.total_amount), 2)                   AS avg_revenue_per_trip,
    ROUND(SUM(f.total_amount), 2)                   AS total_revenue,
    ROUND(AVG(f.revenue_per_mile), 2)               AS avg_revenue_per_mile,
    ROUND(AVG(f.trip_distance_miles), 2)            AS avg_distance_miles,
    ROUND(AVG(f.trip_duration_minutes), 2)          AS avg_duration_minutes,
    ROUND(AVG(f.tip_amount), 2)                     AS avg_tip

FROM {{ ref('fact_trips') }} f
LEFT JOIN {{ ref('dim_zone') }} pu
    ON f.pickup_location_id = pu.location_id
LEFT JOIN {{ ref('dim_zone') }} do
    ON f.dropoff_location_id = do.location_id

GROUP BY
    f.pickup_location_id,
    f.dropoff_location_id,
    pu.zone_name,
    pu.borough,
    do.zone_name,
    do.borough,
    is_same_borough,
    is_airport_route

HAVING COUNT(*) >= 100

ORDER BY total_trips DESC
