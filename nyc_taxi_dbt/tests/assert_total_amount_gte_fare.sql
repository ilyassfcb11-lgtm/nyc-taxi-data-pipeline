-- =============================================================
-- assert_total_amount_gte_fare.sql
-- Business rule: total_amount must always >= fare_amount
-- Reason: total includes fare + tips + fees. It can NEVER be
-- less than the base fare. If it is, the record is corrupted.
-- Fails if: any trip has total_amount < fare_amount
-- =============================================================

SELECT
    pickup_datetime,
    pickup_location_id,
    fare_amount,
    total_amount,
    total_amount - fare_amount AS difference
FROM {{ ref('fact_trips') }}
WHERE total_amount < fare_amount
