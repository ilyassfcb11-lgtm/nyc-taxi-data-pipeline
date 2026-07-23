-- =============================================================
-- stg_zones.sql — Staging: Clean Zone Lookup
-- =============================================================
-- Grain: one row per NYC taxi zone (265 rows)
-- Source: {{ source('raw', 'raw_zone_lookup') }}
-- =============================================================

SELECT
    CAST(LocationID AS INT64)         AS location_id,
    COALESCE(Borough, 'Unknown')      AS borough,
    COALESCE(Zone, 'Unknown')         AS zone_name,
    service_zone                      AS service_zone
FROM {{ source('raw', 'raw_zone_lookup') }}
WHERE LocationID IS NOT NULL
