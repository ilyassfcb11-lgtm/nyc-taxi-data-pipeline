-- =============================================================
-- dim_zone.sql — Core: Zone Dimension Table
-- =============================================================
-- What is a dimension table?
--   A dimension table stores the descriptive attributes of a
--   business entity. Here: one row per NYC taxi zone with its
--   name, borough, and service zone type.
--
--   fact_trips stores location_id (a number).
--   dim_zone stores what that number means (a name + borough).
--   Joining them gives you "Upper East Side South, Manhattan"
--   instead of just "237".
-- =============================================================

CREATE OR REPLACE TABLE `nyc-taxi-intelligence.core.dim_zone`
AS

SELECT
    location_id,
    zone_name,
    borough,
    service_zone,

    -- Flag airport zones for easy filtering
    CASE
        WHEN location_id IN (132, 138) THEN TRUE
        ELSE FALSE
    END AS is_airport
    -- 132 = JFK Airport (Queens)
    -- 138 = LaGuardia Airport (Queens)

FROM `nyc-taxi-intelligence.staging.stg_zones`
;
