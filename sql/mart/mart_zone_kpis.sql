-- =============================================================
-- mart_zone_kpis.sql — Mart: Zone-Level KPIs
-- =============================================================
-- What this table answers:
--   "Which zones are most valuable, most efficient, most busy?"
--
-- Used in dashboard: Zone & Route Analysis page
--   - Top pickup zones by volume and revenue
--   - Zone efficiency scores + advanced operational KPIs
--   - Geographic performance comparison
--
-- Grain: one row per pickup zone (265 rows maximum)
--
-- KPIs included:
--   Basic    → total_trips, total_revenue, avg_revenue_per_trip/mile/hour
--   Scoring  → zone_efficiency_score
--   Advanced → fleet_priority_score, peak_load_factor, zone_utilization_proxy
-- =============================================================

CREATE OR REPLACE TABLE `nyc-taxi-intelligence.mart.mart_zone_kpis`
AS

-- CTE: peak hour per zone + trip count during that peak hour
-- Used for: peak_hour column + peak_load_factor KPI
-- peak_load_factor = how "spikey" demand is (peak hour ÷ avg hourly trips)
WITH peak_hours AS (
    SELECT
        pickup_location_id,
        pickup_hour                 AS peak_hour,
        COUNT(*)                    AS peak_hour_trips
    FROM `nyc-taxi-intelligence.core.fact_trips`
    GROUP BY pickup_location_id, pickup_hour
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY pickup_location_id
        ORDER BY COUNT(*) DESC
    ) = 1
    -- QUALIFY = 1 → keeps only the busiest hour per zone
)

SELECT
    -- -------------------------
    -- Zone identity
    -- -------------------------
    f.pickup_location_id                                AS zone_id,
    z.zone_name,
    z.borough,
    z.service_zone,
    z.is_airport,

    -- -------------------------
    -- Volume KPIs
    -- -------------------------
    COUNT(*)                                            AS total_trips,

    -- -------------------------
    -- Revenue KPIs
    -- -------------------------
    ROUND(SUM(f.total_amount), 2)                       AS total_revenue,
    ROUND(AVG(f.total_amount), 2)                       AS avg_revenue_per_trip,
    ROUND(AVG(f.revenue_per_mile), 2)                   AS avg_revenue_per_mile,
    ROUND(AVG(f.revenue_per_hour), 2)                   AS avg_revenue_per_hour,
    ROUND(AVG(f.fare_amount), 2)                        AS avg_fare,
    ROUND(AVG(f.tip_amount), 2)                         AS avg_tip,

    -- -------------------------
    -- Operational KPIs
    -- -------------------------
    ROUND(AVG(f.trip_distance_miles), 2)                AS avg_distance_miles,
    ROUND(AVG(f.trip_duration_minutes), 2)              AS avg_duration_minutes,

    -- -------------------------
    -- Payment mix
    -- -------------------------
    ROUND(COUNTIF(f.is_credit_card) * 100.0 / COUNT(*), 1)     AS pct_credit_card,
    ROUND(COUNTIF(f.is_airport_pickup) * 100.0 / COUNT(*), 1)  AS pct_airport_trips,

    -- -------------------------
    -- Zone efficiency score
    -- Composite: revenue_per_mile × revenue_per_hour (normalized by /100)
    -- Captures both distance efficiency and time efficiency together
    -- Higher = zone generates more revenue per unit of distance AND time
    -- -------------------------
    ROUND(
        AVG(f.revenue_per_mile) * AVG(f.revenue_per_hour) / 100,
        2
    )                                                   AS zone_efficiency_score,

    -- -------------------------
    -- ADVANCED KPI 1: Fleet Allocation Priority Score (0–100)
    -- -------------------------
    -- Question: "Where should we deploy more taxis?"
    -- Formula: weighted combination of three normalized signals:
    --   50% weight → trip volume   (how busy is this zone?)
    --   30% weight → avg revenue   (how profitable per trip?)
    --   20% weight → efficiency    (revenue per mile × per hour)
    --
    -- Each signal is normalized to 0–1 by dividing by its max across all zones
    -- (window function MAX() OVER() computes the global max without a subquery)
    -- Final score is multiplied by 100 → range 0 to 100
    -- Score of 100 = the single best zone on the weighted combination
    -- -------------------------
    ROUND(
        (
            -- Signal 1: volume (50%)
            COUNT(*) / MAX(COUNT(*)) OVER() * 0.50
            +
            -- Signal 2: revenue per trip (30%)
            AVG(f.total_amount) / NULLIF(MAX(AVG(f.total_amount)) OVER(), 0) * 0.30
            +
            -- Signal 3: zone efficiency (20%)
            (AVG(f.revenue_per_mile) * AVG(f.revenue_per_hour) / 100)
            / NULLIF(MAX(AVG(f.revenue_per_mile) * AVG(f.revenue_per_hour) / 100) OVER(), 0) * 0.20
        ) * 100,
        1
    )                                                   AS fleet_priority_score,

    -- -------------------------
    -- ADVANCED KPI 2: Peak Load Factor
    -- -------------------------
    -- Question: "How concentrated is demand in this zone's busiest hour?"
    -- Formula: peak_hour_trips ÷ (total_trips / 24)
    --   → numerator: trips in the single busiest hour (from CTE)
    --   → denominator: what trips-per-hour would look like if perfectly uniform
    -- Interpretation:
    --   Factor = 1.0 → demand is flat all day (no spike)
    --   Factor = 3.0 → peak hour has 3× the average hourly demand
    --   High factor → zone needs surge capacity; low factor → predictable steady flow
    -- -------------------------
    ROUND(
        ph.peak_hour_trips / NULLIF(COUNT(*) / 24.0, 0),
        2
    )                                                   AS peak_load_factor,

    -- -------------------------
    -- ADVANCED KPI 3: Zone Utilization Proxy
    -- -------------------------
    -- Question: "Is this zone over- or under-served relative to average?"
    -- Formula: zone_trips ÷ avg_trips_per_zone_across_all_zones
    --   AVG(COUNT(*)) OVER() = average trips across every zone
    -- Interpretation:
    --   Proxy = 1.0 → zone has exactly average demand
    --   Proxy > 1.0 → zone is busier than average (e.g. 7.5 = 7.5× average)
    --   Proxy < 1.0 → zone is quieter than average (potentially under-served)
    -- -------------------------
    ROUND(
        COUNT(*) / NULLIF(AVG(COUNT(*)) OVER(), 0),
        2
    )                                                   AS zone_utilization_proxy,

    -- Peak hour comes from the CTE
    ph.peak_hour

FROM `nyc-taxi-intelligence.core.fact_trips` f
LEFT JOIN `nyc-taxi-intelligence.core.dim_zone` z
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
    ph.peak_hour_trips   -- must be in GROUP BY since it comes from JOIN, not aggregation

ORDER BY total_trips DESC
;
