-- =============================================================
-- mart_hourly_demand.sql — Mart: Hourly Demand KPIs
-- =============================================================
-- Grain: one row per (hour, day_of_week, month, zone)
-- Depends on: {{ ref('fact_trips') }}, {{ ref('dim_date') }}, {{ ref('dim_zone') }}
-- =============================================================

SELECT
    f.pickup_hour,
    f.pickup_day_of_week,
    d.day_name,
    d.day_type,
    f.pickup_month,
    d.month_name,
    f.pickup_location_id,
    z.zone_name                         AS pickup_zone,
    z.borough                           AS pickup_borough,
    COUNT(*)                            AS total_trips,
    ROUND(SUM(f.total_amount), 2)       AS total_revenue,
    ROUND(AVG(f.total_amount), 2)       AS avg_revenue_per_trip,
    ROUND(AVG(f.revenue_per_hour), 2)   AS avg_revenue_per_hour,
    ROUND(AVG(f.trip_distance_miles), 2)    AS avg_distance_miles,
    ROUND(AVG(f.trip_duration_minutes), 2)  AS avg_duration_minutes,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        4
    )                                   AS demand_pct_of_total

FROM {{ ref('fact_trips') }} f
LEFT JOIN {{ ref('dim_date') }} d
    ON f.pickup_date = d.date_id
LEFT JOIN {{ ref('dim_zone') }} z
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
