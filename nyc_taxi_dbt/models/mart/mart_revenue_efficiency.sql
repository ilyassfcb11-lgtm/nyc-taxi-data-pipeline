-- =============================================================
-- mart_revenue_efficiency.sql — Mart: Revenue Efficiency KPIs
-- =============================================================
-- Grain: one row per (hour, borough, month, day_type)
-- Depends on: {{ ref('fact_trips') }}, {{ ref('dim_date') }}, {{ ref('dim_zone') }}
-- =============================================================

SELECT
    f.pickup_hour,
    f.pickup_month,
    d.month_name,
    d.day_type,
    z.borough,
    COUNT(*)                                            AS total_trips,
    ROUND(AVG(f.revenue_per_hour), 2)                   AS avg_revenue_per_hour,
    ROUND(AVG(f.revenue_per_mile), 2)                   AS avg_revenue_per_mile,
    ROUND(AVG(f.total_amount), 2)                       AS avg_revenue_per_trip,
    ROUND(SUM(f.total_amount), 2)                       AS total_revenue,
    ROUND(AVG(f.tip_amount), 2)                         AS avg_tip,
    ROUND(
        COUNTIF(f.tip_amount > 0) * 100.0 / COUNT(*), 1
    )                                                   AS pct_trips_with_tip,
    ROUND(AVG(f.trip_distance_miles), 2)                AS avg_distance,
    ROUND(AVG(f.trip_duration_minutes), 2)              AS avg_duration_minutes,
    ROUND(AVG(COALESCE(f.cbd_congestion_fee, 0)), 2)    AS avg_cbd_fee,
    ROUND(SUM(COALESCE(f.cbd_congestion_fee, 0)), 2)    AS total_cbd_fees_collected

FROM {{ ref('fact_trips') }} f
LEFT JOIN {{ ref('dim_date') }} d
    ON f.pickup_date = d.date_id
LEFT JOIN {{ ref('dim_zone') }} z
    ON f.pickup_location_id = z.location_id

GROUP BY
    f.pickup_hour,
    f.pickup_month,
    d.month_name,
    d.day_type,
    z.borough
