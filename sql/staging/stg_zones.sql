-- =============================================================
-- stg_zones.sql — Staging: Clean Zone Lookup
-- =============================================================
-- Simple pass-through with consistent column naming.
-- 265 rows — one per NYC taxi zone.
-- =============================================================

CREATE OR REPLACE TABLE `nyc-taxi-intelligence.staging.stg_zones`
AS

SELECT
    CAST(LocationID AS INT64)   AS location_id,
    Borough                     AS borough,
    Zone                        AS zone_name,
    service_zone                AS service_zone
FROM `nyc-taxi-intelligence.raw.raw_zone_lookup`
WHERE LocationID IS NOT NULL
;
