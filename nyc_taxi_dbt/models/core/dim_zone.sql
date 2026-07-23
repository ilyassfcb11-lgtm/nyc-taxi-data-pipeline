-- =============================================================
-- dim_zone.sql — Core: Zone Dimension Table
-- =============================================================
-- Grain: one row per NYC taxi zone (265 rows)
-- Depends on: {{ ref('stg_zones') }}
-- =============================================================

SELECT
    location_id,
    zone_name,
    borough,
    service_zone,
    CASE
        WHEN location_id IN (132, 138) THEN TRUE
        ELSE FALSE
    END AS is_airport
    -- 132 = JFK Airport, 138 = LaGuardia Airport

FROM {{ ref('stg_zones') }}
