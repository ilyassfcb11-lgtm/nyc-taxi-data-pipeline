-- =============================================================
-- mart_zone_kpis.sql — Mart: Zone-Level KPIs
-- =============================================================
-- Grain: one row per pickup zone (262 active zones)
-- Depends on: {{ ref('fact_trips') }}, {{ ref('dim_zone') }}
-- =============================================================

WITH peak_hours AS (
    SELECT
        pickup_location_id,
        pickup_hour                 AS peak_hour,
        COUNT(*)                    AS peak_hour_trips
    FROM {{ ref('fact_trips') }}
    GROUP BY pickup_location_id, pickup_hour
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY pickup_location_id
        ORDER BY COUNT(*) DESC
    ) = 1
)

SELECT
    f.pickup_location_id                                AS zone_id,
    z.zone_name,
    z.borough,
    z.service_zone,
    z.is_airport,
    COUNT(*)                                            AS total_trips,
    ROUND(SUM(f.total_amount), 2)                       AS total_revenue,
    ROUND(AVG(f.total_amount), 2)                       AS avg_revenue_per_trip,
    ROUND(AVG(f.revenue_per_mile), 2)                   AS avg_revenue_per_mile,
    ROUND(AVG(f.revenue_per_hour), 2)                   AS avg_revenue_per_hour,
    ROUND(AVG(f.fare_amount), 2)                        AS avg_fare,
    ROUND(AVG(f.tip_amount), 2)                         AS avg_tip,
    ROUND(AVG(f.trip_distance_miles), 2)                AS avg_distance_miles,
    ROUND(AVG(f.trip_duration_minutes), 2)              AS avg_duration_minutes,
    ROUND(COUNTIF(f.is_credit_card) * 100.0 / COUNT(*), 1)     AS pct_credit_card,
    ROUND(COUNTIF(f.is_airport_pickup) * 100.0 / COUNT(*), 1)  AS pct_airport_trips,

    -- Zone efficiency score
    ROUND(
        AVG(f.revenue_per_mile) * AVG(f.revenue_per_hour) / 100, 2
    )                                                   AS zone_efficiency_score,

    -- Fleet allocation priority score (0-100)
    ROUND(
        (
            COUNT(*) / MAX(COUNT(*)) OVER() * 0.50
            + AVG(f.total_amount) / NULLIF(MAX(AVG(f.total_amount)) OVER(), 0) * 0.30
            + (AVG(f.revenue_per_mile) * AVG(f.revenue_per_hour) / 100)
              / NULLIF(MAX(AVG(f.revenue_per_mile) * AVG(f.revenue_per_hour) / 100) OVER(), 0) * 0.20
        ) * 100, 1
    )                                                   AS fleet_priority_score,

    -- Peak load factor
    ROUND(
        ph.peak_hour_trips / NULLIF(COUNT(*) / 24.0, 0), 2
    )                                                   AS peak_load_factor,

    -- Zone utilization proxy
    ROUND(
        COUNT(*) / NULLIF(AVG(COUNT(*)) OVER(), 0), 2
    )                                                   AS zone_utilization_proxy,

    ph.peak_hour

FROM {{ ref('fact_trips') }} f
LEFT JOIN {{ ref('dim_zone') }} z
    ON f.pickup_location_id = z.location_id
LEFT JOIN peak_hours ph
    ON f.pickup_location_id = ph.pickup_location_id

GROUP BY
    f.pickup_location_id,
    z.zone_name,
    z.borough,
    z.service_zone,
    z.is_airport,
    ph.peak_hour,
    ph.peak_hour_trips

ORDER BY total_trips DESC
