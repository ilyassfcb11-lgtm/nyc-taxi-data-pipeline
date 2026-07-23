-- =============================================================
-- mart_revenue_efficiency.sql — Mart: Revenue Efficiency KPIs
-- =============================================================
-- What this table answers:
--   "When and where does each taxi generate the most revenue?"
--
-- Used in Tableau: Revenue Efficiency page
--   - Revenue per hour by time period
--   - Top and bottom performing zones by revenue efficiency
--   - Hour × Borough revenue heatmap
--
-- Grain: one row per (hour, borough, month)
-- =============================================================

CREATE OR REPLACE TABLE `nyc-taxi-intelligence.mart.mart_revenue_efficiency`
AS

SELECT
    -- -------------------------
    -- Dimensions
    -- -------------------------
    f.pickup_hour,
    f.pickup_month,
    d.month_name,
    d.day_type,
    z.borough,

    -- -------------------------
    -- Volume
    -- -------------------------
    COUNT(*)                                            AS total_trips,

    -- -------------------------
    -- Revenue efficiency KPIs
    -- -------------------------
    ROUND(AVG(f.revenue_per_hour), 2)                   AS avg_revenue_per_hour,
    ROUND(AVG(f.revenue_per_mile), 2)                   AS avg_revenue_per_mile,
    ROUND(AVG(f.total_amount), 2)                       AS avg_revenue_per_trip,
    ROUND(SUM(f.total_amount), 2)                       AS total_revenue,

    -- -------------------------
    -- Tip behavior
    -- -------------------------
    ROUND(AVG(f.tip_amount), 2)                         AS avg_tip,
    ROUND(
        COUNTIF(f.tip_amount > 0) * 100.0 / COUNT(*), 1
    )                                                   AS pct_trips_with_tip,

    -- -------------------------
    -- Trip characteristics
    -- -------------------------
    ROUND(AVG(f.trip_distance_miles), 2)                AS avg_distance,
    ROUND(AVG(f.trip_duration_minutes), 2)              AS avg_duration_minutes,

    -- -------------------------
    -- CBD congestion fee impact
    -- (new in 2025 — how much does this add per trip?)
    -- -------------------------
    ROUND(AVG(COALESCE(f.cbd_congestion_fee, 0)), 2)    AS avg_cbd_fee,
    ROUND(SUM(COALESCE(f.cbd_congestion_fee, 0)), 2)    AS total_cbd_fees_collected

FROM `nyc-taxi-intelligence.core.fact_trips` f
LEFT JOIN `nyc-taxi-intelligence.core.dim_date` d
    ON f.pickup_date = d.date_id
LEFT JOIN `nyc-taxi-intelligence.core.dim_zone` z
    ON f.pickup_location_id = z.location_id

GROUP BY
    f.pickup_hour,
    f.pickup_month,
    d.month_name,
    d.day_type,
    z.borough
;
