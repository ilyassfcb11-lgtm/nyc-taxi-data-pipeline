-- =============================================================
-- mart_route_analysis.sql — Mart: Route-Level Analysis
-- =============================================================
-- What this table answers:
--   "Which pickup → dropoff combinations are busiest and
--    most profitable?"
--
-- Used in Tableau: Zone & Route Analysis page
--   - Top routes by trip volume
--   - Most profitable routes
--   - Route efficiency comparison
--
-- Grain: one row per (pickup_zone, dropoff_zone) pair
-- Only routes with >= 100 trips are included (removes noise)
-- =============================================================

CREATE OR REPLACE TABLE `nyc-taxi-intelligence.mart.mart_route_analysis`
AS

SELECT
    -- -------------------------
    -- Route identity
    -- -------------------------
    f.pickup_location_id,
    f.dropoff_location_id,
    pu.zone_name                                    AS pickup_zone,
    pu.borough                                      AS pickup_borough,
    do.zone_name                                    AS dropoff_zone,
    do.borough                                      AS dropoff_borough,

    -- Is this an intra-borough trip (same borough start and end)?
    CASE
        WHEN pu.borough = do.borough THEN TRUE
        ELSE FALSE
    END                                             AS is_same_borough,

    -- Is this an airport route (either end is an airport)?
    CASE
        WHEN pu.is_airport OR do.is_airport THEN TRUE
        ELSE FALSE
    END                                             AS is_airport_route,

    -- -------------------------
    -- Volume
    -- -------------------------
    COUNT(*)                                        AS total_trips,

    -- -------------------------
    -- Revenue
    -- -------------------------
    ROUND(AVG(f.total_amount), 2)                   AS avg_revenue_per_trip,
    ROUND(SUM(f.total_amount), 2)                   AS total_revenue,
    ROUND(AVG(f.revenue_per_mile), 2)               AS avg_revenue_per_mile,

    -- -------------------------
    -- Trip characteristics
    -- -------------------------
    ROUND(AVG(f.trip_distance_miles), 2)            AS avg_distance_miles,
    ROUND(AVG(f.trip_duration_minutes), 2)          AS avg_duration_minutes,
    ROUND(AVG(f.tip_amount), 2)                     AS avg_tip

FROM `nyc-taxi-intelligence.core.fact_trips` f
LEFT JOIN `nyc-taxi-intelligence.core.dim_zone` pu
    ON f.pickup_location_id = pu.location_id
LEFT JOIN `nyc-taxi-intelligence.core.dim_zone` do
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
-- Only keep routes with at least 100 trips
-- Routes with fewer trips are statistical noise — too few
-- data points to draw conclusions from

ORDER BY total_trips DESC
;
