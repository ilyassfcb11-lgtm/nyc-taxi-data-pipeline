-- =============================================================
-- mart_hourly_demand.sql — Mart: Hourly Demand KPIs
-- =============================================================
-- What this table answers:
--   "When is demand highest, by hour, day, and zone?"
--
-- Used in Tableau: Demand Analysis page
--   - Heatmap of trips by hour × day of week
--   - Peak hour demand index by zone
--   - Weekend vs weekday comparison
--
-- Grain: one row per (pickup_hour, day_of_week, pickup_month, zone)
-- =============================================================

CREATE OR REPLACE TABLE `nyc-taxi-intelligence.mart.mart_hourly_demand`
AS

SELECT
    -- -------------------------
    -- Dimensions (the "by" columns — what we group by)
    -- -------------------------
    f.pickup_hour,
    f.pickup_day_of_week,
    d.day_name,
    d.day_type,                         -- 'Weekday' or 'Weekend'
    f.pickup_month,
    d.month_name,
    f.pickup_location_id,
    z.zone_name                         AS pickup_zone,
    z.borough                           AS pickup_borough,

    -- -------------------------
    -- Volume KPIs
    -- -------------------------
    COUNT(*)                            AS total_trips,

    -- -------------------------
    -- Revenue KPIs
    -- -------------------------
    ROUND(SUM(f.total_amount), 2)       AS total_revenue,
    ROUND(AVG(f.total_amount), 2)       AS avg_revenue_per_trip,
    ROUND(AVG(f.revenue_per_hour), 2)   AS avg_revenue_per_hour,

    -- -------------------------
    -- Operational KPIs
    -- -------------------------
    ROUND(AVG(f.trip_distance_miles), 2)    AS avg_distance_miles,
    ROUND(AVG(f.trip_duration_minutes), 2)  AS avg_duration_minutes,

    -- -------------------------
    -- Demand index
    -- (what % of total trips happen in this hour/day combination)
    -- -------------------------
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        4
    )                                   AS demand_pct_of_total
    -- SUM(COUNT(*)) OVER () = total trips across ALL rows
    -- Dividing by it gives percentage of total demand

FROM `nyc-taxi-intelligence.core.fact_trips` f
LEFT JOIN `nyc-taxi-intelligence.core.dim_date` d
    ON f.pickup_date = d.date_id
LEFT JOIN `nyc-taxi-intelligence.core.dim_zone` z
    ON f.pickup_location_id = z.location_id

GROUP BY
    f.pickup_hour,
    f.pickup_day_of_week,
    d.day_name,
    d.day_type,
    f.pickup_month,
    d.month_name,
    f.pickup_location_id,
    z.zone_name,
    z.borough
;
